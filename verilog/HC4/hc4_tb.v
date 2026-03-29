`timescale 1ns / 1ns
`include "ram.v"

module hc4_tb;

    // 入出力信号の宣言
    reg clk;
    reg rst_n;
    wire [11:0] pc_out;
    wire [3:0] level_A;
    wire [3:0] level_B;
    wire [3:0] level_C;
    wire [7:0] address_bus;
    wire [3:0] data_bus;
    wire rd_n;
    wire wr_n;

    //メモリー兼レジスタの宣言
    memory_4bit_256nibble ram (
        .address(address_bus),
        .data_bus(data_bus),
        .nwrite_enable(wr_n),
        .nread_enable(rd_n)
    );
    // テスト対象モジュールのインスタンス化
    hc4 uut (
        .clk(clk),
        .rst_n(rst_n),
        .pc_out(pc_out),
        .stackA_out(level_A),
        .stackB_out(level_B),
        .stackC_out(level_C),
        .address_bus(address_bus),
        .data_bus(data_bus),
        .rd_n(rd_n),
        .wr_n(wr_n)
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
        rst_n = 0;

        // リセット解除とテスト開始
        #10 rst_n = 1;

        // シミュレーション実行時間
        #2000000 $finish;
    end

    always @(*) begin
        if (address_bus == 8'hF2 && wr_n == 1) begin
            $display("Time=%0t | PC=%d | levelA=%b | levelB=%b | levelC=%b | ADDR=%h | DATA_OUT=%h | wr_n=%b | rd_n=%b", $time, pc_out, level_A, level_B, level_C, address_bus, data_bus, wr_n, rd_n);
        end
        if (address_bus == 8'hF3 && wr_n == 0) begin
            $display("Time=%0t | PC=%d | levelA=%b | levelB=%b | levelC=%b | ADDR=%h | DATA_OUT=%h | wr_n=%b | rd_n=%b", $time, pc_out, level_A, level_B, level_C, address_bus, data_bus, wr_n, rd_n);
        end
    end

    // テスト結果表示
    // always @(negedge clk) begin
    //     $display("Time=%0t | PC=%d | levelA=%b | levelB=%b | levelC=%b", $time, pc_out, level_A, level_B, level_C);
    // end

endmodule
