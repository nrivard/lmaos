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
    JSR ACIASendString

Init:
    SEI
    COPY16 SystemClockUptime, StartTime         ; preserve starting system clock time
    COPY16 InterruptVector, SystemInterrupt     ; preserve old value of the interrupt vector
    COPYADDR FrameInterrupt, InterruptVector
    CLI

WaitForIt:
    JSR ACIAGetByte                             ; the whole program is just waiting for a Q
    CMP #(ASCII_ESCAPE)
    BNE WaitForIt

RestoreInterrupt:
    SEI
    COPY16 SystemInterrupt, InterruptVector
    CLI

SendPrefix:
    LDA #<ResponseMessagePrefix
    STA r0
    LDA #>ResponseMessagePrefix
    STA r0 + 1
    JSR ACIASendString
SendWaitTime:
    SBC16 SystemClockUptime, StartTime, StartTime   ; subtract StartTime from the current time and store it back since we're done with this value
    LDA StartTime + 1
    JSR PrintByte
    LDA StartTime
    JSR PrintByte
SendSuffix:
    LDA #<ResponseMessageSuffix
    STA r0
    LDA #>ResponseMessageSuffix
    STA r0 + 1
    JSR ACIASendString
Done:
    RTS

; byte to print in A
PrintByte:
    PHA
    JSR ByteToHexString
    LDA r7
    JSR ACIASendByte
    LDA r7 + 1
    JSR ACIASendByte
    PLA
    RTS

FrameInterrupt:
    PHA
    LDA SystemClockJiffies
    CMP #(ClockRateHz)
    BEQ @SendHeartbeat
    JMP @Done
@SendHeartbeat:
    LDA #'*'
    JSR ACIASendByte
@Done:
    PLA
    JMP (SystemInterrupt) 

StartMessage: .asciiz "Press ESC when you can take no more suspense!\r"
ResponseMessagePrefix: .asciiz "You waited for "
ResponseMessageSuffix: .asciiz " seconds! Wow!\r"
