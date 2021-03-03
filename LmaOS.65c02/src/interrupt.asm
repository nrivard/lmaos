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
;;; In addition, any pseudo-registers MUST be pushed and restored
InterruptHandleSystemTimer:
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
