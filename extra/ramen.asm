; 
; 3-minutes timer
; Make sure the clock is set to 1Hz.
;

np
ld #0xF
ld #0
sc [ab] ; mov [0xF0], #0
ld #13
sa r1   ; mov r1, #13
ld #9
sa r0   ; mov r0, #9
ld r0
ld #1
ad r0   ; add r0, #1, r0
ld #0x0
ld #0x0
ld #0x8
jp nc   ; b nc 0x008
ld r1
ld #1
ad r1   ; add r1, #1, r1
ld #0x0
ld #0x0
ld #0x6
jp nc   ; b nc 0x006
ld #0xF
ld #0xF
ld #0x0
sc [ab] ; mov [0xF0], #0xF
ld #0x0
ld #0x1
ld #0xD
jp      ; halt
