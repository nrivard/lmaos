.include "lmaos.inc"
.include "pseudoinstructions.inc"
.include "strings.inc"
.include "system.inc"
.include "duart.inc"
.include "vdp.inc"

.org $0600

.feature string_escapes

; constants
FRAMES_PER_GEN  := 20   ; comparator for number of frames per generation

; zero page locations
Gens        := $A0  ; 16 bit counter for the calculated generation

; Board and Frame buffer state
; For the GameLoop, `BoardCurr` signifies the _currently displayed_ board. which means
; that calculations, copies, etc. should happen on the _opposite_ board/framebuffer!
; For the FrameInterrupt, it will treat this value as the one to set the nametable to!
BoardCurr   := $A2  ; 0 if BoardA, non-zero if BoardB
FrameCount  := $A3  ; current frame count
CalcNextGen := $A4  ; non-zero if the next generation calc is in progress, 0 if complete

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
FrameBufB           := $3400

; Offsets for cardinal directions in our 34 * 24 board from top left corner
CELL_OFFSET := -35
NW  := 0    ; nw corner
N   := 1    ; n cell
NE  := 2    ; ne corner
E   := 36   ; e cell
SE  := 70   ; se corner
S   := 69   ; s cell
SW  := 68   ; sw corner
W   := 34   ; w cell
C   := 35   ; center, the cell itself

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
    LDA #<(RegisterTable)
    LDX #>(RegisterTable)
    JSR VDPInit
    JSR VDPClearVRAM
    JSR VDPCopyDefaultCharset                   ; use default charset and overwrite $0 and $1 patterns
    VDPInitTable PatternTable, PatternsStart, PatternsEnd
    VDPInitTable FrameBufA, NamesStart, NamesEnd
    VDPInitTable FrameBufB, NamesStart, NamesEnd
    VDPInitTable ColorTable, ColorsStart, ColorsEnd
    VDPInitTable SpriteAttributes, SpriteAttrs, SpriteAttrsEnd  ; turn sprites off
    JSR GameInit
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
    JSR CalculateGeneration
@NextGen:
    INC16 Gens
    JSR CopyBoardToFrameBuffer
    JSR CopyGenTextToFrameBuffer
    STZ CalcNextGen
@WaitLoop:
    WAI
    LDA CalcNextGen
    BEQ @WaitLoop
    BRA GameLoop
@Done:
    CLI
    RTS

CalculateGeneration:
    LDA BoardCurr
    BEQ @BoardB
@BoardA:
    COPYADDR (BoardB+35+CELL_OFFSET), r0    ; source
    COPYADDR (BoardA+35+CELL_OFFSET), r1    ; destination
    BRA @Calc
@BoardB:    
    COPYADDR (BoardA+35+CELL_OFFSET), r0    ; source
    COPYADDR (BoardB+35+CELL_OFFSET), r1    ; destination
@Calc:
    LDX #22
@CalcLoopStart:
    LDY #0
@CalcLoop:
    PHY                         ; cache current Y index as we need Y indexing
    PHX                         ; cache current X index as we need
    CLC
    LDA #0                      ; num of alive neighbors
    LDY #NW                     ; not strictly needed, we can drop indexing for first corner
    ADC (r0), Y
    LDY #N
    ADC (r0), Y
    LDY #NE
    ADC (r0), Y
    LDY #E
    ADC (r0), Y
    LDY #SE
    ADC (r0), Y
    LDY #S
    ADC (r0), Y
    LDY #SW
    ADC (r0), Y
    LDY #W
    ADC (r0), Y
    TAX                         ; store neighbors in X
    LDY #C
    LDA (r0), Y
    BEQ @Dead
@Alive:
    CPX #2                      ; alive neighbors < 2?
    BCC @Died
    CPX #4                      ; alive neighbors >= 4?
    BCS @Died
    BRA @Unchanged
