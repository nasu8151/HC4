module hc4_onefile (
    input wire clk,
    input wire rst_n,
    output wire [11:0]      pc_out,
    output wire [3:0]       stackA_out,
    output wire [3:0]       stackB_out,
    output wire [3:0]       stackC_out,
    output wire [7:0]       address_bus,
    inout  wire [3:0]       data_bus,
    output wire             nRAM_RD,
    output wire             nRAM_WR

);
    // Internal signals
    reg [3:0] level_A; //stack level A
    reg [3:0] level_B; //stack level B
    reg [3:0] level_C; //stack level C
    reg [11:0] pc;

    reg [7:0] rom [0:4095];

    initial $readmemh("./jmptest.hex", rom);

    wire [7:0] instruction;

    wire [3:0] opcode;
    wire [3:0] oprand;

    reg [3:0] alu_result;
    reg  carry_out;
    reg  carry_flg;
    reg  zero_flg;

    assign instruction = rom[pc];
    assign pc_out = pc;

    assign opcode = instruction[7:4];
    assign oprand = instruction[3:0];

    assign stackA_out = level_A;
    assign stackB_out = level_B;
    assign stackC_out = level_C;
    assign address_bus = (opcode == 4'b0000 || opcode == 4'b1000) ? {level_A, level_B} : {4'b0000, oprand};
    assign data_bus = (opcode[3] == 1'b0) ? alu_result : 4'bz; //write to data bus for ALU output or immediate data

    assign nRAM_WR = !(!instruction[7] & !clk);
    assign nRAM_RD = !(instruction[7] & !instruction[6] & !instruction[5] & !clk);

    // ALU module
    always @(*) begin
        case (opcode)
            4'b000?: alu_result = level_C; //SM, SC
            4'b0010: {carry_out, alu_result} = level_A - level_B; //SU
            4'b0011: {carry_out, alu_result} = level_A + level_B; //AD
            4'b0100: alu_result = level_A ^ level_B; //XR
            4'b0101: alu_result = level_A | level_B; //OR
            4'b0110: alu_result = level_A & level_B; //AN
            4'b0111: alu_result = level_A;           //SA
            default: alu_result = 4'b0000;
        endcase
    end
    // Main sequential logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc <= 12'b0;
            level_A <= 4'b0;
            level_B <= 4'b0;
            level_C <= 4'b0;
            carry_flg <= 1'b0;
            zero_flg <= 1'b0;
        end else begin
            // Update flags
            zero_flg <= (alu_result == 4'b0000) ? 1'b1 : 1'b0;

            // Execute instruction based on opcode
            case (opcode)
                4'b0???: begin // Stack operations
                    zero_flg <= (alu_result == 4'b0000) ? 1'b1 : 1'b0;
                    if (opcode == 4'b0010 || opcode == 4'b0011) begin
                        carry_flg <= carry_out;
                    end
                    pc <= pc + 1;
                end
                4'b100?: begin // LM, LD
                    level_A <= data_bus;
                    level_B <= level_A;
                    level_C <= level_B;
                    pc <= pc + 1;
                end
                4'b101?: begin // LI
                    level_A <= oprand;
                    level_B <= level_A;
                    level_C <= level_B;
                    pc <= pc + 1;
                end
                4'b1110: begin //JP, NP
                    case (instruction[2:0])
                        3'b000: pc <= {level_C, level_B, level_A};              // JP
                        3'b001: pc <= pc + 1;              // NP
                        3'b010: pc <= (carry_flg == 1) ? {level_C, level_B, level_A} : pc + 1; // JP C
                        3'b011: pc <= (carry_flg == 0) ? {level_C, level_B, level_A} : pc + 1; // JP NC
                        3'b100: pc <= (zero_flg == 1) ? {level_C, level_B, level_A} : pc + 1;  // JP Z
                        3'b101: pc <= (zero_flg == 0) ? {level_C, level_B, level_A} : pc + 1;  // JP NZ
                        default: pc <= pc + 1;
                    endcase
                end
            endcase
        end
    end
endmodule