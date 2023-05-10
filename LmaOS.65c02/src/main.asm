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
.include "vdp.asm"
.include "via.asm"
.include "monitaur.asm"
.include "interrupt.asm"

.code

Main:
    SEI
    LDX #$FF
    TXS

InitVDP:
    LDA #<VDPDefaultRegisters
    LDX #>VDPDefaultRegisters
    JSR VDPInit
    JSR VDPClearVRAM
    JSR VDPCopyDefaultCharset
    VDPRegisterSet CONTROL_2, (CONTROL_2_VRAM_16K | CONTROL_2_DISP_EN | CONTROL_2_MODE_TEXT)
@BootString:
    VDPVramAddrSet VDP_NAME_TABLE_START, 1
    LDX #0
@Loop:
    LDA LmaOSBootText, X
    BEQ @Done
    VDPVramPut
    INX
    BRA @Loop
@Done:
    BIT VDP_BASE+REGISTERS      ; reset internal state


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
    
    ;;; initializes the system clock @100Hz (10 msec)
InitClock:
    LDA #ClockRateHz
    STA SystemClockJiffies
    STZ SystemClockUptime
    STZ SystemClockUptime + 1
    JSR DuartInit

SetupInterruptVector:
    ;;; copy system interrupt handler into the interrupt vector
    COPYADDR InterruptHandleSystemTimer, InterruptVector

    ;;; system clock is setup, turn on interrupts so they start firing
    CLI

FinishBootString:
    BIT VDP_BASE+REGISTERS      ; reset internal state
    VDPVramAddrSet VDP_NAME_TABLE_START + (LmaosBootTextEnd - LmaOSBootText - 1), 1
    LDX #0
@Loop:
    LDA LmaOSBootDone, X
    BEQ @Done
    VDPVramPut
    INX
    BRA @Loop
@Done:
    BIT VDP_BASE+REGISTERS

    
StartMonitor:
    ;;; on startup, we jump into the monitor
    JSR MonitorStart

.segment "RODATA"

LmaOSBootText: .asciiz "Booting up..."
LmaosBootTextEnd:

LmaOSBootDone: .asciiz "Done."
