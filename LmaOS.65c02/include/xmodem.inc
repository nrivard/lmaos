; LmaOS
;
; Copyright Nate Rivard 2020

.ifndef XMODEM_INC
XMODEM_INC = 1

XMODEM_START_OF_HEADER := $01
XMODEM_END_TRANSMISSION := $04
XMODEM_ACK := $06
XMODEM_NACK := $15
XMODEM_END_TRANSMISSION_BLOCK := $17
XMODEM_CANCEL := $18

XMODEM_PACKET_STATE_START = $00
XMODEM_PACKET_STATE_NUMBER = $01
XMODEM_PACKET_STATE_DATA = $02
XMODEM_PACKET_STATE_CHECKSUM = $04

.bss

XModemPacketBuffer:   .res $80
; XModemPacketChecksum: .res $01
; XModemPacketExpected: .res $01

.endif