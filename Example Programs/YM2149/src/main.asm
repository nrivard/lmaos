.include "lmaos.inc"
.include "pseudoinstructions.inc"
.include "system.inc"
.include "via.inc"
.include "strings.inc"

.feature string_escapes

.code

VIA := N8BUS_PORT1

EnvShape := $A0

Main:
    JMP Init

.include "psg.asm"

Init:
    STZ EnvShape
    LDA #PSG_MODE_IDLE
    STA VIA+PERIPHERAL_CONTROL  ; make PSG idle first. CB2 and CA2 start at logic high
    STZ VIA+PORT_A
    STZ VIA+PORT_B
    LDA #$FF
    STA VIA+DDRA    ; make VIA_PORT_A all outputs
    STA VIA+DDRB    ; make VIA_PORT_B all outputs
@WriteToPSG:
    LDA #PSG_REG_MIXER          ; target mixer + i/o settings register
    LDX #$F8                   ; i/o ports are output, turn off all noise, turn on tone output
    JSR PSGWrite
@SetNotes:
    PSGSetFrequency PSG_REG_FREQ_A, 261
    PSGSetFrequency PSG_REG_FREQ_B, 392
    PSGSetFrequency PSG_REG_FREQ_C, 440
@SetLevels:
    LDA #PSG_REG_LVL_A
    LDX #(PSG_LVL_MODE_ENV | $08)
    JSR PSGWrite
    LDA #PSG_REG_LVL_B
    LDX #(PSG_LVL_MODE_ENV | $08)
    JSR PSGWrite
    LDA #PSG_REG_LVL_C
    LDX #(PSG_LVL_MODE_ENV | $08)
    JSR PSGWrite
@ReadFromPSG:
    LDA #PSG_REG_FREQ_A
    JSR PSGRead
    STA $2000
    LDA #PSG_REG_FREQ_A + 1
    JSR PSGRead
    STA $2001
@EnvFreq:
    ; PSGSetEnvelope EnvShape, $0001
    @SetFine:
    LDA #PSG_REG_ENV_FREQ
    LDX #<($FFFF)
    JSR PSGWrite
@SetRough:
    LDA #PSG_REG_ENV_FREQ + 1
    LDX #<($FFFF)
    JSR PSGWrite
@Loop:
    LDA #PSG_REG_ENV_SHAPE
    LDX EnvShape
    JSR PSGWrite
    JSR SerialGetByte
@CheckExit:
    CMP #(ASCII_ESCAPE)
    BEQ @Done
@CheckShape:
    CMP #('1')
    BNE @CheckIncSpeed
    INC EnvShape
    BRA @Loop
@CheckIncSpeed:
    CMP #('+')
    BNE @CheckDecreaseSpeed
@CheckDecreaseSpeed:
@Done:
    LDA #PSG_REG_MIXER
    LDX #$FF
    JSR PSGWrite
    RTS
