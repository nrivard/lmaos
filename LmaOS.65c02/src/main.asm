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
	
	;;; on startup, we jump into the monitor
	JSR MonitorStart
    
    STP
    
UnitTests:
	COPYADDR String1, r0
	COPYADDR String2, r1
	LDY #$04
	JSR StringCompareN
	STP
	
.segment "RODATA"

String1: .asciiz "1234"
String2: .asciiz "12345"

.include "acia.asm"
.include "via.asm"
.include "strings.asm"
.include "interrupt.asm"
.include "monitor.asm"
