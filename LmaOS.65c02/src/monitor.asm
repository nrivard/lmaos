; LmaOS
;
; Copyright Nate Rivard 2020

.include "monitor.inc"

.code

.feature string_escapes

;;; Starts the monitor which will take over until given a command to
;;; hand execution off to some location
MonitorStart:
	JSR MonitorNewConnection
	JSR MonitorPromptLoop

;;; sends the version and greeting on a new connection	
MonitorNewConnection:
	COPYADDR LMAOS_VERSION_STRING, r0
	JSR ACIASendString
	JSR MonitorSyncTransmit
	COPYADDR LMAOS_GREETING, r0
	JSR ACIASendString
	JSR MonitorSyncTransmit
	RTS
	
;;; the main loop where we show a prompt, wait for input, echo, and process
MonitorPromptLoop:
	COPYADDR MONITOR_PROMPT, r0
	JSR ACIASendString
@ResetCommandOffset:
	LDA ACIAReceiveReadOffset
	STA MonitorCommandStartOffset	;; this is our start offset for the command
@WaitForInput:
	LDY ACIAReceiveReadOffset
	CPY ACIAReceiveWriteOffset
	BEQ @WaitForInput
@Echo:
	LDA ACIAReceiveBuffer, Y
	PHA								;; save the value so we can see if this is '\n'
	STA r2
	STZ r2 + 1						;; null-terminate our "string"
	COPYADDR r2, r0
	JSR ACIASendString
	INC ACIAReceiveReadOffset
	JSR MonitorSyncTransmit
@CheckEOL:
	PLA								;; restore the value
	CMP #(ASCII_CARRIAGE_RETURN)	;; is this '\n'?
	BNE @WaitForInput
	JSR MonitorProcessCommand
@NewLine:
	JMP MonitorPromptLoop
	
;;; a synchronous transmit wait loop
MonitorSyncTransmit:
	LDA ACIATransmitInProgress
	BNE MonitorSyncTransmit
	RTS
	
MonitorProcessCommand:
	LDY #(MONITOR_COMMAND_MEM_END - MONITOR_COMMAND_MEM)
	RTS
	
.segment "RODATA"

LMAOS_VERSION_STRING: .asciiz "LmaOS v1.0\n"
LMAOS_GREETING: .asciiz "Unauthorized access of this N8 Bit Special computer will result in prosecution!\n"
MONITOR_PROMPT: .asciiz "> "
LMAOS_NEWLINE: .byte "\n"

MONITOR_ILLEGAL_COMMAND: .asciiz "Illegal command\n"

;;; start of commands lookup table
;;MonitorCommands: .word 

;; these do not end in `\0`
MONITOR_COMMAND_MEM: .byte "mem $"
MONITOR_COMMAND_MEM_END: