np
ld #1
ld #0xf
ld #0x0
sc [ab] ; mov [0xF0], #1
ld #9
sa r1   ;r1 = 16 - 6 - 1
ld #0
sa r2   ;r2 = 0
ld r2
ld #1
ad r2   ;increment r2
ld r2
ld r1
ad r15  ;if r2 > 6, carry flg will be set
ld #0x0
ld #0x0
ld #0x7
jp c    ;if r2 > 6, jump to 0x007
ld r2
ld #0xf
ld #0x0
sc [ab] ;store r2 to 0xf0
ld #0xf
ld #0x0
ld [ab] ;read from 0xf0
sa r15  ;if 0xf0 == 0, zero flg will be set
ld #0x0
ld #0x1
ld #0x7
jp z   ;if 0xf0 is not 0, jump to 0x010
ld #0x0
ld #0x0
ld #0x9
jp      ;jump to 0x009
