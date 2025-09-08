; LCD interface for the HC4
; Uses memory-mapped I/O at 0xF2 (command) and 0xF3 (data)


; .equ LCD_COMMAND, 0xF2
; .equ LCD_DATA, 0xF3

start:
    np
    li #setup:2
    sa r15
    li #setup:1
    sa r14
    li #setup:0
    sa r13
    li #wait2:2
    li #wait2:1
    li #wait2:0
    jp

setup:
    li #0b0011
    li #0xF
    li #0x2
    sm            ; Function set: 8-bit, 2 line, 5x8 dots

    li #setup2:2
    sa r15
    li #setup2:1
    sa r14
    li #setup2:0
    sa r13
    li #wait2:2
    li #wait2:1
    li #wait2:0
    jp

setup2:
    li #0b0011
    li #0xF
    li #0x2
    sm            ; Function set: 8-bit, 2 line, 5x8 dots

    li #0
    sa r0
wait3:
    ld r0
    li #0x1
    ad r0
    li #wait3:2
    li #wait3:1
    li #wait3:0
    jp nc

    li #0b0011
    li #0xF
    li #0x2
    sm            ; Function set: 8-bit, 2 line, 5x8 dots

    li #0
    sa r0
wait4:
    ld r0
    li #0x1
    ad r0
    li #wait4:2
    li #wait4:1
    li #wait4:0
    jp nc

    li #0b0010
    li #0xF
    li #0x2
    sm            ; Function set: 4-bit, 2 line, 5x8 dots

    li #0
    sa r0
wait5:
    ld r0
    li #0x1
    ad r0
    li #wait5:2
    li #wait5:1
    li #wait5:0
    jp nc

    li #0b0010
    li #0xF
    li #0x2
    sm            ; Function set: 4-bit, 2 line, 5x8 dots
    li #0b1000
    li #0xF
    li #0x2
    sm            ; Display off




; wait routine area

wait2:
    li #0
    sa r0
    li #0
    sa r1
wait21:
    li #0
    sa r0
wait20:
    ld r0
    li #0x1
    ad r0
    li #wait20:2
    li #wait20:1
    li #wait20:0
    jp nc
    ld r1
    li #0x1
    ad r1
    li #wait21:2
    li #wait21:1
    li #wait21:0
    jp nc
    ld r15
    ld r14
    ld r13
    jp
