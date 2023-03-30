; LmaOS
;
; Copyright Nate Rivard 2023

.ifndef VDP_INC
VDP_INC = 1

VDP_BASE := N8BUS_PORT0

; register offsets for the VDP
VRAM            := $0
REGISTERS       := $1                   ; writing: 8 registers accessible. reading: status register is available

; Register masks
REG_WR          := $80                  ; used to write to a register
VRAM_WR         := $40                  ; used to write to vram

; Register indices
CONTROL_1       := $0
CONTROL_2       := $1
NAME_TABLE      := $2
COLOR_TABLE     := $3
PATTERN_TABLE   := $4
SPR_ATTR_TABLE  := $5
SPR_PTRN_TABLE  := $6
TEXT_COLOR      := $7

; control register 1 masks
CONTROL_1_MODE_GFX_1    := %0 << 1
CONTROL_1_MODE_GFX_2    := %1 << 1
CONTROL_1_MODE_MULTI    := %0 << 1
CONTROL_1_MODE_TEXT     := %0 << 1

; control register 2 masks
CONTROL_2_MODE_GFX_1    := %00 << 3
CONTROL_2_MODE_GFX_2    := %00 << 3
CONTROL_2_MODE_MULTI    := %01 << 3
CONTROL_2_MODE_TEXT     := %10 << 3

CONTROL_2_VRAM_16K      := %10000000
CONTROL_2_DISP_EN       := %01000000
CONTROL_2_INT_EN        := %00100000
CONTROL_2_SPR_SIZE_2X   := %00000010
CONTROL_2_SPR_ZOOM      := %00000001

; table start multipliers. Divide your intended VRAM address by these
; to get the appropriate register values
NAME_TABLE_MULT         := $0400
COLOR_TABLE_MULT        := $0040
PATTERN_TABLE_MULT      := $0800
SPR_ATTR_TABLE_MULT     := $0080
SPR_PATTERN_TABLE_MULT  := $0800

; status register masks
STATUS_FRAME_FLAG       := %10000000
STATUS_SPR_5TH          := %01000000
STATUS_SPR_COLLISION    := %00100000
STATUS_5TH_SPR_NUM      := %00011111            ; ANDing STATUS with this mask will give you the index to the 5th sprite (not displayed)

; colors :)
COLOR_CLR       := $0
COLOR_BLK       := $1
COLOR_GRN_MED   := $2
COLOR_GRN_LT    := $3
COLOR_BLU_DK    := $4
COLOR_BLU_LT    := $5
COLOR_RED_DK    := $6
COLOR_CYAN      := $7
COLOR_RED_MED   := $8
COLOR_RED_LT    := $9
COLOR_YEL_DK    := $A
COLOR_YEL_LT    := $B
COLOR_GRN_DK    := $C
COLOR_MAG       := $D
COLOR_GRAY      := $E
COLOR_WHITE     := $F

.struct SpriteAttr
    yPos            .byte
    xPos            .byte
    patternIndex    .byte
    color           .byte       ; low nibble contains color. high bit contains EARLY_CLOCK
.endstruct

SPRITE_ATTR_EARLY_CLOCK := %10000000

; waits 2µs, the non-active display max wait time
; these routines are based on 3.6874Mhz so each cycle is just over .25µs
; each NOP is 2 cycles. at ~3.6Mhz, NOP is .5µs
.macro VDPWait
    NOP
    NOP
    NOP
    NOP
.endmacro

; imm is an optional immediate value. if not provided, it's assumed data is already in A
.macro VDPRegisterSet register, imm
.ifnblank imm
    LDA #(imm)
.endif
    STA VDP_BASE+REGISTERS
    VDPWait
    LDA #(register | REG_WR)
    STA VDP_BASE+REGISTERS
    VDPWait
.endmacro

.macro VDPVramAddrSet addr, isWrite
    LDA #<(addr)
    STA VDP_BASE+REGISTERS
.if isWrite
    LDA #>(addr) | VRAM_WR
.else
    LDA #>(addr)
.endif
    STA VDP_BASE+REGISTERS
.endmacro

; byte to send to VRAM should be in A
.macro VDPVramPut
    STA VDP_BASE+VRAM
    VDPWait
.endmacro

; read byte from VRAM and put in A
.macro VDPVramGet
    LDA VDP_BASE+VRAM
    VDPWait
.endmacro

.endif
