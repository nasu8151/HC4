/*
 * HC4eROMandRAM.ino ── ATmega4809 内蔵 EEPROM を
 *   ├─ UART 経由で書き込める "RAM 面"
 *   └─ 8bit アドレス線 → 8bit データ線 で読み出せる "ROM 面"
 * の２つの顔を持たせたワンチップ簡易メモリ。
 *
 * ▼ UART プロトコル (RAM 面) — 変更なし
 *   [STX=0x02][CMD('W'/'R')][ADDR][LEN][DATA…][ETX=0x03]
 *   - 'W' : LEN≤64B を EEPROM[ADDR] へ順次書込
 *   - 'R' : LEN=0     で EEPROM[ADDR] 1B を応答
 *
 * ▼ ROM 面 (UPDATE)
 *   ・PA0‑PA7  … アドレス入力  (8bit)
 *   ・PD0‑PD7  … データ出力   (8bit, 常時ドライブ)
 *   CPU がアドレスバスに値を出力すると、ATmega4809 が同一アドレスの EEPROM を
 *   読んで PD0‑7 に反映する。CS/OE 信号は省略し常時有効 (必要なら後で追加可)。
 *
 *   時系列イメージ:
 *     CPU→[PA] = 0x3C   → MCU 読取 → EEPROM.read(0x3C) = 0xA5
 *                                             ↓
 *                       MCU→[PD] = 0xA5  (CPU データバスへ提示)
 */

#include <Arduino.h>
#include <EEPROM.h>
#include <avr/io.h>  // 低レベル Port 操作用

/* ===== ユーザ設定 ============================= */
#define BAUD_RATE   115200        // UART1 速度 (PC0/PC1)
#define MEM_SIZE    256u          // EEPROM サイズ
#define USE_REG_IO  1             // 1=レジスタ直叩き / 0=pinMode/digitalRead
/* ============================================= */

/* --- 受信パーサ状態 --- */
enum S : uint8_t { STX, CMD, ADDR, LEN, DATA, ETX };

/* --- 前方宣言 --- */
static void handleSerial();
static void serviceROM();

/* ===== MCU SETUP ===== */
void setup() {
  /* UART (RAM 面) */
  Serial1.begin(BAUD_RATE);
  while (!Serial1);

#if USE_REG_IO
  /* PA0‑7 : アドレス入力 (DIR=0) */
  PORTA.DIR = 0x00;
  /* PD0‑7 : データ出力  (DIR=1, 初期値=0) */
  PORTD.DIR = 0xFF;
  VPORTD.OUT = 0x00;
#else
  /*
   * === Arduino ピンマッピング例 (Nano Every) ===
   *   PD0 → D2   PD4 → D6
   *   PD1 → D3   PD5 → D7
   *   PD2 → D4   PD6 → D8
   *   PD3 → D5   PD7 → D9
   *
   * ボードによって異なる場合は pdPins[] を書き替えてください。
   */
  const uint8_t paPins[8] = {22,23,24,25,26,27,28,29};  // PA0‑7
  const uint8_t pdPins[8] = {2,3,4,5,6,7,8,9};          // PD0‑7 (例)
  for (uint8_t i = 0; i < 8; ++i) pinMode(paPins[i], INPUT);
  for (uint8_t i = 0; i < 8; ++i) {
    pinMode(pdPins[i], OUTPUT);
    digitalWrite(pdPins[i], LOW);
  }
#endif
}

/* ===== MAIN LOOP ===== */
void loop() {
  handleSerial();  // RAM 面 (UART 書込/読込)
  serviceROM();    // ROM 面 (ポート読み→出力)
}

/* ------------------------------------------------- */
/*  RAM 面 : UART プロトコル                         */
/* ------------------------------------------------- */
static void handleSerial() {
  static S st = STX;
  static uint8_t cmd, addr, len, idx;
  static uint8_t buf[64];

  if (!Serial1.available()) return;
  uint8_t b = Serial1.read();
  if (b == '\r' || b == '\n') return;

  switch (st) {
    case STX:
      if (b == 0x02) st = CMD;
      break;

    case CMD:
      if (b == 'W' || b == 'R') { cmd = b; st = ADDR; }
      else st = STX;             // 不正コマンド
      break;

    case ADDR:
      addr = b;
      st   = LEN;
      break;

    case LEN:
      len = b; idx = 0;
      st  = (len ? DATA : ETX);
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
          if (addr < MEM_SIZE)
            Serial1.write(EEPROM.read(addr));
        }
      }
      st = STX;
      break;
  }
}

/* ------------------------------------------------- */
/*  ROM 面 : PA[7:0] = アドレス, PD[7:0] = データ   */
/* ------------------------------------------------- */
static void serviceROM() {
  /* クロック 16 MHz / 115200bps でも 100 µs に 1 回程度呼ばれれば十分 */
  static uint8_t prevAddr = 0xFF;   // 初回強制更新用
  uint8_t addr;

#if USE_REG_IO
  addr = VPORTA.IN;                 // 8bit 一括読取り
#else
  const uint8_t paPins[8] = {22,23,24,25,26,27,28,29};
  const uint8_t pdPins[8] = {2,3,4,5,6,7,8,9};
  addr = 0;
  for (uint8_t bit = 0; bit < 8; ++bit) {
    addr |= (digitalRead(paPins[bit]) ? 1 : 0) << bit;
  }
#endif

  if (addr != prevAddr) {
    uint8_t val = EEPROM.read(addr);
#if USE_REG_IO
    VPORTD.OUT = val;               // データ提示
#else
    for (uint8_t bit = 0; bit < 8; ++bit) {
      digitalWrite(pdPins[bit], (val >> bit) & 1);
    }
#endif
    prevAddr = addr;
  }
}
