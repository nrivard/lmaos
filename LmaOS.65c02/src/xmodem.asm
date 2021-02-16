; LmaOS
;
; Copyright Nate Rivard 2020

.ifndef XMODEM_ASM
XMODEM_ASM = 1

.include "acia.asm"
.include "pseudoinstructions.inc"
.include "registers.inc"
.include "xmodem.inc"

.include "via.inc"  ; debug
.include "strings.asm"

.code

; Synchronously receive data at the specified address
;
; Params:
; A: low byte of destination address
; X: high byte of destination address
XModemReceive:
    STA r0                              ; set destination address
    STX r0 + 1
    LDA #1
    STA r1                              ; packet number, starting with 1
    STZ r1 + 1                          ; zero for high byte
@SendMode:
    LDA #(XMODEM_NACK)                  ; send a NACK to inform transmitter we're in CRC mode
    JSR ACIASendByte
    LDA SystemClockUptime               ; copy lowest byte of uptime as timeout check
    STA r2
@WaitForFirstPacket:
    LDA ACIA_STATUS
    BIT #(ACIA_STATUS_MASK_RDR_FULL)    ; have we received anything?
    BNE @ReceievePacket                 ; start of first packet
@CheckTimeout:
    LDA SystemClockUptime
    SEC
    SBC r2
    CMP #3                              ; check for 3 second timeout
    BMI @WaitForFirstPacket
    BRA @SendMode                       ; timed-out. resend NACK
@ReceievePacket:
    JSR ACIAGetByte                     ; get the header byte
    
@Done:
    LDA #(ASCII_CARRIAGE_RETURN)
    JSR ACIASendByte
    RTS

XModemCalculateCRC:

.endif
