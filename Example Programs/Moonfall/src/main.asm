.include "lmaos.inc"
.include "pseudoinstructions.inc"
.include "strings.inc"
.include "system.inc"
.include "duart.inc"
.include "vdp.inc"

.org $0600

.feature string_escapes

; .struct Asteroid
;     color
; .endstruct

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
TwinkleState:    .res 1
    
    .include "bitmaps.asm"

Init:
    STZ FrameDelay
    STZ TwinkleState
    SEI
    LDA #<(RegisterTable)
    LDX #>(RegisterTable)
    JSR VDPInit
    JSR VDPClearVRAM
    JSR PatternTableInit
    JSR NameTableInit
    JSR ColorTableInit
    ; JSR SpritePatternInit
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
    BEQ @Done
@Sleep:
    WAI
    BRA GameLoop
@Done:
    RTS

PatternTableInit:
@SetupVRAMAddr:
    VDPVramAddrSet PatternTable, 1
@CopyPatterns:
    COPYADDR patterns_start, r0
    COPYADDR (patterns_end - patterns_start), r1
    JSR VDPVramPutN
@Done:
    RTS

NameTableInit:
@SetupVRAMAddr:
    VDPVramAddrSet NameTable, 1
@CopyNames:
    COPYADDR map_start, r0
    COPYADDR (map_end - map_start), r1
    JSR VDPVramPutN
@Done:
    RTS

ColorTableInit:
    VDPVramAddrSet ColorTable, 1
@CopyColors:
    COPYADDR colors_start, r0
    COPYADDR (colors_end - colors_start), r1
    JSR VDPVramPutN
@Done:
    RTS

; SpritePatternInit:
;     COPYADDR SpritePatternsStart, VramPtr
;     VDPVramAddrSet SpritePatterns, 1
;     ; LDX #(SpritePatternsEnd - SpritePatternsStart) / 8  ; this is how many sprite patterns we have
; @SpriteLoop:
;     LDY #0
; @WriteVRAMLoop:
;     LDA (VramPtr), Y
;     VDPVramPut
;     INY
;     CPY #24
;     BNE @WriteVRAMLoop
;     ; DEX
;     ; BNE @SpriteLoop
; @Xwing:
;     JSR CopySpriteTable
; @Done:
;     RTS

FrameInterrupt:
    PHA
    BIT VDP_BASE+REGISTERS      ; clear IRQ request
;     BPL @MovePlayer             ; not the VDP (though this shouldn't happen!)
    INC FrameDelay
    LDA FrameDelay
    CMP #60                     ; change each sec
    BNE @Done
    STZ FrameDelay
@Twinkle:
    VDPVramAddrSet NameTable + $10A, 1 ; dealer's choice of star to twinkle
    LDA TwinkleState
    BEQ @TwinkleBig
    DEC TwinkleState
    LDA #(twinkl_1)
    BRA @SetTwinkle
@TwinkleBig:
    INC TwinkleState
    LDA #(twinkl_0)
@SetTwinkle:
    VDPVramPut
;     LDA PatternZero
;     CLC
;     ADC #2                      ; advance the pattern twice, so we always have a matching pair
;     STA PatternZero             ; store it back because it's the start of our current pair
;     VDPVramPut
;     INC A
;     VDPVramPut
; @MovePlayer:
;     JSR CopySpriteTable
;     STZ PlayerMoveDir           ; reset player movement
@Done:
    PLA
    RTI

CopySpriteTable:
    PHA
    PHY
    VDPVramAddrSet SpriteAttributes, 1
    COPYADDR SpriteTable, VramPtr
    LDY #0
@SpriteVramLoop:
    LDA (VramPtr), Y
    VDPVramPut
    INY
    CPY #(SpriteTableEnd - SpriteTable)
    BNE @SpriteVramLoop
@Done:
    PLY
    PLA
    RTS


RegisterTable:
    .byte (CONTROL_1_MODE_GFX_1)
    .byte (CONTROL_2_VRAM_16K | CONTROL_2_MODE_GFX_1)
    .byte (NameTable / NAME_TABLE_MULT)
    .byte (ColorTable / COLOR_TABLE_MULT)
    .byte (PatternTable / PATTERN_TABLE_MULT)
    .byte (SpriteAttributes / SPR_ATTR_TABLE_MULT)
    .byte (SpritePatterns / SPR_PATTERN_TABLE_MULT)
    .byte (COLOR_CLR << 4 | COLOR_BLK)

SpriteTable:
PlayerLeft:                     ; treat as a SpriteAttr struct
    .byte $B0, $80, $00, COLOR_RED_MED
PlayerRight:
    .byte $B0, $88, $01, COLOR_RED_MED
Bullet:
    .byte $00, $00, $00, COLOR_CLR
SpriteTableEnd: