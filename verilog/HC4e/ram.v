`ifndef __ram_v
`define __ram_v

module memory_4bit_16nibble (
    input wire [3:0] address,       // アドレス (8ビットで16ニブル指定)
    inout wire [3:0] data_bus,      // 共通バス (4ビット幅)
    input wire nwrite_enable,        // 書き込み有効信号
    input wire nread_enable          // 読み出し有効信号
);

    // 4ビット幅、16個のメモリ配列
    reg [3:0] memory [0:15];

    // トライステートバスの中間信号
    assign data_bus = (!nread_enable && nwrite_enable) ? memory[address] : 4'bz; // 読み出し時のみデータ出力

    always @(*) begin
        if (!nwrite_enable && nread_enable) begin
            // 書き込み動作
            memory[address] = data_bus; // 共通バスからデータを取得
        end
    end

endmodule

`endif