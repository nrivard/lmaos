; LmaOS
;
; Copyright Nate Rivard 2020

.ifndef SDCARD_ASM
SDCARD_ASM = 1

.include "sdcard.inc"
.include "spi.asm"

.export SDCardInit, SDCardSendCommand, SDCardSendAppCommand

SDCardInit:
    LDX #0
    STZ SDCardInitPhase
@Loop:
    JSR SPIInit
    SPIDeassert
    LDX #$0A        ; loop 10 times (10 * 8 bits is 80 clock cycles)
@EnterSpiMode:
    JSR SPIReadByte
    DEX
    BNE @EnterSpiMode
    INC SDCardInitPhase                             ; SPI_MODE
    SPIAssert
@SendIdle:
    LDA #<Command0
    LDY #>Command0
    JSR SDCardSendCommand
    JSR SDCardWaitForResult
    CMP #SDCARD_R1_IDLE
    BNE @Error
@SendV2Check:
    LDA #<Command8
    LDY #>Command8
    JSR SDCardSendCommand
    JSR SDCardWaitForResult
    CMP #SDCARD_R1_IDLE
    BNE @Error
@RecvV2R7:
    JSR SDCardRecvR7
    LDA SDTransferR7Response
    BNE @Error
    LDA SDTransferR7Response+1
    BNE @Error
    LDA SDTransferR7Response+2
    CMP #SDCARD_VOLTAGE_27_36
    BNE @Error
    LDA SDTransferR7Response+3
    CMP #$AA
    BNE @Error
    INC SDCardInitPhase

    LDX #$FF                        ; max idle loop count
@StartInitLoop:
    LDA #<Command41
    LDY #>Command41
    JSR SDCardSendAppCommand
    BCS @Error
    LDA SDTransferR1Response
    BEQ @Initialized
    DEX
    BNE @Delay                                      ; timeout?
    SEC
    BRA @Error                                       ; too many attempts
@Delay:
    JSR SDCardDelay                                 ; delay just a bit before trying again
    BRA @StartInitLoop
@Initialized:
    INC SDCardInitPhase

@ReadOCR:
    LDA #<Command58
    LDY #>Command58
    JSR SDCardSendCommand
    JSR SDCardWaitForResult
    CMP #0
    BNE @Error
@VerifyOCR:
    JSR SDCardRecvR7
    LDA SDTransferR7Response                        ; is sd card powered up and high capacity?
    AND #(SDCARD_OCR_POWERED_UP | SDCARD_OCR_HIGH_CAPACITY)
    CMP #(SDCARD_OCR_POWERED_UP | SDCARD_OCR_HIGH_CAPACITY)
    BNE @Error                                      ; not powered up or not high capacity. error :(
    INC SDCardInitPhase                             ; READY
    CLC
    BRA @Done
@Error:
    STA $6000
    SEC
@Done:
    SPIDeassert
    RTS

; sends the command at the given address. it is expected the command is entirely properly set up
; low byte is in `A`, high byte is in `Y`
; `A` and `Y` are not preserved as a result of this subroutine
; r0 is destroyed
SDCardSendCommand:
    STA r0
    STY r0 + 1
@SendIdleByte:
    JSR SPIReadByte          ; send an idle byte before every command
    LDY #0
@SendLoop:
    LDA (r0), Y
    JSR SPITransferByte
    INY
    CPY #(.sizeof(SDCardCommand))
    BNE @SendLoop
@Done:
    RTS

    ; sends the app command passed in via pointer in `A` (low-byte) and `Y` (high-byte)
SDCardSendAppCommand:
    PHA
    PHY
@SendAppCommandSequenceStart:
    LDA #<Command55
    LDY #>Command55
    JSR SDCardSendCommand
@ReceiveSequenceStartR1:
    JSR SDCardWaitForResult
    STA SDTransferR1Response
    CMP #(SDCARD_R1_IDLE)           ; TODO: might actually be ok if this 0 or 1...
    BNE @SeqStartError
@SendAppCommand:
    PLY
    PLA
    JSR SDCardSendCommand
@ReceiveAppCommandR1:
    JSR SDCardWaitForResult
    STA SDTransferR1Response
    CMP #2                          ; 0 and 1 are valid, so CMP will clear carry if < 2
    BRA @Done                       ; error condition already set :)
@SeqStartError:
    PLY
    PLA
    SEC
@Done:
    RTS

; continuously reads results until it's something other than $FF
; actual result will be in `A`
SDCardWaitForResult:
@WaitLoop:
    JSR SPIReadByte
    CMP #$FF
    BEQ @WaitLoop
    RTS

SDCardRecvR7:
    PHX
    LDX #0
@Loop:
    JSR SPIReadByte
    STA SDTransferR7Response,X
    INX
    CPX #4
    BNE @Loop
@Done:
    PLX
    RTS

; delays for 10 jiffies (ie, ~100 msec)
SDCardDelay:
    PHY
    LDY #10
@Loop:
    WAI                                             ; just wait until an interrupt brings us back
    DEY
    BNE @Loop
@Done:
    PLY
    RTS

; fetches a single block at an address given by
; `A` lowest byte, `X` middle byte, `Y` highest byte
; note that this can only address up to 8 gig or so which should be fine for awhile :)
; the block data will be stored in SDCardDataPacketBuffer
SDCardReadBlock:
    STA SDCardCommandRequest+SDCardCommand::argument + 3
    STX SDCardCommandRequest+SDCardCommand::argument + 2
    STY SDCardCommandRequest+SDCardCommand::argument + 1
    STZ SDCardCommandRequest+SDCardCommand::argument
    LDA #(SDCARD_COMMAND_READ_BLOCK)
    STA SDCardCommandRequest+SDCardCommand::index
    STZ SDCardCommandRequest+SDCardCommand::crc
    
    SPIAssert
    LDA #<SDCardCommandRequest
    LDY #>SDCardCommandRequest
    JSR SDCardSendCommand
@ReceiveR1:
    JSR SDCardWaitForResult
    CMP #0                                      ; no errors, sd card is initialized
    BNE @Done
@ReceiveToken:
    JSR SDCardWaitForResult                     ; get the data packet token
    CMP #(SDCARD_DATA_TOKEN_SINGLE_BLOCK_OP)
    BNE @Done
@ReceiveBlock:
    LDX #0
@ReceiveBlockLoop1:
    JSR SPIReadByte
    STA SDCardDataPacketBuffer, X
    INX
    BNE @ReceiveBlockLoop1
@ReceiveBlockLoop2:
    JSR SPIReadByte
    STA SDCardDataPacketBuffer + $100, X
    INX
    BNE @ReceiveBlockLoop2
@ReceiveCRC:
    JSR SPIReadByte
    JSR SPIReadByte
    SEC
@Done:
    SPIDeassert
    INVC
    RTS

Command0:  .byte $40, $00, $00, $00, $00, $95   ; GO_IDLE_STATE
Command8:  .byte $48, $00, $00, $01, $AA, $87   ; SEND_IF_COND
Command55: .byte $77, $00, $00, $00, $00, $00   ; APP_CMD
Command58: .byte $7A, $00, $00, $00, $00, $00   ; READ_OCR

;; app commands
Command41: .byte $69, $40, $00, $00, $00, $00   ; APP_SEND_OP_COND

SDCardDataPacketBuffer  := $2000                ; for now let's hardcode this
SDCardCommandRequest    := (SDCardDataPacketBuffer + 512)

.endif
