; LmaOS
;
; Copyright Nate Rivard 2020

.ifndef VIA_INC
VIA_INC = 1

;;; VIA Addresses

VIA_BASE := N8BUS_PORT0

PORT_B := $0
PORT_A := $1
DDRB := $2
DDRA := $3
TIMER1_COUNTER_LOW := $4
TIMER1_COUNTER_HIGH := $5
TIMER1_LATCH_LOW := $6
TIMER1_LATCH_HIGH := $7
TIMER2_COUNTER_LOW := $8
TIMER2_COUNTER_HIGH := $9
SHIFT := $A
AUX_CONTROL := $B
PERIPHERAL_CONTROL := $C
;;; reading counter-low or writing latch-high will reset the interrupt
INTERRUPT_FLAG := $D
INTERRUPT_ENABLE := $E
PORT_A_HANDSHAKE_FREE := $F

;;; Masks and constants

;; enables continuous output. if `0`, timer is in one-shot mode
VIA_TIMER1_CONTROL_MASK_CONTINUOUS = %01000000
;; enables output on PB7. `0` means interrupt-only
VIA_TIMER1_CONTROL_MASK_PB7_ENABLE = %10000000
;; enables continuous output on PB6. `0` means interrupt-only one-shot mode
VIA_TIMER2_CONTROL_MASK_CONTINUOUS = %00100000

VIA_INTERRUPT_MASK_IRQ = $80     ; same as below but for use with INTERRUPT_FLAG
VIA_INTERRUPT_MASK_SET = $80     ; same as above but for use with INTERRUPT_ENABLE
VIA_INTERRUPT_MASK_TIMER1 = $40
VIA_INTERRUPT_MASK_TIMER2 = $20
VIA_INTERRUPT_MASK_CB1 = $10
VIA_INTERRUPT_MASK_CB2 = $08
VIA_INTERRUPT_MASK_SHIFT = $04
VIA_INTERRUPT_MASK_CA1 = $02
VIA_INTERRUPT_MASK_CA2 = $01

.endif
