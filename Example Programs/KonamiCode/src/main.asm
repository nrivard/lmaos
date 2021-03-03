.include "lmaos.inc"
.include "lcd1602.inc"
.include "pseudoinstructions.inc"
.include "strings.inc"
.include "system.inc"
.include "via.inc"

.org $0400

.feature string_escapes

FloorChar := $00
CeilingChar := $01
HeadChar := $02
BodyChar := $03

Main:
@SetupLCD:
    LDA #(LCD_INSTR_DISPLAY | LCD_DISPLAY_ON)   ; display on; cursor off; blink off;
    JSR LCDSendInstruction
    JSR LoadTextures
    LDA #(LCD_INSTR_CLEAR)                      ; clear screen; set DRRAM addr to 0
    JSR LCDSendInstruction
@GameLoop:
    WAI
@CheckFrameDraw:
    JSR UpdateButtonState                       ; button press in any part of the game should count
    SEI
    LDA SystemClockJiffies
    CLI
    AND #$1F
    BNE @NextFrame
    JSR UpdateGameState
    JSR DrawFrame
@ResetButtonState:
    LDA #$FF
    STA ControllerButtonState
@NextFrame:
    BRA @GameLoop
@Done:
    RTS

LoadTextures:
@SetCGRAMAddr:
    LDA #(LCD_INSTR_CGRAM_ADDR)                 ; set CGRAM addr to 0
    JSR LCDSendInstruction
@SendTextures:
    LDA #<CustomCharacters
    LDX #>CustomCharacters
    LDY #(CustomCharactersEnd - CustomCharacters)
    JSR LCDSendBlock
    RTS

UpdateButtonState:
@Preamble:
    PHA
@DebounceButtons:
    LDA VIA1_PORT_A
    CMP #$FF
    BEQ @Done                                   ; if any button was pressed store it (last button wins)
    STA ControllerButtonState
@Done:
    PLA
    RTS

UpdateGameState:
    PHA
    LDA ControllerButtonState
@CheckLeft:
    LSR
    BCS @CheckRight
    DEC GameState
    BPL @CheckRight
    LDA #$0F                                  ; if negative, wrap to other end of the screen
    STA GameState
@CheckRight:
    LSR
    LSR
    BCS @Done
    INC GameState
    LDA #$0F
    CMP GameState
    BCS @Done
    STZ GameState                            ; if >= $10, wrap to left side of screen
@Done:
    PLA
    RTS

;;; draws the frame
;;; TODO: can turn this into a single loop with different default and player chars
DrawFrame:
@Preamble:
    PHA
    PHX
@SendLine1:
    LDA #(LCD_INSTR_DDRAM_ADDR | LCD_LINE1_START)
    JSR LCDSendInstruction
    LDX #0
@Line1Loop:
    LDA #(CeilingChar)
    CPX GameState
    BNE @SendLine1Char
    LDA #(HeadChar)
@SendLine1Char:
    JSR LCDSendByte
    INX
    CPX #$10
    BNE @Line1Loop
@SendLine2:
    LDA #(LCD_INSTR_DDRAM_ADDR | LCD_LINE2_START)
    JSR LCDSendInstruction
    LDX #0
@Line2Loop:
    LDA #(FloorChar)
    CPX GameState
    BNE @SendLine2Char
    LDA #(BodyChar)
@SendLine2Char:
    JSR LCDSendByte
    INX
    CPX #$10
    BNE @Line2Loop
@Done:
    PLX
    PLA
    RTS

; custom characters written into CGRAM on the LCD module.
; each custom character is 8 bytes long (but only bottom 5 bits are used per byte)
CustomCharacters:
.byte $00, $00, $00, $00, $00, $00, $00, $1F    ; floor; \0
.byte $1F, $00, $00, $00, $00, $00, $00, $00    ; ceiling \1
.byte $1F, $00, $00, $00, $0E, $19, $1F, $0E    ; head \2
.byte $0E, $0E, $0E, $0E, $0A, $0A, $0F, $1F    ; body \3
CustomCharactersEnd:

GameState: .byte $00                            ; game state. represents the index of the player
ControllerButtonState: .res 1                   ; last seen button presses. useful for debouncing
