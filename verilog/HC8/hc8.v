`include "alu.v"

module hc4 (
    input wire clk,
    input wire nReset,
    output wire [11:0]      pc_out,
    output wire [3:0]       stackA_out,
    output wire [3:0]       stackB_out,
    output wire [3:0]       stackC_out

);
    reg [7:0] level_A; //stack level A
    reg [7:0] level_B; //stack level B
    reg [7:0] level_C; //stack level C
    reg [15:0] pc;


    reg [7:0] ram [0:255];
    reg [7:0] rom [0:4095];

    wire [7:0] address_bus;
    wire [3:0] data_bus;

    initial $readmemh("./jmptest.hex", rom);

    wire [7:0] instruction;

    wire sub;

    wire [7:0] alu_result;
    wire carry;
    reg  carry_flg;
    reg  zero_flg;

    assign instruction = rom[pc];
    assign pc_out = pc;
    assign stackA_out = level_A;
    assign stackB_out = level_B;
    assign stackC_out = level_C;
    assign sub = instruction[6:4] == 3'b010 ? 1 : 0; //if opcode is 0010 (1010 is not ALU oplation)


    alu ALU (
        .in_A (level_A),
        .in_B (level_B),
        .sel_in (instruction[6:4]),
        .carry_in (sub),
        .out (alu_result),
        .carry_out (carry)
    );


    function [7:0] ADDRESS_MUX(input [7:0] instruction, input [3:0] level_A, input [3:0] level_B);
        if (instruction[6:4] == 3'b000) begin  //if addressing mode is [AB]
            ADDRESS_MUX[3:0] = level_A;
            ADDRESS_MUX[7:4] = level_B;
        end else begin                         //if addressing mode is not [AB] (r, i)
            ADDRESS_MUX[7:4] = 4'h0;
            ADDRESS_MUX[3:0] = instruction[3:0];
        end
    endfunction
    assign address_bus = ADDRESS_MUX(instruction[7:0], level_A, level_B);
    
    function [11:0] NEXT_PC(input [7:0] instruction, input [11:0] pc, input [3:0] level_A, input [3:0] level_B, input [3:0] level_C, input C_flag, input Z_flag);
        reg nJMP;
        if (instruction[7:5] == 3'b111) begin // if current instruction is Jump
            case (instruction[2:0])
                3'b000: nJMP = 0;              // JP
                3'b001: nJMP = 1;              // NP
                3'b010: begin                  // JC
                    if (C_flag == 1)  nJMP = 0;
                    else              nJMP = 1;
                end
                3'b011: begin                  // JNC
                    if (C_flag == 0)  nJMP = 0;
                    else              nJMP = 1;
                end
                3'b100: begin                  // JZ
                    if (Z_flag == 1)  nJMP = 0;
                    else              nJMP = 1;
                end
                3'b101: begin                  // JNZ
                    if (Z_flag == 0)  nJMP = 0;
                    else              nJMP = 1;
                end
                default:  nJMP = 1;
            endcase
        end else begin
            nJMP = 1;
        end
        NEXT_PC = nJMP == 0 ? {level_C, level_B, level_A} : pc + 1;
    endfunction

    function [3:0] BUS_CTRL (input [7:0] instruction, input [3:0] alu_result, input [3:0] ram_out, input [3:0] level_C);
        casez (instruction[7:5])
            3'b000:  BUS_CTRL = level_C;          //SC
            3'b0??:  BUS_CTRL = alu_result;       //ALU instructions (include SA)
            3'b100:  BUS_CTRL = ram_out;          //LD [AB]
            3'b101:  BUS_CTRL = instruction[3:0]; //LD i
            default: BUS_CTRL = 4'bx;             //jp doesnt care data bus ;-)
        endcase
    endfunction
    assign data_bus = BUS_CTRL(instruction, alu_result, ram[address_bus], level_C);

    always @(posedge clk or negedge nReset) begin
        if (nReset == 0) begin
            pc <= 12'b0;
            carry_flg <= 1'b0;
            zero_flg <= 1'b0;
            level_A <= 4'b0;
        end else begin
            casez (instruction[7:6])
                2'b0?: begin // if current instruction is an instruction which stores in the memory or registers
                    ram[address_bus] <= data_bus;
                    zero_flg  <= data_bus == 4'b0 ? 1 : 0;
                    carry_flg <= instruction[7:5] == 3'b001 ? carry : carry_flg;
                end 
                2'b10: begin
                    level_A <= data_bus;
                    level_B <= level_A;
                    level_C <= level_B;
                end
                2'b11: begin
                    //nothing to write here
                end
            endcase
            pc <= NEXT_PC(instruction, pc, level_A, level_B, level_C, carry_flg, zero_flg);
        end
    end
endmodule