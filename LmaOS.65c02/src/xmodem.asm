; LmaOS
;
; Copyright Nate Rivard 2020

.ifndef XMODEM_ASM
XMODEM_ASM = 1

.include "xmodem.inc"

.export XModemReceive

.code

; Synchronously receive data and write to the passed in address
;
; Params:
; A: low byte of destination address
; X: high byte of destination address
;
; Returns:
; Carry: clear if successful, set if canceled
XModemReceive:
    STA XModemDestinationAddress        ; set destination address
    STX XModemDestinationAddress + 1
    LDA #1
    STA XModemPacketNumberExpected      ; packet number, starting with 1 (packet numbers are 1 byte)
@SendMode:
    JSR XModemSendNACK                  ; send a NACK to inform transmitter we're in checksum mode and ready
    LDA SystemClockUptime               ; copy lowest byte of uptime as timeout check
    STA XModemTimeout
@WaitForFirstPacket:
    SERIAL_BYTE_AVAIL                   ; have we received anything?
    BCC @PacketRouter                   ; start of first packet
@CheckTimeout:
    LDA SystemClockUptime
    SEC
    SBC XModemTimeout
    CMP #(XMODEM_TIMEOUT)               ; check for 3 second timeout
    BMI @WaitForFirstPacket
    BRA @SendMode                       ; timed-out. resend NACK
@PacketRouter:
    JSR SerialGetByte                   ; get the header byte
    CMP #(XMODEM_START_OF_HEADER)
    BEQ @ReceivePacketNumber
    CMP #(XMODEM_END_TRANSMISSION)
    BEQ @TransmissionSuccess
    SEC                                 ; canceled
    BRA @Done
@ReceivePacketNumber:
    JSR SerialGetByte                   ; packet number
    STA XModemPacketNumber
    JSR SerialGetByte                   ; 1s complement of packet number
    STA XModemPacketNumberComplement
@ReceivePacketData:
    LDX #0
    STZ XModemCalculatedChecksum        ; reset running checksum
@ReceivePacketDataLoop:
    JSR SerialGetByte
    STA XModemPacketData, X
@CalculateChecksum:
    CLC
    ADC XModemCalculatedChecksum        ; add to running checksum
    STA XModemCalculatedChecksum
    INX
    CPX #(XMODEM_DATA_LENGTH)
    BNE @ReceivePacketDataLoop
@ReceiveChecksum:
    JSR SerialGetByte
    STA XModemPacketChecksum
@VerifyPacketNumber:
    LDA XModemPacketNumberExpected
    CMP XModemPacketNumber              ; expected packet number?
    BEQ @VerifyPacketNumberComplement
    DEC A                               ; previous packet?
    CMP XModemPacketNumber
    BNE @PacketFailed                   ; this packet failed
    BRA @SendAck                        ; already wrote this packet, send an ACK
@VerifyPacketNumberComplement:
    EOR #$FF                            ; 1s complement of expected packet
    CMP XModemPacketNumberComplement
    BNE @PacketFailed
@VerifyChecksum:
    LDA XModemCalculatedChecksum
    CMP XModemPacketChecksum
    BNE @PacketFailed
@WritePacket:
    LDY #0
    LDX #0
@WritePacketLoop:
    LDA XModemPacketData, X
    INX
    STA (XModemDestinationAddress), Y
    INY
    CPY #(XMODEM_DATA_LENGTH)
    BNE @WritePacketLoop
@AdvanceDestinationPointer:
    ADD16 XModemDestinationAddress, XMODEM_DATA_LENGTH        ; advance destination pointer by data size
    INC XModemPacketNumberExpected      ; increment expected packet number
@SendAck:
    JSR XModemSendACK
    BRA @PacketRouter                   ; receive the next packet
@PacketFailed:
    JSR XModemSendNACK
    BRA @PacketRouter
@TransmissionSuccess:
    JSR XModemSendACK
    CLC                                 ; no errors, so CLC
@Done:
    RTS

XModemSendNACK:
    LDA #(XMODEM_NACK)
    JSR SerialSendByte
    RTS

XModemSendACK:
    LDA #(XMODEM_ACK)
    JSR SerialSendByte
    RTS

.endif
