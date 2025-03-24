<span style="font-size: 110%">English version was excalibured.</span>

## 🎯 HC4 CPU Verilog 解説

## 📚 1. 概要
* `hc4` モジュールは、4ビットスタックベースの簡易 CPU（HC4）のトップモジュールです。
* 以下に、部分ごとに分解して詳細に説明します。

---

## 📡 2. モジュール宣言と入出力

```verilog
module hc4 (
    input wire clk,                     // クロック信号
    input wire nReset,                  // 非同期リセット（0でリセット、1で通常動作）
    output wire [11:0] pc_out,          // プログラムカウンタの出力
    output wire [3:0] stackA_out,       // スタックレベルAの出力
    output wire [3:0] stackB_out,       // スタックレベルBの出力
    output wire [3:0] stackC_out,       // スタックレベルCの出力
    output wire [7:0] address_bus,      // アドレスバスの出力
    inout  wire [3:0] data_bus,         // データバス（入出力）
    output wire nRAM_RD,                // RAM 読み出し制御（アクティブ Low）
    output wire nRAM_WR                 // RAM 書き込み制御（アクティブ Low）
);
```

### ✅ ポイント
* `clk`：クロック信号
* `nReset`：リセット信号（アクティブ Low）  
    * 0 でリセット状態、1 で通常動作。
* `pc_out`：プログラムカウンタ（PC）の出力。
* `stackA_out`, `stackB_out`, `stackC_out`：スタックの各レベルの値を外部に出力。
* `address_bus`：メモリアドレスの出力（8ビット）。
* `data_bus`：4ビット幅のデータバス、読み書き両方に対応（inout）。
* `nRAM_RD`：RAM 読み出し制御信号（Low でアクティブ）。
* `nRAM_WR`：RAM 書き込み制御信号（Low でアクティブ）。

---

## 📝 3. レジスタとメモリの定義

```verilog
    reg [3:0] level_A;     // スタック レベル A
    reg [3:0] level_B;     // スタック レベル B
    reg [3:0] level_C;     // スタック レベル C
    reg [11:0] pc;         // プログラムカウンタ（PC）

    reg [7:0] rom [0:4095]; // 8ビット幅の命令ROM、4096命令分
```

### ✅ ポイント
* `level_A` ～ `level_C`：スタックレジスタ。
* `pc`：プログラムカウンタ（命令フェッチ用）。
* `rom`：命令を格納するメモリ（プログラムROM）。
* `$readmemh("./jmptest.hex", rom);` でROMに `jmptest.hex` からデータを読み込む。

---

## 🔢 4. 命令と制御信号の定義

```verilog
    wire [7:0] instruction;         // 現在の命令
    wire sub;                       // ALU の減算/加算制御信号
    wire [3:0] alu_result;          // ALU の出力結果
    wire carry;                     // キャリーフラグ
    reg  carry_flg;                 // キャリーフラグ保持
    reg  zero_flg;                  // ゼロフラグ保持
```

### ✅ ポイント
* `instruction`：現在の命令
* `sub`：ALU が減算モードか加算モードかを指定（1 なら減算、0 なら加算）。
* `alu_result`：ALU からの結果。
* `carry`：ALU のキャリーフラグ（繰り上がりや借り）。
* `carry_flg`：キャリーフラグの保持用レジスタ。
* `zero_flg`：ゼロフラグの保持用レジスタ。

---

## 📡 5. 命令読み込み・PC出力

```verilog
    assign instruction = rom[pc];
    assign pc_out = pc;
    assign stackA_out = level_A;
    assign stackB_out = level_B;
    assign stackC_out = level_C;
```

### ✅ ポイント
* `instruction`：プログラムカウンタ `pc` の位置から命令を読み込み。
* `pc_out`：プログラムカウンタを外部に出力。
* `stackA_out`, `stackB_out`, `stackC_out`：各スタックレベルの値を外部に出力。

---

## 🛠️ 6. ALU インスタンス化

```verilog
    alu ALU (
        .in_A (level_A),
        .in_B (level_B),
        .sel_in (instruction[6:4]),
        .carry_in (sub),
        .out (alu_result),
        .carry_out (carry)
    );
```

### ✅ ポイント
* `ALU` モジュールのインスタンス化。
* `in_A` と `in_B` にスタックレベル A, B を入力。
* `sel_in` に命令の `opcode` を入力。
* `carry_in` に `sub` 信号を入力。
* `alu_result` に演算結果を出力。
* `carry` にキャリーフラグを出力。

---

## 🧠 7. アドレスマルチプレクサ（ADDRESS_MUX）

```verilog
    function [7:0] ADDRESS_MUX(input [7:0] instruction, input [3:0] level_A, input [3:0] level_B);
        if (instruction[6:4] == 3'b000) begin  // if addressing mode is [AB]
            ADDRESS_MUX[3:0] = level_A;
            ADDRESS_MUX[7:4] = level_B;
        end else begin                         // if addressing mode is not [AB] (r, i)
            ADDRESS_MUX[7:4] = 4'h0;
            ADDRESS_MUX[3:0] = instruction[3:0];
        end
    endfunction
    assign address_bus = ADDRESS_MUX(instruction[7:0], level_A, level_B);
```

