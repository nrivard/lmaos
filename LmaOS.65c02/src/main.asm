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
    JSR LCDInit
    
    LDA #<LmaOSBootText
    LDX #>LmaOSBootText
    JSR LCDPrintString
    
    ;;; initializes the system clock @100Hz (10 msec)
ClockInit:
    LDA #ClockRateHz
    STA SystemClockJiffies
    STZ SystemClockUptime
    STZ SystemClockUptime + 1

    JSR VIA1SetupSystemClock
    
    ;;; system clock is setup, turn on interrupts so they
    ;;; they start firing
    CLI

    LDA #(LCD_LINE2_START)
    JSR LCDMoveCursor
    LDA #<LmaOSBootDone
    LDX #>LmaOSBootDone
    JSR LCDPrintString
    
    ;;; on startup, we jump into the monitor
    JSR MonitorStart

.include "acia.asm"
.include "via.asm"
.include "interrupt.asm"
.include "monitaur.asm"
.include "lcd1602.asm"

.segment "RODATA"

LmaOSBootText: .asciiz "Booting up..."
LmaOSBootDone: .asciiz "Done."