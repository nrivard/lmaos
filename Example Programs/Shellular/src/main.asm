.include "lmaos.inc"
.include "pseudoinstructions.inc"
.include "strings.inc"
.include "system.inc"

.org $0600

.feature string_escapes

FRAME_DELAY := 30

FontPtr := $A0
ShellCursorPos := $A2    ; word value for current cursor position

Main:
    JMP Init

SystemInterrupt: .res 2
CursorDelay:     .res 1
    
    .include "vdp.asm"
    .include "ascii.asm"

Init:
    LDA #<VDPDefaultRegisters
    LDX #>VDPDefaultRegisters
    JSR VDPInit
    JSR VDPClearVRAM
    JSR VRAMInit
@SetupIRQ:
    SEI
    LDA #FRAME_DELAY
    STA CursorDelay
    COPY16 InterruptVector, SystemInterrupt     ; preserve old value of the interrupt vector
    COPYADDR FrameInterrupt, InterruptVector
    CLI
@EnableDisplay:
    VDPRegisterSet CONTROL_2, (CONTROL_2_VRAM_16K | CONTROL_2_DISP_EN | CONTROL_2_MODE_TEXT)
    JSR VDPShell
@RestoreIRQ:
    SEI
    COPY16 SystemInterrupt, InterruptVector
    CLI
@Done:
    RTS

VRAMInit:
@Preamble:
    VDPVramAddrSet VDP_PATTERN_TABLE_START, 1
    COPYADDR FontStart, FontPtr
    LDY #0                      ; to get all 256 chars, we can copy 8 bytes 256 times
    LDX #8                      ; or copy 256 bytes 8 times :)
@WriteVRAMLoop:
    LDA (FontPtr), Y
    VDPVramPut
    INY
    BNE @WriteVRAMLoop
    DEX
    BEQ @Done
    INC FontPtr + 1
    BRA @WriteVRAMLoop
@Done:
    RTS

VDPShell:
@ShellPreamble:
    LDA #<(VDP_NAME_TABLE_START)
    STA ShellCursorPos
    LDA #>(VDP_NAME_TABLE_START)
    STA ShellCursorPos + 1
@ShellLoop:
    JSR VDPShellSetPos
    LDA #'_'
    VDPVramPut                  ; this is the cursor
    JSR SerialGetByte
    CMP #(ASCII_ESCAPE)
    BEQ @Done
    CMP #(ASCII_BACKSPACE)
    BEQ @HandleBS
@PrintChar:
    JSR VDPShellSetPos
    VDPVramPut
    INC16 ShellCursorPos
    BRA @ShellLoop
@HandleBS:
    JSR VDPShellSetPos
    LDA #' '
    VDPVramPut
    DEC16 ShellCursorPos
    BRA @ShellLoop
@Done:
    RTS

; sets VRAM ptr equal to current ShellCursorPos
VDPShellSetPos:
    PHA
@SetVRAMPtr:
    BIT VDP_BASE+REGISTERS          ; reset state machine in the VDP
    LDA ShellCursorPos
    STA VDP_BASE+REGISTERS
    VDPWait
    LDA ShellCursorPos + 1
    ORA #(VRAM_WR)
    STA VDP_BASE+REGISTERS
    VDPWait
@Done:
    PLA
    RTS

VDPShellUpdateCursor:
    PHA
    PHY
@CalculatePtr:
    TXA                         ; start with x position
    CLC
    ADC #<(VDP_NAME_TABLE_START)    ; add to the nametable start
    STA ShellCursorPos
    LDA #>(VDP_NAME_TABLE_START)
    STA ShellCursorPos + 1
    CPY #0                      ; bail early if y is zero
    BEQ @SetVRAMPtr
@RowLoop:
    ADD16 ShellCursorPos, 40   ; each row is 40 chars
    DEY
    BNE @RowLoop
@SetVRAMPtr:
    LDA ShellCursorPos
    STA VDP_BASE+REGISTERS
    JSR SerialSendByteAsString
    VDPWait
    LDA ShellCursorPos + 1
    ORA #(VRAM_WR)
    STA VDP_BASE+REGISTERS
    JSR SerialSendByteAsString
    VDPWait
@Done:
    PLY
    PLA
    RTS

FrameInterrupt:
    PHA
;     LDA SystemClockJiffies
;     CMP #(ClockRateHz)
;     BNE @Done
;     DEC Delay
;     BNE @Done
;     LDA #SECONDS_DELAY
;     STA Delay
; @AdvanceBG:
;     INC Colors
;     LDA Colors
;     VDPRegisterSet TEXT_COLOR
; @Done:
    PLA
    JMP (SystemInterrupt)