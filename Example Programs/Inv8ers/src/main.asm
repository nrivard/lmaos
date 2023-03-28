.include "lmaos.inc"
.include "pseudoinstructions.inc"
.include "strings.inc"
.include "system.inc"
.include "duart.inc"

.org $0600

.feature string_escapes

VramPtr := $A0

; VRAM locations for various tables
SpritePatterns      := $0000
PatternTable        := $0800
NameTable           := $1400
SpriteAttributes    := $1000
ColorTable          := $2000

Main:
    JMP Init

SystemInterrupt: .res 2
FrameDelay:      .res 1
PatternZero:     .res 1
    
    .include "vdp.asm"
    .include "bitmaps.asm"

Init:
    STZ FrameDelay
    STZ PatternZero
    SEI
    LDA #<(RegisterTable)
    LDX #>(RegisterTable)
    JSR VDPInit
    JSR VDPClearVRAM
    JSR PatternTableInit
    JSR NameTableInit
    JSR ColorTableInit
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

GameLoop:
    JSR SerialGetByte
    CMP #(ASCII_ESCAPE)
    BNE GameLoop
    RTS

PatternTableInit:
@SetupVRAMAddr:
    VDPVramAddrSet PatternTable, 1
@Preamble:
    LDA #<(PatternsStart)
    STA VramPtr
    LDA #>(PatternsStart)
    STA VramPtr + 1
    LDX #32                      ; or copy 256 bytes 8 times :)
@PatternLoop:
    LDY #0                      ; to get all 256 chars, we can copy 8 bytes 256 times
@WriteVRAMLoop:
    LDA (VramPtr), Y
    VDPVramPut
    INY
    CPY #64
    BNE @WriteVRAMLoop
    DEX
    BEQ @Done
    BRA @PatternLoop
    ; INC VramPtr + 1
    ; BRA @WriteVRAMLoop
@Done:
    RTS

NameTableInit:
@SetupVRAMAddr:
    VDPVramAddrSet NameTable, 1
@WritePatterns:
    LDX #3
@WriteVRAMLoop:
    LDY #$00                    ; 32 * 24 tiles so loop $C0 4 times
@InnerLoop:
    TYA
    VDPVramPut
    INY
    BNE @InnerLoop
    DEX
    BNE @WriteVRAMLoop
@Done:
    RTS

ColorTableInit:
    COPYADDR Colors, VramPtr
    VDPVramAddrSet ColorTable, 1
    LDX #3                     ; there are 32 color table entries, 1 for each set of 8 patterns
@ColorsLoop:
    LDY #0                      ; so loop through all 14 colors 3 times (will overflow color table but that space is unused)
@WriteVRAMLoop:
    LDA (VramPtr), Y
    VDPVramPut
    INY
    CPY #(ColorsEnd - Colors)
    BNE @WriteVRAMLoop
    DEX
    BNE @ColorsLoop
@Done:
    RTS

FrameInterrupt:
    PHA
    BIT VDP_BASE+REGISTERS      ; clear IRQ request
    BPL @Done                   ; not the VDP (though this shouldn't happen!)
    INC FrameDelay
    LDA FrameDelay
    CMP #60                     ; change each sec
    BNE @Done
    STZ FrameDelay
@ChangePattern:
    VDPVramAddrSet NameTable, 1 ; we'll change the first pattern
    LDA PatternZero
    CLC
    ADC #2                      ; advance the pattern twice, so we always have a matching pair
    STA PatternZero             ; store it back because it's the start of our current pair
    VDPVramPut
    INC A
    VDPVramPut
@Done:
    PLA
    RTI

RegisterTable:
    .byte (CONTROL_1_MODE_GFX_1)
    .byte (CONTROL_2_VRAM_16K | CONTROL_2_MODE_GFX_1)
    .byte (NameTable / NAME_TABLE_MULT)
    .byte (ColorTable / COLOR_TABLE_MULT)
    .byte (PatternTable / PATTERN_TABLE_MULT)
    .byte (SpriteAttributes / SPR_ATTR_TABLE_MULT)
    .byte (SpritePatterns / SPR_PATTERN_TABLE_MULT)
    .byte (COLOR_CLR << 4 | COLOR_BLK)

Colors:
    .byte $21, $41, $61, $71, $A1, $C1, $D1, $E1, $31, $51, $F1, $91, $B1, $81
ColorsEnd: