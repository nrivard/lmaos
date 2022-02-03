; LmaOS
;
; Copyright Nate Rivard 2020

.ifndef VIA_ASM
VIA_ASM = 1

.include "via.inc"

.code

VIAInit:
    STZ VIA_BASE+PORT_A
    STZ VIA_BASE+PORT_B
    LDA #$FF
    STA VIA_BASE+DDRA    ; make VIA_PORT_A all outputs
    STA VIA_BASE+DDRB    ; make VIA_PORT_B all outputs
    RTS

;;; Sets up the system clock
VIASetupSystemClock:
    LDA VIA_BASE+AUX_CONTROL                                    ; load existing AUX control
    AND #(VIA_TIMER1_CONTROL_MASK_PB7_ENABLE ^ $FF)             ; clear PB7 enable bit
    ORA #(VIA_TIMER1_CONTROL_MASK_CONTINUOUS)                   ; turn on continuous
    STA VIA_BASE+AUX_CONTROL
    LDA #(VIA_INTERRUPT_MASK_SET | VIA_INTERRUPT_MASK_TIMER1)
    STA VIA_BASE+INTERRUPT_ENABLE

    ; set up timer interval
    LDA #<((MpuRateHz / ClockRateHz) - 2)
    STA VIA_BASE+TIMER1_COUNTER_LOW
    LDA #>((MpuRateHz / ClockRateHz) - 2)
    STA VIA_BASE+TIMER1_COUNTER_HIGH

    RTS

.endif
