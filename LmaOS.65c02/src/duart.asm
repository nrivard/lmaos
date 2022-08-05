; LmaOS
;
; Copyright Nate Rivard 2022

.ifndef DUART_ASM
DUART_ASM = 1

.include "duart.inc"

.code

DuartInit:
    LDA #<DUART_BASE
    STA r0
    LDA #>DUART_BASE
    STA r0 + 1
    LDX #(DuartInitTableEnd - DuartInitTable - 1)   ; start at last pair of bytes
@DuartInitTableLoop:
    LDA DuartInitTable, X                           ; fetch register parameter
    DEX
    LDY DuartInitTable, X                           ; fetch register offset
    DEX
    STA (r0), Y                                     ; store at DUART register
    BPL @DuartInitTableLoop
@StartTimer:
    BIT DUART_BASE+CTR_STRT
@Done:
    RTS

DuartGetByte:
@CheckByteReceived:
    LDA DUART_BASE+SRA
    BIT #(SR_RX_RDY)
    BEQ @CheckByteReceived
@Done:
    LDA DUART_BASE+RxFIFOA
    RTS

DuartSendByte:
    PHA
@CheckTransmitAvailable:
    LDA DUART_BASE+SRA
    BIT #(SR_TX_RDY)
    BEQ @CheckTransmitAvailable
@SendByte:
    PLA
    STA DUART_BASE+TxFIFOA
@Done:
    RTS

; Duart init table that contains register offsets and their data
; this is meant to be accessed from the bottom up
DuartInitTable:
    .byte IMR,      IMR_CT_ENABLE                       ; re-enable IRQs
    .byte CTPL,     <(MpuRateHz / (ClockRateHz * 2))    ; lower nibble of jiffy rate
    .byte CTPU,     >(MpuRateHz / (ClockRateHz * 2))    ; upper nibble of jiffy rate
    .byte CRA,      CR_COMMAND_RTS_SET                  ; assert RTS
    .byte CRA,      CR_TX_ENABLE | CR_RX_ENABLE         ; enable transmitter, enable receiver
    .byte CSRA,     $CC                                 ; 19200 baud on Tx and Rx
    .byte MRA,      MR2_TX_USE_CTS | MR2_STOP_BITS_1    ; normal channel mode, use CTS, 1 stop bit
    .byte MRA,      MR1_RX_USE_RTS | MR1_FIFO_RX_INT | MR1_PARITY_MODE_NONE | MR1_BITS_PER_CHAR_8   ; use RTS, big fifo, no parity, 8 bits
    .byte MRA,      MR0_RX_WATCHDOG | MR0_FIFO_16 | MR0_FIFO_RX_INT  ; turn on Rx watchdog, big fifo, normal baud table
    .byte CRA,      CR_COMMAND_MR_0                     ; reset to MR0
    .byte ACR,      ACR_BRG_SELECT | ACR_TIMER_XTL_CLK  ; use 2nd group of BRG values, use xtl clk for timer
    .byte CRA,      CR_COMMAND_TO_MODE_OFF              ; disable timeout mode
    .byte CRA,      CR_COMMAND_ERR_RES                  ; reset error status
    .byte CRA,      CR_COMMAND_BRK_IRQ_RES              ; reset break change IRQ
    .byte CRA,      CR_COMMAND_TX_RES                   ; reset transmitter
    .byte CRA,      CR_COMMAND_RX_RES                   ; reset receiver
    .byte CRA,      CR_COMMAND_RTS_RES                  ; deassert ~RTS
    .byte IMR,      $00                                 ; turn IRQs off
DuartInitTableEnd:

.endif
