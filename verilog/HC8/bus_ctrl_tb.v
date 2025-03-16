`timescale 1ns / 1ps

module bus_ctrl_tb;
    reg [7:0] instruction;
    reg [7:0] alu_result;
    reg [7:0] level_C;
    reg [7:0] level_A;
    reg [7:0] ram [0:255]; // メモリを模擬
    wire [7:0] data_out;
    
    function [7:0] BUS_CTRL (input [7:0] instruction, input [7:0] alu_result, input [7:0] level_C, input [7:0] level_A);
        casez (instruction[7:4])
            4'b0000:  BUS_CTRL = level_C;          //SC
            4'b0???:  BUS_CTRL = alu_result;       //ALU instructions (include SA)
            4'b1000:  BUS_CTRL = ram[instruction[3:0]]; //LD [AB] or LD r (RAM)
            4'b1010: begin
                BUS_CTRL[7:4] = level_A[7:4]; 
                BUS_CTRL[3:0] = instruction[3:0]; //LD #i
            end
            4'b1100: begin
                BUS_CTRL[7:4] = level_A[3:0]; 
                BUS_CTRL[3:0] = instruction[3:0]; //LS #i                
            end
            default: BUS_CTRL = 8'bx;             //JP doesnt care data bus
        endcase
    endfunction

    assign data_out = BUS_CTRL(instruction, alu_result, level_C, level_A);

    initial begin
        $dumpfile("bus_ctrl_tb.vcd");
        $dumpvars(0, bus_ctrl_tb);
        
        // テストケース1: SC
        instruction = 8'b00000000;
        level_C = 8'b11001100;
        alu_result = 8'b00000000;
        level_A = 8'b00000000;
        #10;
        $display("SC Output: %b", data_out);
        
        // テストケース2: ALU操作
        instruction = 8'b01000000;
        alu_result = 8'b10101010;
        #10;
        $display("ALU Output: %b", data_out);
        
        // テストケース3: メモリ読み出し (LD [AB])
        ram[5] = 8'b11110000;
        instruction = 8'b10000101;
        #10;
        $display("LD [AB] Output: %b", data_out);
        
        // テストケース4: LD #i
        instruction = 8'b10100011;
        level_A = 8'b01010101;
        #10;
        $display("LD #i Output: %b", data_out);
        
        // テストケース5: LS #i
        instruction = 8'b11000111;
        level_A = 8'b11110000;
        #10;
        $display("LS #i Output: %b", data_out);
        
        // シミュレーション終了
        #10;
        $finish;
    end
endmodule
