/*
 * HC4eROMandRAM.ino ── 128 B ROM (EEPROM) + 16×4‑bit RAM/I/O “三役” 完全版
 *   2025‑07‑18   Intel‑HEX 行毎即書込み版 + 小文字 l,r コマンド
 *   2025‑07‑18b  CR を無視し LF で行確定（空行 ERR 解消）
 *
 * ─── 概要 ──────────────────────────────────
 *  UART コマンド (115200‑8N1)
 *    L / l  : Intel‑HEX ローダ  (1 行ずつ即 EEPROM 書込み)
 *    R / r  : 4‑bit RAM ダンプ   (16 word, comma separated)
 *
 *  内蔵 EEPROM 0‑255 を ROM 領域として読み出し、
 *  外付け 4‑bit RAM を PC2‑5, PE0‑3, PF0‑1 で制御。
 *────────────────────────────────────────────*/

#include <Arduino.h>
#include <EEPROM.h>
#include <avr/io.h>

/************* 定数 ******************************/
#define BAUD_RATE 115200
#define MEM_SIZE  256u      /* 内蔵 EEPROM = 256 バイト */

/************* Port/F ビット定義 ******************/
#define PF_nRD 4
#define PF_nWR 5
#define PA_AI  2
#define PA_AO  3
#define PA_BO  4

/************* 4‑bit RAM/I‑O *********************/
static uint8_t ram4[16] = {0};   /* 4‑bit ×16 word */

/************* HEX 変換ユーティリティ *************/
static int hex1(char c){
  if(c>='0'&&c<='9') return c-'0';
  if(c>='A'&&c<='F') return c-'A'+10;
  if(c>='a'&&c<='f') return c-'a'+10;
  return -1;
}
static int hex2(const char* p){
  int h=hex1(p[0]), l=hex1(p[1]);
  return (h<0||l<0)?-1: (h<<4)|l;
}
static int hex4(const char* p){
  int hi=hex2(p), lo=hex2(p+2);
  return (hi<0||lo<0)?-1: (hi<<8)|lo;
}
static int readDataBytes(int len,const char* p,uint8_t* dst){
  for(int i=0;i<len;i++){
    int v=hex2(p+i*2);
    if(v<0) return -1;
    dst[i]=(uint8_t)v;
  }
  return 0;
}
static void putHex(uint8_t b){
  static const char tbl[]="0123456789ABCDEF";
  Serial.write(tbl[b>>4]); Serial.write(tbl[b&0x0F]);
}

/************* Intel‑HEX ローダ *******************/
static void intelhexLoad(){
  char line[96];
  uint32_t baseHigh = 0;   /* type‑04 上位アドレス */
  uint16_t written  = 0;

  while(true){
    /* ---------- 1 行受信 : CR 無視, LF で確定 ---------- */
    uint8_t idx=0;
    while(true){
      while(!Serial.available()){}
      char c = Serial.read();
      if(c=='\r') continue;       /* CR 無視 */
      if(c=='\n') break;          /* LF で行確定 */
      if(idx < sizeof(line)-1) line[idx++] = c;
    }
    line[idx] = '\0';

    if(idx==0){ Serial.println(F("[ERR] empty")); return; }

    /* EOF */
    if(strcmp(line,":00000001FF")==0){
      Serial.print(F("[OK] ")); Serial.println(written);
      return;
    }

    /* 基本フォーマット */
    if(line[0] != ':'){ Serial.println(F("[ERR] fmt")); return; }
    int len   = hex2(&line[1]);
    int addr  = hex4(&line[3]);
    int rtype = hex2(&line[7]);
    if(len<0||addr<0||rtype<0){ Serial.println(F("[ERR] fmt")); return; }

    /* 拡張線形アドレス */
    if(rtype==0x04 && len==2){
      baseHigh = (uint32_t)hex2(&line[9])<<8 | hex2(&line[11]);
      continue;
    }
    /* データレコード以外はスキップ */
    if(rtype!=0x00) continue;

    uint32_t fullAddr = (baseHigh<<16) | (uint16_t)addr;
    if(fullAddr + len > MEM_SIZE){ Serial.println(F("[ERR] range")); return; }

    uint8_t buf[64];
    if(readDataBytes(len,&line[9],buf)!=0){ Serial.println(F("[ERR] data")); return; }
    for(int i=0;i<len;i++) EEPROM.write(fullAddr+i, buf[i]);
    written += len;
  }
}

