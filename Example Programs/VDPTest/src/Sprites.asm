.include "vdp.inc"
.include "lmaos.inc"

; VRAM locations for various tables
SpritesTestPatternTable        := $0000
SpritesTestNameTable           := $0800
SpritesTestSpriteAttributes    := $1000
SpritesTestSpritePatterns      := $2400
SpritesTestColorTable          := $2000

SpritesTest:
    LDA #<(SpritesTestRegisterTable)
    LDX #>(SpritesTestRegisterTable)
    JSR VDPInit
    JSR VDPClearVRAM
    JSR SpritesTestInitVRAM
@EnableDisplay:
    BIT VDP_BASE+REGISTERS                      ; clear INT line
    VDPRegisterSet CONTROL_2, (CONTROL_2_VRAM_16K | CONTROL_2_DISP_EN | CONTROL_2_MODE_GFX_1)
    CLI
@Loop:
    SEI
    DUART_BYTE_AVAIL
    BCS @Loop
    JSR SerialGetByte
    CMP #(ASCII_ESCAPE)
    BEQ @Done
@NextFrame:
    CLI
    WAI
    BRA @Loop
@Done:
    RTS

SpritesTestInitVRAM:
; Skip nametable bc we are only using pattern 0 which was done when we cleared VRAM
@PatternData:
    VDPVramAddrSet SpritesTestPatternTable, 1
    COPYADDR SpritesTestPatternData, r0
    COPYADDR (SpritesTestPatternDataEnd - SpritesTestPatternData), r1
    JSR VDPVramPutN
@ColorData:
    VDPVramAddrSet SpritesTestColorTable, 1
    LDA #(COLOR_GRN_LT << 4 | COLOR_BLK)    ; we are only using pattern 0, so only one entry in color table is required
    VDPVramPut
@SpritePatternData:
    VDPVramAddrSet SpritesTestSpritePatterns, 1
    COPYADDR SpritesTestSprPtrnData, r0
    COPYADDR (SpritesTestSprPtrnDataEnd - SpritesTestSprPtrnData), r1
    JSR VDPVramPutN
@SpriteAttrData:
    VDPVramAddrSet SpritesTestSpriteAttributes, 1
    COPYADDR SpritesTestSprAttrData, r0
    COPYADDR (SpritesTestSprAttrDataEnd - SpritesTestSprAttrData), r1
    JSR VDPVramPutN
@Done:
    RTS

; our test data starts here
SpritesTestRegisterTable:
    .byte (CONTROL_1_MODE_GFX_1)
    .byte (CONTROL_2_VRAM_16K | CONTROL_1_MODE_GFX_1)
    .byte (SpritesTestNameTable / NAME_TABLE_MULT)
    .byte (SpritesTestColorTable / COLOR_TABLE_MULT)
    .byte (SpritesTestPatternTable / PATTERN_TABLE_MULT)
    .byte (SpritesTestSpriteAttributes / SPR_ATTR_TABLE_MULT)
    .byte (SpritesTestSpritePatterns / SPR_PATTERN_TABLE_MULT)
    .byte (COLOR_CLR << 4 | COLOR_BLK)

; we want to fill the canvas with one color and let background function as a border to so we can see where sprites
; are placed. all tiles will be zeroed out so put in a single all-on pattern for the tiles
SpritesTestPatternData:
    .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
SpritesTestPatternDataEnd:

; treat as sprite attr structs
SpritesTestSprAttrData:
    .byte $FF, $00, $00, COLOR_MAG          ; top left corner
    .byte $F7, $08, $00, COLOR_MAG          ; above active area
    .byte $B6, $00, $00, COLOR_MAG          ; bottom left corner
    .byte $BE, $10, $00, COLOR_MAG          ; below active area
    .byte $80, $FF, $00, COLOR_MAG          ; beyond rightmost active area
    .byte $88, $18, $00, SPRITE_ATTR_EARLY_CLOCK | COLOR_MAG    ; beyond leftomost active area
    .byte $D1, $00, $00, COLOR_MAG          ; beyond the disable flag special value (should have no effect)
    .byte $7C, $7C, $00, COLOR_BLU_DK       ; this should be visible!
    .byte $D0, $00, $00, COLOR_MAG          ; this should disable all subsequent sprites
    .byte $CC, $CC, $00, COLOR_GRAY         ; this should NOT be visible!
SpritesTestSprAttrDataEnd:

; our pattern is a center box with a border
SpritesTestSprPtrnData:
    .byte %11111111
    .byte %10000001
    .byte %10000001
    .byte %10011001
    .byte %10011001
    .byte %10000001
    .byte %10000001
    .byte %11111111
SpritesTestSprPtrnDataEnd:
