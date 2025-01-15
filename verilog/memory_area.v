`include "rom.v"
`include "ram.v"

`ifndef __memory_area
`define __memory_area

module memory_area (
    input wire [15:0] address,
    tri wire [7:0] data,
    input wire clk,
    input wire r_nW
);
    
endmodule
`endif 