/************* 4‑bit RAM ダンプ *******************/
static void ramDump(){
  for(uint8_t i=0;i<16;i++){
    putHex(ram4[i] & 0x0F);
    if(i==15) Serial.println(); else Serial.write(',');
  }
}

/************* UART コマンド受付 ******************/
static void programUART(){
  static char buf[8];
  static uint8_t idx=0;

  while(Serial.available()){
    char c = Serial.read();
    if(c=='\r') continue;          /* CR 無視 */
    if(c=='\n'){
      if(idx==0){ continue; }      /* 連続改行は無視 */
      buf[idx]='\0';
      char cmd = buf[0];
      if(cmd=='L'||cmd=='l') intelhexLoad();
      else if(cmd=='R'||cmd=='r') ramDump();
      idx=0;                       /* バッファクリア */
    }else if(idx<sizeof(buf)-1){
      buf[idx++] = c;
    }
  }
}

/************* serviceROM *************************/

/**************** PA→EEPROM→PD (ROM 出力) **********/
static void serviceROM(){
  static uint8_t prev=0xFF;
  uint8_t a = VPORTC.IN & 0x3F;
  if(a!=prev){
    VPORTD.OUT = EEPROM.read(a);
    prev = a;
  }
}

static void checkEneble(){
  uint8_t pf = VPORTF.IN;
  bool rd = !(pf & (1<<PF_nRD));   // Low active
  bool wr = !(pf & (1<<PF_nWR));
  if(rd && wr) return;             // 同時 Low は定義しない
  uint8_t addr = VPORTF.IN & 0x0F; // A0‑A3
  uint8_t data;
  
  if(wr && !rd){
    if(addr==0x0E){  
      VPORTA.OUT &= ~(1<<PA_AI);    // AI̅ パルス
    }
    return;
    }
  else if(rd && !wr){
    if(addr==0x0E){    
    VPORTA.OUT &= ~(1<<PA_AO);
    PORTE.DIR |= 0x0F;
    data = ram4[addr];
    PORTE.OUT = (PORTE.OUT & ~0x0F) | data;
    return;
    }
    else if(addr==0x0F){
    VPORTA.OUT &= ~(1<<PA_BO);
    PORTE.DIR |= 0x0F;
    data = ram4[addr];
    PORTE.OUT = (PORTE.OUT & ~0x0F) | data;
    return;
  }else{
    PORTE.DIR |= 0x0F;
    data = ram4[addr];
    PORTE.OUT = (PORTE.OUT & ~0x0F) | data;
  }
  }else{
      VPORTA.OUT |= (1<<PA_AI);
      VPORTA.OUT |= (1<<PA_AO);
      VPORTA.OUT |= (1<<PA_BO);
      PORTE.DIR &= ~0x0F;          // 駆動 
  }
}

static void RAMRead(){
  VPORTA.OUT |= (1<<PA_AI);
}

static void RAMWrite(){
  uint8_t addr = VPORTF.IN & 0x0F; // A0‑A3
  uint8_t data;
  VPORTA.OUT |= (1<<PA_AO);
  VPORTA.OUT |= (1<<PA_BO);
  data = VPORTE.IN & 0x0F;
  ram4[addr] = data;
}
/************* Arduino 標準関数 *******************/
void setup(){
  Serial.begin(BAUD_RATE);

  /* --- RAM/I/O バス設定 --- */
  PORTF.DIR &= ~0x0F;
  PORTF.DIR &= ~((1<<PF_nRD)|(1<<PF_nWR));
  PORTE.DIR &= ~0x0F;           // PE0‑3 データ Hi‑Z
  PORTE.OUT &= ~0x0F;

  PORTF.DIR &= ~((1<<PF_nRD)|(1<<PF_nWR));
  PORTA.DIR |=  (1<<PA_AI)|(1<<PA_AO)|(1<<PA_BO);
  VPORTA.OUT |= (1<<PA_AI)|(1<<PA_AO)|(1<<PA_BO); // disable (負論理)

  /* --- PA/PD (ROM 出力) --- */
  PORTC.DIR = 0x00;   // PC 入力 (アドレス)
  PORTD.DIR = 0xFF;   // PD 出力 (データ)
  VPORTD.OUT = 0x00;

  attachInterrupt(digitalPinToInterrupt(30),RAMRead,RISING);
  attachInterrupt(digitalPinToInterrupt(31),RAMWrite,RISING);
}

void loop(){
  programUART();   /* UART コマンド受付 */
  checkEneble();
  serviceROM();    /* ROM 読出し */
}