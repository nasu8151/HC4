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

#include <EEPROM.h>
#include <avr/io.h>

/************* 定数 ******************************/
#define BAUD_RATE 115200
#define MEM_SIZE 256u /* 内蔵 EEPROM = 256 バイト */
#define IHEX_LINE_MAX 600

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
uint8_t ram4[16] = { 0 }; /* 4‑bit ×16 word */

// 256x8bit ROM for HC4e program
volatile uint8_t rom8[MEM_SIZE];

/************* HEX 変換ユーティリティ *************/
static int hex1(char c) {
  if (c >= '0' && c <= '9') return c - '0';
  if (c >= 'A' && c <= 'F') return c - 'A' + 10;
  if (c >= 'a' && c <= 'f') return c - 'a' + 10;
  return -1;
}
static int hex2(const char* p) {
  int h = hex1(p[0]), l = hex1(p[1]);
  return (h < 0 || l < 0) ? -1 : (h << 4) | l;
}
static int hex4(const char* p) {
  int hi = hex2(p), lo = hex2(p + 2);
  return (hi < 0 || lo < 0) ? -1 : (hi << 8) | lo;
}
static int readDataBytes(int len, const char* p, uint8_t* dst) {
  for (int i = 0; i < len; i++) {
    int v = hex2(p + i * 2);
    if (v < 0) return -1;
    dst[i] = (uint8_t)v;
  }
  return 0;
}

static void putHex(uint8_t b) {
  static const char tbl[] = "0123456789ABCDEF";
  Serial.write(tbl[b >> 4]);
  Serial.write(tbl[b & 0x0F]);
}

void intelhexLoad() {
  static char line[IHEX_LINE_MAX];
  // static uint8_t rom8[MEM_SIZE];

  // まずRAMに展開（EEPROMには書かない）
  for (uint16_t i = 0; i < MEM_SIZE; i++) rom8[i] = 0xFF;

  uint32_t base = 0;      // type 04 用（通常0のままでOK）
  uint16_t total = 0;

  while (1) {
    // --- 1) ':' まで同期してから 1行読む（fmt対策）
    char c;
    do {
      while (!Serial.available()) {}
      c = Serial.read();
      Serial.write(c);
      if (c == 0x03) {
        Serial.println("User aborted");
          for (uint16_t i = 0; i < MEM_SIZE; i++) { // ROM配列の初期化
            rom8[i] = EEPROM.read(i);
          }
        return;
      }
    } while (c != ':');

    uint16_t idx = 0;
    line[idx++] = ':';   // 先頭

    while (1) {
      while (!Serial.available()) {}
      c = Serial.read();
      Serial.write(c);
      if (c == '\r') continue;
      if (c == '\n') break;

      if (idx < IHEX_LINE_MAX - 1) line[idx++] = c;
      else {
        Serial.println(F("[ERR] line too long"));
        return;
      }
    }
    line[idx] = '\0';

    // EOF
    if (strcmp(line, ":00000001FF") == 0) break;

    // --- 2) ヘッダ解析
    if (line[0] != ':') { Serial.println(F("[ERR] fmt")); return; }

    int len  = hex2(&line[1]);
    int addr = hex4(&line[3]);
    int type = hex2(&line[7]);
    if (len < 0 || addr < 0 || type < 0) { Serial.println(F("[ERR] fmt")); return; }

    // 行長チェック（最低 11 + 2*len 文字必要）
    int need = 11 + 2 * len;
    if ((int)strlen(line) < need) { Serial.println(F("[ERR] fmt")); return; }

    // --- 3) レコード処理
    if (type == 0x04) {
      // Extended Linear Address
      if (len != 2) { Serial.println(F("[ERR] fmt")); return; }
      int hi = hex4(&line[9]);
      if (hi < 0) { Serial.println(F("[ERR] fmt")); return; }
      base = ((uint32_t)hi) << 16;
      continue;
    }

    if (type == 0x00) {
      // Data record
      uint32_t fullAddr = base | (uint16_t)addr;
      if (fullAddr + (uint32_t)len > MEM_SIZE) { Serial.println(F("[ERR] range")); return; }

      for (int i = 0; i < len; i++) {
        int v = hex2(&line[9 + i * 2]);
        if (v < 0) { Serial.println(F("[ERR] data")); return; }
        rom8[fullAddr + i] = (uint8_t)v;
      }
      total += (uint16_t)len;
      continue;
    }

    // それ以外のtypeは無視（必要なら追加）
  }

  // --- 4) EOF後にまとめてEEPROMへ（受信と競合しない）
  for (uint16_t i = 0; i < MEM_SIZE; i++) {
    EEPROM.update(i, rom8[i]);   // updateの方が速くなることが多い
  }

  Serial.print(F("[OK] loaded "));
  Serial.print(total);
  Serial.println(" Bytes.");
}


