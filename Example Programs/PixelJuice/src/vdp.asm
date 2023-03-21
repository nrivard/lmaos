; LmaOS
;
; Copyright Nate Rivard 2022

.ifndef VDP_ASM
VDP_ASM = 1

.include "vdp.inc"

.export VDPInit, VDPWaitLong

NAME_TABLE_START := $0800
PATTERN_TABLE_START := $0000

.code

VDPInit:
    BIT VDP_BASE+REGISTERS          ; reset status register in case memory check touched it
    JSR VDPWaitLong
    LDX #$00
@RegisterLoop:
    LDA VDPDefaultRegisters, X
    STA VDP_BASE+REGISTERS
    JSR VDPWaitLong
    TXA
    ORA #(REG_WR)
    STA VDP_BASE+REGISTERS
    JSR VDPWaitLong
    INX
    CPX #(VDPDefaultRegistersEnd - VDPDefaultRegisters)
    BNE @RegisterLoop
@Done:
    RTS

; during active display, you must wait 8µs
; JSR takes 6 cycles (1.5µs) and RTS takes 6 cycles (1.5µs)
; NOTE: this is a subroutine! not a macro like `VDPWait`. it uses the cycle counts of jumping + returning
VDPWaitLong:
    VDPWait
    VDPWait
    NOP
    NOP
@Done:
    RTS

; X: should contain number of bytes to send. use `0` to send a full page
VDPPutN:
    RTS

; default register values
VDPDefaultRegisters:
    .byte (CONTROL_1_MODE_TEXT)                         ; control reg 1
    .byte (CONTROL_2_VRAM_16K | CONTROL_2_MODE_TEXT)    ; control reg 2
    .byte (NAME_TABLE_START / NAME_TABLE_MULT)          ; nametable addr at $0800 (2 * $400)
    .byte ($00)                                         ; color table not used
    .byte (PATTERN_TABLE_START / PATTERN_TABLE_MULT)    ; pattern table at $0000 (0 * $800)
    .byte ($20)                                         ; sprites not used (but manual has this value...)
    .byte ($00)                                         ; sprites not used
    .byte (COLOR_GRN_LT << 4 | COLOR_BLK)                  ; lt green text on a black background. classic!
VDPDefaultRegistersEnd:

.endif
