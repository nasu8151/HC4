# HC4 ASSEMBLER
## Syntax
> [!NOTE]
> IF you want to know function about assembly, please read [UsersManual_Software.md](https://github.com/nasu8151/HC4/blob/main/UsersManual_Software.md).

### Basic syntax
Let's get right to the explanation, but first, we tell you one.
On HC4 assembler, comments are represented by `;`. characters on the line after `;` are ignored during assembly.
```assembly
<Instruction>
<Instruction> <reg> ;reg means a 4-bit wide register. In the program, it is represented by r0 to r15 in program.
<Instruction> <imm> ;imm means 4 bits wide immediate data. In a program, it is represented as binary from #0000 to #1111.
<Instruction> <flg> ;flg means flag register.

;Addressing option is represented [AB] for SC or [ABC] for JP.
;[AB] means indirect addressing of stack level A and B. MSB is level B.
;[ABC] means indirect addressing of stack level A, B and C. MSB is level C.
<Instruction> <adr>       ; for load and store instructions
<Instruction> <flg> <adr> ; for jump instructions
```

### Pseudo-instruction

Currently not implemented.

## Command line options

* ```-o``` :
  * Specifies output file.