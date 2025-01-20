`timescale 1ns / 1ps

module hc4_tb;

    // 入出力信号の宣言
    reg clk;
    reg nReset;
    wire [11:0] pc_out;
    wire [7:0] instruction_out;
    wire [3:0] alu_out;

    // テスト対象モジュールのインスタンス化
    hc4 uut (
        .clk(clk),
        .nReset(nReset),
        .pc_out(pc_out),
        .instruction_out(instruction_out),
        .alu_out(alu_out)
    );

    // クロック生成
    always #5 clk = ~clk;

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
        #200 $finish;
    end

    // テスト結果表示
    always @(negedge clk) begin
        $display("Time=%0t | PC=%b | Instruction=%b | ALU_OUT=%b", $time, pc_out, instruction_out, alu_out);
    end

endmodule
