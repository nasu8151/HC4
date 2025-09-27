; LCD interface for the HC4
; Uses memory-mapped I/O at 0xF2 (command) and 0xF3 (data)


; .equ LCD_COMMAND, 0xF2
; .equ LCD_DATA, 0xF3

; 0x0x : Register area
; 0x1x : Register evacuation area
; 0x8x~0xDx : Character area
; 0xFx : I/O area

start:
    np
    li #setup:2
    sa r15
    li #setup:1
    sa r14
    li #setup:0
    sa r13
    li #wait_100ms:2
    li #wait_100ms:1
    li #wait_100ms:0
    jp

setup:
    li #0b0011
    li #0xF
    li #0x2
    sm            ; Function set: 8-bit, 2 line, 5x8 dots
    
    li #12
    sa r0
wait2:
    li #wait_1ms_ret1:2
    sa r15
    li #wait_1ms_ret1:1
    sa r14
    li #wait_1ms_ret1:0
    sa r13
    li #wait_1ms:2
    li #wait_1ms:1
    li #wait_1ms:0
    jp
wait_1ms_ret1:
    ld r0
    li #0x1
    ad r0
    li #wait2:2
    li #wait2:1
    li #wait2:0
    jp nc

setup2:
    li #0b0011
    li #0xF
    li #0x2
    sm            ; Function set: 8-bit, 2 line, 5x8 dots

    li #setup3:2
    sa r15
    li #setup3:1
    sa r14
    li #setup3:0
    sa r13
    li #wait_1ms:2
    li #wait_1ms:1
    li #wait_1ms:0
    jp

setup3:
    li #0b0011
    li #0xF
    li #0x2
    sm            ; Function set: 8-bit, 2 line, 5x8 dots


    li #setup5:2
    sa r15
    li #setup5:1
    sa r14
    li #setup5:0
    sa r13
    li #wait_264us:2
    li #wait_264us:1
    li #wait_264us:0
    jp

setup5:
    li #0b0010
    li #0xF
    li #0x2
    sm
    li #0b1000
    li #0xF
    li #0x2
    sm            ; Function set: 4-bit, 2 line, 5x8 dots

    li #setup6:2
    sa r15
    li #setup6:1
    sa r14
    li #setup6:0
    sa r13
    li #wait_264us:2
    li #wait_264us:1
    li #wait_264us:0
    jp

setup6:
    li #0b0000
    li #0xF
    li #0x2
    sm
    li #0b1000
    li #0xF
    li #0x2
    sm            ; Display OFF


    li #setup7:2
    sa r15
    li #setup7:1
    sa r14
    li #setup7:0
    sa r13
    li #wait_264us:2
    li #wait_264us:1
    li #wait_264us:0
    jp

setup7:
    li #0b0000
    li #0xF
    li #0x2
    sm
    li #0b0001
    li #0xF
    li #0x2
    sm            ; Display clear

    li #14
    sa r0
wait8:
    li #wait_1ms_ret8:2
    sa r15
    li #wait_1ms_ret8:1
    sa r14
    li #wait_1ms_ret8:0
    sa r13
    li #wait_1ms:2
    li #wait_1ms:1
    li #wait_1ms:0
    jp
wait_1ms_ret8:
    ld r0
    li #0x1
    ad r0
    li #wait8:2
    li #wait8:1
    li #wait8:0
    jp nc

setup8:
    li #0b0000
    li #0xF
    li #0x2
    sm
    li #0b0110
    li #0xF
    li #0x2
    sm            ; Entry mode set: increment, no shift

    li #setup9:2
    sa r15
    li #setup9:1
    sa r14
    li #setup9:0
    sa r13
    li #wait_264us:2
    li #wait_264us:1
    li #wait_264us:0
    jp

setup9:
    li #0b0000
    li #0xF
    li #0x2
    sm
    li #0b1100
    li #0xF
    li #0x2
    sm            ; Display ON, cursor OFF, blink OFF

    li #data:2
    sa r15
    li #data:1
    sa r14
    li #data:0
    sa r13
    li #wait_264us:2
    li #wait_264us:1
    li #wait_264us:0
    jp

data:
    li #0b1011
    li #0xF
    li #0x3
    sm
    li #0b0010
    li #0xF
    li #0x3
    sm            ; Display "ｲ"

    li #halt:2
    li #halt:1
    li #halt:0
halt:
    jp


; Wait 1ms
; Subroutine group 1

wait_1ms:
    li #5
    sa r9
wait_1ms_loop:
    li #4
    sa r8
wait_1ms_loop2:
    ld r8
    li #0x1
    ad r8
    li #wait_1ms_loop2:2
    li #wait_1ms_loop2:1
    li #wait_1ms_loop2:0
    jp nc
    ld r9
    li #0x1
    ad r9
    li #wait_1ms_loop:2
    li #wait_1ms_loop:1
    li #wait_1ms_loop:0
    jp nc
    ld r15
    ld r14
    ld r13
    jp


; Wait 264us (HD44780's minimum command execution time)
; Subroutine group 1

wait_264us:
    li #3
    sa r9
wait_264us_loop:
    li #13
    sa r8
wait_264us_loop2:
    ld r8
    li #0x1
    ad r8
    li #wait_264us_loop2:2
    li #wait_264us_loop2:1
    li #wait_264us_loop2:0
    jp nc
    ld r9
    li #0x1
    ad r9
    li #wait_264us_loop:2
    li #wait_264us_loop:1
    li #wait_264us_loop:0
    jp nc
    ld r15
    ld r14
    ld r13
    jp


; Wait 100ms
; Subroutine group 1

wait_100ms:
    ld r15
    li #0x1
    li #0xF
    sm          ; Evacuate r15
    ld r14
    li #0x1
    li #0xE
    sm          ; Evacuate r14
    ld r13
    li #0x1
    li #0xD
    sm          ; Evacuate r13
    li #2
    sa r9
wait_100ms_loop:
    li #9
    sa r8
    ld r9
    li #0x1
    li #0x9
    sm
wait_100ms_loop2:
    ld r8
    li #0x1
    li #0x8
    sm
    li #wait_1ms_ret:2
    sa r15
    li #wait_1ms_ret:1
    sa r14
    li #wait_1ms_ret:0
    sa r13
    li #wait_1ms:2
    li #wait_1ms:1
    li #wait_1ms:0
    jp
wait_1ms_ret:
    li #0x1
    li #0x8
    lm
    li #0x1
    ad r8
    li #wait_100ms_loop2:2
    li #wait_100ms_loop2:1
    li #wait_100ms_loop2:0
    jp nc

    li #0x1
    li #0x9
    lm       ; restore r9
    li #0x1
    ad r9
    li #wait_100ms_loop:2
    li #wait_100ms_loop:1
    li #wait_100ms_loop:0
    jp nc
    li #0x1
    li #0xD
    lm       ; restore r13
    sa r13
    li #0x1
    li #0xE
    lm       ; restore r14
    sa r14
    li #0x1
    li #0xF
    lm       ; restore r15
    ld r14
    ld r13
    jp

