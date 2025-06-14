Instruction to internal signals. (x means "Don't Care")

| Name            | Opc  | ALU_S[0..1] | ~ALU_OE | ~is_JP | Carry_EN  | ~Stack_LE | Mem_R |
| --------------- | ---- | ----------- | ------- | ------ | --------- | --------- | ----- |
| (Reserved)      | 000x | xx          | x       | x      | x         | 1         | x     |
| ```AD r```      | 0011 | 01          | 0       | 1      | 1         | 1         | 0     |
| ```XR r```      | 0100 | 10          | 0       | 1      | 0         | 1         | 0     |
| ```SA r```      | 0111 | 11          | 0       | 1      | 0         | 1         | 0     |
| ```LD r```      | 100x | xx          | 1       | 1      | 0         | 0         | 1     |
| ```LD #i```     | 1010 | 00          | 0       | 1      | 0         | 0         | 0     |
| (Reserved)      | 110x | xx          | x       | x      | x         | x         | x     |
| ```JP *[ABC]``` | 111x | xx          | x       | 0      | 0         | 1         | 0     |