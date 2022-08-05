; LmaOS
;
; Copyright Nate Rivard 2022

.ifndef DUART_INC
DUART_INC = 1

DUART_BASE := DUART_PORT

.macro DUART_BYTE_AVAIL
.local @Done
    SEC                 ; no byte available by default
    LDA DUART_BASE+SRA
    BIT #(SR_RX_RDY)
    BEQ @Done           ; no byte available
    CLC                 ; byte is available
@Done:
.endmacro

; register offsets for the DUART. 
; Registers marked with `(~RD)` are accessed on a read of that address
; Registers marked with `(~WR)` are accessed on a write of that address
; Registers marked with `(R/W)` are read-write and accessed on either

MRA         := $00 ; mode register, channel A (R/W)

SRA         := $01 ; status register, channel A (~RD)
CSRA        := SRA ; clock select register, channel A (~WR)

; NOTE: a ~RD at $02 is `reserved` and could have undesired effects
CRA         := $02 ; command register, channel A (~WR)

RxFIFOA     := $03 ; Rx holding register, channel A (~RD)
TxFIFOA     := RxFIFOA ; Tx holding register, channel A (~WR)

IPCR        := $04 ; input port change register (~RD)
ACR         := IPCR ; auxiliary control register (~WR)

ISR         := $05 ; interrupt status register (~RD)
IMR         := ISR ; interrupt mask register (~WR)

CTU         := $06 ; counter/timer register, upper (~RD)
CTPU        := CTU ; counter/timer preset register, upper (~WR)

CTL         := $07 ; counter/timer register, lower (~RD)
CTPL        := CTL ; counter/timer preset register, lower (~WR)

MISC        := $0C ; miscellaneous do what you want with it register (R/W)

IPR         := $0D ; input port register (~RD)
OPCR        := IPR ; output port configuration register (~WR)

CTR_STRT    := $0E ; counter/timer start (~RD)
SOPR        := CTR_STRT ; set output bits register (~WR)

CTR_STOP    := $0F ; counter/timer stop (~RD)
ROPR        := CTR_STOP ; reset output bits register (~WR)

; ACR masks
ACR_TIMER_XTL_CLK   := (%110) << 4  ; timer-mode, use external clock unchanged
ACR_BRG_SELECT      := 1 << 7       ; select the 2nd group of BRG values 

; IRQ masks
IMR_CT_ENABLE := %00001000

; MR options
MR0_RX_WATCHDOG         := %10000000
MR0_FIFO_16             := %00001000
MR0_FIFO_RX_INT         := %01000000  ; bit 1 of Rx fifo interrupt level

MR0_BAUD_NORMAL         := %000       ; use normal baud rate table
MR0_BAUD_EXT1           := %001       ; use extended 1 baud rate table
MR0_BAUD_EXT2           := %100       ; use extended 2 baud rate table

MR1_RX_USE_RTS          := %10000000  ; receiver should use RTS control
MR1_FIFO_RX_INT         := %01000000  ; bit 2 of Rx fifo interrupt level
MR1_PARITY_MODE_NONE    := %10 << 3   ; no parity
MR1_BITS_PER_CHAR_8     := %11        ; 8 bits per character

MR2_CHANNEL_MODE_NORMAL := %00 << 6   ; normal channel mode
MR2_CHANNEL_MODE_ECHO   := %01 << 6   ; echo mode
MR2_TX_USE_RTS          := %00100000  ; TX should use RTS control
MR2_TX_USE_CTS          := %00010000  ; TX should use CTS control
MR2_STOP_BITS_1         := %00000111  ; 1.0 stop bits

; SR masks
SR_RX_RDY               := %00000001  ; a char has been received
SR_RX_FULL              := %00000010  ; the receive FIFO is full
SR_TX_RDY               := %00000100  ; a char can be added to Tx fifo
SR_TX_EMPTY             := %00001000  ; Tx fifo is empty

; CR options and commands
CR_RX_ENABLE            := %00000001
CR_RX_DISABLE           := %00000010
CR_TX_ENABLE            := %00000100
CR_TX_DISABLE           := %00001000

CR_COMMAND_NOP          := %0000 << 4 ; nop
CR_COMMAND_MR_1         := %0001 << 4 ; reset MR pointer to MR1
CR_COMMAND_RX_RES       := %0010 << 4 ; reset receiver. Rx disabled and FIFO is flushed
CR_COMMAND_TX_RES       := %0011 << 4 ; reset transmitter
CR_COMMAND_ERR_RES      := %0100 << 4 ; reset error status. clears all error statuses (break, parity, etc.)
CR_COMMAND_BRK_IRQ_RES  := %0101 << 4 ; reset break change interrupt
CR_COMMAND_BRK_STRT     := %0110 << 4 ; force TxD low. Tx must be active to be accepted
CR_COMMAND_BRK_STP      := %0111 << 4 ; force TxD high
CR_COMMAND_RTS_SET      := %1000 << 4 ; assert ~RTS (take low)
CR_COMMAND_RTS_RES      := %1001 << 4 ; negate ~RTS (take high)
CR_COMMAND_TO_MODE_ON   := %1010 << 4 ; turn timeout mode on (read docs for details)
CR_COMMAND_MR_0         := %1011 << 4 ; sets MR pointer to MR0
CR_COMMAND_TO_MODE_OFF  := %1100 << 4 ; turn timeout mode off (read docs for details)
CR_COMMAND_UNUSED       := %1101 << 4 ; not used so don't use it!
CR_COMMAND_PWR_DOWN_ON  := %1110 << 4 ; turn power-down mode on. ONLY AVAILABLE ON CHANNEL A
CR_COMMAND_PWR_DOWN_OFF := %1111 << 4 ; turn power-down mode off. ONLY AVAILABLE ON CHANNEL A

; OPCR masks


.endif
