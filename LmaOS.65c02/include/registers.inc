; LmaOS
;
; Copyright Nate Rivard 2020

;;; Synthetic 16-bit registers in ZP

.ifndef REGISTERS_INC
REGISTERS_INC = 1

.exportzp r0, r1, r2, r3, r4, r5, r6, r7, SystemClockJiffies, SystemClockUptime

.zeropage

r0: .res 2
r1: .res 2
r2: .res 2
r3: .res 2
r4: .res 2
r5: .res 2
r6: .res 2

;; return values should start here and work backwards
r7: .res 2

;;; system uptime
SystemClockJiffies: .res 1
SystemClockUptime: .res 2

.endif
