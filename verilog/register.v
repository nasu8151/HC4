`ifndef __register
`define __register

module register #(
    parameter WIDTH = 4
)(
    input wire [WIDTH-1:0] in,
    input wire clk,
    input wire nEnable,
    input wire nReset,
    output reg [WIDTH-1:0] out
);
    always @(posedge clk or negedge nReset) begin
        if (!nReset) begin
            out <= 4'b0;
        end else if (!nEnable) begin
            out <= in;
        end
    end
endmodule
`endif