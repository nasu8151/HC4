; 
; 3-minutes timer
; Make sure the clock is set to 1Hz.
;

np
ld #0xF
ld #0
sa r15
sc [ab] ; mov [0xF0], #0
ld #0xB
sa r14
ld #0xD
sa r13
ld #13
sa r1   ; mov 
ld #9
sa r0
ld r0
ld #1
ad r0
ld r15
ld r15
ld r13
jp nc
ld #1
ld r1
ad r1
ld r15
ld r15
ld r14
jp nc
ld #0xF
ld #0xF
ld #0x0
sc [ab]
ld #0
ld #0xF
ld #0
sc [AB]
ld #0x0
ld #0x2
ld #0x6
jp
