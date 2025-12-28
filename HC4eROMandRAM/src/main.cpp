#include <Arduino.h>

/*
 * HC4eROMandRAM.ino ── 128 B ROM (EEPROM) + 16×4‑bit RAM/I/O “三役” 完全版
 *   2025‑07‑18   Intel‑HEX 行毎即書込み版 + 小文字 l,r コマンド
 *   2025‑07‑18b  CR を無視し LF で行確定（空行 ERR 解消）
 *
 * ─── 概要 ──────────────────────────────────
 *  UART コマンド (115200‑8N1, LF)
 *    L / l  : Intel‑HEX ローダ  (1 行ずつ即 EEPROM 書込み)
 *    R / r  : 4‑bit RAM ダンプ   (16 word, comma separated)
 *
 *  内蔵 EEPROM 0‑255 を ROM 領域として読み出し、
 *  外付け 4‑bit RAM を PC2‑5, PE0‑3, PF0‑1 で制御。
 *────────────────────────────────────────────*/

#include <avr/io.h>

#include "disasm.h"
#include "hex.h"

/************* 定数 ******************************/
#define BAUD_RATE 115200

/************* Port/F ビット定義 ******************/
#define PF_nRD 4
#define PF_nWR 5

#define PIN_nRD PIN_PF4
#define PIN_nWR PIN_PF5

#define PA_AI 2
#define PA_AO 3
#define PA_BO 4

#define PIN_nPORT_OE  PIN_PA2
#define PIN_nPORTA_WE PIN_PA3
#define PIN_nPORTB_WE PIN_PA4

#define PIN_CLK PIN_PA6
#define PIN_RST PIN_PA5

/************* 4‑bit RAM/I‑O *********************/
volatile uint8_t ram4[16] = { 0 }; /* 4‑bit ×16 word */

volatile uint8_t latchedAddr = 0;
volatile uint8_t latchedData = 0;

volatile uint8_t curnWR;

volatile uint8_t onclkrise = 0;

// 256x8bit ROM for HC4e program
volatile uint8_t rom8[MEM_SIZE];

uint8_t ontrace = 0;

/************* 4‑bit RAM ダンプ *******************/
static void ramDump(char *args) {
  if (*args == 'h' || *args == 'H') {
    Serial.println("Usage: R");
    Serial.println(" Dumps 16x4-bit RAM contents.");
    return;
  } else if (*args == 'c' || *args == 'C') {
    for (uint8_t i = 0; i < 16; i++) {
      Serial.print(ram4[i]);
      Serial.write(',');
    }
    uint8_t pc = VPORTC.IN;
    Serial.print(pc);
    Serial.print(',');
    Serial.println(rom8[pc]);
  } else {
    Serial.println("r0  r1  r2  r3  r4  r5  r6  r7  r8  r9  r10 r11 r12 r13 r14 r15");
    for (uint8_t i = 0; i < 16; i++) {
      if (ram4[i] < 10) Serial.write(' ');
      Serial.print(ram4[i]);
      if (i == 15) {
        Serial.println();
        break;
      } else {
        Serial.write(',');
      }
      Serial.write(' ');
    }
    uint8_t pc = VPORTC.IN;
    Serial.print("PC=");
    Serial.print(pc);
    Serial.print(", Inst=");
    Serial.print(rom8[pc], HEX);
    Serial.print(" (");
    Serial.print(disasm(rom8[pc]));
    Serial.println(")");
  }
}

static void trace() {
  if (Serial.available()) {
    char c = Serial.read();
    if (c == 0x03) { // Ctrl-C
      ontrace = 0;
      Serial.print("Trace stopped.\n> ");
      return;
    }
  }
  if (onclkrise) {
    onclkrise = 0;
    ramDump("c");
  }
}

static void startTrace() {
  ontrace = 1;
  Serial.println("Trace started. (Ctrl-C to stop)");
}

static void help() {
  Serial.println("r or R : Read HC4e RAM data");
  Serial.println("l or L : Load to HC4e ROM");
  Serial.println("t or T : Trace execution (Ctrl-C to stop)");
  Serial.println("         *make sure HC4e CPU is running and in low clock mode.");
  Serial.println("h or H : Help");
}

/************* UART コマンド受付 ******************/
static void programUART() {
  static char buf[8];
  static uint8_t idx = 0;

  while (Serial.available()) {
    char c = Serial.read();
    if (0x20 <= c) Serial.write(c);
    if (c == '\r') continue; /* CR 無視 */
    if (c == '\n') {
      Serial.write('\n');
      if (idx == 0) { 
        Serial.print("> "); 
        continue; 
      } /* 連続改行は無視 */
      buf[idx] = '\0';
      char cmd = buf[0];
      char *args = &buf[1];
      while (*args == ' ') args++; /* スペーススキップ */
      if (cmd == 'l' || cmd == 'L') intelhexLoad(args);
      else if (cmd == 'r' || cmd == 'R') ramDump(args);
      else if (cmd == 't' || cmd == 'T') startTrace();
      else if (cmd == 'h' || cmd == 'H') help();
      else Serial.println("Unknown command. type 'h' for help.");
      idx = 0; /* バッファクリア */
      if (ontrace == 0) Serial.print("> ");

    } else if (idx < sizeof(buf) - 1) {
      buf[idx++] = c;
    }
  }
}


