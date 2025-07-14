`timescale 1ns / 1ps
`include "ram.v"

module hc4e_tb;

    // 入出力信号の宣言
    reg clk;
    reg nReset;
    wire [7:0] pc_out;
    wire [3:0] level_A;
    wire [3:0] level_B;
    wire [3:0] address_bus;
    wire [3:0] data_bus;
    wire nRAM_RD;
    wire nRAM_WR;

    //メモリー兼レジスタの宣言
    memory_4bit_16nibble ram (
        .address(address_bus),
        .data_bus(data_bus),
        .nwrite_enable(nRAM_WR),
        .nread_enable(nRAM_RD)
    );
    // テスト対象モジュールのインスタンス化
    hc4e uut (
        .clk(clk),
        .nReset(nReset),
        .pc_out(pc_out),
        .stackA_out(level_A),
        .stackB_out(level_B),
        .data_bus(data_bus),
        .nRAM_RD(nRAM_RD),
        .nRAM_WR(nRAM_WR)
    );

    // クロック生成
    always #5 clk = ~clk;

    // テストシナリオ
    initial begin
        // 波形ファイル生成（シミュレーション確認用）
        $dumpfile("hc4e_tb.vcd");
        $dumpvars(0, hc4e_tb);

        // 初期化
        clk = 0;
        nReset = 0;

        // リセット解除とテスト開始
        #10 nReset = 1;

        // シミュレーション実行時間
        #100 $finish;
    end

    // テスト結果表示
    always @(negedge clk) begin
        $display("Time=%0t | PC=%d | levelA=%b | levelB=%b |", $time, pc_out, level_A, level_B);
    end

endmodule