/************* 4‑bit RAM ダンプ *******************/
static void ramDump() {
  Serial.println("r0  r1  r2  r3  r4  r5  r6  r7  r8  r9  r10 r11 r12 r13 r14 r15");
  for (uint8_t i = 0; i < 16; i++) {
    Serial.print(ram4[i]);
    if (i == 15) {
      Serial.println();
      break;
    } else {
      Serial.write(',');
    }
    Serial.write(' ');
    if (ram4[i] < 10) Serial.write(' ');
  }
}

static void help() {
  Serial.println("r or R : Read HC4e RAM data");
  Serial.println("l or L : Load to HC4e ROM");
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
      if (idx == 0) { continue; } /* 連続改行は無視 */
      buf[idx] = '\0';
      char cmd = buf[0];
      if (cmd == 'l' || cmd == 'L') intelhexLoad();
      else if (cmd == 'r' || cmd == 'R') ramDump();
      else if (cmd == 'h' || cmd == 'H') help();
      else Serial.println("Unknown command. type 'h' for help.");
      idx = 0; /* バッファクリア */
      Serial.print("> ");
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

void RAMWrite() {
  VPORTE.DIR &= ~0x0F; 
  VPORTA.OUT |= PIN3_bm;
  uint8_t addr = VPORTF.IN & 0x0F;  // A0‑A3
  uint8_t data = VPORTE.IN & 0x0F;
  ram4[addr] = data;
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

  // attachInterrupt(digitalPinToInterrupt(PIN_nRD), RAMRead, CHANGE);
  // attachInterrupt(digitalPinToInterrupt(PIN_nWR), RAMWrite, RISING);
  // attachInterrupt(digitalPinToInterrupt(PIN_CLK), serviceROM, FALLING);
  PORTA.PIN6CTRL = PORT_ISC_RISING_gc;

  Serial.println("\nHC4e ROM/RAM Monitor");
  Serial.print("> ");

  for (uint16_t i = 0; i < MEM_SIZE; i++) { // ROM配列の初期化
    rom8[i] = EEPROM.read(i);
  }

  // while(1) の前で初期化（重要）
  uint8_t prevnRD = digitalReadFast(PIN_nRD);
  uint8_t prevnWR = digitalReadFast(PIN_nWR);

  static uint8_t latchedAddr = 0;
  static uint8_t latchedData = 0;

  while (1) {
    // ---- RD処理（そのままでOK）
    uint8_t curnRD = digitalReadFast(PIN_nRD);
    if (curnRD != prevnRD) RAMRead();
    prevnRD = curnRD;

    // ---- WR処理（ここを強化）
    uint8_t curnWR = digitalReadFast(PIN_nWR);

    // /WRがLOWの間に常にラッチ（番地ズレ対策）
    if (curnWR == 0) {
      VPORTE.DIR &= ~0x0F;              // ★必ず入力（バス競合防止）
      latchedAddr = VPORTF.IN & 0x0F;
      latchedData = VPORTE.IN & 0x0F;
    }

    // 立ち上がりで確定して書き込み
    if (prevnWR == 0 && curnWR == 1) {
      ram4[latchedAddr] = latchedData;
    }
    prevnWR = curnWR;

    if (digitalReadFast(PIN_RST) == 0) { //リセット時にもROM読み出し
      uint8_t ad = VPORTC.IN;
      VPORTD.OUT = rom8[ad];
    }

    programUART();
    serviceRAM();
    delayMicroseconds(750);
  }
}


void loop() {

}

// クロック立ち上がり割り込み
// ROM読み込み、PORTB制御
ISR(PORTA_PORT_vect) {
  VPORTA.OUT |= PIN4_bm;
  PORTA.INTFLAGS = PIN6_bm;
  uint8_t a = VPORTC.IN;
  VPORTD.OUT = rom8[a];
  // VPORTD.OUT = EEPROM.read(a);
}
