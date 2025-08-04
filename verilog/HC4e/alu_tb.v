`timescale 1ns / 1ps

module alu_tb;

    // 入出力信号の宣言
    reg [3:0] in_A;        // 入力A
    reg [3:0] in_B;        // 入力B
    reg [2:0] sel_in;      // 操作選択信号
    reg carry_in;          // キャリー入力
    wire [3:0] out;        // 出力
    wire carry_out;        // キャリー出力

    // ALUモジュールのインスタンス化
    alu uut (
        .in_A(in_A),
        .in_B(in_B),
        .sel_in(sel_in),
        .carry_in(carry_in),
        .out(out),
        .carry_out(carry_out)
    );

    // テストシナリオ
    initial begin
        // 波形ダンプファイル生成（シミュレーション確認用）
        $dumpfile("alu_tb.vcd");
        $dumpvars(0, alu_tb);

        // 初期化
        in_A = 4'b0;
        in_B = 4'b0;
        sel_in = 3'b0;
        carry_in = 1'b0;

        // テストケース: 加算 (sel_in = 3'b011)
        #10 in_A = 4'b0101; in_B = 4'b0011; sel_in = 3'b011; carry_in = 1'b0;
        #10 $display("Add: A=%b, B=%b, Cin=%b, Out=%b, Cout=%b", in_A, in_B, carry_in, out, carry_out);

        // テストケース: XOR (sel_in = 3'b100)
        #10 in_A = 4'b1100; in_B = 4'b1010; sel_in = 3'b100; carry_in = 1'b0;
        #10 $display("XOR: A=%b, B=%b, Out=%b", in_A, in_B, out);

        // テストケース: パススルー (sel_in = 3'b111)
        #10 in_A = 4'b1010; in_B = 4'b0000; sel_in = 3'b111; carry_in = 1'b0;
        #10 $display("Pass-through: A=%b, Out=%b", in_A, out);

        // テスト終了
        #10 $finish;
    end

endmodule
