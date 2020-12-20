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
	COPYADDR LMAOS_PROMPT, r0
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
	COPYADDR LMAOS_ILLEGAL_COMMAND, r0
	JSR ACIASendString
	JSR MonitorSyncTransmit
@NullTerminateCommand:				;; TODO: this should really be first step since not every command will be illegal lol
	LDY ACIAReceiveReadOffset
	DEY								;; we've already incremented the offset, we wnat to overwrite the last one
	;;STZ ACIAReceiveBuffer, Y		;; null-terminate the string
;; TODO:
	RTS
	
.segment "RODATA"

LMAOS_VERSION_STRING: .asciiz "LmaOS v1.0\n"
LMAOS_GREETING: .asciiz "Unauthorized access of this N8 Bit Special computer will result in prosecution!\n"
LMAOS_PROMPT: .asciiz "> "
LMAOS_NEWLINE: .asciiz "\n"
LMAOS_ILLEGAL_COMMAND: .asciiz "Illegal command\n"

;;; start of commands lookup table
;;MonitorCommands: .word 

MONITOR_COMMAND_MEM: .asciiz "mem $"