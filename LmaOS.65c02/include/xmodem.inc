; LmaOS
;
; Copyright Nate Rivard 2020

.ifndef XMODEM_INC
XMODEM_INC = 1

XMODEM_TIMEOUT := 3

XMODEM_START_OF_HEADER := $01
XMODEM_END_TRANSMISSION := $04
XMODEM_ACK := $06
XMODEM_NACK := $15
XMODEM_END_TRANSMISSION_BLOCK := $17
XMODEM_CANCEL := $18

XMODEM_DATA_LENGTH := $80

.exportzp XModemDestinationAddress, XModemTimeout
.export XModemPacketData, XModemPacketNumber, XModemPacketNumberComplement, XModemPacketChecksum, XModemCalculatedChecksum, XModemPacketNumberExpected

.zeropage

XModemDestinationAddress: .res $02
XModemTimeout: .res $01

.bss

XModemPacketData:     .res $80  ; 0280
XModemPacketNumber:   .res $01  ; 0300
XModemPacketNumberComplement: .res $01  ; 0301
XModemPacketChecksum: .res $01  ; 0302
XModemCalculatedChecksum: .res $01 ; 0303
XModemPacketNumberExpected: .res $01 ; 0304

.endif
