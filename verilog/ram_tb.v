module tb_memory_4bit_256nibble;

    reg clk;
    reg [7:0] address;
    wire [3:0] data_bus;
    reg [3:0] data_in;
    reg write_enable;
    reg data_bus_drive;
    reg [3:0] bus_out;

    // バスドライバ (双方向バスの制御)
    assign data_bus = data_bus_drive ? data_in : 4'bz; // 入力時にドライブ
    always @(*) bus_out = data_bus; // 読み出しデータをキャプチャ

    ram uut (
        .clk(clk),
        .address(address),
        .data_bus(data_bus),
        .write_enable(write_enable)
    );

    // クロック生成
    initial begin
        $dumpfile("ram.vcd"); // 保存する波形ファイル名
        $dumpvars(0, tb_memory_4bit_256nibble); // 波形を記録する階層
        clk = 0;
        forever #5 clk = ~clk; // 10ns周期のクロック
    end

    initial begin
        // 初期化
        write_enable = 0;
        data_bus_drive = 0;
        address = 0;
        data_in = 0;

        // 書き込みテスト
        #10;
        address = 8'h0A;    // アドレス10
        data_in = 4'b1010;  // データ 1010
        data_bus_drive = 1; // バスにデータをドライブ
        write_enable = 1;   // 書き込み有効
        #10;                //ホールドタイム確保
        write_enable = 0;
        data_bus_drive = 0; // バス解放

        // 読み出しテスト
        #10;
        address = 8'h0A;    // アドレス10

        // 波形確認用
        #10;
        $finish;
    end

endmodule
