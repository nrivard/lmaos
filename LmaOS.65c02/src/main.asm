; LmaOS
;
; Copyright Nate Rivard 2020

.include "pseudoinstructions.inc"
.include "strings.inc"
.include "system.inc"
.include "vectors.inc"
.include "zeropage.inc"

.include "serial.asm"
.include "duart.asm"
.include "via.asm"
.include "monitaur.asm"
.include "lcd1602.asm"
.include "interrupt.asm"

.code

Main:
    SEI
    LDX #$FF
    TXS

; do NOT JSR to this routine, it overwrites _all_ of RAM to test it, including the stack
RamTestPointer := r0
RamTest:
    COPYADDR r1, RamTestPointer
    LDY #<r1                    ; test data (Y contents) should always match low byte of the address
@TestLoop:
    TYA
    STA (RamTestPointer)
    CMP (RamTestPointer)
    BNE @TestDone
    INC16 RamTestPointer
    BEQ @TestDone               ; never taken. if this is taken, it means we have no ROM
    INY                         ; bc it completely looped around the address space
    BRA @TestLoop
@TestDone:
    LDA RamTestPointer
    STA SystemRAMCapacity
    LDA RamTestPointer + 1
    STA SystemRAMCapacity + 1

    ;;; initializes hardware
;     JSR LCDInit
    
;     LDA #<LmaOSBootText
;     LDX #>LmaOSBootText
;     JSR LCDPrintString
    
    ;;; initializes the system clock @100Hz (10 msec)
@InitClock:
    LDA #ClockRateHz
    STA SystemClockJiffies
    STZ SystemClockUptime
    STZ SystemClockUptime + 1
    JSR DuartInit

@SetupInterruptVector:
    ;;; copy system interrupt handler into the interrupt vector
    COPYADDR InterruptHandleSystemTimer, InterruptVector

    ;;; system clock is setup, turn on interrupts so they start firing
    CLI

; @DisplayBootStatus:
;     LDA #(LCD_LINE2_START)
;     JSR LCDMoveCursor
;     LDA #<LmaOSBootDone
;     LDX #>LmaOSBootDone
;     JSR LCDPrintString
    
StartMonitor:
    ;;; on startup, we jump into the monitor
    JSR MonitorStart

.segment "RODATA"

; LmaOSBootText: .asciiz "Booting up..."
; LmaOSBootDone: .asciiz "Done."
