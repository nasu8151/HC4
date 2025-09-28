; LCD interface for the HC4
; Uses memory-mapped I/O at 0xF0 (Button input), 0xF2 (command) and 0xF3 (data)

; .equ BUTTONS     0xF0
; .equ LCD_COMMAND 0xF2
; .equ LCD_DATA    0xF3

; 0x0x : Register area
; 0x1x : Register evacuation area
; 0x8x~0xDx : Character area
; 0xFx : I/O area

start:
    np
    li #0x0
    li #0xF
    li #0x0
    sm          ; Clear output port at 0xF0
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
    li #0
    sa r4
    li #0
    sa r5
    li #0
    sa r6
    li #0
    sa r7         ; Clear digit registers

    li #opening_message:2
    li #opening_message:1
    li #opening_message:0
    jp

main:
    li #0xc
    li #0xF
    li #0x2
    sm            
    li #0
    li #0xF
    li #0x2
    sm            ; Set DDRAM address to 0x40 (2nd line, pos 0)

    li #write1000:2
    sa r15
    li #write1000:1
    sa r14
    li #write1000:0
    sa r13
    li #wait_264us:2
    li #wait_264us:1
    li #wait_264us:0
    jp            ; Wait for HD44780 to finish
write1000:
    li #0x3
    li #0xF
    li #0x3
    sm
    ld r7
    li #0xF
    li #0x3
    sm            ; Display thousands digit

    li #write100:2
    sa r15
    li #write100:1
    sa r14
    li #write100:0
    sa r13
    li #wait_264us:2
    li #wait_264us:1
    li #wait_264us:0
    jp            ; Wait for HD44780 to finish
write100:
    li #0x3
    li #0xF
    li #0x3
    sm
    ld r6
    li #0xF
    li #0x3
    sm            ; Display hundreds digit

    li #write10:2
    sa r15
    li #write10:1
    sa r14
    li #write10:0
    sa r13
    li #wait_264us:2
    li #wait_264us:1
    li #wait_264us:0
    jp            ; Wait for HD44780 to finish
write10:
    li #0x3
    li #0xF
    li #0x3
    sm
    ld r5
    li #0xF
    li #0x3
    sm            ; Display tens digit

    li #write1:2
    sa r15
    li #write1:1
    sa r14
    li #write1:0
    sa r13
    li #wait_264us:2
    li #wait_264us:1
    li #wait_264us:0
    jp            ; Wait for HD44780 to finish
write1:
    li #0x3
    li #0xF
    li #0x3
    sm
    ld r4
    li #0xF
    li #0x3
    sm            ; Display ones digit

    li #0x0
    li #0xF
    li #0x0
    sm            ; Clear output port at 0xF0 (turn off buzzer)

poll_release:
    li #0xF
    li #0x0
    lm             ; Read switches at 0xF0
    sa r15         ; Dummy write to set Z flag
    li #poll_release:2
    li #poll_release:1
    li #poll_release:0
    jp nz         ; If not zero, continue polling

poll:
    li #0xF
    li #0x0
    lm             ; Read switches at 0xF0
    sa r15         ; Dummy write to set Z flag
    li #poll:2
    li #poll:1
    li #poll:0
    jp z          ; If zero, continue polling
    
    li #1
    ld r4
    ad r4         ; Increment ones digit
    li #6
    ld r4
    ad r15        ; If r4 > 10, carry flag will be set
    li #main:2
    li #main:1
    li #main:0
    jp nc         ; If not carry, skip reset
    li #0
    sa r4         ; Reset ones digit to 0
    li #1
    ld r5
    ad r5         ; Increment tens digit
    li #6
    ld r5
    ad r15        ; If r5 > 10, carry flag will be set
    li #main:2
    li #main:1
    li #main:0
    jp nc         ; If not carry, skip reset
    li #0
    sa r5         ; Reset tens digit to 0
    li #1
    ld r6
    ad r6         ; Increment hundreds digit
    li #6
    ld r6
    ad r15        ; If r6 > 10, carry flag will be set
    li #main:2
    li #main:1
    li #main:0
    jp nc         ; If not carry, skip reset
    li #0
    sa r6         ; If carry, reset hundreds digit to 0
    li #1
    ld r7
    ad r7         ; Increment thousands digit
    li #6
    ld r7
    ad r15        ; If r7 > 10, carry flag will be set
    li #main:2
    li #main:1
    li #main:0
    jp nc         ; If not carry, skip reset
    li #0
    sa r7         ; If carry, reset thousands digit to 0
    li #0x5
    li #0xF
    li #0x0
    sm            ; Output 5V to buzzer at 0xF0
    li #done:2
    sa r15
    li #done:1
    sa r14
    li #done:0
    sa r13
    li #wait_100ms:2
    li #wait_100ms:1
    li #wait_100ms:0
    jp            ; Wait 100ms
done:
    li #main:2
    li #main:1
    li #main:0
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

opening_message:
    li #0b0100
    li #0xF
    li #0x3
    sm
    li #0b1000
    li #0xF
    li #0x3
    sm            ; Display "H"
    li #msg1:2
    sa r15
    li #msg1:1
    sa r14
    li #msg1:0
    sa r13
    li #wait_264us:2
    li #wait_264us:1
    li #wait_264us:0
    jp            ; Wait for HD44780 to finish
msg1:
    li #0b0110
    li #0xF
    li #0x3
    sm
    li #0b0101
    li #0xF
    li #0x3
    sm            ; Display "e"
    li #msg2:2
    sa r15
    li #msg2:1
    sa r14
    li #msg2:0
    sa r13
    li #wait_264us:2
    li #wait_264us:1
    li #wait_264us:0
    jp            ; Wait for HD44780 to finish
msg2:
    li #0b0110
    li #0xF
    li #0x3
    sm
    li #0b1100
    li #0xF
    li #0x3
    sm            ; Display "l"
    li #msg3:2
    sa r15
    li #msg3:1
    sa r14
    li #msg3:0
    sa r13
    li #wait_264us:2
    li #wait_264us:1
    li #wait_264us:0
    jp            ; Wait for HD44780 to finish
msg3:
    li #0b0110
    li #0xF
    li #0x3
    sm
    li #0b1100
    li #0xF
    li #0x3
    sm            ; Display "l"
    li #msg4:2
    sa r15
    li #msg4:1
    sa r14
    li #msg4:0
    sa r13
    li #wait_264us:2
    li #wait_264us:1
    li #wait_264us:0
    jp            ; Wait for HD44780 to finish
msg4:
    li #0b0110
    li #0xF
    li #0x3
    sm
    li #0b1111
    li #0xF
    li #0x3
    sm            ; Display "o"
    li #msg5:2
    sa r15
    li #msg5:1
    sa r14
    li #msg5:0
    sa r13
    li #wait_264us:2
    li #wait_264us:1
    li #wait_264us:0
    jp            ; Wait for HD44780 to finish
msg5:
    li #0b0010
    li #0xF
    li #0x3
    sm
    li #0b0001
    li #0xF
    li #0x3
    sm            ; Display "!"
    li #msg6:2
    sa r15
    li #msg6:1
    sa r14
    li #msg6:0
    sa r13
    li #wait_264us:2
    li #wait_264us:1
    li #wait_264us:0
    jp            ; Wait for HD44780 to finish
msg6:
    li #main:2
    li #main:1
    li #main:0
    jp
