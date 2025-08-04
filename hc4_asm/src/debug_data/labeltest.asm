reset: np ;おもち
start: ;ラベル
    ld r0
    ld #1
    ad r0       ;r0をインクリメント
    ld #0x0
    ls #0x0
    ld #0x0
    ls #0x1
    jp
koko: ;banana
    ad r1 ; 実行されない命令