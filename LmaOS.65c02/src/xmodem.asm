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
;
; Uses:
; r0: destination address
; r1: expected packet number
; r2: time out (phase 1) / running checksum (phase 2)
XModemReceive:
    STA r0                              ; set destination address
    STX r0 + 1
    LDA #1
    STA r1                              ; packet number, starting with 1 (packet numbers are 1 byte)
@SendMode:
    JSR XModemSendNACK                  ; send a NACK to inform transmitter we're in checksum mode and ready
    LDA SystemClockUptime               ; copy lowest byte of uptime as timeout check
    STA r2
@WaitForFirstPacket:
    LDA ACIA_STATUS
    BIT #(ACIA_STATUS_MASK_RDR_FULL)    ; have we received anything?
    BNE @ReceivePacket                  ; start of first packet
@CheckTimeout:
    LDA SystemClockUptime
    STA VIA1_PORT_A             ; debug
    SEC
    SBC r2
    CMP #3                              ; check for 3 second timeout
    BMI @WaitForFirstPacket
    BRA @SendMode                       ; timed-out. resend NACK
@ReceivePacket:
    JSR ACIAGetByte                     ; get the header byte
    STA VIA1_PORT_B
    CMP #(XMODEM_START_OF_HEADER)
    BEQ @VerifyPacketNumber
    CMP #(XMODEM_END_TRANSMISSION)
    BEQ @Done
    BRA @PacketFailed                   ; not start of header
@VerifyPacketNumber:
    JSR ACIAGetByte
    CMP r1                              ; same as expected packet number?
    BNE @PacketFailed 
@VerifyPacketNumberComplement:
    JSR ACIAGetByte
    CLC
    ADC r1
    CMP #$FF
    BNE @PacketFailed
    LDX #0
    STZ r2
@ReceivePacketLoop:
    JSR ACIAGetByte
    STA XModemPacketBuffer, X
    CLC
    ADC r2                              ; add to running checksum
    INX
    BNE @ReceivePacketLoop
@VerifyChecksum:
    JSR ACIAGetByte
    CMP r2
    BNE @PacketFailed
    LDY #0
    LDX #0
@WritePacketLoop:
    LDA XModemPacketBuffer, X
    INX
    STA (r0), Y
    INY
    BNE @WritePacketLoop
@AdvanceDestinationPointer:
    INC r0 + 1                          ; should only have to increment the upper byte
    LDA #(XMODEM_ACK)                   ; ACK the packet
    JSR ACIASendByte
    BRA @ReceivePacket                  ; receive the next packet
@PacketFailed:
    JSR XModemSendNACK
    BRA @ReceivePacket
@Done:
    LDA #(XMODEM_ACK)
    JSR ACIASendByte
    RTS

XModemSendNACK:
    LDA #(XMODEM_NACK)
    STA VIA1_PORT_B
    JSR ACIASendByte
    RTS

.endif
