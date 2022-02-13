.include "lmaos.inc"
.include "lcd1602.inc"
.include "pseudoinstructions.inc"
.include "strings.inc"
.include "system.inc"
.include "via.inc"
.include "sdcard.inc"

.org $0600

.feature string_escapes

Main:
    JMP SDCardInit

; storage
CommandPointer: .res 2
SDTransferToSend: .res 1     ; stores interstitial work sent to device
SDTransferReceived: .res 1   ; stores interstitial result from device
SDTransferR1Response: .res 1 ; stores the last received R1 response
SDTransferR7Response: .res 4 ; stores additional received arguments

SDCardInitPhase: .res 1      ; last successful init phase completed

; initialize the SD card. carry will be set if an error occurred
; and the last successful phase will be stored in SDCardInitPhase
SDCardInit:
@ConfigureVIAPort:
    STZ SDCardInitPhase                             ; UNKNOWN
    LDA SDCARD_VIA_DDR                              ; set the appropriate pins to inputs
    ORA #(SDCARD_SCLK | SDCARD_MOSI | SDCARD_CSB)   ; MOSI, SCLK, and ~CS are outputs
    AND #(SDCARD_MISO ^ $FF)                        ; MISO is an input
    STA SDCARD_VIA_DDR
@BootSDCard:
    LDA #(SDCARD_MOSI | SDCARD_CSB)                 ; MOSI and CS should be high as part of bootup
    LDX #$A0                                        ; need 74 (or more) SCLK pulses, so we'll do 80 (160 high/low transitions)
@BootSDCardLoop:
    EOR #(SDCARD_SCLK)                              ; only SCLK bit is changing here
    STA SDCARD_VIA_PORT
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
    STX $6000
    BEQ @Initialized
    DEX
    BEQ @Done                                       ; tried 10 times to no avail
    BRA @StartInitLoop
@Initialized:
    INC SDCardInitPhase
@Done:
    LDA #(SDCARD_CSB | SDCARD_MOSI)                 ; de-select device
    STA SDCARD_VIA_PORT
    RTS

; continuously reads results until it's something other than $FF
; actual result will be in `A`
SDCardWaitForResult:
@WaitLoop:
    JSR SDCardReadByte
    CMP #$FF
    BEQ @WaitLoop
    RTS

; Sends the contents of `A` and returns the response in `A`
SDCardTransferByte:
    PHX
    PHY
    STA SDTransferToSend
@Preamble:
    LDX #8
@TransferLoop:
    ASL SDTransferToSend        ; shift MSB into carry
    LDA #0
    BCC @SendBit
    ORA #(SDCARD_MOSI)          ; carry is set, so send a 1 on MOSI
@SendBit:
    STA SDCARD_VIA_PORT         ; send with clock low, CS low and whatever MOSI is
    NOP                         ; even out the timing
    NOP
    NOP
    NOP
    NOP
    NOP
    EOR #(SDCARD_SCLK)          ; just flip SCLK high
    STA SDCARD_VIA_PORT
@BitReceived:
    LDA SDCARD_VIA_PORT         ; and we will make our read of MISO
.if (SDCARD_MISO = $80)         ; if MISO is Px7, we can greatly speed this up with just a rotation
    ASL A                       ; rotate MISO bit into carry
.else
    AND #(SDCARD_MISO)
    CLC                         ; assume bit was zero
    BEQ @UpdateReceived
    SEC                         ; was a 1, set carry
.endif
@UpdateReceived:
    ROL SDTransferReceived      ; rotate carry into received byte
    DEX
    BNE @TransferLoop
@Done:
    LDA #(SDCARD_MOSI)          ; MOSI high (idle) and clk low
    STA SDCARD_VIA_PORT
    LDA SDTransferReceived
    PLY
    PLX
    RTS

; convenience that reads a byte and returns it in `A`
SDCardReadByte:
    LDA #$FF
    JMP SDCardTransferByte      ; we'd just RTS anyway so let SDCardTransferByte do that directly

; sends the command at the given address. it is expected the command is entirely properly set up
; low byte is in `A`, high byte is in `Y`
; `A` and `Y` are not preserved as a result of this subroutine
; r0 is destroyed
SDCardSendCommand:
    STA r0
    STY r0 + 1
@SendIdleByte:
    LDA #$FF
    JSR SDCardTransferByte          ; send an idle byte before every command
    LDY #0
@SendLoop:
    LDA (r0), Y
    JSR SDCardTransferByte
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
    JSR SDCardReadByte
    CMP #0              ; we need this so carry is in a known state
    BNE @Done
    JSR SDCardReadByte
    CMP #0              ; again, known carry state
    BNE @Done
    JSR SDCardReadByte
    CMP #SDCARD_VOLTAGE_27_36   ; card accepts a valid voltage range
    BNE @Done
    JSR SDCardReadByte
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
    CMP #(SDCARD_R1_IDLE)            ; $01 if successful (TODO: 0 might be ok too!)
    BNE @Done
@ReceiveR7:
    LDY #$00
@ReceiveR7Loop:
    JSR SDCardReadByte
    STA SDTransferR7Response, Y
    INY
    CPY #$04
    BNE @ReceiveR7Loop
    SEC                             ; set this so it gets inverted :)
@Done:
    INVC
    RTS

; sends the app command passed in via `A` (low-byte) and `Y` (high-byte)
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

;; commands      CMD  ARG1 ARG2 ARG3 ARG4 CRC
Command0:  .byte $40, $00, $00, $00, $00, $95   ; GO_IDLE_STATE
Command8:  .byte $48, $00, $00, $01, $AA, $87   ; SEND_IF_COND
Command55: .byte $77, $00, $00, $00, $00, $00   ; APP_CMD
Command58: .byte $7A, $00, $00, $00, $00, $00   ; READ_OCR

;; app commands
Command41: .byte $69, $40, $00, $00, $00, $00   ; APP_SEND_OP_COND

haha: .byte $69
