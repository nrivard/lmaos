; LmaOS
;
; Copyright Nate Rivard 2022

.ifndef BITMAPS_ASM
BITMAPS_ASM = 1

; bg tiles
Dead    := $00
Aliv    := $01

PatternsStart:
    ; green on black
    .byte $00, $00, $00, $00, $00, $00, $00, $00    ; dead
    .byte $00, $7F, $7F, $7F, $7F, $7F, $7F, $7F    ; alive
PatternsEnd:

NamesStart:
    .byte "Conway's Game of Life v01", $00, $00, $00, $00, $00, $00, $00 ; string is 25 bytes

    ; padding
    ; row 1 (interior)
    .byte 0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    ; row 2
    .byte 0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    ; row 3
    .byte 0,0,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

    .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0
    .byte 0,0,0,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

    .byte "0000 Generations",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
NamesEnd:

ColorsStart:
    .byte (COLOR_GRN_LT << 4 | COLOR_BLK)
    .byte (COLOR_WHITE << 4 | COLOR_BLK)
    .byte (COLOR_WHITE << 4 | COLOR_BLK)
    .byte (COLOR_WHITE << 4 | COLOR_BLK)
    .byte (COLOR_WHITE << 4 | COLOR_BLK)
    .byte (COLOR_WHITE << 4 | COLOR_BLK)
    .byte (COLOR_WHITE << 4 | COLOR_BLK)
    .byte (COLOR_WHITE << 4 | COLOR_BLK)
    .byte (COLOR_WHITE << 4 | COLOR_BLK)
    .byte (COLOR_WHITE << 4 | COLOR_BLK)
    .byte (COLOR_WHITE << 4 | COLOR_BLK)
    .byte (COLOR_WHITE << 4 | COLOR_BLK)
    .byte (COLOR_WHITE << 4 | COLOR_BLK)
    .byte (COLOR_WHITE << 4 | COLOR_BLK)
    .byte (COLOR_WHITE << 4 | COLOR_BLK)
    .byte (COLOR_WHITE << 4 | COLOR_BLK)
    .byte (COLOR_WHITE << 4 | COLOR_BLK)
    .byte (COLOR_WHITE << 4 | COLOR_BLK)
    .byte (COLOR_WHITE << 4 | COLOR_BLK)
    .byte (COLOR_WHITE << 4 | COLOR_BLK)
    .byte (COLOR_WHITE << 4 | COLOR_BLK)
    .byte (COLOR_WHITE << 4 | COLOR_BLK)
    .byte (COLOR_WHITE << 4 | COLOR_BLK)
    .byte (COLOR_WHITE << 4 | COLOR_BLK)
    .byte (COLOR_WHITE << 4 | COLOR_BLK)
    .byte (COLOR_WHITE << 4 | COLOR_BLK)
    .byte (COLOR_WHITE << 4 | COLOR_BLK)
    .byte (COLOR_WHITE << 4 | COLOR_BLK)
    .byte (COLOR_WHITE << 4 | COLOR_BLK)
    .byte (COLOR_WHITE << 4 | COLOR_BLK)
    .byte (COLOR_WHITE << 4 | COLOR_BLK)
    .byte (COLOR_WHITE << 4 | COLOR_BLK)
ColorsEnd:

SpriteAttrs:
    .byte SPRITE_DISABLE_Y_POS, $00, $00, $00
SpriteAttrsEnd:

.endif
