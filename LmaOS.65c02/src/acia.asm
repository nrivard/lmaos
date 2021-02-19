; LmaOS
;
; Copyright Nate Rivard 2020

.ifndef ACIA_ASM
ACIA_ASM = 1

.include "acia.inc"
.include "registers.inc"

.export ACIAGetByte, ACIASendByte, ACIASendString

.code

;;; Initialize the ACIA
ACIAInit:
    ; setup ACIA for interrupt receiving, 19200, no parity
    LDA #(ACIA_STOP_BITS_SINGLE_NO_PARITY | ACIA_WORD_LENGTH_FULL | ACIA_CLOCK_SOURCE_INTERNAL | ACIA_BAUD_RATE_19200)
    STA ACIA_CONTROL
    ; turn off all interrupts
    LDA #(ACIA_PARITY_MODE_DISABLED | ACIA_ECHO_MODE_NORMAL | ACIA_RECEIVER_MODE_IRQ_DISABLED | ACIA_TRANSMITTER_MODE_IRQ_DISABLED | ACIA_DATA_TERMINAL_READY)
    STA ACIA_COMMAND
    RTS
        
;; gets a byte from the ACIA, blocking until received
;;
;; Results
;; A: received byte
ACIAGetByte:
@CheckByteReceived:
    LDA ACIA_STATUS
    BIT #(ACIA_STATUS_MASK_RDR_FULL)
    BEQ @CheckByteReceived
@Done:
    LDA ACIA_DATA
    RTS
    
;; sends a char via the ACIA synchronously
;;
;; Params
;; A: byte to send
ACIASendByte:
    PHA				; save param
@CheckTransmitEmpty:
    LDA ACIA_STATUS
    BIT #(ACIA_STATUS_MASK_TDR_EMPTY)
    BEQ @CheckTransmitEmpty
@SendByte:
    PLA				; restore param
    STA ACIA_DATA
@Done:
    RTS
    
;;; sends a string via the ACIA synchronously
;;;
;;; Params
;;; r0: pointer to the null-terminated that should be sent.
ACIASendString:
    PHA
    PHY
    LDY #$00
@SendChar:
    LDA (r0), Y
    BEQ @Done
    JSR ACIASendByte
    INY
    BRA @SendChar
@Done:
    PLY
    PLA
    RTS

.endif