@Died:
    LDA #0
    STA (r1), Y                 ; died of loneliness or overcrowding :(
    BRA @Next
@Dead:
    CPX #3                      ; if dead and exactly 3 neighbors, we're born
    BNE @Unchanged
    LDA #1
    STA (r1), Y                 ; born in new board
    BRA @Next
@Unchanged:
    STA (r1), Y                 ; store current state into new board
@Next:
    INC16 r0
    INC16 r1
    PLX
    PLY
    INY
    CPY #32
    BNE @CalcLoop
    ADD16 r0, 2                 ; add 2 to get base ptr for next row
    ADD16 r1, 2
    DEX
    BNE @CalcLoopStart
@Done:
    RTS

CopyBoardToFrameBuffer:
    LDA BoardCurr
    BEQ @FrameBfrB
    VDPVramAddrSet FrameBufA+32, 1
    COPYADDR (BoardA+35), r0    ; skip entire top row (34) + 1st cell (border)
    BRA @CopyFB
@FrameBfrB:
    VDPVramAddrSet FrameBufB+32, 1
    COPYADDR (BoardB+35), r0    ; skip entire top row (34) + 1st cell (border)
    JSR VDPWaitLong
@CopyFB:
    LDX #22                     ; 22 rows of data
@CopyFBLoopStart:
    LDY #0
@CopyFBLoop:
    LDA (r0), Y
    STA VDP_BASE+VRAM
    JSR VDPWaitLong
    INY
    CPY #32                     ; end of data on this row?
    BNE @CopyFBLoop
    ADD16 r0, 34                ; add full row to our pointer
    DEX
    BNE @CopyFBLoopStart
@Done:
    RTS

CopyGenTextToFrameBuffer:
    LDA BoardCurr
    BEQ @FrameBfrB
    VDPVramAddrSet FrameBufA + (23 * 32), 1 ; col 0 of the 23rd row
    BRA @CopyHiByte
@FrameBfrB:
    VDPVramAddrSet FrameBufB + (23 * 32), 1 ; col 0 of the 23rd row
@CopyHiByte:
    LDA Gens + 1
    JSR ByteToHexString
    LDA r7
    STA VDP_BASE+VRAM
    JSR VDPWaitLong
    LDA r7 + 1
    STA VDP_BASE+VRAM
    JSR VDPWaitLong     ; almost definitely unnecessary
@CopyLoByte:
    LDA Gens
    JSR ByteToHexString
    LDA r7
    STA VDP_BASE+VRAM
    JSR VDPWaitLong
    LDA r7 + 1
    STA VDP_BASE+VRAM
    JSR VDPWaitLong     ; almost definitely unnecessary
    RTS

FrameInterrupt:
    PHA
    ; PHX
    ; PHY
    BIT VDP_BASE+REGISTERS      ; clear IRQ request
@CheckFrame:
    DEC FrameCount
    BNE @Done
    LDA #FRAMES_PER_GEN
    STA FrameCount
@NextGen:
    LDA BoardCurr
    BEQ @BoardB
    VDPRegisterSet 2, (FrameBufA / NAME_TABLE_MULT)
    BRA @TriggerCalc
@BoardB:
    VDPRegisterSet 2, (FrameBufB / NAME_TABLE_MULT)
@TriggerCalc:
    LDA BoardCurr
    EOR #$FF
    STA BoardCurr
    LDA #1
    STA CalcNextGen
@Done:
    ; PLY
    ; PLX
    PLA
    RTI

; Zeroes out game board memory (dead) and then copies initial state to both game boards
GameInit:
    COPYADDR 0, Gens
    LDA #1
    STA CalcNextGen             ; calculation is in progress to start. we copy 0th state, that's gen 0
    STZ BoardCurr               ; BoardA
@ClearBoards:
    COPYADDR BoardA, r0
    COPYADDR BoardB, r1
    LDY #4
@ClearBoardLoopStart:
    LDX #0                      ; 34 * 24 = 816 which is 4 * 204
@ClearBoardLoop:
    LDA #0
    STA (r0)
    STA (r1)
    INC16 r0
    INC16 r1
    INX
    CPX #204
    BNE @ClearBoardLoop
    DEY
    BNE @ClearBoardLoopStart
@CopyState:
    COPYADDR (NamesStart+32), r0  ; 2nd row of names table is initial state
    COPYADDR (BoardA+35), r1      ; skip entire top row (34) + 1st cell (border)
    COPYADDR (BoardB+35), r2
    LDX #22                     ; 22 rows of data
@CopyStateLoopStart:
    LDY #0                     
@CopyStateLoop:
    LDA (r0), Y
    STA (r1), Y
    STA (r2), Y
    INY
    CPY #32
    BNE @CopyStateLoop
    ADD16 r0, 32
    ADD16 r1, 34
    ADD16 r2, 34
    DEX
    BNE @CopyStateLoopStart
    ; TODO: need to copy generations text!
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
