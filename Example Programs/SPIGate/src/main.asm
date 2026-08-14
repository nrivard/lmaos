.include "lmaos.inc"
.include "pseudoinstructions.inc"
.include "strings.inc"
.include "system.inc"

.org $0600

.feature string_escapes

Main:
    JMP SpiGateInit

.include "sdcard.asm"

SpiGateInit:
    LDX #0
@Loop:
    JSR SDCardInit
    BCS @Error
    COPYADDR SDCardInitSuccess,r0
    JSR SerialSendString
@FetchMBR:
    JSR SPIEnableFastMode           ; let's try fast mode :)
    LDA #0
    TAX
    TAY
    JSR SDCardReadBlock
    BCS @Error
@PrintMBR:
    COPYADDR SDCardDataPacketBuffer,r0
    LDX #0
    LDY #2
@PrintMBRLoop:
    LDA (r0)
    JSR SerialSendByteAsString
    LDA #' '
    JSR SerialSendByte
    INC16 r0
    INX
    BNE @PrintMBRLoop
    
    DEY
    BNE @PrintMBRLoop
    BRA @Done
@Error:
    COPYADDR SDCardInitError,r0
    JSR SerialSendString
@Done:
    RTS

SDCardInitError:     .asciiz "SD card could not be initialized\r\n"
SDCardInitSuccess:   .asciiz "SD card initialized\r\n"
