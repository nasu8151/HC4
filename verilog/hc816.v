`include "alu.v"
`include "instdec.v"
`include "register.v"
`include "counter.v"

module hc816;
    reg clk = 1'b0;
    reg nReset = 1'b0;
    reg [7:0] dataBus;
    wire [15:0] ram_Address;
    wire carry;
    reg carry_flg;
    wire [7:0] aluResultBus;
    wire [7:0] alu_A;
    wire [7:0] indexX_out;
    wire [7:0] indexY_out;
    wire [15:0] rom_Address;
    wire [15:0] rom_Data;
    wire accumlator_Enable;
    wire index_X_Enable;
    wire index_Y_Enable;

    // temporaly params. may change.
    reg [2:0] sel;

    register accumlator(.in (aluResultBus), .clk (clk), .nEnable (accumlator_Enable), .nReset (nReset), .out (alu_A));
    register indexreg_X(.in (aluResultBus), .clk (clk), .nEnable (index_X_Enable), .nReset (nReset), .out (indexX_out));
    register indexreg_Y(.in (aluResultBus), .clk (clk), .nEnable (index_Y_Enable), .nReset (nReset), .out (indexY_out));

    alu ALU(.in_A (alu_A), .in_B (dataBus), .sel_in (sel), .carry_in (1'b0), .out (aluResultBus), .carry_out (carry));
    counter programCounter8H(.in (indexY_out), .clk (clk), .nLoadEnable (), .countEnable (), .nReset (nReset), .out (rom_Address[15:8]));
    counter programCounter8L(.in (indexY_out), .clk (clk), .nLoadEnable (), .countEnable (), .nReset (nReset), .out (rom_Address[7:0]));
    rom programROM(.address (rom_Address), .data (rom_Data));

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, alu_A, dataBus, clk, nReset, sel, carry_flg);
    end

    always #1 begin
        clk <= ~clk;
    end
    
    initial begin
        #2
        sel = 3'b000;
        #1
        nReset = 1'b1;
        #2
        dataBus = 8'd21;
        sel = 3'b100;
        #2
        dataBus = 8'd100;
        sel = 3'b101;
        #20
        dataBus = 8'd50;
        sel = 3'b100;
        #4
        $finish;
    end

    always @(posedge clk ) begin
        carry_flg <= carry;
    end
    
endmodule