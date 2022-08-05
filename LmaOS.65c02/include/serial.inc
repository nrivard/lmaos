; LmaOS
;
; Copyright Nate Rivard 2022

.ifndef SERIAL_INC
SERIAL_INC = 1

.export SerialGetByte, SerialSendByte

;;; This include file contains an interface serial hardware drivers can conform to
;;; Each declared function in this interface should point to a conforming subroutine
;;; Callers should JSR into these subroutines unless otherwise noted!

; Synchronous GetByte subroutine
; `A` will contain the received byte
SerialGetByte := DuartGetByte

; Synchronous SendByte subroutine
; Sends the byte in `A` (which is preserved)
SerialSendByte := DuartSendByte

; Very fast macro for testing if a byte is available
; this is meant to be called in a tight loop
; `C` will be clear if there is a byte available, set if there is not
; NOTE: may destroy `A`!
.define SERIAL_BYTE_AVAIL   DUART_BYTE_AVAIL

.endif
