¡¡¡ガバガバEnglish注意報発令中!!!

# Table of Contents
- [Table of Contents](#table-of-contents)
- [Descriptions](#descriptions)
- [Architecture](#architecture)
  - [Overview](#overview)
  - [Instructions list](#instructions-list)
    - [How to read these tables](#how-to-read-these-tables)
    - [Logical and alithmetic instructions](#logical-and-alithmetic-instructions)
    - [Register access instructions](#register-access-instructions)
  - [Instruction manual](#instruction-manual)

# Descriptions
A 4-bit CPU made with 74-series logic ICs.
# Architecture
## Overview
The CPU has an 8-bit wide address bus and a 4-bit wide data bus.
All of instructions are 8-bit wide.

## Instructions list
### How to read these tables

As noted earlier, instruction of this CPU is 8-bit wide.   
"rrrr" means a 4-bit wide register. In the program, it is represented by ```r0``` to ```r15```.    
"iiii" means a 4-bit wide immediate data.    
"cond." means jump conditions.

### Logical and alithmetic instructions

| Name      | Opc  | Opr  |
| --------- | ---- | ---- |
| ```ADD``` | 0010 | rrrr |
| ```SUB``` | 0011 | rrrr |
| ```AND``` | 0100 | rrrr |
| ```OR```  | 0101 | rrrr |
| ```XOR``` | 0110 | rrrr |

These instructions are modifys register.

### Register access instructions

| Name      | Opc  | Opr   |
| --------- | ---- | ----- |
| ```STA``` | 0000 | rrrr  |
| ```STC``` | 0001 | rrrr  |
| ```LD```  | 1000 | rrrr  |
| ```LDI``` | 1010 | iiii  |
| ```JMP``` | 1100 | cond. |

```STA``` and ```STC``` modify registers.    
```LD``` loads a register value onto stack.    
```LDI``` loads a immediate data onto stack.    
```JMP``` loads stack level A to C onto program counter (PC).    
## Instruction manual
