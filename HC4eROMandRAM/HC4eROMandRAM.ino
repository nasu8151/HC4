/*
 * HC4eROMandRAM.ino ── 128 B ROM + 16×4‑bit RAM/I/O  “三役” 完全版
 *   ▼ UART コマンド
 *       02 'W' ADDR LEN DATA… 03   → EEPROM.write
 *       02 'R' ADDR 00  03        → EEPROM.read 1B 応答
 *       02 'r' ADDR 00  03        → RAM4[0‑F] 読出し (4bit)
 *   ▼ ハード配線
 *       ROM : PA→addr (未使用)  PD→data
 *       RAM : PE0‑3=data  PC2‑5=addr  PF0=nRD̅ PF1=nWR̅ PF2=AI̅ PF3=AO̅ PF4=BO̅
 */

#include <Arduino.h>
#include <EEPROM.h>
#include <avr/io.h>

#define BAUD_RATE 115200
#define MEM_SIZE  256u

/* ===== グローバル ===== */
static uint8_t ram4[16] = {0};        // 4‑bit×16 word (下位4bitのみ使用)

/* ===== ピン定義 (PortF) ===== */
#define PF_nRD 0
#define PF_nWR 1
#define PF_AI  2
#define PF_AO  3
#define PF_BO  4

/* ===== 状態列挙 (UART パーサ) ===== */
enum S:uint8_t{STX,CMD,ADDR,LEN,DATA,ETX};

/* ===== プロトタイプ ===== */
static void programUART();   // ROM W/R + RAM r
static void serviceRAM();    // 4bit RAM + I/O
static void serviceROM();    // PA→EEPROM→PD (ポート ROM)

/******************** setup ************************/
void setup(){
  Serial1.begin(BAUD_RATE);

  /* --- RAM/I/O バス設定 --- */
  PORTC.DIR &= ~(0b00111100);   // PC2‑5 A0‑A3 入力
  PORTE.DIR &= ~0x0F;           // PE0‑3 データ Hi‑Z
  PORTE.OUT &= ~0x0F;

  PORTF.DIR &= ~((1<<PF_nRD)|(1<<PF_nWR));
  PORTF.DIR |=  (1<<PF_AI)|(1<<PF_AO)|(1<<PF_BO);
  VPORTF.OUT |= (1<<PF_AI)|(1<<PF_AO)|(1<<PF_BO); // disable (負論理)

  /* --- PA/PD (ROM 出力) --- */
  PORTA.DIR = 0x00;   // PA 入力 (アドレス)
  PORTD.DIR = 0xFF;   // PD 出力 (データ)
  VPORTD.OUT = 0x00;
  Serial1.write(PORTF.DIR);
  Serial1.write(VPORTF.OUT);
}

/******************** loop *************************/
void loop(){
  programUART();   // UART 処理（ROM W/R と RAM 読み）
  serviceRAM();    // RAM / I/O バス
  serviceROM();    // EEPROM → PD 出力
}

/**************** UART プロトコル ******************/
static void programUART(){
  static S st=STX; static uint8_t cmd,addr,len,idx; static uint8_t buf[64];
  while(Serial1.available()){
    uint8_t b=Serial1.read();
    if((st==STX)&&(b=='\r'||b=='\n')) continue;   // STX待ち時のみ改行無視
    switch(st){
      case STX:  if(b==0x02) st=CMD; break;
      case CMD:  if(b=='W'||b=='R'||b=='r'){cmd=b;st=ADDR;} else st=STX; break;
      case ADDR: addr=b; st=LEN; break;
      case LEN:  len=b; idx=0; st=(cmd=='W'?(len?DATA:ETX):ETX); break;
      case DATA: buf[idx++]=b; if(idx>=len) st=ETX; break;
      case ETX:
        if(b==0x03){
          if(cmd=='W'){
            for(uint8_t i=0;i<len && addr+i<MEM_SIZE;i++)
              EEPROM.update(addr+i,buf[i]);
          }else if(cmd=='R'){
            if(addr<MEM_SIZE) Serial1.write(EEPROM.read(addr));
          }else if(cmd=='r'){
            addr &= 0x0F;
            Serial1.write(ram4[addr] & 0x0F);
          }
        }
        st=STX; break;
    }
  }
}

/**************** 4bit RAM / I/O サイクル **********/
static void serviceRAM(){
  uint8_t pf = VPORTF.IN;
  bool rd = !(pf & (1<<PF_nRD));   // Low active
  bool wr = !(pf & (1<<PF_nWR));
  if(rd && wr) return;             // 同時 Low は定義しない

  uint8_t addr = (VPORTC.IN >> 2) & 0x0F; // A0‑A3
  uint8_t data;

  /* --- 書込みサイクル --- */
  if(wr && !rd){
    data = VPORTE.IN & 0x0F;

    if(addr==0x0E){  
      VPORTF.OUT &= ~(1<<PF_AI);    // AI̅ パルス
      ram4[addr] = data;

    } else{
      VPORTF.OUT |= (1<<PF_AI);
      ram4[addr] = data;
    }
    PORTE.DIR &= ~0x0F;          // Hi‑Z 戻し
  }
  /* --- 読出しサイクル --- */
  else if(rd && !wr){
    if(addr==0x0E){
    VPORTF.OUT |= (1<<PF_AO);
    VPORTF.OUT |= (1<<PF_BO);    
    VPORTF.OUT &= ~(1<<PF_AO);
    data = ram4[addr];
    PORTE.OUT = (PORTE.OUT & ~0x0F) | data;
    PORTE.DIR |= 0x0F;          // 駆動
  }
    else if(addr==0x0F){
    VPORTF.OUT |= (1<<PF_AO);
    VPORTF.OUT |= (1<<PF_BO);
    VPORTF.OUT &= ~(1<<PF_BO);
    data = ram4[addr];
    PORTE.OUT = (PORTE.OUT & ~0x0F) | data;
    PORTE.DIR |= 0x0F;          // 駆動
  } else{
    VPORTF.OUT |= (1<<PF_AO);
    VPORTF.OUT |= (1<<PF_BO);
    data = ram4[addr];
    PORTE.OUT = (PORTE.OUT & ~0x0F) | data;
    PORTE.DIR |= 0x0F;          // 駆動
  }
  }
  /* --- アイドル --- */
  else{
    PORTE.DIR &= ~0x0F;
    VPORTF.OUT |= (1<<PF_AO)|(1<<PF_BO);
  }
}

/**************** PA→EEPROM→PD (ROM 出力) **********/
static void serviceROM(){
  static uint8_t prev=0xFF;
  uint8_t a = VPORTA.IN;
  if(a!=prev){
    VPORTD.OUT = EEPROM.read(a);
    prev = a;
  }
}
