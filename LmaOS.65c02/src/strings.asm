; LmaOS
;
; Copyright Nate Rivard 2020

.ifndef STRINGS_ASM
STRINGS_ASM = 1

.include "strings.inc"

.export StringLength, StringCompareN, StringCompare, StringCopy, HexStringToWord, CharToByte, ByteToHexString, NibbleToChar

.code

;;; finds length of a null-terminated string
;;;
;;;	Params
;;; r0: pointer to null-terminated string
;;;  Y: length of the string, excluding the null-terminator
StringLength:
    LDY #$00
@Loop:
    LDA (r0), Y
    BEQ @Done
    INY
    ;; TODO: if Y is zero again, add $100 to r1, add $100 to r3, and start again
    JMP @Loop
@Done:
    RTS

;;; compares 2 strings for up to N characters
;;;
;;; Params
;;;  Y: count of chars to compare
;;; r0: pointer to first string
;;; r1: pointer to second string
;;;
;;; Results
;;; Flags: Zero flag set if strings are equal
StringCompareN:
    DEY					;; work backwards but we need to dec Y so we're at correct index
@Loop:
    CPY #$FF			;; char count reached?
    BEQ @Done
    LDA (r0), Y
    CMP (r1), Y
    BNE @Done			;; not equal, z already clear
@CheckEOS:
    DEY
    JMP @Loop
@Done:
    RTS

;;; compares 2 null-terminated strings
;;; 
;;; Params:
;;; r0: pointer to first null-terminated string
;;; r1: pointer to second null-terminated string
;;;
;;; Results
;;; Flags: Zero flag set if strings are equal, 
StringCompare:
    JSR StringLength
    STA r7				;; save length
    SWAP16 r0, r1		;; swap pointers
    JSR StringLength
    CPY r7
    BEQ @Compare
@Fail:
    LDA $00				;; clear zero
    JMP @Done
@Compare:
    JSR StringCompareN
@Done:
    RTS
    
;;; copies a string to another memory location
;;;
;;; Params:
;;; r0 - pointer to null-terminated string to copy
;;; r1 - pointer to destination of copied string
;;;
;;; Returns:
;;; Y will contain the length of the copied string
StringCopy:
    LDY #$00
@Loop:
    LDA (r0), Y
    BEQ @Done
    STA (r1), Y
    INY
    JMP @Loop
@Done:
    RTS
    
;;; converts a hex numeric null-terminated string to a 16-bit native unsigned integer
;;;
;;; Params
;;; r0: pointer to ascii numeric null-terminated string.
;;;	    This string cannot be longer than 4 digits!.
;;;
;;; Results
;;; r7: unsigned 16-bit integer value of the string
;;; Flags: Carry will be set if error encountered
HexStringToWord:
@DigitCount:
    JSR StringLength	;; find out the length of the string (already in r0)
@Preamble:
    TYA				    ;; X: nibble index
    TAX
    COPYADDR $00, r7	;; reset our return value
    CPX #$05			;; too many digits! only 4 supported (16-bit)
    BCS @Done
    DEX
    LDY #$00			;; Y: index into string
@LoadDigit:
    LDA (r0), Y
    BEQ @Done			;; null-terminator
@ExtractByte:
    JSR CharToByte
    BCS @Done
@NibbleShift:
    STX r4
    BBR0 r4, @StoreNibble ;; odd index need to be shifted
    ASL A				;; shift 4 times to promote to upper nibble
    ASL A
    ASL A
    ASL A
@StoreNibble:
    CPX #$02			;; check if upper byte
    BCC	@LowerByte
@UpperByte:
    ORA r7 + 1
    STA r7 + 1
    JMP @NextDigit
@LowerByte:
    ORA r7
    STA r7
@NextDigit:
    DEX
    INY
    JMP @LoadDigit
@Done:
    RTS

; converts an ascii value representing a hex digit (0…F) into a native byte
; this return will treat both lowercase a…f and uppercase A…F as valid
;
; Params
; A: the char to convert
;
; Returns
; A: the converted byte
; Flags: Carry will be set if ascii value is not a valid digit
;
; ex: the character '7' will be returned as $07
CharToByte:
    SEC
    SBC #'0'
    CMP #$0A            ; check 0…9
    BCC @Done
    SBC #$07            ; 'A' - '9' - 1
    CMP #$10            ; check A…F
    BCC @Done
    SBC #$20            ; 'a' - 'A'
    CMP #$10			; check a…f though no one should write it lowercase, it's dumb A…F (lolz)
@Done:
	RTS

;;; converts a native byte to 2 ascii bytes (not null-terminated!)
;;; Lifted from Wozmon. Thanks Woz!
;;;
;;; Params
;;; A: the byte to convert to a string
;;;
;;; Results
;;; r7: the converted 2 ascii bytes, in big endian order (ie, string order)
;;; ex: `$1F` will be returned as `r7: '1', r7+1: 'F'`
ByteToHexString:
    PHA
@UpperNibble:
    LSR
    LSR
    LSR
    LSR
    JSR NibbleToChar
    STA r7
@LowerNibble:
    PLA
    JSR NibbleToChar
    STA r7 + 1
@Done:
    RTS

; Params
; A: the nibble to convert
;
; Results
; A: ascii code for the nibble
NibbleToChar:
    AND #$0F
    ORA #'0'
    CMP #('9' + 1) 		; digit?
    BCC @Done
    ADC #$06			; = 'A'-'9'
@Done:
    RTS
    
.endif