module hc4 (
    input wire clk,
    input wire rst_n,
    output wire [7:0]      pc_out,
    output wire [3:0]       stackA_out,
    output wire [3:0]       stackB_out,
    output wire [3:0]       address_bus,
    inout  wire [3:0]       data_bus,
    output wire             rd_n,
    output wire             wr_n

);
    // Internal signals
    reg [3:0] level_A; //stack level A
    reg [3:0] level_B; //stack level B
    // reg [3:0] level_C; //stack level C
    reg [7:0] pc;

    reg [7:0] rom [0:255];

    initial $readmemh("./jmptest.hex", rom);

    wire [7:0] instruction;

    wire [3:0] opcode;
    wire [3:0] oprand;

    reg [3:0] alu_result;
    reg  carry_out;
    reg  carry_flg;

    assign instruction = rom[pc];
    assign pc_out = pc;

    assign opcode = instruction[7:4];
    assign oprand = instruction[3:0];

    assign stackA_out = level_A;
    assign stackB_out = level_B;
    // assign stackC_out = level_C;
    assign address_bus = oprand; //address bus is used for memory access with immediate operand
    assign data_bus = (opcode[3] == 1'b0) ? alu_result : 4'bz; //write to data bus for ALU output or immediate data

    assign wr_n = !(!opcode[3] & !clk);
    assign rd_n = !(opcode[3:1] == 3'b100 & !clk);

    assign stack_op = (opcode[3] == 1'b0) ? 1'b1 : 1'b0; //stack operation if opcode[3] is 0, else memory operation
    assign add_sub  = (opcode[3:1] == 3'b001) ? 1'b1 : 1'b0; //AD or SU if opcode == 0010 or 0011
    assign lm_ld    = (opcode[3:1] == 3'b100) ? 1'b1 : 1'b0; //LM or LD if opcode[3:1] is 100
    assign li       = (opcode[3:1] == 3'b101) ? 1'b1 : 1'b0; //LI if opcode[3:1] is 101
    assign jp_np    = (opcode[3:1] == 3'b111) ? 1'b1 : 1'b0; //JP or NP if opcode[3:1] is 111

    // ALU module
    always @(*) begin
        casez (opcode)
            // 4'b000?: alu_result = level_C; //SM, SC
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
            pc <= 8'b0;
            // level_A <= 4'b0;
            // level_B <= 4'b0;
            // level_C <= 4'b0;
            carry_flg <= 1'b0;
        end else begin
            // Execute instruction based on opcode
            if (stack_op) begin
                if (opcode == 4'b0010 || opcode == 4'b0011) begin
                    carry_flg <= carry_out;
                end
            end
            if (lm_ld) begin
                level_A <= data_bus;
                level_B <= level_A;
                // level_C <= level_B;
            end
            if (li) begin
                level_A <= oprand;
                level_B <= level_A;
                // level_C <= level_B;
            end
            if (jp_np) begin //JP, NP
                case (instruction[2:0])
                    3'b000: pc <= {level_B, level_A};              // JP
                    3'b001: pc <= pc + 1;              // NP
                    3'b010: pc <= (carry_flg == 1) ? {level_B, level_A} : pc + 1; // JP C
                    3'b011: pc <= (carry_flg == 0) ? {level_B, level_A} : pc + 1; // JP NC
                    default: pc <= pc + 1;
                endcase
            end else begin
                pc <= pc + 1;
            end
        end
    end
endmodule
