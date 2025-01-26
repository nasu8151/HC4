`include "alu.v"

module hc4 (
    input wire clk,
    input wire nReset,
    output wire [11:0] pc_out,
    output wire [7:0] instruction_out,
    output wire [3:0] alu_out
);
    reg [3:0] level_A; //stack level A
    reg [3:0] level_B; //stack level B
    reg [3:0] level_C; //stack level C
    reg [11:0] pc;

    assign pc_out = pc;

    reg [3:0] ram [0:255];
    reg [7:0] rom [0:4095];

    wire [7:0] address_bus;
    wire [3:0] data_bus;

    initial $readmemh("./test.hex", rom);

    reg [7:0] instruction;
    assign instruction_out = instruction;

    wire sub;
    assign sub = instruction[6:4] == 3'b010 ? 1 : 0; //if opcode is 0010 (1010 is not ALU oplation)

    wire [3:0] alu_result;
    wire carry;
    reg  carry_flg;
    reg  zero_flg;

    alu ALU (
        .in_A (level_A),
        .in_B (level_B),
        .sel_in (instruction[6:4]),
        .carry_in (sub),
        .out (alu_result),
        .carry_out (carry)
    );

    assign alu_out = alu_result;

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
        if (instruction[7:5] == 3'b111) begin // if current instruction is Jump
            case (instruction[2:1])
                2'b00: begin                  
                    if (instruction[0] == 0) begin // JP
                        NEXT_PC[11:8] = level_C;
                        NEXT_PC[7:4]  = level_B;
                        NEXT_PC[3:0]  = level_A;
                    end else begin                 // NP
                        NEXT_PC = pc + 1;
                    end
                end
                2'b01: begin                  // JC
                    if (C_flag == 1) begin
                        NEXT_PC[11:8] = level_C;
                        NEXT_PC[7:4]  = level_B;
                        NEXT_PC[3:0]  = level_A;
                    end else begin
                        NEXT_PC = pc + 1;
                    end
                end
                2'b10: begin                  // JZ
                    if (Z_flag == 1) begin
                        NEXT_PC[11:8] = level_C;
                        NEXT_PC[7:4]  = level_B;
                        NEXT_PC[3:0]  = level_A;
                    end else begin
                        NEXT_PC = pc + 1;
                    end
                end
                default: NEXT_PC = 12'bx;
            endcase
        end else begin
            NEXT_PC = pc + 1;
        end
        
    endfunction

    function [3:0] BUS_CTRL (input [7:0] instruction, input [3:0] alu_result, input [3:0] ram_out);
        if (instruction[7] == 0)             BUS_CTRL = alu_result;
        else if (instruction[7:5] == 3'b100) BUS_CTRL = ram_out;
        else if (instruction[7:5] == 3'b101) BUS_CTRL = instruction[3:0];
        else                                 BUS_CTRL = 4'bx;
    endfunction
    assign data_bus = BUS_CTRL(instruction, alu_out, ram[address_bus]);

    always @(posedge clk or negedge nReset) begin
        if (nReset == 0) begin
            pc = 12'b0;
        end else begin
            pc = NEXT_PC(instruction, pc, level_A, level_B, level_C, carry_flg, zero_flg);
        end
    end

    always @(negedge clk ) begin
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
        instruction <= rom[pc];
    end
endmodule