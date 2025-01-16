`ifndef __rom
`define __rom

module rom (
    input wire [11:0] address,
    output reg [7:0] data
);
    always @(*) begin
        case (address)
            12'h000: data = 8'hDE;
            12'h001: data = 8'hAD;
            12'h002: data = 8'hBE;
            12'h003: data = 8'hEF;
            12'h004: data = 8'h19;
            12'h005: data = 8'h19;
            default: data = 8'hFF;
        endcase
    end
endmodule

`endif
