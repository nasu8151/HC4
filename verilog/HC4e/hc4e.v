/*
iverilog -o hc4e_tb.out -s hc4e_tb hc4e_tb.v hc4e.v
vvp hc4e_tb.out
*/
`include "alu.v"

module hc4e (
    input wire clock,
    input wire nReset,
    input wire [7:0] instruction,
    output wire [7:0]      pc_out,
    output wire [3:0]       stackA_out,
    output wire [3:0]       stackB_out,
    inout  wire [3:0]       data_bus,
    output wire [3:0]       address_bus,
    output wire             nRAM_RD,
    output wire             nRAM_WR

);
    reg [3:0] level_A; //stack level A
    reg [3:0] level_B; //stack level B
    reg [7:0] pc;
    reg [23:0] prescale;
    reg clk;




    wire sub;

    wire [3:0] alu_result;
    wire carry;
    reg  carry_flg;
    reg  zero_flg;

    assign pc_out = pc;
    assign stackA_out = level_A;
    assign stackB_out = level_B;
    assign sub = instruction[6:4] == 3'b010 ? 1 : 0; //if opcode is 0010 (1010 is not ALU oplation)
    assign nRAM_WR = !(!instruction[7] & !clk);
    assign nRAM_RD = !(instruction[7] & !instruction[6] & !instruction[5] & !clk);
    assign address_bus = instruction[3:0];

    initial begin
        prescale = 24'd0;
        clk    = 1'd0;
    end

        always @(posedge clock) begin
        if (prescale == 24'd9_999_999) begin
            prescale <= 24'd0;         // プリスケールをクリア
            clk    <= ~clk;  // 1 Hz ごとにメインカウンタを +1
        end else begin
            prescale <= prescale + 24'd1; // それ以外はプリスケールをインクリメント
        end
    end
    
    alu ALU (
        .in_A (level_A),
        .in_B (level_B),
        .sel_in (instruction[6:4]),
        .carry_in (sub),
        .out (alu_result),
        .carry_out (carry)
    );
    
    function [7:0] NEXT_PC(input [7:0] instruction, input [7:0] pc, input [3:0] level_A, input [3:0] level_B, input C_flag);
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
                default:  NEXT_PC = pc + 1;
            endcase
        end else begin
            NEXT_PC = pc + 1;
        end
    endfunction

    function [3:0] BUS_CTRL (input [7:0] instruction, input [3:0] alu_result);
        casez (instruction[7:5])
            3'b0??:  BUS_CTRL = alu_result;       //ALU instructions (include SA)
            3'b100:  BUS_CTRL = 4'bz;             //LD [AB] or LD r (RAM)
            3'b101:  BUS_CTRL = instruction[3:0]; //LD i
            default: BUS_CTRL = 4'bx;             //jp doesnt care data bus
        endcase
    endfunction
    assign data_bus = BUS_CTRL(instruction, alu_result);

    always @(posedge clk or negedge nReset) begin
        if (nReset == 0) begin
            pc <= 8'b0;
            carry_flg <= 1'b0;
            level_A <= 4'b0;
        end else begin
            casez (instruction[7:6])
                2'b0?: begin // if current instruction is an instruction which stores in the memory or registers
                    carry_flg <= instruction[7:5] == 3'b001 ? carry : carry_flg;
                end 
                2'b10: begin
                    level_A <= data_bus;
                    level_B <= level_A;
                end
                2'b11: begin
                    //nothing to write here
                end
            endcase
            pc <= NEXT_PC(instruction, pc, level_A, level_B, carry_flg);
        end
    end
endmodule