static void serviceRAM() {
  uint8_t nRD = digitalReadFast(PIN_nRD);
  uint8_t nWR = digitalReadFast(PIN_nWR);
  uint8_t dataAddr = VPORTF.IN & 0x0F;
  if (nWR == 0) {
    if (dataAddr == 0x0E) {
      digitalWriteFast(PIN_nPORTA_WE, LOW);
    } else if (dataAddr == 0x0F) {
      digitalWriteFast(PIN_nPORTB_WE, LOW);
    } else {
      VPORTE.DIR &= ~0x0F;
    }
  } else if (nRD == 0) { // nRDがアサートされていたら
    if (dataAddr == 0x0E) {
      VPORTE.DIR &= ~0x0F;
      digitalWriteFast(PIN_nPORT_OE, LOW);
    } else {
      VPORTE.DIR |= 0x0F;
      VPORTE.OUT = ram4[dataAddr];
    }
  }
}

void RAMRead() {
  if (digitalReadFast(PIN_nRD) == 0){ // もしnRDがアサートされていたなら
    uint8_t dataAddr = VPORTF.IN & 0x0F;
    VPORTE.DIR |= 0x0F;
    VPORTE.OUT = ram4[dataAddr];
  } else {
    digitalWriteFast(PIN_nPORT_OE, HIGH);
    PORTE.DIR &= ~0x0F;  // バスを開放
  }
}

/************* Arduino 標準関数 *******************/
void setup() {
  Serial.begin(BAUD_RATE);

  /* --- RAM/I/O バス設定 --- */
  PORTF.DIR &= ~0x0F;
  PORTF.DIR &= ~((1 << PF_nRD) | (1 << PF_nWR));
  PORTE.DIR &= ~0x0F;  // PE0‑3 データ Hi‑Z
  PORTE.OUT &= ~0x0F;

  PORTF.DIR &= ~((1 << PF_nRD) | (1 << PF_nWR));
  PORTA.DIR |= (1 << PA_AI) | (1 << PA_AO) | (1 << PA_BO);
  VPORTA.OUT |= (1 << PA_AI) | (1 << PA_AO) | (1 << PA_BO);  // disable (負論理)

  /* --- PA/PD (ROM 出力) --- */
  PORTC.DIR = 0x00;  // PC 入力 (アドレス)
  PORTD.DIR = 0xFF;  // PD 出力 (データ)
  VPORTD.OUT = 0x00;

  PORTA.PIN6CTRL = PORT_ISC_RISING_gc; // clk

  Serial.println("\nHC4e ROM/RAM Monitor");
  Serial.print("> ");

  for (uint16_t i = 0; i < MEM_SIZE; i++) { // ROM配列の初期化
    rom8[i] = EEPROM.read(i);
  }

  // while(1) の前で初期化（重要）
  uint8_t prevnRD = digitalReadFast(PIN_nRD);

  while (1) {
    // ---- RD処理（そのままでOK）
    uint8_t curnRD = digitalReadFast(PIN_nRD);
    if (curnRD != prevnRD) RAMRead();
    prevnRD = curnRD;

    // ---- WR処理（ここを強化）
    curnWR = digitalReadFast(PIN_nWR);

    // /WRがLOWの間に常にラッチ（番地ズレ対策）
    if (curnWR == 0) {
      VPORTE.DIR &= ~0x0F;              // 必ず入力（バス競合防止）
      latchedAddr = VPORTF.IN & 0x0F;
      latchedData = VPORTE.IN & 0x0F;
    }

    if (digitalReadFast(PIN_RST) == 0) { //リセット時にもROM読み出し
      uint8_t ad = VPORTC.IN;
      VPORTD.OUT = rom8[ad];
    }
    if (ontrace == 0) {
      programUART();
    } else {
      trace();
    }
    serviceRAM();
    delayMicroseconds(750);
  }
}


void loop() {

}

// クロック立ち上がり割り込み
// ROM読み込み, PORTA制御, RAM書込み
ISR(PORTA_PORT_vect) {
  VPORTA.OUT |= PIN4_bm;
  PORTA.INTFLAGS = PIN6_bm;
  onclkrise = 1;
  uint8_t a = VPORTC.IN;
  VPORTD.OUT = rom8[a];
  // VPORTD.OUT = EEPROM.read(a);
  if (curnWR == 0) {   // curnWR は割り込み直前のnWRの状態なので...
    ram4[latchedAddr] = latchedData;
  }
}
