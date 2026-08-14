.include "lmaos.inc"
.include "pseudoinstructions.inc"
.include "strings.inc"
.include "system.inc"
.include "duart.inc"
.include "vdp.inc"

.feature string_escapes

StatusRegister :=  $A2

; VRAM locations for various tables
PatternTable        := $0000
NameTableEven       := $0800
NameTableOdd        := $0C00
SpriteAttributes    := $1000
SpritePatterns      := $2400
ColorTable          := $2000

SKIP_COUNT := 30

.code

Main:
    JMP Init

SystemInterrupt:    .res 2
FrameCount:         .res 1              ; how many frames to skip
FrameBufferIdx:     .res 1              ; if 0, use one frame buffer. if 1, use the other in VRAM

Init:
    SEI
    STZ StatusRegister
    LDA #<(RegisterTable)
    LDX #>(RegisterTable)
    JSR VDPInit
    JSR VDPClearVRAM
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
    VDPRegisterSet CONTROL_1, (CONTROL_1_MODE_GFX_1)
    VDPRegisterSet CONTROL_2, (CONTROL_2_VRAM_16K | CONTROL_1_MODE_GFX_1)    ; turn off INTs and display
    COPY16 SystemInterrupt, InterruptVector
    DUART_IRQ_ENABLE
    CLI
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
    LDA StatusRegister
    JSR SerialSendByteAsString
@NextFrame:
    CLI
    WAI
    BRA GameLoop
@Done:
    RTS

FrameInterrupt:
    PHA
    LDA VDP_BASE+REGISTERS      ; save status register
    STA StatusRegister
@Done:
    PLA
    RTI

RegisterTable:
    .byte (CONTROL_1_MODE_GFX_1)
    .byte (CONTROL_2_VRAM_16K | CONTROL_1_MODE_GFX_1)
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

.segment "BUFFERS"

; we have the name table to copy here
NameTableCopyStart: .res $400
NameTableCopyEnd:
