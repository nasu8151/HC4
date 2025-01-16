`timescale 1ns / 1ps

module tb_rom;

    // 入出力信号を定義
    reg [11:0] address;       // アドレス信号
    wire [7:0] data;          // データ出力信号

    // ROMモジュールのインスタンス化
    rom uut (
        .address(address),
        .data(data)
    );

    // テストシナリオ
    initial begin
        // 波形ダンプファイル生成 (シミュレーション時の確認用)
        $dumpfile("tb_rom.vcd");
        $dumpvars(0, tb_rom);

        // 初期化
        address = 12'h000;

        // テストケース: 各アドレスのデータを読み出す
        #10 address = 12'h000; // アドレス0
        #10 $display("Address: %h, Data: %h", address, data);

        #10 address = 12'h001; // アドレス1
        #10 $display("Address: %h, Data: %h", address, data);

        #10 address = 12'h002; // アドレス2
        #10 $display("Address: %h, Data: %h", address, data);

        #10 address = 12'h003; // アドレス3
        #10 $display("Address: %h, Data: %h", address, data);

        #10 address = 12'h004; // アドレス4
        #10 $display("Address: %h, Data: %h", address, data);

        #10 address = 12'h005; // アドレス5
        #10 $display("Address: %h, Data: %h", address, data);

        #10 address = 12'h0FF; // 存在しないアドレス (default)
        #10 $display("Address: %h, Data: %h", address, data);

        // シミュレーション終了
        #10 $finish;
    end

endmodule
