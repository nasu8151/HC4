# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

HC4 is a homebrew educational CPU family built from 74-series logic ICs, with KiCad hardware, Verilog models, an AVR-based ROM/RAM emulator, and user manuals. Most prose, comments and commit messages are in Japanese. The models:

| Model | Stack | PC | Data bus | Address bus | Notes |
|---|---|---|---|---|---|
| HC4 | 3 levels (A/B/C) | 12 bit | 4 bit | 8 bit | Base model. Variants: `HC4_KiCad/` (original), `HC4_KiCad_XR/` (current work, branch `hc4xr`) |
| HC4<sub>E</sub> | 2 levels (A/B) | 8 bit | 4 bit | 4 bit | Lightweight "education" model, `HC4_KiCad_EE/` |
| HC8 | 3 levels | impl.-dependent | 8 bit | 8 bit | Extended ISA (LS, JL, LP); Verilog only |

## Architecture essentials (spans many files)

- **Harvard, stack-based.** Instructions are 8 bits: upper nibble = opcode, lower nibble = register number `r0`–`r15` / immediate. Loads (`LD`, `LI`) push: A ← new, B ← old A, C ← old B. ALU ops take A and B and write the result to memory/register.
- **Opcode map** (HC4): `0000 SC [AB]`, `0001 SC r`, `0010 SU`, `0011 AD`, `0100 XR`, `0101 OR`, `0110 AN`, `0111 SA`, `1000 LD [AB]`, `1001 LD r`, `101x LI #i`, `110x` reserved, `111x JP [ABC]` (low 3 bits select JP/NP/JC/JNC/JZ/JNZ). The opcode → control-signal truth table (what the KiCad instruction decoder implements) is [extra/instruction.md](extra/instruction.md) (and `extra/instruction_HC4e.md`).
- **Jumps** go to `{C,B,A}` (HC4), so the target must be pushed with `LI` beforehand. `[AB]` indirect addressing uses B as the high nibble.
- **Memory map:** RAM 0x00–0x0F is the register area `r0`–`r15` (single-instruction access); 0xF0–0xFF is I/O in the reference design (memory-mapped I/O). HC4<sub>E</sub> uses r14/r15 as I/O.
- **Flags:** C is updated only by `SU`/`AD`; Z by any store-type (opcode `0xxx`) instruction.
- Hardware revisions have known errata (e.g. HC4 Rev2 `SU`/`XR` broken, fixed in Rev3) — see "既知のエラッタ" in [UsersManual_Software_JP.md](UsersManual_Software_JP.md) before assuming a hardware bug is a design-spec behavior.

Keep the Verilog models, the KiCad instruction decoder, `extra/instruction*.md`, and the manuals consistent when changing ISA behavior.

## Verilog simulation (Icarus Verilog)

Each CPU lives in `verilog/<model>/`; run from inside that directory because ROMs are loaded via relative `$readmemh` paths (HC4: `./jmptest.hex`, HC8: `./test.hex`).

```sh
cd verilog/HC4
iverilog -o hc4_tb.out -s hc4_tb -g 2005-sv ./hc4_onefile.v ./hc4_tb.v
vvp ./hc4_tb.out          # prints writes to I/O 0xF2/0xF3, dumps hc4_tb.vcd
gtkwave ./hc4_tb.vcd
```

- Each model has two implementations: a modular `hc4.v` (``` `include "alu.v" ```) and a self-contained `hc4_onefile.v`. They have **different port names**: `hc4.v` uses `nReset`/`nRAM_RD`/`nRAM_WR`, `hc4_onefile.v` uses `rst_n`/`rd_n`/`wr_n`. The current `hc4_tb.v` only compiles against `hc4_onefile.v` (the command in `verilog/verilog.md` using `hc4.v` fails).
- `verilog/HC4e/hc4e_tb.v` currently fails to elaborate against `hc4e.v` (no `clk` port) — it is out of sync.
- Unit testbenches (`alu_tb.v`, `ram_tb.v`, `rom_tb.v`, `address_mux_tb.v`, HC8 `bus_ctrl_tb.v`) run the same way with `-s <tb module name>` and the module under test. Testbenches `` `include "ram.v" ``, so don't also pass `ram.v` on the command line.
- Naming rules (`Verilog.md`): active-low signals start with `n` (newer code also uses `_n` suffix); identifiers start lowercase.
- `*.out` and `*.vcd` are gitignored.

## Programs and assembler

- Sample programs (`.asm` / `.hex`) are in `extra/`. Assemble with the external assembler [hcxasm](https://github.com/nasu8151/hcxasm); `hc4_asm/` (Rust) is **deprecated**.
- Assembly syntax: `;` comments, `r0`–`r15`, immediates as `#0000`–`#1111`, `[AB]` / `[ABC]` indirect.

## HC4eROMandRAM (PlatformIO firmware)

AVR (ATmega4809 / AVR16EA48 / ATmega1609, Arduino framework) firmware that emulates ROM and RAM for HC4<sub>E</sub>. Source in `HC4eROMandRAM/src/` (`main.cpp`, `hex.cpp` Intel-HEX loading, `disasm.cpp` disassembler). Build/upload with PlatformIO, choosing an env from `platformio.ini`, e.g. `pio run -e ATmega4809_upload_serialupdi -t upload`. The AVR16EA48 env uses a forked platform (`nasu8151/platform-atmelmegaavr`).

## Hardware (KiCad)

- Schematics are hierarchical: top `HC4_KiCad.kicad_sch` with sheets `alu`, `stackunit`, `programcounter`, `instructiondecode`, `addressbus`, `databus`, `clockandreset`. Project-local symbol libs `74xx_2.kicad_sym`, `Device2.kicad_sym`, footprints in `Library.pretty/`.
- `HC4_KiCad_tb.*` is a SPICE testbench project; LTspice models are in `sim/` (requires downloading `74hc.lib`/`74hc_full.lib` from ltwiki first).
- `production/` and `*_gbr/` zips are fabrication outputs (JLCPCB fabrication-toolkit); `temp-freerouting.dsn` is a Freerouting intermediate. Don't hand-edit `.kicad_pcb`/`.kicad_sch` S-expressions when a KiCad tool/MCP operation can do it.
- `.history/` directories are editor local-history noise, not project files.

## Documentation

- `README.md` (EN), `UsersManual_Hardware.md` (JP), `UsersManual_Software.md` (EN), `UsersManual_Software_JP.md` (JP, most up to date — ISA reference, tutorial, errata). The Japanese manuals are authoritative; English versions lag.
- Build the JP software manual PDF from the repo root (needs pandoc 3.x + TeX Live LuaLaTeX with LuaTeX-ja/bxjscls and Yu fonts):
  ```sh
  pandoc UsersManual_Software_JP.md -d docs/pandoc/pdf.yaml -o UsersManual_Software_JP.pdf
  ```
  `docs/pandoc/fixups.lua` converts raw HTML `<br>`/`<sub>` in the Markdown for LaTeX, so those tags are fine to use in the manual.
