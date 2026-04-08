- [How to read these tables](#how-to-read-these-tables)
- [Instruction table](#instruction-table)
  - [HC4](#hc4)
  - [HC4E](#hc4e)
  - [HC8](#hc8)
- [Instruction List](#instruction-list)
  - [Logical and alithmetic instructions](#logical-and-alithmetic-instructions)
  - [Register and memory access instructions](#register-and-memory-access-instructions)
  - [System control instructions](#system-control-instructions)
- [Instruction manual](#instruction-manual)
  - [Logical and alithmetic instructions](#logical-and-alithmetic-instructions-1)
  - [Register and memory access instructions](#register-and-memory-access-instructions-1)
  - [System control instructions](#system-control-instructions-1)
  - [HC4E](#hc4e-1)
- [Instruction usage examples and caveats](#instruction-usage-examples-and-caveats)
- [Tutorial: LED blink (lchika.asm)](#tutorial-led-blink-lchikaasm)
- [Troubleshooting](#troubleshooting)


# How to read these tables

As noted [README](https://github.com/nasu8151/HC4), instruction of these CPUs are 8-bit wide.   
```r``` means a 4-bit wide register. In the program, it is represented by ```r0``` to ```r15``` in program.    
```#i``` means a 4-bit wide immediate data.    
```[AB]``` means indirect addressing of stack level A and B. MSB is level B.   
```[ABC]``` means indirect addressing of stack level A, B and C. MSB is level C.    
"PC" means Program Counter.

# Instruction table

Do not include any instructions marked as (Reserved) in the program.
These instrucitons may not work correctly. 

## HC4

| bit 5-4→<br>7-6↓ | 00         | 01         | 10                      | 11         |
| ---------------- | ---------- | ---------- | ----------------------- | ---------- |
| 00               | ```SM```   | ```SC r``` | ```SU r```              | ```AD r``` |
| 01               | ```XR r``` | ```OR r``` | ```AN r```              | ```SA r``` |
| 10               | ```LM```   | ```LD r``` | ```LI #```              | (Reserved) |
| 11               | (Reserved) | (Reserved) | ```JP flag```, ```NP``` | (Reserved) |

## HC4<sub>E</sub>

| bit 5-4→<br>7-6↓ | 00         | 01         | 10                      | 11         |
| ---------------- | ---------- | ---------- | ----------------------- | ---------- |
| 00               | (Reserved) | (Reserved) | (Reserved)              | ```AD r``` |
| 01               | ```XR r``` | (Reserved) | (Reserved)              | ```SA r``` |
| 10               | (Reserved) | ```LD r``` | ```LI #```              | (Reserved) |
| 11               | (Reserved) | (Reserved) | ```JP flag```, ```NP``` | (Reserved) |

## HC8

| bit 5-4→<br>7-6↓ | 00         | 01         | 10                      | 11                      |
| ---------------- | ---------- | ---------- | ----------------------- | ----------------------- |
| 00               | ```SM```   | ```SC r``` | ```SU r```              | ```AD r```              |
| 01               | ```XR r``` | ```OR r``` | ```AN r```              | ```SA r```              |
| 10               | ```LM```   | ```LD r``` | ```LI #```              | (Reserved)              |
| 11               | ```LS #``` | (Reserved) | ```JP flag```, ```NP``` | ```JL flag```, ```LP``` |

# Instruction List

## Logical and alithmetic instructions

| Name       | Opc  | Opr | Flag changes | Function   |                            |
| ---------- | ---- | --- | ------------ | ---------- | -------------------------- |
| ```SU r``` | 0010 | r   | C, Z         | r <= A-B   | SUbtract and store in r    |
| ```AD r``` | 0011 | r   | C, Z         | r <= A+B   | ADd and store in r         |
| ```XR r``` | 0100 | r   | Z            | r <= A^B   | bitwise XoR and store in r |
| ```OR r``` | 0101 | r   | Z            | r <= A\|B  | bitwise OR and store in r  |
| ```AN r``` | 0110 | r   | Z            | r <= A&B   | bitwise ANd and store in r |

## Register and memory access instructions

| Name          | Opc  | Opr  | Flag changes |                            |
| ------------- | ---- | ---- | ------------ | -------------------------- |
| ```SM```      | 0000 | 0000 | Z            | Store C in [AB]            |
| ```SC r```    | 0001 | r    | Z            | Store C in r               |
| ```SA r```    | 0111 | r    | Z            | Store A in r               |
| ```LM```      | 1000 | 0000 |              | LoaD from [AB]             |
| ```LD r```    | 1001 | r    |              | LoaD form r                |
| ```LI #i```   | 1010 | i    |              | LoaD immediate             |
| \*```LS #i``` | 1100 | i    |              | Load immediate and Shift A |

Note:    
\* Only for HC8.

## System control instructions

| Name        | Opc  | Opr  |                               |
| ----------- | ---- | ---- | ----------------------------- |
| ```JP```    | 1110 | 0000 | JumP [ABC]                    |
| ```JP C```  | 1110 | 0010 | Jump if Carry flag is set     |
| ```JP NC``` | 1110 | 0011 | Jump if Carry flag is Not set |
| ```JP Z```  | 1110 | 0100 | Jump if Zero flag is set      |
| ```JP NZ``` | 1110 | 0101 | Jump if Zero flag is Not set  |
| ```NP```    | 1110 | 0001 | No oPlation                   |

# Instruction manual
## Logical and alithmetic instructions

These instructions are executed for stack levels A and B, and store the results in registers which specified ```r```.

## Register and memory access instructions

Store instructions store value of stack level A or C in registers or memory area. ```SA r``` instruction refers stack level A, and ```SC r``` and ```SM``` instructions refer stack level C.   
Load instructions, ```LD```,  load stack level A from register or memory area. When a value is loaded into stack level A, the previous value of level A moves to level B, and the value of level B moves to level C. ```LD r``` refers register ```r```, ```LI #i``` loads immediate data and ```LM``` refers memory address specified level A and B.   
Load and shift instruction, ```LS #i```, used to load an 8-bit wide data onto the stack.
For the ```LS #``` and ```LI #``` instructions, binary(```0b1010```) and hexadecimal(```0xA```) literals can be used.

## System control instructions

```NP``` does nothing. This is equivalent to ```NOP```.   
```JP``` instructions change conditionally PC.

## HC4<sub>E</sub>

In HC4<sub>E</sub>, only stack levels A and B are valid.
It has 16 nibbles of address space, only register addressing mode(```r```) and 8-bit wide program counter.
I/O Registers are placed ```r14``` and ```r15```.

# Instruction usage examples and caveats

## AD r / SU r

Example:

```asm
ld #0x3
ld #0x5
ad r1
```

Caveats:

- Operands are mainly stack A/B, and the result is written to register `r`.
- C and Z flags are updated and may affect the next conditional jump.

## XR r / OR r / AN r

Example:

```asm
ld #0xA
ld #0x3
xr r2
```

Caveats:

- Z flag update can be used for zero-check branching.
- Do not confuse arithmetic carry behavior with logical operations.

## SA r / SC r / SM

Example:

```asm
ld #0x9
sa r0
```

Caveats:

- `SA r` stores A, while `SC r` and `SM` store C.
- Depending on assembler dialect, store-to-[AB] may be written as `SM` or `SC [AB]`.

## LD r / LI #i / LM

Example:

```asm
li #0xF
ld r1
lm
```

Caveats:

- Load pushes stack levels down (A <- new, B <- old A, C <- old B).
- `LM` depends on `[AB]`, so prepare stack values before reading memory.

## JP family / NP

Example:

```asm
ld #0
ld #0
ld #0x4
jp
```

Caveats:

- Jump destination is made from stack levels; wrong loading order causes wrong branch.
- `NP` is useful as a timing separator during debug.

# Tutorial: LED blink (lchika.asm)

Reference file: `extra/lchika.asm`

```asm
np
ld #0xF
ld #0xF
ld #0
sc [AB]
ld #0
ld #0xF
ld #0
sc [AB]
ld #0
ld #0
ld #0x1
jp
```

Line-by-line intent:

1. `np`: initial NOP.
2. `ld #0xF`: prepare address part.
3. `ld #0xF`: prepare address part.
4. `ld #0`: output data (for one LED state).
5. `sc [AB]`: write to memory-mapped I/O.
6. `ld #0`: prepare next write.
7. `ld #0xF`: keep I/O range.
8. `ld #0`: output data for another state.
9. `sc [AB]`: write again.
10. `ld #0`: prepare jump destination part.
11. `ld #0`: prepare jump destination part.
12. `ld #0x1`: prepare jump destination part.
13. `jp`: loop back.

# Troubleshooting

- Avoid instructions marked as Reserved.
- Verify I/O address decoding in hardware.
- Verify stack content before `JP`.
- Verify C/Z flag updates before conditional jump.
- Verify stack push side effect after `LD` and `LI`.
- On HC4E, avoid code that assumes stack level C.
- Verify assembler dialect differences for `SM` and `SC [AB]`.
