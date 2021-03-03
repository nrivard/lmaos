; LmaOS
;
; Copyright Nate Rivard 2021

; A full listing of system provided subroutines and their addresses.
;
; NOTE: I don't think this is deterministic! We are using cc65's code relocation so if you change
; any of these associated files it will likely cascade into address changes for _all_ of these routines.
; Verify the new addresses in lmaos.rom.map where they are exported so you can see their addresses.
;
; NOTE 2: this is not imported _anywhere_. It is for your external program use _only_!
; copy and paste this into your project (along with any other relevant `.inc` files for system defined consts)
; so you can JSR into these routines. See the relevant `.asm` file for preconditions on calling them.

.ifndef LMAOS_INC
LMAOS_INC = 1

; Zero-page reserved
r0                 := $00
r1                 := $02
r2                 := $04
r3                 := $06
r4                 := $08
r5                 := $0A
r6                 := $0C
r7                 := $0E
SystemClockJiffies := $10
SystemClockUptime  := $11
InterruptHandler   := $13

; Interrupt Handler
InterruptRouter    := $808B

; ACIA
ACIAGetByte        := $8041
ACIASendByte       := $804C
ACIASendString     := $8059

; LCD
LCDInit            := $848A
LCDMoveCursor      := $84A1
LCDPollBusy        := $84C3
LCDPrintString     := $84A9
LCDSendByte        := $84BC
LCDSendInstruction := $84C9
LCDSendBlock       := $84D0

; XModem
XModemReceive      := $82F6

; Strings
StringLength       := $8241
StringCompareN     := $824C
StringCompare      := $825C
StringCopy         := $8281
NibbleToHexString  := $82EB
ByteToHexString    := $82DA
HexStringToWord    := $828E

.endif
