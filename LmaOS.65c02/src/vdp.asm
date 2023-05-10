; LmaOS
;
; Copyright Nate Rivard 2022

.ifndef VDP_ASM
VDP_ASM = 1

.include "vdp.inc"

.export VDPInit, VDPClearVRAM, VDPWaitLong, VDPCopyDefaultCharset, VDPDefaultRegisters, VDPVramPutN

.code

; initialize VDP according to pointer in A/X
; register table should be 8 bytes long, starting with CONTROL_1 and ending with TEXT_COLOR
; A: low byte of register pointer
; X: high byte of register pointer
VDPInit:
    STA r0                          ; setup table pointer
    STX r0 + 1
    BIT VDP_BASE+REGISTERS          ; reset status register in case memory check touched it
    LDY #$00
@RegisterLoop:
    LDA (r0), Y
    STA VDP_BASE+REGISTERS
    TYA
    ORA #(REG_WR)
    STA VDP_BASE+REGISTERS
    INY
    CPY #(8)
    BNE @RegisterLoop
@Done:
    RTS

; zeroes out all of vram
VDPClearVRAM:
    VDPVramAddrSet 0, 1
    LDX #$40                    ; write 40 pages of data ($40 * $100 = 16k)
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

VDPCopyDefaultCharset:
    VDPVramAddrSet VDP_PATTERN_TABLE_START, 1
    COPYADDR CharsetStart, r0
    COPYADDR (CharsetEnd - CharsetStart), r1
    JSR VDPVramPutN
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

; r0: pointer to start of data. subroutine will fetch data from the ptr, send to VDP, increment until
; number of bytes to send is reached
; r1: 16-bit count of number of bytes to transfer
;
; NOTE: this uses the normal VDPVramPut macro, it does _not_ use VDPWaitLong so is only appropriate to use
; when VDP output is disabled _or_ during blanking periods 
VDPVramPutN:
@Preamble:
    PHA
@Loop:
    LDA (r0)
    VDPVramPut
    INC16 r0
    DEC16 r1
    BNE @Loop
    LDA r1 + 1		; DEC16 only returns flags on lower-byte, so test high-byte
    BNE @Loop
@Done:
    PLA
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

.include "charset.asm"

.endif
