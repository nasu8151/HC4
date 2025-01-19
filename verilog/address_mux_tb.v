`timescale 1ns / 1ps

module ADDRESS_MUX_tb();

    // 信号の宣言
    reg [3:0] register_address; // レジスタアドレス
    reg [7:0] ab_address;       // ABアドレス
    reg [3:0] opcode;           // オペコード
    wire [7:0] address_out;     // 出力アドレス

    // ADDRESS_MUX 関数のインスタンス化
    function [7:0] ADDRESS_MUX(
        input  [3:0] register_address,
        input  [7:0] ab_address,
        input  [3:0] opcode
    );
        if (opcode[2:0] == 3'b000) begin  // [AB] アドレッシングモード
            ADDRESS_MUX = ab_address;
        end else begin                     // 他のアドレッシングモード (r, i)
            ADDRESS_MUX[7:4] = 4'h0;
            ADDRESS_MUX[3:0] = register_address;
        end
    endfunction

    // ADDRESS_MUX の呼び出し
    assign address_out = ADDRESS_MUX(register_address, ab_address, opcode);

    // テストシナリオ
    initial begin
        // 波形ダンプファイル生成
        $dumpfile("tb_ADDRESS_MUX.vcd");
        $dumpvars(0, ADDRESS_MUX_tb);

        // テストケース: アドレッシングモード [AB] (opcode = 3'b000)
        opcode = 4'b0000; ab_address = 8'hAB; register_address = 4'h0;
        #10 $display("Opcode: %b, AB Address: %h, Register Address: %h, Address Out: %h", opcode, ab_address, register_address, address_out);

        // テストケース: レジスタモード (opcode = 3'b001)
        opcode = 4'b0001; ab_address = 8'hCD; register_address = 4'h5;
        #10 $display("Opcode: %b, AB Address: %h, Register Address: %h, Address Out: %h", opcode, ab_address, register_address, address_out);

        // テストケース: レジスタモード (opcode = 3'b010)
        opcode = 4'b0010; ab_address = 8'hFF; register_address = 4'hA;
        #10 $display("Opcode: %b, AB Address: %h, Register Address: %h, Address Out: %h", opcode, ab_address, register_address, address_out);

        // テストケース: アドレッシングモード [AB] (opcode = 3'b000)
        opcode = 4'b1000; ab_address = 8'h12; register_address = 4'hF;
        #10 $display("Opcode: %b, AB Address: %h, Register Address: %h, Address Out: %h", opcode, ab_address, register_address, address_out);

        // シミュレーション終了
        #10 $finish;
    end

endmodule
