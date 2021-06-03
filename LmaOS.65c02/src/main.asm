; LmaOS
;
; Copyright Nate Rivard 2020

.include "pseudoinstructions.inc"
.include "strings.inc"
.include "system.inc"
.include "vectors.inc"
.include "zeropage.inc"

.include "acia.asm"
.include "via.asm"
.include "interrupt.asm"
; .include "monitaur.asm"
; .include "lcd1602.asm"

.code

Main:
    LDX #$FF
    TXS

; debug
    COPYADDR 0, r0
    LDA #<r0
    LDX #>r0
    JSR DebugPrint

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

; debug
    LDA #<SystemRAMCapacity
    LDX #>SystemRAMCapacity
    JSR DebugPrint

    ;;; initializes hardware
    JSR VIAInit
    JSR ACIAInit
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
    JSR VIASetupSystemClock

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
    
; StartMonitor:
;     ;;; on startup, we jump into the monitor
;     JSR MonitorStart

ACIATest:
    JSR ACIAGetByte                 ; just wait for connection and throw away what we receive
    LDA #(ASCII_CARRIAGE_RETURN)
    JSR ACIASendByte
@TestLoop:
    JSR ACIAGetByte
    JSR ACIASendByte                ; echo
    STA N8BUS_PORT3                 ; send byte to arduino
    STZ N8BUS_PORT3                 ; 0 for high byte to arduino
    LDA #(ASCII_CARRIAGE_RETURN)
    JSR ACIASendByte
    LDX #0
@PrintLoop:
    LDA Huh, X
    BEQ ACIATest
    JSR ACIASendByte
    INX
    BRA @PrintLoop

; prints the 16 bit value to n8 bus port 3 at passed in pointer
; A: low byte of pointer
; X: high byte of pointer
DebugPrint:
    PHY
    STA r0
    STX r0 + 1
@Print:
    LDY #0
    LDA (r0), Y
    STA N8BUS_PORT3
    INY
    LDA (r0), Y
    STA N8BUS_PORT3
@Done:
    PLY
    RTS

.segment "RODATA"

Huh: .asciiz "Huh?"
; LmaOSBootText: .asciiz "Booting up..."
; LmaOSBootDone: .asciiz "Done."
