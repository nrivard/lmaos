.include "lmaos.inc"
.include "pseudoinstructions.inc"
.include "strings.inc"
.include "system.inc"
.include "duart.inc"
.include "vdp.inc"

.org $0600

.feature string_escapes

; constants
FRAMES_PER_GEN  := 60   ; comparator for number of frames per generation

; zero page locations
GenCalc     := $A0  ; 16 bit counter for the calculated generation
GenRndr     := $A2  ; 16 bit counter for the rendered generation

; Board and Frame buffer state
; For the GameLoop, `BoardCurr` signifies the _currently displayed_ board. which means
; that calculations, copies, etc. should happen on the _opposite_ board/framebuffer!
; For the FrameInterrupt, it will treat this value as the one to set the nametable to!
BoardCurr   := $A4  ; 0 if BoardA, non-zero if BoardB
FrameCount  := $A6  ; current frame count

GenASCII_Hi := $C0  ; 4 byte ASCII representation for current generation count
GenASCII_Lo := $C2

; RAM locations for our 2 boards which are both 32 * 22 boards
; with an extra 1 cell "dead" border all around (34 * 24)
; each cell is a byte with current nonzero being alive, zero being dead
BoardA      := $8000
BoardB      := $9000

; VRAM locations for various tables
PatternTable        := VDP_PATTERN_TABLE_START
SpriteAttributes    := $0800
ColorTable          := $1400
SpritePatterns      := $2000
FrameBufA           := $3000
FrameBufB           := $3500

; sets VRAM address and then copies all bytes from start to end to vram
.macro VDPInitTable vramAddr, ramStart, ramEnd
    VDPVramAddrSet  vramAddr, 1
    COPYADDR    ramStart, r0
    COPYADDR    (ramEnd - ramStart), r1
    JSR VDPVramPutN
.endmacro

Main:
    JMP Init

SystemInterrupt: .res 2

    .include "bitmaps.asm"

Init:
    SEI
    COPYADDR $0000, $A0
    COPYADDR $0000, $A2
    LDA #<(RegisterTable)
    LDX #>(RegisterTable)
    JSR VDPInit
    JSR VDPClearVRAM
    JSR VDPCopyDefaultCharset                   ; use default charset and overwrite $0 and $1 patterns
    VDPInitTable PatternTable, PatternsStart, PatternsEnd
    VDPInitTable FrameBufA, NamesStart, NamesEnd
    VDPInitTable ColorTable, ColorsStart, ColorsEnd
    JSR GameInit
    JSR CopyGenTextToVram
@SetupIRQ:
    DUART_IRQ_DISABLE                           ; turn off timer interrupts, we are going to use VDP frames instead
    COPY16 InterruptVector, SystemInterrupt     ; preserve old value of the interrupt vector
    COPYADDR FrameInterrupt, InterruptVector
    LDA #FRAMES_PER_GEN                         ; setup our frame counter
    STA FrameCount
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
    SEI
    DUART_BYTE_AVAIL
    BCS @AdvanceGame
    JSR SerialGetByte
    CMP #(ASCII_ESCAPE)
    BEQ @Done
@AdvanceGame:
    CLI
    WAI
    DEC FrameCount
    BNE GameLoop
    LDA #FRAMES_PER_GEN
    STA FrameCount
@NextGen:
    SEI
    INC16 GenCalc
    CLI
    BRA GameLoop
@Done:
    CLI
    RTS

CopyBoardToFrameBuffer:
    LDA BoardCurr
    BEQ @FrameBfrB
    VDPVramAddrSet FrameBufA, 1
    COPYADDR (BoardA+35), r0    ; skip entire top row (34) + 1st cell (border)
    BRA @CopyFB
@FrameBfrB:
    VDPVramAddrSet FrameBufB, 1
    COPYADDR (BoardB+35), r0    ; skip entire top row (34) + 1st cell (border)
@CopyFB:
    JSR VDPWaitLong     ; do we need this?
    LDX #22                     ; 22 rows of data
    LDY #0
@CopyFBLoop:
    LDA (r0), Y
    STA VDP_BASE+VRAM
    INY
    CPY #32
    BNE @CopyFBLoop
    ADD16 r0, 32
    DEX
    BNE @CopyFBLoop
@Done:
    RTS

CopyGenTextToVram:
    LDA BoardCurr
    BEQ @FrameBfrB
    VDPVramAddrSet FrameBufA + (31 * 23), 1
    BRA @CopyHiByte
