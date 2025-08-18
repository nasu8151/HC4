`timescale 1ns / 1ps

module memory_4bit_16nibble_tb;

    reg [3:0] address;
    reg [3:0] data_in;
    wire [3:0] data_out;
    reg nwrite_enable;
    reg nread_enable;

    // `data_bus` を inout にするためのトライステートバス
    wire [3:0] data_bus;
    assign data_bus = (!nwrite_enable && nread_enable) ? data_in : 4'bz;
    
    assign data_out = data_bus;

    // メモリモジュールのインスタンス化
    memory_4bit_16nibble uut (
        .address(address),
        .data_bus(data_bus),
        .nwrite_enable(nwrite_enable),
        .nread_enable(nread_enable)
    );

    initial begin
        $dumpfile("ram.vcd");
        $dumpvars(0, memory_4bit_16nibble_tb);

        // 初期化
        address = 4'h0;
        data_in = 4'b0000;
        nwrite_enable = 1;
        nread_enable = 1;

        // **書き込みテスト**
        #10 address = 4'h5; data_in = 4'b1010; nwrite_enable = 0; nread_enable = 1; // アドレス5に1010を書き込み
        #10 nwrite_enable = 1;
        #10 address = 4'hA; data_in = 4'b0111; nwrite_enable = 0; nread_enable = 1; // アドレス10に0111を書き込み
        #10 nwrite_enable = 1;

        // **読み出しテスト**
        #10 address = 4'h5; nread_enable = 0; nwrite_enable = 1; // アドレス5の値を読み出し
        #10 $display("Read from 0x05: %b", data_out);
        #10 nread_enable = 1;

        #10 address = 4'hA; nread_enable = 0; nwrite_enable = 1; // アドレス10の値を読み出し
        #10 $display("Read from 0x0A: %b", data_out);
        #10 nread_enable = 1;

        // シミュレーション終了
        #10 $finish;
    end

endmodule
