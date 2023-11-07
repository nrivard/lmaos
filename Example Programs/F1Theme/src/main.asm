.include "lmaos.inc"
.include "pseudoinstructions.inc"
.include "system.inc"
.include "via.inc"
.include "strings.inc"
.include "vdp.inc"
.include "duart.inc"

.feature string_escapes

.code

VIA := N8BUS_PORT1

Main:
    JMP Init

.include "psg.asm"

SystemInterrupt:    .res 2
ChordDuration:      .res 1      ; chords last 1 sec, aka 60 frames
ChordCount:         .res 1      ; chords are played twice
ChordIndex:         .res 1      ; where in the song we are

Init:
    STZ ChordIndex
    STZ ChordDuration

    SEI
@SetupIRQ:
    DUART_IRQ_DISABLE           ; use VSYNC frames instead of built-in timer
    COPY16 InterruptVector, SystemInterrupt
    COPYADDR FrameInterrupt, InterruptVector
@EnableFrameInterrupts:
    BIT VDP_BASE+REGISTERS                      ; clear INT line
    VDPRegisterSet CONTROL_2, (CONTROL_2_VRAM_16K | CONTROL_2_INT_EN)   ; enable interrupts
@SetupVIA:
    LDA #PSG_MODE_IDLE
    STA VIA+PERIPHERAL_CONTROL  ; make PSG idle first. CB2 and CA2 start at logic high
    STZ VIA+PORT_A
    STZ VIA+PORT_B
    LDA #$FF
    STA VIA+DDRA               ; make VIA_PORT_A all outputs
    STA VIA+DDRB               ; make VIA_PORT_B all outputs
@SetupPSG:
    LDA #PSG_REG_MIXER         ; target mixer + i/o settings register
    LDX #$F9                   ; i/o ports are output, turn off all noise, turn on tone output
    JSR PSGWrite
    LDA #PSG_REG_LVL_B
    LDX #$0A
    JSR PSGWrite
    LDA #PSG_REG_LVL_C
    LDX #$0A
    JSR PSGWrite
    CLI
@PlaySong:
    JSR SongLoop
@RestoreIRQ:
    SEI
    BIT VDP_BASE+REGISTERS           ; clear INT line
    VDPRegisterSet CONTROL_2, (CONTROL_2_VRAM_16K | CONTROL_2_MODE_TEXT)    ; turn off INTs and display
    COPY16 SystemInterrupt, InterruptVector
    DUART_IRQ_ENABLE
    CLI
@Done:
    LDA #PSG_REG_MIXER
    LDX #$FF                    ; turn all sound output off
    JSR PSGWrite
    RTS

SongLoop:
    SEI
    DUART_BYTE_AVAIL
    BCS @NextFrame
    JSR SerialGetByte
    CMP #(ASCII_ESCAPE)
    BEQ @Done
@NextFrame:
    CLI
    WAI
    BRA SongLoop
@Done:
    CLI
    RTS

FrameInterrupt:
    PHA
    PHY
    PHX
    BIT VDP_BASE+REGISTERS      ; clear IRQ request
@CheckDuration:
    LDA ChordDuration
    BEQ @PlayChord
    DEC ChordDuration
    BRA @Done
@PlayChord:
    LDA #60
    STA ChordDuration
    LDY ChordIndex
@ChB:
    LDA #PSG_REG_FREQ_B         ; lower bits of Ch B
    LDX ChB, Y
    JSR PSGWrite
    LDA #PSG_REG_FREQ_B + 1     ; upper bits of Ch B
    LDX ChB + 1, Y
    JSR PSGWrite
@ChC:
    LDA #PSG_REG_FREQ_C         ; lower bits of Ch C
    LDX ChC, Y
    JSR PSGWrite
    LDA #PSG_REG_FREQ_C + 1     ; upper bits of Ch C
    LDX ChC + 1, Y
    JSR PSGWrite
    INY
    INY
@CheckMax:
    CPY #(4 * 2)                ; length of our song
    BNE @WriteChordIndex
    LDY #0
@WriteChordIndex:
    STY ChordIndex
@Done:
    PLX
    PLY
    PLA
    RTI

; melody
ChA:
    .word D__+4

; rhythm chords
ChB:
    .word A__+5, Bb_+5, C__+6, B__+5
ChC:
    .word F__+5, F__+5, F__+6, G__+5



Scale:
    ;     oct   1      2      3      4      5      6      7      8
 C__:   .word $0D5D, $06AF, $0357, $01AC, $00D6, $006B, $0035, $001B	; C
 Csh:   .word $0C9C, $064E, $0327, $0194, $00CA, $0065, $0032, $0019	; C# / Db
 D__:   .word $0BE7, $05F4, $02FA, $017D, $00BE, $005F, $0030, $0018	; D
 Dsh:   .word $0B3C, $059E, $02CF, $0168, $00B4, $005A, $002D, $0016	; D# / Eb
 E__:   .word $0A9B, $054E, $02A7, $0153, $00AA, $0055, $002A, $0015	; E
 F__:   .word $0A02, $0501, $0281, $0140, $00A0, $0050, $0028, $0014	; F
 Fsh:   .word $0973, $04BA, $025D, $012E, $0097, $004C, $0026, $0013	; F# / Gb
 G__:   .word $08EB, $0476, $023B, $011D, $008F, $0047, $0024, $0012	; G
 Gsh:   .word $086B, $0436, $021B, $010D, $0087, $0043, $0022, $0011	; G# / Ab
 A__:   .word $07F2, $03F9, $01FD, $00FE, $007F, $0040, $0020, $0010	; A
 Bb_:   .word $0780, $03C0, $01E0, $00F0, $0078, $003C, $001E, $000F	; A# / Bb
 B__:   .word $0714, $038A, $01C5, $00E3, $0071, $0039, $001C, $000E	; B
