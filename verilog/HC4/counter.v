`ifndef __counter
`define __counter

module counter #(
    parameter WIDTH = 12
) (
    input wire [WIDTH-1:0] in,
    input wire clk,
    input wire nLoadEnable,
    input wire countEnable,
    input wire nReset,
    output reg [WIDTH-1:0] out
);

    always @(posedge clk or negedge nReset) begin
        if (!nReset) begin
            out <= 12'b0;
        end else if (!nLoadEnable) begin
            out <= in;
        end else if (countEnable) begin
            out <= out + 1;
        end
    end
endmodule
`endif