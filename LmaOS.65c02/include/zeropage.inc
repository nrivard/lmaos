; LmaOS
;
; Copyright Nate Rivard 2020

;;; Synthetic 16-bit registers in ZP

.ifndef REGISTERS_INC
REGISTERS_INC = 1

.exportzp r0, r1, r2, r3, r4, r5, r6, r7, SystemClockJiffies, SystemClockUptime, SystemRAMCapacity, InterruptVector

.zeropage

r0: .res 2
r1: .res 2
r2: .res 2
r3: .res 2
r4: .res 2
r5: .res 2
r6: .res 2

; return values should start here and work backwards
r7: .res 2

; system uptime
SystemClockJiffies: .res 1
SystemClockUptime: .res 2

; verified RAM capacity, as measured at startup
SystemRAMCapacity: .res 2

; interrupt handler vector. you can overwrite this to handle your own interrupts.
;
; NOTE: be sure to call the original interrupt handler (See `InterruptRouter` in `lmaos.inc`)
; if the interrupt was not handled in your routine.
;
; NOTE 2: you are responsible for being a good system citizen! Be fast and preserve register values
; before calling the system vector handler (or `RTI` if you fully took care of the interrupt)
;
; ex:
; CustomInterruptHandler:
;   BIT N8BUS_PORT_1                    ; custom hardware on port 1
;   BPL @Unhandled
; @HandleInterrupt:
;   ;; do some work to ack the interrupt and process it quickly
;   RTI
; @Unhandled:
;   JMP InterruptHandleSystemTimer      ; let the system handle it
InterruptVector: .res 2

.endif
