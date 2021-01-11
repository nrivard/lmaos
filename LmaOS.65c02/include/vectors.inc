; LmaOS
;
; Copyright Nate Rivard 2020

.segment "VECTORS"

.addr InterruptRouter ;; NMI (Non-maskable interrupt) vector
.addr Main ;; RESET vector
.addr InterruptRouter ;; IRQ (Interrupt) vector
