; LmaOS
;
; Copyright Nate Rivard 2022

.ifndef SERIAL_ASM
SERIAL_ASM = 1

.include "serial.inc"

.export SerialSendString, SerialSendByteAsString

.code

; synchronously sends string using SerialSendByte
; r0: pointer to the null-terminated string that should be sent
SerialSendString:
    PHA
    PHY
    LDY #0
@SendChar:
    LDA (r0), Y
    BEQ @Done
    JSR SerialSendByte
    INY
    BRA @SendChar
@Done:
    PLY
    PLA
    RTS

; synchronously sends the byte in `A` as a hex string via SerialSendByte
; this is a convenience and destroys r7
SerialSendByteAsString:
    PHA
@ConvertAndSend:
    JSR ByteToHexString
    LDA r7
    JSR SerialSendByte
    LDA r7 + 1
    JSR SerialSendByte
@Done:
    PLA
    RTS

.endif
