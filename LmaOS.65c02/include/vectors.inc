; LmaOS
;
; Copyright Nate Rivard 2020

.ifndef VECTORS_INC
VECTORS_INC = 1

.segment "VECTORS"

.addr InterruptRouter ;; NMI (Non-maskable interrupt) vector
.addr Main ;; RESET vector
.addr InterruptRouter ;; IRQ (Interrupt) vector

.endif
