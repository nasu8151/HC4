#ifndef __HEX_H__
#define __HEX_H__

#include <Arduino.h>
#include <EEPROM.h>

#define IHEX_LINE_MAX 600
#define MEM_SIZE 256u /* 内蔵 EEPROM = 256 バイト */

extern volatile uint8_t rom8[MEM_SIZE];

static int hex1(char c);
static int hex2(const char* p);
static int hex4(const char* p);
static int readDataBytes(int len, const char* p, uint8_t* dst);

void intelhexLoad(char *args);

#endif /* __HEX_H__ */