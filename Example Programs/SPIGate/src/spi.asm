; LmaOS
;
; Copyright Nate Rivard 2020

.ifndef SPI_ASM
SPI_ASM = 1

; .include "spi.inc"

SPIMASTER := N8BUS_PORT0
DATA := $00
CMD := $01


SPIMASTER_CLK_SEL   := %00000011
SPIMASTER_DEN       := %00000100
SPIMASTER_IEN       := %00001000
SPIMASTER_BUSY      := %01000000
SPIMASTER_ITC       := %10000000

SPIInit:
    LDA #$03    ; lowest clock speed, no devices selected, no interrupts
    STA SPIMASTER+CMD
    RTS

SPIEnableFastMode:
    LDA SPIMASTER+CMD   ; highest clock speed, leave everything else intact
    AND #(SPIMASTER_CLK_SEL ^ $FF)
    ORA #1
    STA SPIMASTER+CMD
    RTS

; convenience that reads a byte and returns it in `A`
SPIReadByte:
    LDA #$FF
    ;; FALLTHROUGH to SDCardTransferByte. It will handle the RTS
    
; Sends the contents of `A` and returns the response in `A`
SPITransferByte:
    STA SPIMASTER+DATA
@Loop:
    BIT SPIMASTER+CMD
    BPL @Loop
    LDA SPIMASTER+DATA
    RTS

; assumes you already have the device selected as this just enables it
.macro SPIAssert
    LDA SPIMASTER+CMD
    ORA #SPIMASTER_DEN
    STA SPIMASTER+CMD
.endmacro

.macro SPIDeassert
    LDA SPIMASTER+CMD
    AND #(SPIMASTER_DEN ^ $FF)
    STA SPIMASTER+CMD 
.endmacro

.endif
