; FORM-5.27.00: compact stock ROM BaseStats decoder.
;
; Stock records are 24 bytes in ROM instead of the historical 28:
; - Pokédex id is implied by BaseStats/Pokédex table order.
; - Tutor 17-32 are stored only when nonzero in BaseStatsTutorHighCompat.
; - Growth rate uses a 2-bit common table plus sparse arbitrary-value overrides.
;
; Sprite dimensions remain sourced directly from the generated .pic header and
; picture bank remains explicit. Runtime ABI is deliberately unchanged:
; wMonHeader is still materialized in the legacy 28-byte layout.
;
; Input: HL = compact 24-byte stock BaseStats record.
; Bank $30 must already be mapped by GetMonHeader.
DecodeCompactMonHeader::
	ld de,wMonHeader
	ld a,[wd0b5]
	ld [de],a ; synthesized wMonHIndex
	inc de

	; HP/Atk/Def/Spd/Special, types, catch rate, base EXP, sprite dimensions.
	ld c,10
.copyPrefix
	ld a,[hli]
	ld [de],a
	inc de
	dec c
	jr nz,.copyPrefix

	; Front/back sprite pointers.
	ld c,4
.copyPics
	ld a,[hli]
	ld [de],a
	inc de
	dec c
	jr nz,.copyPics

	; Tutor 1-16 stay inline in the compact record.
	ld c,2
.copyTutorLow
	ld a,[hli]
	ld [de],a
	inc de
	dec c
	jr nz,.copyTutorLow

	; Tutor 17-32 remain independently extensible through the sparse table.
	push hl
	call LoadCompactMonTutorHigh
	pop hl

	; Growth is independent of sprite dimensions and packed four species/byte.
	push hl
	call GetCompactMonGrowthRate
	ld b,a
	pop hl
	ld a,b
	ld [de],a
	inc de

	; Seven TM/HM bytes plus explicit picture bank.
	ld c,8
.copyTail
	ld a,[hli]
	ld [de],a
	inc de
	dec c
	jr nz,.copyTail
	ret

; Input: DE = destination for wMonHMoves bytes 3-4.
; Output: writes two bytes and advances DE by 2.
; Table format: species, Tutor17-24 byte, Tutor25-32 byte; species 0 terminates.
LoadCompactMonTutorHigh:
	ld a,[wd0b5]
	ld b,a
	ld hl,BaseStatsTutorHighCompat
.scan
	ld a,[hli]
	and a
	jr z,.zero
	cp b
	jr z,.found
	inc hl
	inc hl
	jr .scan
.found
	ld a,[hli]
	ld [de],a
	inc de
	ld a,[hl]
	ld [de],a
	inc de
	ret
.zero
	xor a
	ld [de],a
	inc de
	ld [de],a
	inc de
	ret

; Returns A = historical raw growth-rate byte for the current stock Pokémon.
; wd11e still contains its 1-based Pokédex number while GetMonHeader
; is materializing the record.
GetCompactMonGrowthRate:
	push de
	; First honor a per-species raw-byte override. This preserves the original
	; ability to introduce any future growth-rate value, not only 0/3/4/5.
	ld a,[wd0b5]
	ld b,a
	ld hl,BaseStatsGrowthRateOverrides
.overrideScan
	ld a,[hli]
	and a
	jr z,.packed
	cp b
	jr z,.overrideFound
	inc hl
	jr .overrideScan
.overrideFound
	ld a,[hl]
	pop de
	ret

.packed
	ld a,[wd11e]
	dec a
	ld c,a              ; zero-based Pokédex index
	and %00000011
	ld b,a              ; slot within packed byte (0..3)
	ld a,c
	srl a
	srl a               ; packed-byte index
	ld e,a
	ld d,0
	ld hl,BaseStatsGrowthRates
	add hl,de
	ld a,[hl]
	ld c,b
.shift
	ld b,a
	ld a,c
	and a
	jr z,.shiftDone
	dec c
	ld a,b
	srl a
	srl a
	jr .shift
.shiftDone
	ld a,b
	and %00000011
	ld e,a
	ld d,0
	ld hl,.growthValues
	add hl,de
	ld a,[hl]
	pop de
	ret
.growthValues
	db 0,3,4,5
