# Verilog Simulation
使い方がわかったので採用
## 記述ルール(仮)
* 負論理の信号は先頭に`n`をつける   
* 変数の語頭は必ず小文字

HC4/ is a 4-bit CPU.
HC8/ is an 8-bit CPU.

Commands to compile verilog simulation files:

```
cd ./verilog/hc4/
iverilog -o hc4_tb.out -s hc4_tb -g 2005-sv ./hc4.v ./hc4_tb.v
vvp ./hc4_tb.out
gtkwave ./hc4_tb.vcd
```
