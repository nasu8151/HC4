#include "disasm.h"

static char buf[8];

const char *disasm(uint8_t instruction) {
  const char *mnemonics[] = {
    "SM", "SC", "SU", "AD", 
    "XR", "AN", "OR", "SA",
    "LM", "LD", "LI", "??",
    "??", "??", "JP", "??"
  };
  const char *flags[] = {"", "", "C", "NC"};
  uint8_t opcode = instruction >> 4;
  uint8_t operand = instruction & 0x0F;
  if (instruction == 0xE1) {
    strncpy(buf, "NP", sizeof(buf));
  } else if (opcode == 0xE) {
    snprintf(buf, sizeof(buf), "%s %s", mnemonics[opcode], flags[operand]);
  } else if (opcode == 0xA) {
    snprintf(buf, sizeof(buf), "%s #%d", mnemonics[opcode], operand);
  } else if (opcode == 0x0 || opcode == 0x8) {
    strncpy(buf, mnemonics[opcode], sizeof(buf));
  } else if (opcode < 0xB) {
    snprintf(buf, sizeof(buf), "%s R%d", mnemonics[opcode], operand);
  } else {
    snprintf(buf, sizeof(buf), "%s %d", mnemonics[opcode], operand);
  }
  return buf;
}