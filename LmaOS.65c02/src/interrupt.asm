; LmaOS
;
; Copyright Nate Rivard 2020

.export InterruptRouter, InterruptHandleSystemTimer

.code

;;; interrupt router. It's sole function is to jump to the address
;;; contained in `InterruptVector`. If you change this value, you need to either:
;;; • `JMP` to `InterruptHandleSystemTimer` from your custom interrupt handler which 
;;;    will make the `RTI` call
;;; • Call `RTI` yourself if you handled the interrupt
InterruptRouter:
    JMP (InterruptVector)

;;; This routine uses A but not any other registers, so subroutines 
;;; routed to will then have to push and pull any index registers
;;; In addition, do _NOT_ use pseudoregisters in interrupt routines
InterruptHandleSystemTimer:
    PHA
    LDA VIA_BASE+INTERRUPT_FLAG
@InteruptClock:
    BIT VIA_BASE+TIMER1_COUNTER_LOW     ; ACK the interrupt
    DEC SystemClockJiffies
    BNE @Done
    LDA #ClockRateHz                    ; reset jiffies
    STA SystemClockJiffies
    INC16 SystemClockUptime
@Done:
    PLA
    RTI
