; Shared decoder for packed Move / Item / Trainer names.
; GetName locates the selected packed entry in its source bank, then stores the
; source pointer/bank/length in wcd6d[0..3] before calling here. The decoder
; loads that metadata before it reuses the same buffer for the packed stream.
; The packed entry is copied once to the high end of the existing 20-byte wcd6d
; name scratch area, then expanded forward in place. Because expansion only grows
; the stream and the packed copy ends at wcd6d+$14, output cannot overwrite unread
; packed bytes. No extra WRAM buffer and no ROM0 token table are required.

PackedNameTokenPairs:
	db $a4, $b1 ; $01 = "er"
	db $ae, $ad ; $02 = "on"
	db $a8, $ad ; $03 = "in"
	db $a0, $b1 ; $04 = "ar"
	db $a2, $aa ; $05 = "ck"
	db $a0, $ad ; $06 = "an"
	db $ab, $a4 ; $07 = "le"
	db $ae, $b1 ; $08 = "or"
	db $a4, $a0 ; $09 = "ea"
	db $7f, $81 ; $0a = " B"
	db $a2, $a7 ; $0b = "ch"
	db $a4, $7f ; $0c = "e "
	db $ab, $a0 ; $0d = "la"
	db $b1, $a0 ; $0e = "ra"
	db $b4, $ad ; $0f = "un"
	db $a8, $b2 ; $10 = "is"
	db $ae, $b6 ; $11 = "ow"
	db $a4, $a4 ; $12 = "ee"
	db $7f, $92 ; $13 = " S"
	db $a8, $b3 ; $14 = "it"
	db $ab, $ab ; $15 = "ll"
	db $a0, $b3 ; $16 = "at"
	db $b2, $b3 ; $17 = "st"
	db $b4, $b1 ; $18 = "ur"
	db $7f, $8f ; $19 = " P"
	db $a8, $a2 ; $1a = "ic"
	db $8c, $a0 ; $1b = "Ma"
	db $a4, $b3 ; $1c = "et"
	db $a8, $b1 ; $1d = "ir"
	db $a3, $01 ; $1e = "der"
	db $a4, $ad ; $1f = "en"
	db $ae, $ab ; $20 = "ol"
	db $03, $a6 ; $21 = "ing"
	db $a8, $a3 ; $22 = "id"
	db $91, $ae ; $23 = "Ro"
	db $a8, $05 ; $24 = "ick"
	db $b2, $a7 ; $25 = "sh"
	db $b3, $b3 ; $26 = "tt"
	db $a6, $a4 ; $27 = "ge"
	db $ae, $b2 ; $28 = "os"
	db $7f, $80 ; $29 = " A"
	db $a0, $ac ; $2a = "am"
	db $a4, $ab ; $2b = "el"
	db $ae, $ac ; $2c = "om"
	db $af, $01 ; $2d = "per"
	db $b3, $a7 ; $2e = "th"
	db $0f, $0b ; $2f = "unch"
	db $8f, $ae ; $30 = "Po"
	db $92, $b3 ; $31 = "St"
	db $a8, $a6 ; $32 = "ig"
	db $7f, $82 ; $33 = " C"
	db $7f, $8a ; $34 = " K"
	db $7f, $93 ; $35 = " T"
	db $83, $0e ; $36 = "Dra"
	db $8b, $09 ; $37 = "Lea"
	db $a0, $05 ; $38 = "ack"
	db $a0, $ab ; $39 = "al"
	db $a8, $ab ; $3a = "il"
	db $b4, $a1 ; $3b = "ub"
	db $b4, $b3 ; $3c = "ut"
	db $01, $b1 ; $3d = "err"
	db $02, $a4 ; $3e = "one"
	db $0a, $3d ; $3f = " Berr"
	db $3f, $b8 ; $40 = " Berry"
PackedNameTokenPairsEnd:
ASSERT PackedNameTokenPairsEnd - PackedNameTokenPairs == $40 * 2

DecodePackedName::
	; wcd6d+0/+1 = source pointer (little endian)
	; wcd6d+2 = source bank
	; wcd6d+3 = packed length including @ terminator
	ld a,[wcd6d + 3]
	ld c,a
	ld b,0
	ld a,[wcd6d]
	ld l,a
	ld a,[wcd6d + 1]
	ld h,a
	ld a,LOW(wcd6d + $14)
	sub c
	ld e,a
	ld a,HIGH(wcd6d + $14)
	sbc b
	ld d,a
	push de ; packed RAM start
	ld a,[wcd6d + 2]
	call FarCopyData2
	pop hl
	ld de,wcd6d
.nextSymbol
	ld a,[hli]
	cp "@"
	jr z,.terminator
	push hl
	call .emitSymbol
	pop hl
	jr .nextSymbol
.terminator
	; Fill the rest of GetName's legacy 20-byte scratch window with terminators.
.padTail
	ld [de],a
	inc de
	ld a,e
	cp LOW(wcd6d + $14)
	jr nz,.morePadding
	ld a,d
	cp HIGH(wcd6d + $14)
	ret z
.morePadding
	ld a,"@"
	jr .padTail

.emitSymbol
	; A = packed symbol, DE = output. Tokens recursively expand to main-charmap bytes.
	cp $41
	jr nc,.raw
	dec a
	add a
	push de
	ld e,a
	ld d,0
	ld hl,PackedNameTokenPairs
	add hl,de
	ld a,[hli]
	ld c,a
	ld b,[hl]
	pop de ; recover output pointer
	push bc
	ld a,c
	call .emitSymbol
	pop bc
	ld a,b
	jp .emitSymbol
.raw
	ld [de],a
	inc de
	ret
