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

; ACIA
ACIAGetByte        := $8039
ACIASendByte       := $8044    
ACIASendString     := $8051

; LCD
LCDInit            := $8481    
LCDMoveCursor      := $849F
LCDPollBusy        := $84C1    
LCDPrintByte       := $84BA
LCDPrintString     := $84A7    
LCDSendInstruction := $84C7

; XModem
XModemReceive      := $82ED

.endif
