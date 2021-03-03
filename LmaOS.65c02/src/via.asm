; LmaOS
;
; Copyright Nate Rivard 2020

.ifndef VIA_ASM
VIA_ASM = 1

.include "via.inc"
.include "system.inc"

.code

VIA1Init:
    STZ VIA1_DDRA    ; make VIA_PORT_A all inputs
    STZ VIA1_DDRB    ; make VIA_PORT_B all inputs
    RTS

;;; Sets up the system clock
VIA1SetupSystemClock:
    ; setup aux control register and interrupt enable
    LDA VIA1_AUX_CONTROL
    AND #(VIA_TIMER1_CONTROL_MASK_PB7_ENABLE ^ $FF)
    ORA #(VIA_TIMER1_CONTROL_MASK_CONTINUOUS)
    STA VIA1_AUX_CONTROL
    LDA #(VIA_INTERRUPT_MASK_SET | VIA_INTERRUPT_MASK_TIMER1)
    STA VIA1_INTERRUPT_ENABLE

    ; set up timer interval
    LDA #<((MpuRateHz / ClockRateHz) - 2)
    STA VIA1_TIMER1_COUNTER_LOW
    LDA #>((MpuRateHz / ClockRateHz) - 2)
    STA VIA1_TIMER1_COUNTER_HIGH

    RTS

.endif