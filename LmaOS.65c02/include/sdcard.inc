; LmaOS
;
; Copyright Nate Rivard 2020

.ifndef SDCARD_INC
SDCARD_INC = 1

SDCARD_R1_IDLE              := %00000001
SDCARD_R1_ERASE_RESET       := %00000010
SDCARD_R1_ERROR_CMD         := %00000100
SDCARD_R1_ERROR_CRC         := %00001000
SDCARD_R1_ERROR_ERASE_SEQ   := %00010000
SDCARD_R1_ERROR_ADDR        := %00100000
SDCARD_R1_ERROR_PARAM       := %01000000

SDCARD_VOLTAGE_27_36        := $01   ; 2,7 - 3,6V card

SDCARD_OCR_POWERED_UP       := %10000000    ; value for return arg 0
SDCARD_OCR_HIGH_CAPACITY    := %01000000    ; value for return arg 0

SDCARD_DATA_TOKEN_ACCEPTED      := %010
SDCARD_DATA_TOKEN_ERROR_CRC     := %001
SDCARD_DATA_TOKEN_ERROR_WRITE   := %110

SDCARD_DATA_TOKEN_SINGLE_BLOCK_OP  := $FE   ; data token for cmd 17, 18, 24 (single block operations)
SDCARD_DATA_TOKEN_MULTI_BLOCK_OP   := $FC   ; data token for cmd 25 (multi-block operation)
SDCARD_DATA_TOKEN_MULTI_BLOCK_STOP := $FD   ; stop token for cmd 25

SDCARD_COMMAND_READ_BLOCK   := $51          ; command index for reading a single block

.struct SDCardCommand
    index       .byte
    argument    .res 4
    crc         .byte
.endstruct

.struct SDCardDataPacket
    data        .res 512
    crc         .word                       ; needs to be fetched even if ignored
    token       .byte                       ; this will actually get sent first but comes after `data` in memory
.endstruct

.enum SDCardInitPhase
    UNKNOWN = 0
    SPI_MODE = 1
    IDLE_RECEIVED = 2
    V2_CARD = 3
    OCR_READ = 4
    INITIALIZED = 5
    READY = 6
.endenum

; TODO: we need to figure out where this will eventually live. bss or zp
; but this can't happen until this moves into LmaOS itself
; .bss  

; storage
SDTransferR1Response: .res 1 ; stores the last received R1 response
SDTransferR7Response: .res 4 ; stores additional received arguments

SDCardInitPhase: .res 1      ; last successful init phase completed

.endif
