; LmaOS
;
; Copyright Nate Rivard 2020

.ifndef SDCARD_INC
SDCARD_INC = 1

; set these to the appropriate VIA port addresses
SDCARD_VIA_PORT := VIA_BASE+PORT_B
SDCARD_VIA_DDR := VIA_BASE+DDRB

; set these to bit masks for how your sd card interface is wired up to the VIA
SDCARD_CSB  := %00000001
SDCARD_MOSI := %00000010
SDCARD_SCLK := %00000100
SDCARD_MISO := %10000000    ; NOTE: there is an assembly-time speed optimization if SDCARD_MISO is Px7!

SDCARD_R1_IDLE              := %00000001
SDCARD_R1_ERASE_RESET       := %00000010
SDCARD_R1_ERROR_CMD         := %00000100
SDCARD_R1_ERROR_CRC         := %00001000
SDCARD_R1_ERROR_ERASE_SEQ   := %00010000
SDCARD_R1_ERROR_ADDR        := %00100000
SDCARD_R1_ERROR_PARAM       := %01000000

SDCARD_VOLTAGE_27_36 := $01   ; 2,7 - 3,6V card

SDCARD_OCR_POWERED_UP       := %10000000    ; value for return arg 0
SDCARD_OCR_HIGH_CAPACITY    := %01000000    ; value for return arg 0

.struct SDCardCommand
    index       .byte
    argument    .res 4
    crc         .byte
.endstruct

.enum SDCardInitPhase
    UNKNOWN = 0
    SPI_MODE = 1
    IDLE_RECEIVED = 2
    V2_CARD = 3
    OCR_READ = 4
    INITIALIZED = 5
.endenum

.endif
