.include "lmaos.inc"
.include "lcd1602.inc"
.include "strings.inc"

.org $0400

.feature string_escapes

UpArrow := $00
DownArrow := $01
LeftArrow := $7F
RightArrow := $7E

Main:
@Preamble:
    LDA #(LCD_INSTR_CLEAR)
    JSR LCDSendInstruction
@SendStatus:
    LDA #<LoadingTextures
    STA r0
    LDA #>LoadingTextures
    STA r0 + 1
    JSR ACIASendString
@PrintCheatCode:
    JSR LoadTextures
    JSR PrintKonamiCode
@Done:
    RTS

LoadTextures:
@SetCGRAMAddr:
    LDA #(LCD_INSTR_CGRAM_ADDR)             ; set CGRAM addr to 0
    JSR LCDSendInstruction
@SendTextures:
    LDA #<CustomCharacters
    LDX #>CustomCharacters
    LDY #(CustomCharactersEnd - CustomCharacters)
    JSR LCDSendBlock
@Done:
    RTS

PrintKonamiCode:
@SetDDRAMAddr:
    LDA #(LCD_INSTR_HOME)
    JSR LCDSendInstruction
@SendCode:
    LDA #<KonamiCode
    LDX #>KonamiCode
    LDY #(KonamiCodeEnd - KonamiCode)
    JSR LCDSendBlock
@Done:
    RTS

LoadingTextures: .asciiz "Loading textures...\r"

; custom characters written into CGRAM on the LCD module.
; each custom character is 8 bytes long (but only bottom 5 bits are used per byte)
CustomCharacters:
.byte $00, $04, $0E, $15, $04, $04, $00, $00    ; up arrow glyph; \0
.byte $00, $04, $04, $15, $0E, $04, $00, $00    ; down arrow glyph; \1
CustomCharactersEnd:

KonamiCode: .byte UpArrow, UpArrow, DownArrow, DownArrow, LeftArrow, RightArrow, LeftArrow, RightArrow, 'B', 'A', " Start"
KonamiCodeEnd:
