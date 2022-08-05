.include "duart.inc"
.include "lmaos.inc"
.include "pseudoinstructions.inc"
.include "strings.inc"
.include "system.inc"

.org $1000

.feature string_escapes

Main:
    JSR DuartGetByte
    JSR DuartSendByte
    CMP #(ASCII_ESCAPE)
    BNE Main
@Done:
    RTS
