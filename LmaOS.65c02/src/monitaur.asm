; LmaOS
;
; Copyright Nate Rivard 2020

.include "monitaur.inc"
.include "pseudoinstructions.inc"
.include "via.inc"

.include "acia.asm"
.include "strings.asm"
.include "xmodem.asm"

.code

.feature string_escapes

MonitorStart:
@FlushLine:
    JSR ACIAGetByte
    LDA #(ASCII_CARRIAGE_RETURN)
    JSR ACIASendByte
@SendGreeting:
    COPYADDR LMAOS_VERSION_STRING, r0
    JSR ACIASendString
    COPYADDR LMAOS_GREETING, r0
    JSR ACIASendString
@MonitorGetCommandLoop:
    LDA #'>'
    JSR ACIASendByte
    LDY #0
@WaitForInput:
    JSR ACIAGetByte
    JSR ACIASendByte				; echo received byte (already in A)
    CMP #(ASCII_CARRIAGE_RETURN)
    BEQ @ProcessCommand
    STA MonitorCommandBuffer, Y
    INY
    BRA @WaitForInput
@ProcessCommand:
    JSR MonitorTokenizeCommandBuffer
    JSR MonitorProcessCommand
@Done:
    BRA @MonitorGetCommandLoop

; tokenizes the command buffer into separate tokens, up to 3
; token pointers are stored in order starting at r5.
; CMD @ r4, ADDR1 @ r5, [ADDR2 @ r6]
; this subroutine null-terminates tokens by inserting '\0' into the original string
; '\0' is stored for unused args
MonitorTokenizeCommandBuffer:
@Preamble:
    LDX #0
@ClearArgs:
    STZ r4, X
    INX
    CPX #6
    BNE @ClearArgs
    COPYADDR r4, r0                         ; copy r4 (base pointer addr) into r0 as incrementable pointer
    LDX #0                                  ; index into monitor command buffer
@WritePointerToRegister:
    ; TODO: we should really check if (r0) > r6 because it means we tried to parse more than 3 tokens
    TXA                                     ; copy pointer to command buffer index into current token register
    CLC
    ADC #<MonitorCommandBuffer
    STA (r0)
    INC r0
    LDA #>MonitorCommandBuffer
    ADC #0
    STA (r0)
    INC r0
@TokenCharacterLoop:
    LDA MonitorCommandBuffer, X
    CMP #(ASCII_LINE_FEED)                  ; all done!
    BEQ @Done
    CMP #' '                                ; end of token
    BEQ @NullTerminateToken
    INX
    BRA @TokenCharacterLoop
@NullTerminateToken:
    STZ MonitorCommandBuffer, X
    INX
    BRA @WritePointerToRegister
@Done:
    STZ MonitorCommandBuffer, X
    RTS

MonitorProcessCommand:
@Preamble:
    LDX #0                                  ; index into command lookup table
@CommandLoop:
    CPX #(MonitorCommandLookupTableEnd - MonitorCommandLookupTable) ; are we past the end?
    BEQ @JmpNextCommand                     ; illegal command
    LDY #0                                  ; index into parsed command. have to reset on each loop
@CommandCompare:
    CPY #2                                  ; end of command?
    BEQ @CheckCommandTerminated
    LDA (r4), Y
    CMP MonitorCommandLookupTable, X
    BNE @TryNextCommand                     ; not a match
    INX
    INY
    BRA @CommandCompare
@TryNextCommand:
    CPY #0                                  ; was first or 2nd letter wrong?
    BNE @TryNextCommand2
    INX                                     ; first letter wrong, double increment
@TryNextCommand2:
    INX
    BRA @CommandLoop
@CheckCommandTerminated:
    LDA (r4), Y
    BEQ @JmpNextCommandSetup
    JMP MonitorProcessIllegalCommand
@JmpNextCommandSetup:
    DEX                                     ; unadvance X so we can jump to processed command pointer in jump table
    DEX
@JmpNextCommand:
    JMP (MonitorCommandJumpTable, X)        ; no JSR (<addr>, X) :(
MonitorProcessCommandDone:
    RTS

MonitorProcessReadCommand:
@CheckLength:
    LDA r6                                  ; do we have a specified length?
    BNE @ParseLength
    LDA #1                                  ; unspecified length means 1
    STA r6
    BRA @ParseAddress
@ParseLength:
    COPY16 r6, r0
    JSR HexStringToWord
    LDA r7
    STA r6
@ParseAddress:
    COPY16 r5, r0                           ; copy parsed address into r0
    JSR HexStringToWord
    COPY16 r7, r5                           ; save the base pointer back
    LDY #0
@SendLoop:
    LDA (r5), Y                             ; load value at parsed address
@SendASCII:
    JSR ByteToHexString
    LDA r7
    JSR ACIASendByte
    LDA r7 + 1
    JSR ACIASendByte
    LDA #' '
    JSR ACIASendByte
@CheckLoopDone:
    INY
    CPY r6
    BEQ @Done
    BRA @SendLoop
@Done:
    LDA #(ASCII_CARRIAGE_RETURN)
    JSR ACIASendByte
    JMP MonitorProcessCommandDone

MonitorProcessWriteCommand:
    COPY16 r5, r0                       ; copy address pointer into r0
    JSR HexStringToWord
    COPY16 r7, r5                       ; overwrite address pointer with its value
    COPY16 r6, r0                       ; copy value pointer into r0
    JSR HexStringToWord
@WriteNewValue:
    LDA r7                              ; can only write a byte so load lower byte of r7
    STA (r5)
@Done:
    JMP MonitorProcessCommandDone

MonitorProcessTransferCommand:
    COPY16 r5, r0
    JSR HexStringToWord
    LDA r7
    LDX r7 + 1
    JSR XModemReceive
    JMP MonitorProcessCommandDone

MonitorProcessExecuteCommand:
    COPY16 r5, r0                       ; copy address pointer into r0
    JSR HexStringToWord
    JSR @JSRIndirect
    BRA @Done                           ; JSR to @JSRIndirect will return on the next line: BRA @Done
@JSRIndirect:
    JMP (r7)
@Done:
    JMP MonitorProcessCommandDone

MonitorProcessIllegalCommand:
    COPYADDR MONITAUR_ILLEGAL_COMMAND_START, r0
    JSR ACIASendString
@EchoIllegalCommand:
    COPY16 r4, r0
    JSR ACIASendString
@TerminateIllegalCommand:
    COPYADDR MONITAUR_ILLEGAL_COMMAND_END, r0
    JSR ACIASendString
@Done:
    JMP MonitorProcessCommandDone

SampleProgram:
    LDA #$AA
    STA VIA1_PORT_A
    STA VIA1_PORT_B
    RTS
    
.segment "RODATA"

LMAOS_VERSION_STRING: 			.asciiz "LmaOS v1.0\n"
LMAOS_GREETING: 				.asciiz "Unauthorized access of this N8 Bit Special computer will result in prosecution!\n"

MONITAUR_ILLEGAL_COMMAND_START: .asciiz "Illegal command: \""
MONITAUR_ILLEGAL_COMMAND_END: 	.asciiz "\"\n"
MONITAUR_TRANSFER_RESPONSE:     .asciiz "Coming soon.\n"

MonitorCommandLookupTable: .byte "rd", "wr", "tx", "ex"
MonitorCommandLookupTableEnd:
MonitorCommandJumpTable: .addr MonitorProcessReadCommand, MonitorProcessWriteCommand, MonitorProcessTransferCommand, MonitorProcessExecuteCommand, MonitorProcessIllegalCommand
