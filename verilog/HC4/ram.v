module ram (
    input wire clk,                 // クロック信号
    input wire [7:0] address,       // アドレス (8ビットで256ニブル指定)
    inout wire [3:0] data_bus,      // 共通バス (4ビット幅)
    input wire write_enable         // 書き込み有効信号
);

    // 4ビット幅、256個のメモリ配列
    reg [3:0] memory [0:255];

    // トライステートバスの中間信号
    reg [3:0] data_out;
    assign data_bus = ( !write_enable && clk) ? data_out : 4'bz; // 読み出し時にデータ出力

    always @(posedge clk) begin
        if (!write_enable) begin
            // 読み出し動作
            data_out <= memory[address];
        end
    end

    always @(negedge clk ) begin
        if (write_enable) begin
            // 書き込み動作
            memory[address] <= data_bus; // 共通バスからデータを取得
        end
    end

endmodule
