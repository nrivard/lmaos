; LmaOS
;
; Copyright Nate Rivard 2020

.ifndef SDCARD_ASM
SDCARD_ASM = 1

.include "sdcard.inc"

.export SDCardInit, SDCardSendCommand, SDCardSendAppCommand

; initialize the SD card. carry will be set if an error occurred
; and the last successful phase will be stored in SDCardInitPhase
SDCardInit:
    STZ SDCardInitPhase                             ; UNKNOWN
@ConfigureSPI:
    JSR SPIInit
@BootSDCard:
    LDA #(SPI_MOSI | SPI_CSB)                       ; MOSI and CS should be high as part of bootup
    LDX #$A0                                        ; need 74 (or more) SCLK pulses, so we'll do 80 (160 high/low transitions)
@BootSDCardLoop:
    EOR #(SPI_SCLK)                                 ; only SCLK bit is changing here
    STA SPI_VIA_PORT
    DEX
    BNE @BootSDCardLoop
    INC SDCardInitPhase                             ; SPI_MODE
@SendIdle:
    JSR SDCardSendIdle
    BCS @Done
    INC SDCardInitPhase                             ; IDLE_RECEIVED
@SendV2Check:
    JSR SDCardSendV2Check
    BCS @Done
    INC SDCardInitPhase                             ; V2_CARD
@SendReadOCR:
    JSR SDCardSendReadOCR
    BCS @Done
    INC SDCardInitPhase                             ; OCR_READ
@SendStartInitialization:
    LDX #$FF                                        ; retry 255 times. does this need to be higher? time will tell!
@StartInitLoop:
    LDA #<Command41
    LDY #>Command41
    JSR SDCardSendAppCommand
    BCS @Done
    LDA SDTransferR1Response
    BEQ @Initialized
    DEX
    BNE @Delay                                      ; timeout?
    SEC
    BRA @Done                                       ; too many attempts
@Delay:
    JSR SDCardDelay                                 ; delay just a bit before trying again
    BRA @StartInitLoop
@Initialized:
    INC SDCardInitPhase
@RereadOCR:
    JSR SDCardSendReadOCR
    BCS @Done
    LDA SDTransferR7Response                        ; is sd card powered up and high capacity?
    AND #(SDCARD_OCR_POWERED_UP | SDCARD_OCR_HIGH_CAPACITY)
    CMP #(SDCARD_OCR_POWERED_UP | SDCARD_OCR_HIGH_CAPACITY)
    BNE @Done                                       ; not powered up or not high capacity. error :(
    INC SDCardInitPhase                             ; READY
    CLC
@Done:
    JSR SDCardDeselect
    RTS

SDCardDeselect:
    LDA #(SPI_CSB | SPI_MOSI)                       ; de-select device
    STA SPI_VIA_PORT
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

; continuously reads results until it's something other than $FF
; actual result will be in `A`
SDCardWaitForResult:
@WaitLoop:
    JSR SPIReadByte
    CMP #$FF
    BEQ @WaitLoop
    RTS

; sends the command at the given address. it is expected the command is entirely properly set up
; low byte is in `A`, high byte is in `Y`
; `A` and `Y` are not preserved as a result of this subroutine
; r0 is destroyed
SDCardSendCommand:
    STA r0
    STY r0 + 1
@SendIdleByte:
    LDA #$FF
    JSR SPITransferByte          ; send an idle byte before every command
    LDY #0
@SendLoop:
    LDA (r0), Y
    JSR SPITransferByte
    INY
    CPY #(.sizeof(SDCardCommand))
    BNE @SendLoop
@Done:
    RTS

; send GO_IDLE_STATE. carry will be clear if successful, 1 if error
SDCardSendIdle:
    LDA #<Command0
    LDY #>Command0
    JSR SDCardSendCommand
@ReceiveR1:
    JSR SDCardWaitForResult
    STA SDTransferR1Response
    CMP #(SDCARD_R1_IDLE)            ; $01 if successful
    INVC
@Done:
    RTS

; send SEND_IF_COND. carry will be clear if successful, 1 if error
SDCardSendV2Check:
    LDA #<Command8
    LDY #>Command8
    JSR SDCardSendCommand
@ReceiveR1:
    JSR SDCardWaitForResult
    STA SDTransferR1Response
    CMP #(SDCARD_R1_IDLE) ; $01 if successful
    BNE @Done
@ReceiveR7:
    JSR SPIReadByte
    CMP #0              ; we need this so carry is in a known state
    BNE @Done
    JSR SPIReadByte
    CMP #0              ; again, known carry state
    BNE @Done
    JSR SPIReadByte
    CMP #SDCARD_VOLTAGE_27_36   ; card accepts a valid voltage range
    BNE @Done
    JSR SPIReadByte
    CMP Command8 + 4    ; matches the pattern we sent in arg4
@Done:
    INVC
    RTS

; send READ_OCR and store response in SDTransferR7Response 
; carry will be clear if successful, 1 if error
SDCardSendReadOCR:
    LDA #<Command58
    LDY #>Command58
    JSR SDCardSendCommand
@ReceiveR1:
    JSR SDCardWaitForResult
    STA SDTransferR1Response
    CMP #2                          ; 0 and 1 are valid, so CMP will clear carry if < 2
    BCS @Done
@ReceiveR7:
    LDY #$00
@ReceiveR7Loop:
    JSR SPIReadByte
    STA SDTransferR7Response, Y
    INY
    CPY #$04
    BNE @ReceiveR7Loop
    CLC                             ; success so clear carry
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
    JSR SDCardDeselect
    INVC
    RTS

;; commands      CMD  ARG1 ARG2 ARG3 ARG4 CRC
Command0:  .byte $40, $00, $00, $00, $00, $95   ; GO_IDLE_STATE
Command8:  .byte $48, $00, $00, $01, $AA, $87   ; SEND_IF_COND
Command55: .byte $77, $00, $00, $00, $00, $00   ; APP_CMD
Command58: .byte $7A, $00, $00, $00, $00, $00   ; READ_OCR

;; app commands
Command41: .byte $69, $40, $00, $00, $00, $00   ; APP_SEND_OP_COND

SDCardDataPacketBuffer  := $1000                ; for now let's hardcode this
SDCardCommandRequest    := (SDCardDataPacketBuffer + 512)

.endif
