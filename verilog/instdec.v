`ifndef __instdec
`define __instdec

module instdec (
    input wire [15:0] rom_in,
    input wire clk,
    output wire [2:0] alu_sel,
    output wire nAccum_sel,
    output wire nIndex_X_sel,
    output wire nIndex_Y_sel,
    output reg [7:0] data
);

    wire [3:0] decoded;
    reg [7:0] instruction;

    always @(posedge clk) begin
        instruction <= rom_in[15:8];
        data <= rom_in[7:0];
    end

    assign alu_sel = instruction[5:3];

    assign decoded = 4'b0001 << instruction[1:0];
    assign nAccum_sel = ~decoded[0];
    assign nIndex_X_sel = ~decoded[2];
    assign nIndex_Y_sel = ~decoded[3];
endmodule
`endif