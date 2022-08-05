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
N: .res $02
NMinusOne: .res $02
NMinusTwo: .res $02

PrintStartMessage:
    LDA #<StartMessage
    STA r0
    LDA #>StartMessage
    STA r0 + 1
    JSR SerialSendString

Init:
    STZ N
    STZ N + 1
    STZ NMinusOne
    STZ NMinusOne + 1
    STZ NMinusTwo
    STZ NMinusTwo + 1

SeedTerms:
    LDA #0
    JSR PrintByte             ; first number is always zero. let's send it :)
    JSR PrintByte
    LDA #' '
    JSR SerialSendByte
    INC NMinusOne             ; now we seed the first term

CalculateNextTerm:
    ADC16 NMinusTwo, NMinusOne, N
    BMI @SendTerm               ; if high byte of N is positive, we might have overflowed. check NMinusOne
    LDA NMinusOne + 1
    BPL @SendTerm               ; if high byte of NMinusOne is positive, we haven't overflowed
    BRA Done
@SendTerm:
    JSR PrintByte         ; high byte is already in A
    LDA N
    JSR PrintByte
    COPY16 NMinusOne, NMinusTwo
    COPY16 N, NMinusOne
    LDA #' '
    JSR SerialSendByte
    BRA CalculateNextTerm

Done:
    LDA #(ASCII_CARRIAGE_RETURN)
    JSR SerialSendByte
    RTS

; byte to print in A
PrintByte:
    PHA
    JSR ByteToHexString
    LDA r7
    JSR SerialSendByte
    LDA r7 + 1
    JSR SerialSendByte
    PLA
    RTS

StartMessage: .asciiz "The Fibonacci sequence (in 16-bits)\r"
