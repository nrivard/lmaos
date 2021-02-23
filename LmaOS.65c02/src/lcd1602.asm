; LmaOS
;
; Copyright Nate Rivard 2021

.ifndef LCD1602_ASM
LCD1602_ASM = 1

.include "lcd1602.inc"

.export LCDInit, LCDMoveCursor, LCDPrintByte, LCDPrintString, LCDSendInstruction, LCDPollBusy

LCDInit:
@Preamble:
    PHA
@SetupLCD:
    LDA #(LCD_INSTR_FUNCTION | LCD_FUNCTION_DATA_LENGTH_8 | LCD_FUNCTION_LINES_2)
    JSR LCDSendInstruction
    LDA #(LCD_INSTR_DISPLAY | LCD_DISPLAY_ON | LCD_CURSOR_ON)       ; display on, cursor on, blinking off
    JSR LCDSendInstruction
    LDA #(LCD_INSTR_ENTRY_MODE | LCD_CURSOR_INCREMENT_MASK)         ; addr increment, no shift
    JSR LCDSendInstruction
    LDA #(LCD_INSTR_CLEAR)
    JSR LCDSendInstruction
@Done:
    PLA
    RTS

LCDClear:
    LDA #(LCD_INSTR_CLEAR)
    JSR LCDSendInstruction
    PLA
    RTS

; A: character position to move the cursor to
; See provided character positions for start of lines 1 and 2
LCDMoveCursor:
@Preamble:
    PHA
@MoveCursor:
    ORA #(LCD_INSTR_DDRAM_ADDR)
    JSR LCDSendInstruction
@Done:
    PLA
    RTS

; A: low byte of string address
; X: high byte of string address
LCDPrintString:
@Preamble:
    PHY
    STA r0
    STX r0 + 1
    LDY #0
@PrintLoop:
    LDA (r0), Y
    BEQ @Done
    JSR LCDPrintByte
    INY
    BRA @PrintLoop
@Done:
    PLY
    RTS

; A: the byte to print
LCDPrintByte:
    JSR LCDPollBusy
    STA LCDDataRegister
    RTS

LCDPollBusy:
    BIT LCDInstructionRegister
    BMI LCDPollBusy
    RTS

; A: instruction to send
LCDSendInstruction:
    JSR LCDPollBusy
    STA LCDInstructionRegister
    RTS

.endif
