; LmaOS
;
; Copyright Nate Rivard 2020

;;; Monitor Addresses
.ifndef MONITAUR_INC
MONITAUR_INC = 1

.export MonitorCommandBuffer

.bss

; the current command buffer. terminated by carriage return
MonitorCommandBuffer: .res $80 

.macro DUMP addr, length
.scope
    PHA
    PHY
	LDY #0
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
.endscope
.endmacro

.endif
