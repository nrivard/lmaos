; LmaOS
;
; Copyright Nate Rivard 2020

.include "monitor.inc"

.code

.feature string_escapes

;; Starts the monitor which will take over until given a command to
;; hand execution off to some location
MonitorStart:
    COPYADDR LMAOS_VERSION_STRING, r0
    JSR ACIASendString
    COPYADDR LMAOS_GREETING, r0
    JSR ACIASendString	
@MonitorGetCommandLoop:
    STZ MonitorCommandBufferOffset	; reset command buffer offset
    COPYADDR MONITOR_PROMPT, r0
    JSR ACIASendString				; send "> "
@WaitForInput:
    JSR ACIAGetByte
    JSR ACIASendByte				; echo received byte (already in A)
@CheckTerminated:
    CMP #(ASCII_LINE_FEED)			; ignore line feed
    BEQ @WaitForInput
    CMP #(ASCII_CARRIAGE_RETURN)	; end of command?
    BEQ @ProcessCommand
@AppendToBuffer:
    LDY MonitorCommandBufferOffset
    STA MonitorCommandBuffer, Y
    INC MonitorCommandBufferOffset
    JMP @WaitForInput
@ProcessCommand:
    JSR MonitorProcessCommand
    JMP @MonitorGetCommandLoop
    
;; Processes the monitor commands
;; "rd <addr>[…<endaddr>]" read an address (or a range of addresses)
;; "wr <addr> <value>"				write to an address
MonitorProcessCommand:
@NullTerminateBuffer:
    LDA #$00
    LDY MonitorCommandBufferOffset
    STA MonitorCommandBuffer, Y
@CheckRead:
    LDY #(MONITOR_COMMAND_READ_END - MONITOR_COMMAND_READ)
    COPYADDR MonitorCommandBuffer, r0
    COPYADDR MONITOR_COMMAND_READ, r1
    JSR StringCompareN
    BEQ ProcessReadCommand
    JMP ProcessIllegalCommand

ProcessReadCommand:
    COPYADDR MonitorCommandBuffer, r0
ParseAddress:
    CLC
    LDA r0
    ADC #(MONITOR_COMMAND_READ_END - MONITOR_COMMAND_READ)
    STA r0
    LDA r0 + 1
    ADC #$00
    STA r0 + 1
    JSR HexStringToWord
    LDA (r7)
    STA r0
@ConvertToASCII:
    LDA r0				; send upper nibble
    JSR ByteToHexString
    LDA r7
    JSR ACIASendByte
    LDA r7 + 1
    JSR ACIASendByte
@Done:
    LDA #(ASCII_CARRIAGE_RETURN)
    JSR ACIASendByte
    RTS

ProcessIllegalCommand:
    COPYADDR MONITOR_ILLEGAL_COMMAND_START, r0
    JSR ACIASendString
@EchoIllegalCommand:
    COPYADDR MonitorCommandBuffer, r0
    JSR ACIASendString
@TerminateIllegalCommand:
    COPYADDR MONITOR_ILLEGAL_COMMAND_END, r0
    JSR ACIASendString
    RTS
    
.segment "RODATA"

LMAOS_VERSION_STRING: 			.asciiz "LmaOS v1.0\n"
LMAOS_GREETING: 				.asciiz "Unauthorized access of this N8 Bit Special computer will result in prosecution!\n"

MONITOR_PROMPT: 				.asciiz "> "
MONITOR_ILLEGAL_COMMAND_START: 	.asciiz "Illegal command: \""
MONITOR_ILLEGAL_COMMAND_END: 	.asciiz "\"\n"

;;; start of commands lookup table
;;MonitorCommands: .word 

;; these do not end in `\0`
MONITOR_COMMAND_READ: .byte "rd "
MONITOR_COMMAND_READ_END:
MONITOR_COMMAND_WRITE: .byte "wr "
MONITOR_COMMAND_WRITE_END: