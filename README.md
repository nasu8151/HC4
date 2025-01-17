¡¡¡ガバガバEnglish注意報発令中!!!

# Table of Contents
- [Table of Contents](#table-of-contents)
- [Descriptions](#descriptions)
- [Architecture](#architecture)
  - [Overview](#overview)
  - [Block diagram](#block-diagram)
  - [Instructions list](#instructions-list)
    - [How to read these tables](#how-to-read-these-tables)
    - [Logical and alithmetic instructions](#logical-and-alithmetic-instructions)
    - [Register and memory access instructions](#register-and-memory-access-instructions)
  - [Instruction manual](#instruction-manual)
    - [Logical and alithmetic instructions](#logical-and-alithmetic-instructions-1)
    - [Register and memory access instructions](#register-and-memory-access-instructions-1)

# Descriptions
A 4-bit CPU made with 74-series logic ICs.
# Architecture
## Overview
The CPU has an 8-bit wide address bus and a 4-bit wide data bus.
All of instructions are 8-bit wide.
## Block diagram

![Block diagram of this CPU.](./HC4.svg)

## Instructions list
### How to read these tables

As noted earlier, instruction of this CPU is 8-bit wide.   
```r``` means a 4-bit wide register. In the program, it is represented by ```r0``` to ```r15``` in program.    
```i``` means a 4-bit wide immediate data.    
```cond.``` means jump conditions.    
```[AB]``` means indirect addressing of stack level A and B. MSB is level B.

### Logical and alithmetic instructions

| Name       | Opc  | Opr |                            |
| ---------- | ---- | --- | -------------------------- |
| ```AD r``` | 0010 | r   | ADd and store in r         |
| ```SU r``` | 0011 | r   | SUbtract and store in r    |
| ```AN r``` | 0100 | r   | bitwise ANd and store in r |
| ```OR r``` | 0101 | r   | bitwise OR and store in r  |
| ```XR r``` | 0110 | r   | bitwise XoR and store in r |

### Register and memory access instructions

| Name           | Opc  | Opr   |                           |
| -------------- | ---- | ----- | ------------------------- |
| ```SC *[AB]``` | 0000 | 0000  | Store C in [AB]           |
| ```SC r```     | 0001 | r     | Store C in r              |
| ```SA r```     | 0111 | r     | Store A in r              |
| ```LD r```     | 1000 | r     | LoaD from r               |
| ```LD *[AB]``` | 1001 | 0000  | LoaD form [AB]            |
| ```LD i```     | 1010 | i     | LoaD immediate            |
| ```JP cond.``` | 1110 | cond. | JumP if condition is true |
     
Note:    
\* Can be omitted addressing.
## Instruction manual
### Logical and alithmetic instructions

These instructions are executed for stack levels A and B, and store the results in registers which specified ```r```.

### Register and memory access instructions

Store instructions store value of stack level A or C in registers or memory area. ```SA r``` instruction refers stack level A, and ```SC r``` and ```SC [AB]``` instructions refer stack level C.   
Load instructions, ```LD```,  load stack level A from register or memory area. When a value is loaded into stack level A, the previous value of level A moves to level B and value of level B moves to level C. ```LD r``` refers register ```r```, ```LD i``` loads immediate data and ```LD [AB]``` refers memory address specified level A and B.