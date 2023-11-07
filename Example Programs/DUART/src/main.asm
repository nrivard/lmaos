.include "duart.inc"
.include "lmaos.inc"
.include "pseudoinstructions.inc"
.include "strings.inc"
.include "system.inc"

.org $0600

.feature string_escapes

Main:
    JMP GameLoop

ComputerNumber: .res 1
GuessCount:     .res 1      ; stores the total number of guesses
PrevDistance:   .res 1      ; stores the distance between prev guess and ComputerNumber
                            ; so we can decide if you are getting warmer or colder

GameLoop:
@GenerateNumber:
    LDA SystemClockJiffies
    JSR Random
    AND #($0F)
    STA ComputerNumber
    STZ PrevDistance
    STZ GuessCount
    COPYADDR GuessMsg, r0
    JSR SerialSendString
@PrintPrompt:
    LDA #'>'
    JSR SerialSendByte
@WaitForResponse:
    JSR SerialGetByte
    CMP #(ASCII_ESCAPE)
    BNE @Echo
    JMP @Done
@Echo:
    JSR SerialSendByte
    PHA                     ; cache the guess
    SerialSendNewLine
@ProcessGuess:
    PLA                     ; restore the guess
    JSR CharToByte
    BCS @Nan
@CompareGuess:
    INC GuessCount
    CMP ComputerNumber
    BNE @WrongGuess

@RightGuess:
    COPYADDR RightMsg, r0
    JSR SerialSendString

    LDA GuessCount
    JSR SerialSendByteAsString

    COPYADDR RightMsgEnd, r0
    JSR SerialSendString

    BRA GameLoop

@Nan:
    LDA #<NaNMsg
    STA r0
    LDA #>NaNMsg
    STA r0 + 1
    JSR SerialSendString

    JMP GameLoop

@WrongGuess:
    LDY PrevDistance        ; cache prev distance for use later
    LDX ComputerNumber      ; compare guess to real number
    JSR AbsDistance         ; A already contains the real guess
    STA PrevDistance

    COPYADDR ThinkingMsg, r0
    JSR SerialSendString

    LDA GuessCount          ; is this the first guess?
    CMP #$01
    BEQ @FirstGuess
    CMP #$10
    BEQ @TooManyGuesses
    BRA @CheckWarmVsCold

@FirstGuess:
    COPYADDR FirstGuessMsg, r0
    JSR SerialSendString
    BRA @TryAgain
@TooManyGuesses:
    COPYADDR SarcasticMsg, r0
    JSR SerialSendString
    BRA @TryAgain
@CheckWarmVsCold:
    CPY PrevDistance
    BEQ @Lukewarm           ; equidistant
    BCS @Warmer             ; prev distance > current distance
@Colder:
    COPYADDR ColdMsg, r0
    JSR SerialSendString
    BRA @TryAgain
@Lukewarm:
    COPYADDR LukewarmMsg, r0
    JSR SerialSendString
    BRA @TryAgain
@Warmer:
    COPYADDR WarmMsg, r0
    JSR SerialSendString
@TryAgain:
    COPYADDR GuessAgainMsg, r0
    JSR SerialSendString
    JMP @PrintPrompt

@Done:
    RTS

; returns psuedo-random number back in A
;
; A: seed from which to generate a random number (ex: jiffy clock or frame count)
; NOTE: taken from https://codebase64.org/doku.php?id=base:small_fast_8-bit_prng
Random:
    CMP #0          ; not sure when A was loaded so we have to reset Z flag to be safe
    BEQ @PerformEOR
    ASL
    BEQ @Done
    BCC @Done
@PerformEOR:
    EOR #$1D
@Done:
    RTS

; returns the distance between 2 numbers as a positive integer
; A: first number
; X: second number
;
; returns distance in A (destroyed)
AbsDistance:
    PHX
	STX $A
	SEC
	SBC $A
	BPL @Done
	EOR #$FF            ; value is negative so 2's complement negate it for abs value
	INC A
@Done:
	PLX
	RTS

GuessMsg:       .asciiz "What number am I thinking of between 0 and F? (I am a computer so I think in hex!)\n"
NaNMsg:         .asciiz "That's not even a number so you lose!\n"

ThinkingMsg:    .asciiz "Hmm..."
FirstGuessMsg:  .asciiz "good first guess but no"
WarmMsg:        .asciiz "getting warmer"
LukewarmMsg:    .asciiz "stayed lukewarm"
ColdMsg:        .asciiz "getting colder"
SarcasticMsg:   .asciiz "you know there are only $10 possibilities"
GuessAgainMsg:  .asciiz ". Make another guess.\n"

RightMsg:       .asciiz "YES! You did it in $"
RightMsgEnd:    .asciiz " guesses. Press ESC to quit.\n"
