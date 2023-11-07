; LmaOS
;
; Copyright Nate Rivard 2023

.ifndef PSG_ASM
PSG_ASM = 1

.include "psg.inc"
.include "via.inc"

; A: register number
; X: value to write
PSGWrite:
    PHA
@SetRegister:
    STA VIA+PORT_A
    LDA #PSG_MODE_REG
    STA VIA+PERIPHERAL_CONTROL
    LDA #PSG_MODE_IDLE
    STA VIA+PERIPHERAL_CONTROL
@WriteData:
    TXA
    STA VIA+PORT_A
    LDA #PSG_MODE_WR
    STA VIA+PERIPHERAL_CONTROL
    LDA #PSG_MODE_IDLE
    STA VIA+PERIPHERAL_CONTROL
@Done:
    PLA
    RTS

; A: register number to read
; read value will be returned back in A
PSGRead:
@SetRegister:
    STA VIA+PORT_A
    LDA #PSG_MODE_REG
    STA VIA+PERIPHERAL_CONTROL
    LDA #PSG_MODE_IDLE
    STA VIA+PERIPHERAL_CONTROL
@SetPortAsInput:
    LDA #0
    STA VIA+DDRA
@ReadData:
    LDA #PSG_MODE_RD
    STA VIA+PERIPHERAL_CONTROL
    LDA VIA+PORT_A                  ; read from PSG
    PHA                             ; save the value
    LDA #PSG_MODE_IDLE
    STA VIA+PERIPHERAL_CONTROL
@SetPortAsOutput:
    LDA #$FF
    STA VIA+DDRA
@Done:
    PLA
    RTS

.endif