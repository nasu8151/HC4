`timescale 1ns / 1ps

module hc8_tb;

    // 入出力信号の宣言
    reg clk;
    reg nReset;
    wire [15:0] pc_out;
    wire [7:0] level_A;
    wire [7:0] level_B;
    wire [7:0] level_C;

    // テスト対象モジュールのインスタンス化
    hc4 uut (
        .clk(clk),
        .nReset(nReset),
        .pc_out(pc_out),
        .stackA_out(level_A),
        .stackB_out(level_B),
        .stackC_out(level_C)
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
