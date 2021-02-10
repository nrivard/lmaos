; LmaOS
;
; Copyright Nate Rivard 2020

.include "pseudoinstructions.inc"
.include "registers.inc"
.include "system.inc"
.include "via.inc"

.code

;;; interrupt router. This routine uses A but not any other registers, so subroutines 
;;; routed to will then have to push and pull any index registers
;;; In addition, any pseudo-registers MUST be pushed and restored
InterruptRouter:
    PHA
    LDA VIA1_INTERRUPT_FLAG
@InteruptClock:
    BIT VIA1_TIMER1_COUNTER_LOW     ; ACK the interrupt
    DEC SystemClockJiffies
    BNE @Done
    LDA #ClockRateHz
    STA SystemClockJiffies          ; reset jiffies
    INC16 SystemClockUptime
@Done:
    PLA
    RTI
