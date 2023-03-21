.include "lmaos.inc"
.include "pseudoinstructions.inc"
.include "strings.inc"
.include "system.inc"

.org $0400

.feature string_escapes

Main:
    JMP PrintStartMessage

; storage
N: .res $04
NMinusOne: .res $04
NMinusTwo: .res $04

PrintStartMessage:
    LDA #<StartMessage
    STA r0
    LDA #>StartMessage
    STA r0 + 1
    JSR SerialSendString

Init:
    STZ N
    STZ N + 1
    STZ N + 2
    STZ N + 3
    COPY32 N, NMinusOne
    COPY32 N, NMinusTwo

SeedTerms:
    JSR SendN                 ; first number is always zero. let's send it :)
    INC NMinusOne             ; now we seed the first term

CalculateNextTerm:
    ADC32 NMinusTwo, NMinusOne, N
    BCS Done                    ; if carry is set, we overflowed
@SendTerm:
    JSR SendN
    COPY32 NMinusOne, NMinusTwo
    COPY32 N, NMinusOne
    BRA CalculateNextTerm

Done:
    LDA #(ASCII_CARRIAGE_RETURN)
    JSR SerialSendByte
    RTS

SendN:
    PHA
    LDA N + 3
    JSR SerialSendByteAsString
    LDA N + 2
    JSR SerialSendByteAsString
    LDA N + 1
    JSR SerialSendByteAsString
    LDA N
    JSR SerialSendByteAsString
    LDA #' '
    JSR SerialSendByte
    PLA
    RTS

StartMessage: .asciiz "The Fibonacci sequence (in 32-bits)\r"
