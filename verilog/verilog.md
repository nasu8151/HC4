# Verilog Simulation
使い方がわかったので採用
## 記述ルール(仮)
* 負論理の信号は先頭に`n`をつける   
* 変数の語頭は必ず小文字

Commands to compile verilog simulation files:

```
iverilog -o hc4_tb.out -s hc4_tb -g 2005-sv ./hc4.v ./hc4_tb.v
vvp ./hc4_tb.out
gtkwave ./hc4_tb.vcd
```