@FrameBfrB:
    VDPVramAddrSet FrameBufB + (31 * 23), 1
@CopyHiByte:
    LDA GenRndr + 1
    JSR ByteToHexString
    LDA r7
    STA VDP_BASE+VRAM
    JSR VDPWaitLong
    LDA r7 + 1
    STA VDP_BASE+VRAM
    JSR VDPWaitLong
@CopyLoByte:
    LDA GenRndr
    JSR ByteToHexString
    LDA r7
    STA VDP_BASE+VRAM
    JSR VDPWaitLong
    LDA r7 + 1
    STA VDP_BASE+VRAM
    JSR VDPWaitLong
    RTS

FrameInterrupt:
    PHA
    PHX
    PHY
    BIT VDP_BASE+REGISTERS      ; clear IRQ request
    CMP16 GenRndr, GenCalc
    BNE @NextGen
    JMP @Done
@NextGen:
    COPY16 GenCalc, GenRndr
    LDA BoardCurr
    BNE @BoardB
    VDPRegisterSet 2, (FrameBufA / NAME_TABLE_MULT)
    BRA @Done
@BoardB:
    VDPRegisterSet 2, (FrameBufB / NAME_TABLE_MULT)
;     VDPVramAddrSet (FrameBufA+32), 1
;     LDA BoardCurr
;     BNE @BoardB
;     COPYADDR (BoardA+35), r0
;     BRA @BoardSet
; @BoardB:
;     COPYADDR (BoardB+35), r0
; @BoardSet:
;     COPYADDR 32, r1
;     LDX #22         ; 22 rows of board data
; @NextGenLoop:
;     JSR VDPVramPutN
;     ADD16 r0, 2    ; next row, skipping dead border
;     COPYADDR 32, r1
;     DEX
;     BNE @NextGenLoop
; @GenerationsText:
;     JSR CalcGenerationsText
;     VDPVramAddrSet (FrameBufA+(32 * 23)), 1
;     VDPWait
;     LDA GenASCII_Hi + 0
;     VDPVramPut
;     LDA GenASCII_Hi + 1
;     VDPVramPut
;     LDA GenASCII_Hi + 2
;     VDPVramPut
;     LDA GenASCII_Hi + 3
;     VDPVramPut
@Done:
    PLY
    PLX
    PLA
    RTI

; Zeroes out game board memory (dead) and then copies initial state to game board A
GameInit:
    COPYADDR 0, GenRndr
    COPYADDR 0, GenCalc
    STZ BoardCurr               ; BoardA
@BoardA:
    COPYADDR BoardA, r0
    LDY #4
    LDX #0                      ; 34 * 24 = 816 which is 4 * 204
@BoardALoop:
    LDA #0
    STA (r0)
    INC16 r0
    INX
    CPX #204
    BNE @BoardALoop
    DEY
    BNE @BoardALoop
@BoardB:
    COPYADDR BoardB, r0
    LDY #4
    LDX #0
@BoardBLoop:
    LDA #0
    STA (r0)
    INC16 r0
    INX
    CPX #204
    BNE @BoardBLoop
    DEY
    BNE @BoardBLoop
@CopyState:
    COPYADDR (NamesStart+32), r0  ; 2nd row of names table is initial state
    COPYADDR (BoardA+35), r1      ; skip entire top row (34) + 1st cell (border)
    LDX #22                     ; 22 rows of data
    LDY #0                     
@CopyStateLoop:
    LDA (r0), Y
    STA (r1), Y
    INY
    CPY #32
    BNE @CopyStateLoop
    ADD16 r0, 32
    ADD16 r1, 34
    DEX
    BNE @CopyStateLoop
@Done:
    RTS

RegisterTable:
    .byte (CONTROL_1_MODE_GFX_1)
    .byte (CONTROL_2_VRAM_16K | CONTROL_2_MODE_GFX_1)
    .byte (FrameBufA / NAME_TABLE_MULT)
    .byte (ColorTable / COLOR_TABLE_MULT)
    .byte (PatternTable / PATTERN_TABLE_MULT)
    .byte (SpriteAttributes / SPR_ATTR_TABLE_MULT)
    .byte (SpritePatterns / SPR_PATTERN_TABLE_MULT)
    .byte (COLOR_CLR << 4 | COLOR_BLK)
