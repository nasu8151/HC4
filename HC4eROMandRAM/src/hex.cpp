#include "hex.h"

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

