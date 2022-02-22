; LmaOS
;
; Copyright Nate Rivard 2020

.ifndef SPI_INC
SPI_INC = 1

; set these to the appropriate VIA port addresses
SPI_VIA_PORT := VIA_BASE+PORT_B
SPI_VIA_DDR := VIA_BASE+DDRB

; set these to bit masks for how your sd card interface is wired up to the VIA
SPI_CSB  := %00000001
SPI_MOSI := %00000010
SPI_SCLK := %00000100
SPI_MISO := %10000000    ; NOTE: there is an assembly-time speed optimization if SDCARD_MISO is Px7!

; .export SPITransferToSend, SPITransferReceived

; TODO: we need to figure out where this will eventually live. bss or zp
; but this can't happen until this moves into LmaOS itself
; .bss  

SPITransferToSend: .res 1       ; stores interstitial work sent to device
SPITransferReceived: .res 1      ; stores interstitial result from device

.endif
