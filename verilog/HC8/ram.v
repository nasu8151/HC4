module memory_8bit_2kbyte (
    input wire [11:0] address,       // アドレス 
    inout wire [7:0] data_bus,       // 読み書きポート
    input wire nchip_enable,         // メモリの有効信号
    input wire nwrite_enable,        // 書き込み有効信号
    input wire nread_enable          // 読み出し有効信号
);

    // 8ビット幅、2048個のメモリ配列
    reg [7:0] memory [0:2047];

    // トライステートバスの中間信号
    assign data_bus = (!nchip_enable && !nread_enable && nwrite_enable) ? memory[address] : 8'bz; // 読み出し時のみデータ出力

    always @(*) begin
        if (!nchip_enable && !nwrite_enable && nread_enable) begin
            // 書き込み動作
            memory[address] = data_bus; // 共通バスからデータを取得
        end
    end

endmodule
