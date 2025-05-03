np      ;nop
ld #0
ls #0x2
sa r0   ;store 0x02 to r0
ld #0
ls #0
ld #0x8
ls #0
jl      ;jump and link to 0x0080
e1      ;fill delay slot
ld r0
ld #0xf
ls #0xe
ld #0
ls #0
sc      ;store r0 to 0xfe00
ld #0
ls #0
ld #0x8
ls #0
jl      ;jump and link to 0x0080
np      ;fill delay slot
ld #0
ls #0
ld #0
ls #4
jp      ;jump to 0x0004 (loop)
np      ;fill delay slot

.org 0x0080
sa r14
ld #0
sc r15  ;store return address to r14 and r15
ld r0
ld #1
ad r0   ;add r0 #1 r0
ld r14
ld r15
jp      ;return
np