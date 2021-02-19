; LmaOS
;
; Copyright Nate Rivard 2020

;;; Monitor Addresses
.ifndef MONITAUR_INC
MONITAUR_INC = 1

.bss

; the current command buffer. terminated by carriage return
MonitorCommandBuffer: .res $80 

.macro DUMP addr, length
.local @Loop
.local @Send
.local @SendASCII
    PHA
    PHY
	LDY #$00
@Loop:
	LDA addr, Y
@SendASCII:
    JSR ByteToHexString
    LDA r7
    JSR ACIASendByte
    LDA r7 + 1
    JSR ACIASendByte
    LDA #' '
    JSR ACIASendByte
	INY
	CPY #(length)
	BNE @Loop
@Send:
	LDA #(ASCII_CARRIAGE_RETURN)
	JSR ACIASendByte
    PLY
    PLA
.endmacro

.endif
