; Blink on 1MHz clock
; 2025-09-08 by nasu8151

np
loop:
    li #0xF
    li #0xF
    li #0x0
    sm            ; all output, HIGH
    li #l1:2
    sa r15
    li #l1:1
    sa r14
    li #l1:0
    sa r13
    li #wait_100ms:2
    li #wait_100ms:1
    li #wait_100ms:0
    jp
l1:
    li #0x0
    li #0xF
    li #0x0
    sm            ; all output, LOW
    li #l2:2
    sa r15
    li #l2:1
    sa r14
    li #l2:0
    sa r13
    li #wait_100ms:2
    li #wait_100ms:1
    li #wait_100ms:0
    jp
l2:
    li #loop:2
    li #loop:1
    li #loop:0
    jp


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
    li #wait_1ms_ret:2
    li #wait_1ms_ret:1
    li #wait_1ms_ret:0
    jp

wait_100ms:
    li #2
    sa r9
wait_100ms_loop:
    li #9
    sa r8
    ld r9
    li #0x1
    li #0x1
    sm
wait_100ms_loop2:
    ld r8
    li #0x1
    li #0x0
    sm
    li #wait_1ms:2
    li #wait_1ms:1
    li #wait_1ms:0
    jp
wait_1ms_ret:
    li #0x1
    li #0x0
    lm
    li #0x1
    ad r8
    li #wait_100ms_loop2:2
    li #wait_100ms_loop2:1
    li #wait_100ms_loop2:0
    jp nc

    li #0x1
    li #0x1
    lm       ; restore r9
    li #0x1
    ad r9
    li #wait_100ms_loop:2
    li #wait_100ms_loop:1
    li #wait_100ms_loop:0
    jp nc
    ld r15
    ld r14
    ld r13
    jp


