.include "lmaos.inc"
.include "lcd1602.inc"
.include "pseudoinstructions.inc"
.include "strings.inc"
.include "system.inc"
.include "via.inc"

.org $0400

.feature string_escapes

Main:
    JMP PrintStartMessage

; storage
StartTime: .res 2
Delay: .res 1
SystemInterrupt: .res 2

PrintStartMessage:
    LDA #<StartMessage
    STA r0
    LDA #>StartMessage
    STA r0 + 1
    JSR SerialSendString

Init:
    SEI
    COPY16 SystemClockUptime, StartTime         ; preserve starting system clock time
    COPY16 InterruptVector, SystemInterrupt     ; preserve old value of the interrupt vector
    COPYADDR FrameInterrupt, InterruptVector
    CLI

WaitForIt:
    JSR SerialGetByte                             ; the whole program is just waiting for a Q
    CMP #(ASCII_ESCAPE)
    BNE WaitForIt

RestoreInterrupt:
    SEI
    COPY16 SystemInterrupt, InterruptVector
    CLI

SendPrefix:
    LDA #(ASCII_CARRIAGE_RETURN)
    JSR SerialSendByte
    LDA #<ResponseMessagePrefix
    STA r0
    LDA #>ResponseMessagePrefix
    STA r0 + 1
    JSR SerialSendString
SendWaitTime:
    SBC16 SystemClockUptime, StartTime, StartTime   ; subtract StartTime from the current time and store it back since we're done with this value
    LDA StartTime + 1
    JSR SerialSendByteAsString
    LDA StartTime
    JSR SerialSendByteAsString
SendSuffix:
    LDA #<ResponseMessageSuffix
    STA r0
    LDA #>ResponseMessageSuffix
    STA r0 + 1
    JSR SerialSendString
Done:
    RTS

FrameInterrupt:
    PHA
    LDA SystemClockJiffies
    CMP #(ClockRateHz)
    BEQ @SendHeartbeat
    JMP @Done
@SendHeartbeat:
    LDA #'*'
    JSR SerialSendByte
@Done:
    PLA
    JMP (SystemInterrupt) 

StartMessage: .asciiz "Press ESC when you can take no more suspense!\r"
ResponseMessagePrefix: .asciiz "You waited for "
ResponseMessageSuffix: .asciiz " seconds! Wow!\r"