### ✅ ポイント
* `ADDRESS_MUX`：アドレスの選択
    * アドレッシングモード `[AB]` の場合：`level_A` と `level_B` からアドレス生成。
    * 即値やレジスタの場合：`instruction[3:0]` をアドレスの下位4ビットに設定。

---

## 🔁 8. プログラムカウンタ更新（NEXT_PC）

```verilog
    function [11:0] NEXT_PC(input [7:0] instruction, input [11:0] pc, input [3:0] level_A, input [3:0] level_B, input [3:0] level_C, input C_flag, input Z_flag);
        reg nJMP;
        if (instruction[7:5] == 3'b111) begin // if current instruction is Jump
            case (instruction[2:0])
                3'b000: NEXT_PC = {level_C, level_B, level_A};  // JP
                3'b001: NEXT_PC = pc + 1;                       // NP
                3'b010: begin                                  // JC
                    if (C_flag == 1) NEXT_PC = {level_C, level_B, level_A};
                    else             NEXT_PC = pc + 1;
                end
                3'b011: begin                                  // JNC
                    if (C_flag == 0) NEXT_PC = {level_C, level_B, level_A};
                    else             NEXT_PC = pc + 1;
                end
                3'b100: begin                                  // JZ
                    if (Z_flag == 1) NEXT_PC = {level_C, level_B, level_A};
                    else             NEXT_PC = pc + 1;
                end
                3'b101: begin                                  // JNZ
                    if (Z_flag == 0) NEXT_PC = {level_C, level_B, level_A};
                    else             NEXT_PC = pc + 1;
                end
                default:  NEXT_PC = pc + 1;
            endcase
        end else begin
            NEXT_PC = pc + 1;
        end
    endfunction
```

### ✅ ポイント
* `NEXT_PC`：ジャンプ命令の処理
    * `JP`：スタックの `CBA` からジャンプ。
    * `NP`：次の命令へ進む。
    * `JC`/`JNC`：キャリーフラグで条件付きジャンプ。
    * `JZ`/`JNZ`：ゼロフラグで条件付きジャンプ。
    * デフォルトは `pc + 1` で次の命令。

---

## 🔀 9. バス制御（BUS_CTRL）

```verilog
    function [3:0] BUS_CTRL (input [7:0] instruction, input [3:0] alu_result, input [3:0] level_C);
        casez (instruction[7:5])
            3'b000:  BUS_CTRL = level_C;          // SC
            3'b0??:  BUS_CTRL = alu_result;       // ALU instructions (include SA)
            3'b100:  BUS_CTRL = 4'bz;             // LD [AB] or LD r (RAM)
            3'b101:  BUS_CTRL = instruction[3:0]; // LD i
            default: BUS_CTRL = 4'bx;             // JP doesn't use data bus
        endcase
    endfunction
    assign data_bus = BUS_CTRL(instruction, alu_result, level_C);
```

### ✅ ポイント
* `BUS_CTRL`：バス制御
    * `SC`：`level_C` をデータバスに出力。
    * `ALU` 命令：`alu_result` をデータバスに出力。
    * `LD [AB]` / `LD r`：RAM からの読み込み → 高インピーダンス。
    * `LD i`：即値をバスに出力。

---

## 🔁 10. メイン処理（always ブロック）

```verilog
    always @(posedge clk or negedge nReset) begin
        if (nReset == 0) begin
            pc <= 12'b0;
            carry_flg <= 1'b0;
            zero_flg <= 1'b0;
            level_A <= 4'b0;
        end else begin
            casez (instruction[7:6])
                2'b0?: begin // if current instruction is an instruction which stores in the memory or registers
                    zero_flg  <= data_bus == 4'b0 ? 1 : 0;
                    carry_flg <= instruction[7:5] == 3'b001 ? carry : carry_flg;
                end 
                2'b10: begin
                    level_A <= data_bus;
                    level_B <= level_A;
                    level_C <= level_B;
                end
                2'b11: begin
                    // nothing to write here
                end
            endcase
            pc <= NEXT_PC(instruction, pc, level_A, level_B, level_C, carry_flg, zero_flg);
        end
    end
```

### ✅ ポイント
* `nReset == 0`：リセット時に初期化。
* 命令の `opcode` によって以下の動作
    * `0x`：メモリやレジスタに書き込み。
        * ゼロフラグ、キャリーフラグ更新。
    * `10`：スタックのシフト更新。
        * `level_A` → `level_B` → `level_C` へプッシュ。
    * `11`：ジャンプのみ、何も書き込みなし。

---

## 🎉 11. まとめ
* HC4 は 4 ビットスタックベースの CPU で、ジャンプ、スタック操作、ALU 演算などの基本的な命令を実行可能。
* Verilog での記述はモジュール化され、ALU、ROM 読み込み、バス制御などが含まれている。