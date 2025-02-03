module rom (
    input wire [11:0] address,       // アドレス (8ビットで256ニブル指定)
    output reg [7:0] data      // 共通バス (4ビット幅)
);

    // 4ビット幅、256個のメモリ配列
    reg [7:0] memory [0:4095];

    initial $readmemh("./jmptest.hex", memory);

    always @(*) begin
        // 読み出し動作
        data <= memory[address];
    end

endmodule