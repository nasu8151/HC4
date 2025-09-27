`timescale 1ns / 1ns
`include "ram.v"

module hc4_tb;

    // 入出力信号の宣言
    reg clk;
    reg nReset;
    wire [11:0] pc_out;
    wire [3:0] level_A;
    wire [3:0] level_B;
    wire [3:0] level_C;
    wire [7:0] address_bus;
    wire [3:0] data_bus;
    wire nRAM_RD;
    wire nRAM_WR;

    //メモリー兼レジスタの宣言
    memory_4bit_256nibble ram (
        .address(address_bus),
        .data_bus(data_bus),
        .nwrite_enable(nRAM_WR),
        .nread_enable(nRAM_RD)
    );
    // テスト対象モジュールのインスタンス化
    hc4 uut (
        .clk(clk),
        .nReset(nReset),
        .pc_out(pc_out),
        .stackA_out(level_A),
        .stackB_out(level_B),
        .stackC_out(level_C),
        .address_bus(address_bus),
        .data_bus(data_bus),
        .nRAM_RD(nRAM_RD),
        .nRAM_WR(nRAM_WR)
    );

    // クロック生成
    always #500 clk = ~clk;

    // テストシナリオ
    initial begin
        // 波形ファイル生成（シミュレーション確認用）
        $dumpfile("hc4_tb.vcd");
        $dumpvars(0, hc4_tb);

        // 初期化
        clk = 0;
        nReset = 0;

        // リセット解除とテスト開始
        #10 nReset = 1;

        // シミュレーション実行時間
        #200000000 $finish;
    end

    always @(*) begin
        if (address_bus == 8'hF2 && nRAM_WR == 0) begin
            $display("Time=%0t | PC=%d | levelA=%b | levelB=%b | levelC=%b | ADDR=%h | DATA_OUT=%h | nRAM_WR=%b | nRAM_RD=%b", $time, pc_out, level_A, level_B, level_C, address_bus, data_bus, nRAM_WR, nRAM_RD);
        end
        if (address_bus == 8'hF3 && nRAM_WR == 0) begin
            $display("Time=%0t | PC=%d | levelA=%b | levelB=%b | levelC=%b | ADDR=%h | DATA_OUT=%h | nRAM_WR=%b | nRAM_RD=%b", $time, pc_out, level_A, level_B, level_C, address_bus, data_bus, nRAM_WR, nRAM_RD);
        end
    end

    // テスト結果表示
    // always @(negedge clk) begin
    //     $display("Time=%0t | PC=%d | levelA=%b | levelB=%b | levelC=%b", $time, pc_out, level_A, level_B, level_C);
    // end

endmodule
