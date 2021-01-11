; LmaOS
;
; Copyright Nate Rivard 2020

;;; Monitor Addresses

.zeropage

; offset to put the next recv'd char
MonitorCommandBufferOffset: .res 1

.bss

; the current command buffer. terminated by carriage return
MonitorCommandBuffer: .res $80 

.macro DUMP addr, length
.local @Loop
.local @Send
	LDY #$00
@Loop:
	LDA addr, Y
	JSR ACIASendByte
	INY
	CPY #(length)
	BNE @Loop
@Send:
	LDA #(ASCII_CARRIAGE_RETURN)
	JSR ACIASendByte
	JSR ACIASendByte
.endmacro