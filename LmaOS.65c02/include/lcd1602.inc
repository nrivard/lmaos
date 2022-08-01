; LmaOS
;
; Copyright Nate Rivard 2021

.ifndef LCD1602_INC
LCD1602_INC = 1

; no actual hardware!
DISPLAY_BASE := N8BUS_PORT1

LCDInstructionRegister := DISPLAY_BASE + 0
LCDDataRegister := DISPLAY_BASE + 1

; instructions
LCD_INSTR_CLEAR = $01
LCD_INSTR_HOME = $02
LCD_INSTR_ENTRY_MODE = $04
LCD_INSTR_DISPLAY = $08
LCD_INSTR_SHIFT = $10
LCD_INSTR_FUNCTION = $20
LCD_INSTR_CGRAM_ADDR = $40
LCD_INSTR_DDRAM_ADDR = $80

LCD_STATUS_MASK_BUSY = $80
LCD_STATUS_MASK_ADDR = $7F

; for use with the ENTRY_MODE instruction
LCD_CURSOR_INCREMENT_MASK = $02             ; a 1 auto-increments (and shifts cursor the right), a 0 auto-decrements (and shifts cursor to the left)
LCD_DISPLAY_SHIFT_MASK = $01                ; a 1 shifts display left, a 0 right

; for use with the DISPLAY instruction
LCD_DISPLAY_ON = $04
LCD_CURSOR_ON = $02
LCD_CURSOR_BLINK = $01

; for use with the SHIFT instruction
LCD_SHIFT_MASK = $0C
LCD_SHIFT_CURSOR_LEFT = $00
LCD_SHIFT_CURSOR_RIGHT = $04
LCD_SHIFT_DISPLAY_LEFT = $08
LCD_SHIFT_DISPLAY_RIGHT = $0C

; for use with the FUNCTION instruction
LCD_FUNCTION_MASK = $1C
LCD_FUNCTION_DATA_LENGTH_8 = $10            ; 0 is data length of 4
LCD_FUNCTION_LINES_2 = $08                  ; 0 is 1 line mode
LCD_FUNCTION_FONT_HEIGHT_11 = $04           ; 0 is dot height of 8 (required for 2 line mode)

LCD_CGRAM_ADDR_MASK = $3F
LCD_DDRAM_ADDR_MASK = $7F

LCD_LINE1_START := $00                      ; ddram address of start of line 1
LCD_LINE2_START := $28                      ; ddram address of start of line 2

.endif
