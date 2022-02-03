; LmaOS
;
; Copyright Nate Rivard 2020

.ifndef PSEUDOINSTRUCTIONS_INC
PSEUDOINSTRUCTIONS_INC = 1

;; 1 byte copy from one address to another
;;
;; {PARAM} address of source value
;; {PARAM} address of destination value
.macro COPY source, destination
    LDA source
    STA destination
.endmacro

;; 16 bit data copy from one address to another
;;
;; {PARAM} low-byte address of source 16 bit value
;; {PARAM} low-byte address of destination 16 bit value
.macro COPY16 source, destination
    LDA source
    STA destination
    LDA source + 1
    STA destination + 1
.endmacro

.macro COPYADDR addr, destination
    LDA #(<addr)
    STA destination
    LDA #(>addr)
    STA destination + 1
.endmacro

.macro SWAP lhs, rhs
	LDA lhs
	LDX rhs
	STX lhs
	STA rhs
.endmacro

.macro SWAP16 lhs, rhs
	SWAP lhs, rhs
	SWAP lhs + 1, rhs + 1
.endmacro

.macro ADD16 addr, imm
    CLC
    LDA addr
    ADC #<imm
    STA addr
    LDA addr + 1
    ADC #>imm
    STA addr + 1
.endmacro

;; 16 bit ADC
;;
;; { PARAM } low-byte address of 16-bit value
;; { PARAM } low-byte address of 16-bit value
;; { PARAM } low-byte address of desired 16-bit result
.macro ADC16 lhs, rhs, result
    CLC
    LDA lhs
    ADC rhs
    STA result
    LDA lhs + 1
    ADC rhs + 1
    STA result + 1
.endmacro

;; 16 bit SUB
;;
;; { PARAM } low-byte address of 16-bit value
;; { PARAM } low-byte address of 16-bit value
;; { PARAM } low-byte address of desired 16-bit result
.macro SBC16 lhs, rhs, result
	SEC
	LDA lhs
	SBC rhs
	STA result
	LDA lhs + 1
	SBC rhs + 1
	STA result + 1
.endmacro

;; 16 bit INC
;;
;; {PARAM} low-byte address of 16-bit value
;;
;; NOTE: Caller can check for zero bit in SR as it will only be zero when _both_
;; high and low bytes are zero
.macro INC16 addr
    INC addr
    BNE @NoWrap
    INC addr + 1
@NoWrap:
.endmacro

;; 16 bit DEC
;;
;; {PARAM} low-byte address of 16-bit value
;;
;; NOTE: SR status is based on lower byte only
.macro DEC16 addr
    LDA addr
    BNE @NoWrap
    DEC addr + 1
@NoWrap:
    DEC addr
.endmacro

.macro ROL16 addr
    ROL addr
    ROL addr + 1
.endmacro

.macro ROR16 addr
    ROR addr + 1
    ROR addr
.endmacro

.macro ASL16 addr
    ASL addr
    ROL addr + 1
.endmacro

.macro LSR16 addr
    LSR addr + 1
    ROR addr
.endmacro

;; -A (negate accumulator)
.macro NEG
    EOR #$FF
    INC A
.endmacro

.endif