`ifndef __alu
`define __alu

// ALU, Alithmetic Logic Unit
module alu (
    input wire [3:0] in_A,
    input wire [3:0] in_B,
    input wire [2:0] sel_in,
    input wire carry_in ,
    output wire [3:0] out ,
    output wire carry_out 
);
    wire [4:0] result;
    reg [3:0] internal_A;
    reg [3:0] internal_B;

    always @(*) begin
        case(sel_in)
            3'b011: begin            //Add
                internal_A = in_A;
                internal_B = in_B;
            end
            3'b100: begin            //Bitwise xor
                internal_A = in_A ^ in_B;
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
    assign out = result[3:0];
    assign carry_out = result[4];
    
endmodule
`endif 