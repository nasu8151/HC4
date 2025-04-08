`include "./alu8.v"

module hc4 (
    input wire clk,
    input wire nReset,
    output wire [15:0]      pc_out,
    output wire [7:0]       stackA_out,
    output wire [7:0]       stackB_out,
    output wire [7:0]       stackC_out,
    output wire [15:0]       address_bus,
    inout  wire [7:0]       data_bus,
    output wire             nRAM_RD,
    output wire             nRAM_WR

);
    reg [7:0] level_A; //stack level A
    reg [7:0] level_B; //stack level B
    reg [7:0] level_C; //stack level C
    reg [15:0] pc;


    reg [7:0] ram [0:255];
    reg [7:0] rom [0:4095];

    // wire [15:0] address_bus;
    // wire [7:0] data_bus;

    initial $readmemh("./test.hex", rom);

    reg [7:0] instruction;

    wire sub;

    wire [7:0] alu_result;
    wire carry;
    reg  carry_flg;
    reg  zero_flg;

    assign pc_out = pc;
    assign stackA_out = level_A;
    assign stackB_out = level_B;
    assign stackC_out = level_C;
    assign sub = instruction[6:4] == 3'b010 ? 1 : 0; //if opcode is 0010 (1010 is not ALU oplation)
    assign nRAM_WR = !(!instruction[7] & !clk);
    assign nRAM_RD = !(instruction[7] & !instruction[6] & !instruction[5] & !clk);

    alu8 ALU (
        .in_A (level_A),
        .in_B (level_B),
        .sel_in (instruction[6:4]),
        .carry_in (sub),
        .out (alu_result),
        .carry_out (carry)
    );


    function [15:0] ADDRESS_MUX(input [7:0] instruction, input [7:0] level_A, input [7:0] level_B);
        if (instruction[6:4] == 3'b000) begin  //if addressing mode is [AB]
            ADDRESS_MUX[7:0] = level_A;
            ADDRESS_MUX[15:8] = level_B;
        end else begin                         //if addressing mode is not [AB] (r, i)
            ADDRESS_MUX[15:4] = 12'h0;
            ADDRESS_MUX[3:0] = instruction[3:0];
        end
    endfunction
    assign address_bus = ADDRESS_MUX(instruction[7:0], level_A, level_B);
    
    function [15:0] NEXT_PC(input [7:0] instruction, input [15:0] pc, input [7:0] level_A, input [7:0] level_B, input C_flag, input Z_flag);
        reg nJMP;
        if (instruction[7:5] == 3'b111) begin // if current instruction is Jump
            case (instruction[2:0])
                3'b000: NEXT_PC = {level_B, level_A};              // JP
                3'b001: NEXT_PC = pc + 1;              // NP
                3'b010: begin                  // JC
                    if (C_flag == 1) NEXT_PC = {level_B, level_A};
                    else             NEXT_PC = pc + 1;
                end
                3'b011: begin                  // JNC
                    if (C_flag == 0) NEXT_PC = {level_B, level_A};
                    else             NEXT_PC = pc + 1;
                end
                3'b100: begin                  // JZ
                    if (Z_flag == 1) NEXT_PC = {level_B, level_A};
                    else             NEXT_PC = pc + 1;
                end
                3'b101: begin                  // JNZ
                    if (Z_flag == 0) NEXT_PC = {level_B, level_A};
                    else             NEXT_PC = pc + 1;
                end
                default:  NEXT_PC = pc + 1;
            endcase
        end else begin
            NEXT_PC = pc + 1;
        end
    endfunction

    function [7:0] BUS_CTRL (input [7:0] instruction, input [7:0] alu_result, input [7:0] level_C, input [7:0] level_A);
        casez (instruction[7:5])
            3'b000:  BUS_CTRL = level_C;          //SC
            3'b0??:  BUS_CTRL = alu_result;       //ALU instructions (include SA)
            3'b100:  BUS_CTRL = 8'bz; //LD [AB] or LD r (RAM)
            3'b101: begin
                BUS_CTRL[7:4] = level_A[7:4]; 
                BUS_CTRL[3:0] = instruction[3:0]; //LD #i
            end
            3'b110: begin
                BUS_CTRL[7:4] = level_A[3:0]; 
                BUS_CTRL[3:0] = instruction[3:0]; //LS #i                
            end
            default: BUS_CTRL = 8'bx;             //JP doesnt care data bus
        endcase
    endfunction
    assign data_bus = BUS_CTRL(instruction, alu_result, level_C, level_A);

    always @(posedge clk or negedge nReset) begin
        if (nReset == 0) begin
            carry_flg <= 1'b0;
            zero_flg <= 1'b0;
            level_A <= 8'b0;
            level_B <= 8'b0;
            level_C <= 8'b0;
            instruction <= 8'b0;
        end else begin
            casez (instruction[7:5])
                3'b0??: begin // if current instruction is an instruction which stores in the memory or registers
                    // ram[address_bus] <= data_bus;
                    zero_flg  <= data_bus == 4'b0 ? 1 : 0;
                    carry_flg <= instruction[7:5] == 3'b001 ? carry : carry_flg;
                end 
                3'b10?: begin
                    level_A <= data_bus;
                    level_B <= level_A;
                    level_C <= level_B;
                end
                3'b110: begin
                    level_A <= data_bus;
                end
                3'b111: begin
                    //nothing to write here
                end
            endcase
            instruction <= rom[pc];
        end
    end

    always @(negedge clk or negedge nReset) begin
        if (nReset == 0) begin
            pc = 16'b0;
        end else begin
            pc <= NEXT_PC(instruction, pc, level_A, level_B, carry_flg, zero_flg);
        end
    end
endmodule