; LmaOS
;
; Copyright Nate Rivard 2020

.ifndef SDCARD_ASM
SDCARD_ASM = 1

.include "sdcard.inc"

.export SDCardInit

SDCardInit:
@ConfigureVIAPort:
    LDA SDCARD_VIA_DDR_ADDR                         ; set the appropriate pins to inputs
    ORA #(SDCARD_SCLK | SDCARD_MOSI | SDCARD_CSB)   ; MOSI, SCLK, and ~CS are outputs
    AND #(SDCARD_MISO ^ $FF)                        ; MISO is an input
    STA SDCARD_VIA_DDR_ADDR

.endif
