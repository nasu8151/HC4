np
start: ;ラベル
    ld r0
    ld #1
    ad r0       ;r0をインクリメント
    ld #start:3 ;start[15:12]をロード
    ls #start:2 ;start[11:8]をロード
    ld #start:1 ;start[7:4]をロード
    ls #start:0 ;start[3:0]をロード
    jp