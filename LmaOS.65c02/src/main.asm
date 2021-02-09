; LmaOS
;
; Copyright Nate Rivard 2020

.include "system.inc"
.include "vectors.inc"
.include "registers.inc"
.include "pseudoinstructions.inc"

.code

Main:
    LDX #$FF
    TXS

    ;;; initializes hardware
    JSR VIA1Init
    JSR ACIAInit
    
    LDA #$01
    STA VIA1_PORT_A
    
    ;;; initializes the system clock @100Hz (10 msec)
ClockInit:
    LDA #ClockRateHz
    STA SystemClockJiffies
    STZ SystemClockUptime
    STZ SystemClockUptime + 1

    JSR VIA1SetupSystemClock
    
    LDA VIA1_PORT_A
    ORA #$02
    STA VIA1_PORT_A
    
    ;;; system clock is setup, turn on interrupts so they
    ;;; they start firing
    CLI
    
    ;; debug crap
    LDA #$69
    STA $4000
    
    ;;; on startup, we jump into the monitor
    JSR MonitorStart
    
    STP
    
UnitTests:
    LDA #$FB
    JSR ByteToHexString
    STP
    
.segment "RODATA"

String1: .byte "rd 4", $00

.include "acia.asm"
.include "via.asm"
.include "strings.asm"
.include "interrupt.asm"
.include "monitor.asm"
