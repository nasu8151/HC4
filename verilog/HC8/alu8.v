`ifndef __alu8
`define __alu8

// ALU, Alithmetic Logic Unit
module alu8 (
    input wire [7:0] in_A,
    input wire [7:0] in_B,
    input wire [2:0] sel_in,
    input wire carry_in ,
    output wire [7:0] out ,
    output wire carry_out 
);
    wire [8:0] result;
    reg [7:0] internal_A;
    reg [7:0] internal_B;

    always @(*) begin
        case(sel_in)
            3'b010: begin            //Subtract
                internal_A = ~in_B;
                internal_B = in_A;
            end
            3'b011: begin            //Add
                internal_A = in_B;
                internal_B = in_A;
            end
            3'b100: begin            //Bitwise xor
                internal_A = in_A ^ in_B;
                internal_B = 8'b0;
            end
            3'b101: begin            //Bitwise or
                internal_A = in_A | in_B;
                internal_B = 8'b0;
            end
            3'b110: begin            //Bitwise and
                internal_A = in_A & in_B;
                internal_B = 8'b0;
            end
            3'b111: begin            //thru A
                internal_A = in_A;
                internal_B = 8'b0;
            end
            default: begin
                internal_A = 8'bx;   //don't care (Not a ALU instruction)
                internal_B = 8'bx;
            end
        endcase
    end

    assign result = internal_A + internal_B + carry_in;
    assign out = result[7:0];
    assign carry_out = result[8];
    
endmodule
`endif 