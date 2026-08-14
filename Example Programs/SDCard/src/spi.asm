; LmaOS
;
; Copyright Nate Rivard 2020

.ifndef SPI_ASM
SPI_ASM = 1

.include "spi.inc"

SPIInit:
@ConfigureVIAPort:
    LDA SPI_VIA_DDR                             ; set the appropriate pins to inputs
    ORA #(SPI_SCLK | SPI_MOSI | SPI_CSB)        ; MOSI, SCLK, and ~CS are outputs
    AND #(SPI_MISO ^ $FF)                       ; MISO is an input
    STA SPI_VIA_DDR
    RTS

; convenience that reads a byte and returns it in `A`
SPIReadByte:
    LDA #$FF
    ;; FALLTHROUGH to SDCardTransferByte. It will handle the RTS
    
; Sends the contents of `A` and returns the response in `A`
SPITransferByte:
    PHX
    PHY
    STA SPITransferToSend
@Preamble:
    LDX #8
@TransferLoop:
    ASL SPITransferToSend        ; shift MSB into carry
    LDA #0
    BCC @SendBit
    ORA #(SPI_MOSI)             ; carry is set, so send a 1 on MOSI
@SendBit:
    STA SPI_VIA_PORT            ; send with clock low, CS low and whatever MOSI is
    NOP                         ; even out the timing
    NOP
    NOP
    NOP
    NOP
    NOP
    EOR #(SPI_SCLK)             ; just flip SCLK high
    STA SPI_VIA_PORT
@BitReceived:
    LDA SPI_VIA_PORT            ; and we will make our read of MISO
.if (SPI_MISO = $80)            ; if MISO is Px7, we can greatly speed this up with just a rotation
    ASL A                       ; rotate MISO bit into carry
.else
    AND #(SPI_MOSI)
    CLC                         ; assume bit was zero
    BEQ @UpdateReceived
    SEC                         ; was a 1, set carry
.endif
@UpdateReceived:
    ROL SPITransferReceived      ; rotate carry into received byte
    DEX
    BNE @TransferLoop
@Done:
    LDA #(SPI_MOSI)              ; MOSI high (idle) and clk low
    STA SPI_VIA_PORT
    LDA SPITransferReceived
    PLY
    PLX
    RTS

.endif
