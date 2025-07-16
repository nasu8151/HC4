/*
 * HC4eROMandRAM.ino  ── ATmega4809 を “簡易メモリユニット” として使うスケッチ
 *
 *  ■ 階層構造（2025‑07‑11 改訂）
 *    ① **ROM プログラマ (UART)**
 *       ‑ PC から 64 B ×2 フレームで 128 B の命令列を書込み
 *       ‑ ベリファイ用に 1 B 読出し `'R'` コマンドも残す
 *         → 書込み×2 → 読取り×1 の 3 フレームで完了
 *    ② **ROM 読み出し (パラレル)**
 *       ‑ PA[7:0] = アドレス入力 → PD[7:0] にデータ提示
 *    ③ **RAM 制御**（フックのみ。今後拡張）
 *
 *  ▼ UART フレーム（①）
 *    [0]=0x02 [1]=CMD('W'/'R') [2]=ADDR [3]=LEN [4…]=DATA [last]=0x03
 *      CMD='W': LEN=1–64, DATA=書込バイト列
 *      CMD='R': LEN=0      , DATA=なし  → MCU が 1 B 応答
 *
 *  ▼ ポート割り当て（②）
 *    PA0‑PA7 … アドレス入力  (8bit)
 *    PD0‑PD7 … データ出力   (8bit, 常時ドライブ)
 */

#include <Arduino.h>
#include <EEPROM.h>
#include <avr/io.h>

/* ===== 設定 ===== */
#define BAUD_RATE   115200
#define MEM_SIZE    256u
#define USE_REG_IO  1         // 0: Arduino API, 1: レジスタ直叩き
/* ================= */

/* 受信パーサ状態 */
enum S : uint8_t { STX, CMD, ADDR, LEN, DATA, ETX };

/* プロトタイプ */
static void programROM();   // UART 書込み + 1B 読出し
static void serviceROM();   // パラレル読み出し
static void serviceRAM();   // 予備

/* ===== SETUP ===== */
void setup() {
  Serial1.begin(BAUD_RATE);     // PC 不在でも即起動

#if USE_REG_IO
  PORTA.DIR = 0x00;             // PA as input (addr)
  PORTD.DIR = 0xFF;             // PD as output (data)
  VPORTD.OUT = 0x00;
#else
  const uint8_t paPins[8] = {22,23,24,25,26,27,28,29};
  const uint8_t pdPins[8] = {2,3,4,5,6,7,8,9};
  for (uint8_t p: paPins) pinMode(p, INPUT);
  for (uint8_t p: pdPins) { pinMode(p, OUTPUT); digitalWrite(p, LOW);}  
#endif
}

/* ===== LOOP ===== */
void loop() {
  programROM();   // UART フレーム処理
  serviceROM();   // パラレル ROM 出力
  serviceRAM();   // 将来拡張
}

/* ------------------------------------------------- */
/* ① UART → ROM 書込み / 1B 読出し                  */
/* ------------------------------------------------- */
static void programROM() {
  static S st = STX;
  static uint8_t cmd, addr, len, idx;
  static uint8_t buf[64];

  if (!Serial1.available()) return;
  uint8_t b = Serial1.read();
  if (b == '\r' || b == '\n') return;   // 改行コード無視

  switch (st) {
    case STX:
      if (b == 0x02) st = CMD;
      break;

    case CMD:
      if (b == 'W' || b == 'R') { cmd = b; st = ADDR; }
      else st = STX;  // 不正コマンド
      break;

    case ADDR:
      addr = b;
      st   = LEN;
      break;

    case LEN:
      len = b; idx = 0;
      st  = (cmd == 'W' ? (len ? DATA : ETX) : ETX);  // 'R' は LEN=0 を期待
      break;

    case DATA:
      buf[idx++] = b;
      if (idx >= len) st = ETX;
      break;

    case ETX:
      if (b == 0x03) {
        if (cmd == 'W') {
          for (uint8_t i = 0; i < len && (uint16_t)addr + i < MEM_SIZE; ++i) {
            EEPROM.update(addr + i, buf[i]);
          }
        } else if (cmd == 'R') {
          if (addr < MEM_SIZE) Serial1.write(EEPROM.read(addr));
        }
      }
      st = STX;
      break;
  }
}

/* ------------------------------------------------- */
/* ② PA[7:0] → EEPROM → PD[7:0]                     */
/* ------------------------------------------------- */
static void serviceROM() {
  static uint8_t prevAddr = 0xFF;
  uint8_t addr;

#if USE_REG_IO
  addr = VPORTA.IN;
#else
  const uint8_t paPins[8] = {22,23,24,25,26,27,28,29};
  addr = 0;
  for (uint8_t i = 0; i < 8; ++i) addr |= (digitalRead(paPins[i]) ? 1 : 0) << i;
#endif

  if (addr != prevAddr) {
    uint8_t val = EEPROM.read(addr);
#if USE_REG_IO
    VPORTD.OUT = val;
#else
  const uint8_t pdPins[8] = {2,3,4,5,6,7,8,9};
    for (uint8_t i = 0; i < 8; ++i) digitalWrite(pdPins[i], (val >> i) & 1);
#endif
    prevAddr = addr;
  }
}

/* ------------------------------------------------- */
/* ③ RAM 用フック                                   */
/* ------------------------------------------------- */
static void serviceRAM() {
  //  未実装
}
