# HC4eROMandRAM

これは、HC4<sub>E</sub>ボード用のROM/RAMを担当するプログラムです。
開発には、[PlatformIO](https://platformio.org/)を推奨しますが、書き込みはArduino IDEでも可能です。

## 書き込み方法(PlatformIO)

まず、VSCodeをダウンロードしてインストールしてください。そして、拡張機能の[PlatformIO](https://platformio.org/)を導入してください。\
つづいて、[HC4eROMandRAM.code-workspace](HC4eROMandRAM.code-workspace)を開き、ワークスペースに入ります。

### SerialUPDIの場合

SerialUPDIライタの作り方は、[この辺](https://nemuisan.blog.bai.ne.jp/?eid=239957)や[ここ](https://github.com/SpenceKonde/AVR-Guidance/blob/master/UPDI/jtag2updi.md)を参照してください。

## 書き込み方法(Arduino IDE)

まず、Arduino IDEをダウンロードし、インストールします。そして、[HC4eROMandRAM.ino](HC4eROMandRAM.ino)を開き、ツールバーからFile->Preferencies...(ファイル->基本設定)を開きます。\
そこにある、Additional Board Manager URLs(追加のボードマネージャーURL)を開き、```https://mcudude.github.io/MegaCoreX/package_MCUdude_MegaCoreX_index.json```を追加してください。\
![Additional Board Manager URLs](extras\2025-12-27-193407.png)
すると、サイドバーのボードマネージャーから```MegaCoreX```が落とせるようになるので、検索してインストールしてください。

### SerialUPDIの場合

SerialUPDIライタの作り方は、[この辺](https://nemuisan.blog.bai.ne.jp/?eid=239957)や[ここ](https://github.com/SpenceKonde/AVR-Guidance/blob/master/UPDI/jtag2updi.md)を参照してください。\

SerialUPDIライタをパソコンにつなぎ、またUPDI端子とGND、必要に応じて電源をHC4<sub>E</sub>ボードにつなぎます。\
つづいて、Arduino IDEのTools下の設定を以下のように変更してください。\
![Tools settings](extras\2025-12-27-191716.png)\
COMポートは適宜読み替えてください。\
そうしたら、普通の書き込みボタンではなく、Sketch->Upload Using Programmerを押すか、Ctrl+Shift+Uを押して書き込んでください。

### jtag2updiの場合

まず、jtag2updiスケッチの書き込まれたArduino(Uno R3/Nano)を用意し、[公式リポジトリ](https://github.com/ElTangas/jtag2updi)や[この辺](https://burariweb.info/electronic-work/arduino-updi-writing-method.html)を参考にHC4<sub>E</sub>ボードとつなぎます。\
つづいて、Arduino IDEのTools下の設定を以下のように変更してください。\
![Tools settings](extras\2025-12-28-081600.png)\
そうしたら、普通の書き込みボタンではなく、Sketch->Upload Using Programmerを押すか、Ctrl+Shift+Uを押して書き込んでください。

## 動作確認

[Tera Term](https://teratermproject.github.io/)などのターミナルソフトを使用します。ここでは、Tera Termを使用しているものとします。\
Tera Termを開くと、接続先を選ぶ画面が出ます。そこの、シリアルにチェックを入れ、UPDIライタではなく、**HC4<sub>E</sub>のシリアルアダプタ**を選んでください。もしわからなければ、UPDIライタを外してみてください。\
設定->シリアルポートを選び、スピードを```115200```に設定します。つづいて、設定->端末を選び改行コードを送信、受信ともに```LF```に設定してください。\
黒い画面で```h```をタイプし改行すると、以下の表示が出れば成功です。![help command](extras\2025-12-28-090254.png)
つづいて```l```をタイプし改行したのちプログラムのintel hexのデータを右クリックか```Alt+V```で貼り付けて、そのプログラムが正しく動けば、完全に成功しています。
![succeed](extras\2025-12-28-091017.png)