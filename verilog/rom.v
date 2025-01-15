`ifndef __rom
`define __rom

module rom (
    input wire [15:0] address,
    output wire [15:0] data
);
    reg [15:0] buffer;
    always @(*) begin
        case (address)
            16'h0000: 16'b0000000000000000 
            default: 16'hFFFF
        endcase
    end
    assign data = buffer;
endmodule
`endif