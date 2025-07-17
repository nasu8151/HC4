# HC4 ASSEMBLER

## Syntax

> [!NOTE]
> IF you want to know function about assembly, please read [instructions_manual.md](https://github.com/nasu8151/HC4/blob/main/instructions_manual.md).

### Basic syntax

Let's get right to the explanation, but first, we tell you one.
On HC4 assembler, comments are represented by `;`. characters on the line after `;` are ignored during assembly.

```assembly
<Instruction>
<Instruction> <reg> ;reg means a 4-bit wide register. In the program, it is represented by r0 to r15 in program.
<Instruction> <imm> ;imm means 4 bits wide immediate data. In a program, it is represented as literal such as #12, #0xC or #0b1100.
<Instruction> <flg> ;flg means flag register.

;stk is optional. stk is represented [AB] or [ABC].
;[AB] means indirect addressing of stack level A and B. MSB is level B.
;[ABC] means indirect addressing of stack level A, B and C. MSB is level C.
<Instruction> <stk>
<Instruction> <flg> <stk>
```

## Command Line Options

```shell
hc4_asm filename -o output -f [hex | ihex]
```

- ```-o``` : Set output file name.
- ```-f``` : Set output format (```hex``` for verilog or ```ihex```)
