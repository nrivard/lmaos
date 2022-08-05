; LmaOS
;
; Copyright Nate Rivard 2021
;
; A full listing of system provided storage and subroutines.
;
; THIS FILE IS GENERATED
;
; NOTE: This is not imported in LmaOS itself, it is for your external program use _only_!
; You should copy and paste this file into your program's project to expose system utility subroutines
; and any allocated system storage you should avoid using.

.ifndef LMAOS_INC
LMAOS_INC = 1

; Zero-page reserved
r0                            := $00
r1                            := $02
r2                            := $04
r3                            := $06
r4                            := $08
r5                            := $0A
r6                            := $0C
r7                            := $0E
SystemClockJiffies            := $10
SystemClockUptime             := $11
SystemRAMCapacity             := $13
InterruptVector               := $15
MonitorCommandDebugTokens     := $17
XModemDestinationAddress      := $18
XModemTimeout                 := $1A

; RAM reserved
; TODO: Open a MR if you have figured this out :)

; Read-only
MonitorCommandBuffer          := $0200
XModemPacketData              := $0280
XModemPacketNumber            := $0300
XModemPacketNumberComplement  := $0301
XModemPacketChecksum          := $0302
XModemCalculatedChecksum      := $0303
XModemPacketNumberExpected    := $0304
SerialSendString              := $C000
SerialSendByteAsString        := $C011
SerialGetByte                 := $C03B
SerialSendByte                := $C046
ACIAGetByte                   := $C082
ACIASendByte                  := $C08D
StringLength                  := $C28A
StringCompareN                := $C295
StringCompare                 := $C2A5
StringCopy                    := $C2CA
HexStringToWord               := $C2D7
ByteToHexString               := $C323
NibbleToHexString             := $C334
XModemReceive                 := $C33F
InterruptRouter               := $C3F5
InterruptHandleSystemTimer    := $C3F8
LCDInit                       := $C53F
LCDMoveCursor                 := $C556
LCDPrintString                := $C55E
LCDSendByte                   := $C571
LCDPollBusy                   := $C578
LCDSendInstruction            := $C57E
LCDSendBlock                  := $C585

.endif
