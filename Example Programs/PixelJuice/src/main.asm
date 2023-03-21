.include "lmaos.inc"
.include "pseudoinstructions.inc"
.include "strings.inc"
.include "system.inc"

.org $0600

.feature string_escapes

FontPtr := $A0
ShellCursorPos := $A2    ; word value for current cursor position

Main:
    JMP Init
    
    .include "vdp.asm"
    .include "ascii.asm"

Init:
    JSR VDPInit
    JSR VRAMInit
@EnableDisplay:
    LDA #(CONTROL_2_VRAM_16K | CONTROL_2_DISP_EN | CONTROL_2_MODE_TEXT)
    STA VDP_BASE+REGISTERS
    VDPWait
    LDA #(REG_WR | CONTROL_2)
    STA VDP_BASE+REGISTERS
    VDPWait
    JSR VDPShell
@Done:
    RTS

VRAMInit:
@SetupVRAMAddr:
    LDA #<(PATTERN_TABLE_START)
    STA VDP_BASE+REGISTERS
    VDPWait
    LDA #>(PATTERN_TABLE_START) | VRAM_WR
    STA VDP_BASE+REGISTERS
    VDPWait
@Preamble:
    LDA #<(FontStart)
    STA FontPtr
    LDA #>(FontStart)
    STA FontPtr + 1
    LDY #0                      ; to get all 256 chars, we can copy 8 bytes 256 times
    LDX #8                      ; or copy 256 bytes 8 times :)
@WriteVRAMLoop:
    LDA (FontPtr), Y
    VDPVramPut
    INY
    BNE @WriteVRAMLoop
    DEX
    BEQ @Done
    INC FontPtr + 1
    BRA @WriteVRAMLoop
@Done:
    RTS

VDPShell:
@ShellPreamble:
    STZ ShellCursorPos
    STZ ShellCursorPos + 1
    LDA #<(NAME_TABLE_START)
    STA ShellCursorPos
    STA VDP_BASE+REGISTERS
    VDPWait
    LDA #>(NAME_TABLE_START)
    STA ShellCursorPos
    ORA #(VRAM_WR)          ; high byte already in A
    STA VDP_BASE+REGISTERS
    VDPWait
@ShellLoop:
    JSR SerialGetByte
    CMP #(ASCII_ESCAPE)
    BEQ @Done
    VDPVramPut
    BRA @ShellLoop
@Done:
    RTS
