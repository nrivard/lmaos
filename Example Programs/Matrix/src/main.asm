.include "lmaos.inc"
.include "pseudoinstructions.inc"
.include "strings.inc"
.include "system.inc"
.include "duart.inc"
.include "vdp.inc"

.org $0600

.feature string_escapes

NameTablePtr := $A0                      ; ptr to the start in NameTableCopy
FramePtr     := $A2

; VRAM locations for various tables
PatternTable        := $0000
NameTableEven       := $0800
NameTableOdd        := $0C00
SpriteAttributes    := $1000
SpritePatterns      := $2400
ColorTable          := $2000

SKIP_COUNT := 30

Main:
    JMP Init

SystemInterrupt:    .res 2
FrameCount:         .res 1              ; how many frames to skip
FrameBufferIdx:     .res 1              ; if 0, use one frame buffer. if 1, use the other in VRAM

Init:
    SEI
    LDA SKIP_COUNT
    STA FrameCount
    LDA #1
    STA FrameBufferIdx                  ; we want to populate the odd framebuffer first. we pre-populate even buffer
    LDA #<(RegisterTable)
    LDX #>(RegisterTable)
    JSR VDPInit
    JSR VDPClearVRAM
    JSR NameTableInit
    JSR ColorTableInit
    JSR VDPCopyDefaultCharset
    COPYADDR NameTableCopyStart, NameTablePtr    ; set the pointer to the name table
@SetupIRQ:
    DUART_IRQ_DISABLE                           ; turn off timer interrupts, we are going to use VDP frames instead
    COPY16 InterruptVector, SystemInterrupt     ; preserve old value of the interrupt vector
    COPYADDR FrameInterrupt, InterruptVector
@EnableDisplay:
    BIT VDP_BASE+REGISTERS                      ; clear INT line
    VDPRegisterSet CONTROL_2, (CONTROL_2_VRAM_16K | CONTROL_2_DISP_EN | CONTROL_2_INT_EN | CONTROL_2_MODE_GFX_1)
    CLI
@StartGame:
    JSR GameLoop
@RestoreIRQ:
    SEI
    BIT VDP_BASE+REGISTERS                      ; clear INT line
    VDPRegisterSet CONTROL_1, (CONTROL_1_MODE_TEXT)
    VDPRegisterSet CONTROL_2, (CONTROL_2_VRAM_16K | CONTROL_2_MODE_TEXT)    ; turn off INTs and display
    COPY16 SystemInterrupt, InterruptVector
    DUART_IRQ_ENABLE
    CLI
@Done:
    RTS

NameTableInit:
@SetupVRAMAddr:
    COPYADDR NameTableCopyStart, NameTablePtr
    VDPVramAddrSet NameTableEven, 1
    LDX #4
@CopyNames:
    LDY #0
@Loop:
    TYA
    VDPVramPut
    STA (NameTablePtr), Y
    INY
    BNE @Loop
    INC NameTablePtr + 1                    ; inc high byte of our pointer
    DEX
    BNE @CopyNames
@Done:
    RTS

ColorTableInit:
    VDPVramAddrSet ColorTable, 1
@CopyColors:
    LDX #24
@Loop:
    LDA ColorTableStart + 0
    VDPVramPut
    LDA ColorTableStart + 1
    VDPVramPut
    LDA ColorTableStart + 2
    VDPVramPut
    LDA ColorTableStart + 3
    VDPVramPut
    DEX
    BNE @Loop
@Done:
    RTS

GameLoop:
    SEI
    DUART_BYTE_AVAIL
    BCS @Physics
    JSR SerialGetByte
    CMP #(ASCII_ESCAPE)
    BEQ @Done
@Physics:
    BIT FrameBufferIdx
    BNE @SetOddFrameBuffer
    VDPVramAddrSet NameTableEven, 1
    BRA @FillFrameBuffer
@SetOddFrameBuffer:
    VDPVramAddrSet NameTableOdd, 1
@FillFrameBuffer:
    COPY16 NameTablePtr, FramePtr
    LDY #0
    LDX #3
@CopyNameTableLoop:
    LDA (FramePtr), Y
    STA VDP_BASE+VRAM
    JSR VDPWaitLong
    INY
    BNE @CopyNameTableLoop
    INC FramePtr + 1
    DEX
    BNE @CopyNameTableLoop
@NextFrame:
    CLI
    WAI
    BRA GameLoop
@Done:
    RTS

FrameInterrupt:
    PHA
    PHY
    PHX
    BIT VDP_BASE+REGISTERS      ; clear IRQ request
    DEC FrameCount
    BNE @Done
    LDA SKIP_COUNT
    STA FrameCount
@AdvanceNameTablePtr:
    CLC
    LDA NameTablePtr
    ADC #$20
    STA NameTablePtr            ; we don't care if it wraps around!
@SwapNameTable:
    BIT FrameBufferIdx
    BNE @SwapToOdd
    VDPRegisterSet (NameTableEven / NAME_TABLE_MULT), NAME_TABLE
    LDA #1
    STA FrameBufferIdx
    BRA @Done
@SwapToOdd:
    VDPRegisterSet (NameTableOdd / NAME_TABLE_MULT), NAME_TABLE
    STZ FrameBufferIdx
@Done:
    PLX
    PLY
    PLA
    RTI

RegisterTable:
    .byte (CONTROL_1_MODE_GFX_1)
    .byte (CONTROL_2_VRAM_16K | CONTROL_2_MODE_GFX_1)
    .byte (NameTableEven / NAME_TABLE_MULT)
    .byte (ColorTable / COLOR_TABLE_MULT)
    .byte (PatternTable / PATTERN_TABLE_MULT)
    .byte (SpriteAttributes / SPR_ATTR_TABLE_MULT)
    .byte (SpritePatterns / SPR_PATTERN_TABLE_MULT)
    .byte (COLOR_CLR << 4 | COLOR_RED_DK)

ColorTableStart:
    .byte (COLOR_WHITE << 4 | COLOR_BLK)
    .byte (COLOR_GRN_LT << 4 | COLOR_GRN_DK)
    .byte (COLOR_RED_DK << 4 | COLOR_BLU_DK)
    .byte (COLOR_YEL_DK << 4 | COLOR_CLR)
ColorTableEnd:

; we have the name table to copy here
NameTableCopyStart: .res $400
NameTableCopyEnd:
