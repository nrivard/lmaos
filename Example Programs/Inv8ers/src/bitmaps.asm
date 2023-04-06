; LmaOS
;
; Copyright Nate Rivard 2022

.ifndef BITMAPS_ASM
BITMAPS_ASM = 1

; bg tiles
Space    := $00
CrabLeft := $02
CrabRight := $03
SquidLeft := $04
SquidRight := $05
OctoLeft := $06
OctoRight := $07

; sprites
XwingLeft := $00
XwingRight := $01

PatternsStart:
    
    .byte $0, $0, $0, $0, $0, $0, $0, $0
    .byte $0, $0, $0, $0, $0, $0, $0, $0
    .byte $04, $12, $17, $1D, $1F, $0F, $04, $08    ; crab, normal, left
    .byte $10, $24, $F4, $DC, $FC, $F8, $10, $08    ; crab, normal, right
    .byte $01, $03, $07, $0D, $0F, $02, $05, $0A    ; squid, normal, left
    .byte $80, $C0, $E0, $B0, $F0, $40, $A0, $50    ; squid, normal, right
    .byte $03, $1F, $3F, $39, $3F, $06, $0D, $30    ; octopus, normal, left
    .byte $C0, $F8, $FC, $9C, $FC, $60, $B0, $0C    ; octopus, normal, right


PatternsEnd:

SpritePatternsStart:
    .byte $01, $03, $03, $83, $87, $87, $FF, $FF
    .byte $80, $C0, $C0, $C1, $E1, $E1, $FF, $FF
    .byte $00, $18, $18, $18, $18, $18, $18, $00    ; lazer
SpritePatternsEnd:

.endif
