; LmaOS
;
; Copyright Nate Rivard 2022

.ifndef VDP_ASM
VDP_ASM = 1

.include "vdp.inc"

.export VDPInit, VDPClearVRAM, VDPWaitLong

VDP_NAME_TABLE_START := $0800
VDP_PATTERN_TABLE_START := $0000

.code

; initialize VDP according to pointer in A/X
; register table should be 8 bytes long, starting with CONTROL_1 and ending with TEXT_COLOR
; A: low byte of register pointer
; X: high byte of register pointer
VDPInit:
    STA r0                          ; setup table pointer
    STX r0 + 1
    BIT VDP_BASE+REGISTERS          ; reset status register in case memory check touched it
    JSR VDPWaitLong
    LDY #$00
@RegisterLoop:
    LDA (r0), Y
    STA VDP_BASE+REGISTERS
    JSR VDPWaitLong
    TYA
    ORA #(REG_WR)
    STA VDP_BASE+REGISTERS
    JSR VDPWaitLong
    INY
    CPY #(8)
    BNE @RegisterLoop
@Done:
    RTS

; zeroes out all of vram
VDPClearVRAM:
    LDA #0
    STA VDP_BASE+REGISTERS
    VDPWait
    LDA #(VRAM_WR)
    STA VDP_BASE+REGISTERS
    VDPWait
    LDX #$40                    ; write 40 pages of data
    LDY #0
@WriteByte:
    STZ VDP_BASE+VRAM
    VDPWait
    INY
    BNE @WriteByte
    DEX
    BNE @WriteByte
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
    .byte (VDP_NAME_TABLE_START / NAME_TABLE_MULT)      ; nametable addr at $0800 (2 * $400)
    .byte ($00)                                         ; color table not used
    .byte (VDP_PATTERN_TABLE_START / PATTERN_TABLE_MULT) ; pattern table at $0000 (0 * $800)
    .byte ($20)                                         ; sprites not used (but manual has this value...)
    .byte ($00)                                         ; sprites not used
    .byte (COLOR_GRN_LT << 4 | COLOR_BLK)               ; lt green text on a black background. classic!
VDPDefaultRegistersEnd:

.endif
