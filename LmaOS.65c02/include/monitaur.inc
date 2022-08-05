; LmaOS
;
; Copyright Nate Rivard 2020

;;; Monitor Addresses
.ifndef MONITAUR_INC
MONITAUR_INC = 1

.exportzp MonitorCommandDebugTokens
.export MonitorCommandBuffer

.zeropage

; if this is non-zero, send tokenized buffer back to client
MonitorCommandDebugTokens: .res $01

.bss

; the current command buffer. terminated by carriage return
MonitorCommandBuffer: .res $80

.macro DUMP addr, length
.local @Loop, @SendASCII, @Done
    PHA
    PHY
	LDY #0
@Loop:
	LDA addr, Y
@SendASCII:
    JSR ByteToHexString
    LDA r7
    JSR SerialSendByte
    LDA r7 + 1
    JSR SerialSendByte
    LDA #' '
    JSR SerialSendByte
	INY
	CPY #(length)
	BNE @Loop
@Done:
	LDA #(ASCII_CARRIAGE_RETURN)
	JSR SerialSendByte
    PLY
    PLA
.endmacro

.endif
