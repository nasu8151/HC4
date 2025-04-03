`timescale 1ns / 1ps
`include "ram.v"

module hc8_tb;

    // 入出力信号の宣言
    reg clk;
    reg nReset;
    wire [15:0] pc_out;
    wire [7:0]  level_A;
    wire [7:0]  level_B;
    wire [7:0]  level_C;
    wire [15:0] address_bus;
    wire [7:0]  data_bus;
    wire nRAM_RD;
    wire nRAM_WR;

    // メモリ兼レジスタの宣言
    memory_8bit_64kbyte ram (
        .address(address_bus),
        .data_bus(data_bus),
        .nchip_enable(1'b0),
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
        .nRAM_RD(nRAM_RD),
        .nRAM_WR(nRAM_WR),
        .address_bus(address_bus),
        .data_bus(data_bus)
    );

    // クロック生成
    always #5 clk = ~clk;

    // テストシナリオ
    initial begin
        // 波形ファイル生成（シミュレーション確認用）
        $dumpfile("hc8_tb.vcd");
        $dumpvars(0, hc8_tb);

        // 初期化
        clk = 0;
        nReset = 0;

        // リセット解除とテスト開始
        #10 nReset = 1;

        // シミュレーション実行時間
        #800 $finish;
    end

    // テスト結果表示
    always @(negedge clk) begin
        $display("Time=%0t | PC=%d | levelA=%h | levelB=%h | levelC=%h", $time, pc_out, level_A, level_B, level_C);
    end

endmodule
