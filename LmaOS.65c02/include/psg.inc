; LmaOS
;
; Copyright Nate Rivard 2023

.ifndef PSG_INC
PSG_INC = 1

.macro PSGSetFrequency register, freq
.local @SetFine, @SetRough
@SetFine:
    LDA #register
    LDX #<(VDPClockHz / (2 * 16 * freq))
    JSR PSGWrite
@SetRough:
    LDA #register + 1
    LDX #>(VDPClockHz / (2 * 16 * freq)) & $0F
    JSR PSGWrite
.endmacro

.macro PSGSetEnvelope shape, freq
.local @SetFine, @SetRough
@SetFine:
    LDA #PSG_REG_ENV_FREQ
    LDX #<(VDPClockHz / (2 * 256 * freq))
    JSR PSGWrite
@SetRough:
    LDA #PSG_REG_ENV_FREQ + 1
    LDX #>(VDPClockHz / (2 * 256 * freq))
    JSR PSGWrite
@SetShape:
    LDA #PSG_REG_ENV_SHAPE
    LDX shape
    JSR PSGWrite
.endmacro

; PCR values for the VIA
PSG_MODE_IDLE       := $CC
PSG_MODE_REG        := $EE
PSG_MODE_WR         := $EC
PSG_MODE_RD         := $CE

PSG_REG_FREQ_A      := $00      ; rough + fine freq for ch A
PSG_REG_FREQ_B      := $02      ; rough + fine freq for ch B
PSG_REG_FREQ_C      := $04      ; rough + fine freq for ch C
PSG_REG_FREQ_N      := $06      ; 5-bit noise freq
PSG_REG_MIXER       := $07
PSG_REG_LVL_A       := $08
PSG_REG_LVL_B       := $09
PSG_REG_LVL_C       := $0A
PSG_REG_ENV_FREQ    := $0B      ; rought + fine freq for envelope
PSG_REG_ENV_SHAPE   := $0D
PSG_REG_IO_A        := $0E
PSG_REG_IO_B        := $0F

; PSG volume level modes
PSG_LVL_MODE_FIXED  := $0 << 4
PSG_LVL_MODE_ENV    := $1 << 4

; Notetable (these are 16-bit, pre-converted values you can place directly in the rough and fine freq registers)
C_4            := $01B9

.endif
