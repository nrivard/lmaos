; LmaOS
;
; Copyright Nate Rivard 2020

.include "acia.inc"

.code

;;; Initialize the ACIA
ACIAInit:
  ; init buffer first
  STZ ACIAReceiveReadOffset
  STZ ACIAReceiveWriteOffset
  STZ ACIATransmitOffset
  STZ ACIATransmitInProgress

  ; setup ACIA for interrupt receiving, 19200, no parity
  LDA #(ACIA_STOP_BITS_SINGLE_NO_PARITY | ACIA_WORD_LENGTH_FULL | ACIA_CLOCK_SOURCE_INTERNAL | ACIA_BAUD_RATE_19200)
  STA ACIA_CONTROL
  LDA #(ACIA_PARITY_MODE_DISABLED | ACIA_ECHO_MODE_NORMAL | ACIA_RECEIVER_MODE_IRQ_ENABLED | ACIA_TRANSMITTER_MODE_IRQ_DISABLED | ACIA_DATA_TERMINAL_READY)
  STA ACIA_COMMAND
  RTS

;;; sends a string via the ACIA asynchronously
;;;
;;; Params
;;; r0: pointer to the null-terminated that should be sent. 
;;; this string is copied, so does not need to be stable beyond this call
;;; NOTE: calling this while a send is in progress will cancel the current send
ACIASendString:
	COPYADDR ACIATransmitBuffer, r1					;; set up destination. r0 is already set by caller
  	JSR StringCopy					                ;; copy string in r0 to transmit send buffer
  	STZ ACIATransmitOffset                          ;; reset offset
  	INC ACIATransmitInProgress                      ;; toggle in-progress byte. TODO: could be count of remaining chars?
  	UPD_TXD_IRQ ACIA_TRANSMITTER_MODE_IRQ_ENABLED
  	RTS

;;; ACIA interrupt handler
ACIAHandleInterrupt:
  PHY
  PHA                                             ;; save ACIA status, we need it again for checking transmit
  BIT #(ACIA_STATUS_MASK_RDR_FULL)
  BEQ @CheckTransmit
@ReceiveData:
  LDA ACIA_DATA
  LDY ACIAReceiveWriteOffset
  STA ACIAReceiveBuffer, Y
  INC ACIAReceiveWriteOffset
@CheckTransmit:
  PLA                                             ;; pull ACIA status
  BIT #(ACIA_STATUS_MASK_TDR_EMPTY)
  BEQ @Done                                       ;; txd buffer is not empty
  LDA ACIATransmitInProgress
  BEQ @Done                                       ;; no transmission in progress, skip to Done    
@TransmitData:
  LDY ACIATransmitOffset
  LDA ACIATransmitBuffer, Y
  BEQ @TransmitFinalize                           ;; null terminator, finalize transmission
@TransmitNextChar:
  STA ACIA_DATA
  INC ACIATransmitOffset
  JMP @Done
@TransmitFinalize:
  UPD_TXD_IRQ ACIA_TRANSMITTER_MODE_IRQ_DISABLED
  STZ ACIATransmitInProgress
@Done:
  PLY
  RTS
