; LmaOS
;
; Copyright Nate Rivard 2020

.include "pseudoinstructions.inc"
.include "system.inc"
.include "vectors.inc"
.include "zeropage.inc"

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
@InitClock:
    LDA #ClockRateHz
    STA SystemClockJiffies
    STZ SystemClockUptime
    STZ SystemClockUptime + 1

    JSR VIA1SetupSystemClock

@SetupInterruptVector:
    ;;; copy system interrupt handler into the interrupt vector
    COPYADDR InterruptHandleSystemTimer, InterruptVector

    ;;; system clock is setup, turn on interrupts so they
    ;;; they start firing
    CLI

@DisplayBootStatus:
    LDA #(LCD_LINE2_START)
    JSR LCDMoveCursor
    LDA #<LmaOSBootDone
    LDX #>LmaOSBootDone
    JSR LCDPrintString
    
StartMonitor:
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
