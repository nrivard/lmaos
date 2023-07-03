.include "lmaos.inc"
.include "pseudoinstructions.inc"
.include "strings.inc"
.include "system.inc"
.include "duart.inc"
.include "vdp.inc"

.export SpriteTable

.org $0600

.feature string_escapes

; metadata for asteroids
; ex:
; instantiation:    { velocityX: $FF, velocityY: $02, frameCounter: $02FF, destination: $B1 }
; frame1:           { velocityX: $FF, velocityY: $02, frameCounter: $0100, destination: $B1 } X is now zero, so move -1 pixels along x axis. reset X framecounter
; frame2:           { velocityX: $FF, velocityY: $02, frameCounter: $0000, destination: $B1 } X and Y are now zero. move -1 x, +1 along Y
; frame3:           { velocityX: $FF, velocityY: $02, frameCounter: $0100, destination: $B1 } same as frame 1. if destination reached, blow this puppy up :)
.struct Asteroid
    velocityX       .byte       ; NOT USED YET
    velocityY       .byte       ; signed y direction frame counter (can't be negative or our asteroids would "fall" up)
    frameCounter    .byte       ; MSB [X X X X Y Y Y Y] LSB. 4 bit frame counters for each axis
    destination     .byte       ; scanline index destination for detonation
.endstruct

VramPtr := $A0

; VRAM locations for various tables
SpritePatterns      := $0000
PatternTable        := $0800
NameTable           := $1400
SpriteAttributes    := $1000
ColorTable          := $2000

Main:
    JMP Init

SystemInterrupt:    .res 2
RandomNumSeed:      .res 1
SpawnTimer:         .res 1
ActiveAsteroids:    .res 1      ; bitfield of indexes for active asteroids
    
    .include "bitmaps.asm"

Init:
    SEI
    LDA SystemClockJiffies
    STA RandomNumSeed
    LDA #<(RegisterTable)
    LDX #>(RegisterTable)
    JSR VDPInit
    JSR VDPClearVRAM
    JSR PatternTableInit
    JSR NameTableInit
    JSR ColorTableInit
    JSR SpritePatternInit
@SetupIRQ:
    DUART_IRQ_DISABLE                           ; turn off timer interrupts, we are going to use VDP frames instead
    COPY16 InterruptVector, SystemInterrupt     ; preserve old value of the interrupt vector
    COPYADDR FrameInterrupt, InterruptVector
@EnableDisplay:
    BIT VDP_BASE+REGISTERS                      ; clear INT line
    VDPRegisterSet CONTROL_2, (CONTROL_2_VRAM_16K | CONTROL_2_DISP_EN | CONTROL_2_INT_EN | CONTROL_2_MODE_GFX_1)
    CLI
@TEST:
    LDA #$80
    JSR SerialSendByte
    STA SpriteTable+SpriteAttr::yPos
    LDA #$80
    STA SpriteTable+SpriteAttr::xPos
    LDA #$00
    STA SpriteTable+SpriteAttr::patternIndex
    LDA #(COLOR_BLU_DK)
    STA SpriteTable+SpriteAttr::color
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

SpritePatternInit:
    VDPVramAddrSet SpritePatterns, 1
@CopySprites:
    COPYADDR sprites_start, r0
    COPYADDR (sprites_end - sprites_start), r1
    JSR VDPVramPutN
@Done:
    RTS

; returns psuedo-random number back in A
;
; NOTE: taken from https://codebase64.org/doku.php?id=base:small_fast_8-bit_prng
AdvanceRandom:
	LDA RandomNumSeed
	INC RandomNumSeed
; A: seed from which to generate a random number (ex: jiffy clock or frame count)
Random:
    CMP #0          ; not sure when A was loaded so we have to reset Z flag to be safe
    BEQ @PerformEOR
    ASL
    BEQ @Done
    BCC @Done
@PerformEOR:
    EOR #$1D
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
	LDX #0
@UpdateAsteroidsLoop:
	JSR UpdateAsteroid
    JSR CullAsteroidIfNecessary
	INX
	CPX #8
	BNE @UpdateAsteroidsLoop
@CheckSpawnTimer:
	DEC SpawnTimer
	BNE @NextFrame
@SpawnAsteroid:
	JSR AdvanceRandom
	STA SpawnTimer
	JSR SpawnAsteroid
@NextFrame:
    CLI
    WAI
    BRA GameLoop
@Done:
    RTS

SpawnAsteroid:
    PHA
    PHX
    PHY
@FindNextAvail:
    LDY #0
@FindNextAvailLoop:
	LDA SpriteTable+SpriteAttr::color, Y
	BEQ @RandomNumber
	INY					; advance by size of the struct
	INY
	INY
	INY
	CPY #(8 * .sizeof(SpriteAttr))
	BEQ @Done
	BRA @FindNextAvailLoop
@RandomNumber:
    JSR AdvanceRandom
@CalcStartPos:
    STA SpriteTable+SpriteAttr::xPos, Y
	LDA #0
	STA SpriteTable+SpriteAttr::yPos, Y
	LDA #(COLOR_BLU_DK)
	STA SpriteTable+SpriteAttr::color, Y
@CalcVelocityY:
    JSR AdvanceRandom
    AND #$03
    INC A
    STA AsteroidTable+Asteroid::velocityY, Y
@StoreVelocityY:
	STA AsteroidTable+Asteroid::frameCounter, Y ; store high byte
@CalcDestination:
	JSR AdvanceRandom
	AND #$07			; generate vertical tile number from $10…$16
    CMP #$07
    BNE @FinalizeDestination
    DEC A
@FinalizeDestination:
	ORA #$10
	STA AsteroidTable+Asteroid::destination, Y
@Done:
    PLY
    PLX
    PLA
    RTS
    
; X: Index of the asteroid to update
UpdateAsteroid:
	PHA
	PHY
	PHX
@ShiftY:
	TXA					; have to shift Y by size of `Asteroid` struct
	ASL
	ASL
	TAX
@UpdateYFrameCounter:
	LDA AsteroidTable+Asteroid::frameCounter, X
	AND #$0F
	DEC A
	BNE @StoreYFrameCounter
	INC SpriteTable+SpriteAttr::yPos, X			; increment Y pos
	LDA AsteroidTable+Asteroid::velocityY, X	; reset frame counter
@StoreYFrameCounter:
	STA AsteroidTable+Asteroid::frameCounter, X
@Done:
	PLX
	PLY
	PLA
	RTS

; X: Index of the asteroid to cull (if necessary)
CullAsteroidIfNecessary:
	PHA
	PHX
	PHY
@ShiftX:
	TXA
	ASL
	ASL
	TAX
@CalculateTile:
	LDA SpriteTable+SpriteAttr::yPos, X
	LSR					; divide by 8 to get the vertical tile number
	LSR
	LSR
	CMP AsteroidTable+Asteroid::destination, X
	BNE @Done
@AddCrater:
	STA r0
	STZ r0 + 1
	ASL16 r0			; multiply by 32 to get tile index
	ASL16 r0
	ASL16 r0
	ASL16 r0
	ASL16 r0
	LDA SpriteTable+SpriteAttr::xPos, X
	LSR					; again divide by 8 to get horizontal tile number
	LSR
	LSR
	STA r1
@SetVram:
	ADD16 r0, NameTable
    ADC16 r0, r1, r0
    LDA r0
    STA VDP_BASE+REGISTERS
    LDA r0 + 1
    ORA #(VRAM_WR)
    STA VDP_BASE+REGISTERS
    JSR VDPWaitLong     ; we are not in blanking so we have to wait awhile...
    LDA #(crtr_lft)
    VDPVramPut
    JSR VDPWaitLong
    LDA #(crtr_rgt)
    VDPVramPut
@DeleteAsteroid:
	LDA #0
	STA SpriteTable+SpriteAttr::color, X
@Done:
	PLY
	PLX
	PLA
	RTS

FrameInterrupt:
    PHA
    BIT VDP_BASE+REGISTERS      ; clear IRQ request
    INC RandomNumSeed
@CopySpriteTable:
    VDPVramAddrSet SpriteAttributes, 1
    COPYADDR SpriteTable, r0
    COPYADDR (SpriteTableEnd - SpriteTable), r1
    JSR VDPVramPutN
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

SpriteTable: ; treat as an array of SpriteAttr structs
    ; .byte $80, $80, $00, COLOR_YEL_DK
    .res (32 * .sizeof(SpriteAttr))
SpriteTableEnd:

AsteroidTable:
    .res (8 * .sizeof(Asteroid))
AsteroidTableEnd:
