; FORM-5.62.12: first-render helpers for one-shot Pokédex pages.
; Kept in a floating ROMX section so this one-shot renderer does not consume
; fixed bank $34 expansion room.

PokedexData_PrepareInitialViewForm::
	ld a,[wcf91]
	ld d,a
	ld a,[wPokedexViewForm]
	ld e,a
	; Preserve one Species+Form pair across both bank-$34 operations. DE survives
	; CALLBA's trampoline while A/BC/HL are scratch.
	push de
	callba RegionalFormLoadPokedexHeader
	pop de
	callba RegionalFormOverridePokedexPalette
	ret

PokedexData_OverrideInitialViewMetrics::
	ld a,[wPokedexViewForm]
	and a
	ret z
	; Reuse the established form-aware metric reader from the Pokédex helper bank.
	callba PokedexData_CopyHeightWeightFields

	ld de,wBuffer + 14
	coord hl,12,6
	lb bc,1,2
	call PrintNumber
	ld a,$60
	ld [hl],a
	ld de,wBuffer + 15
	coord hl,15,6
	lb bc,LEADING_ZEROES | 1,2
	call PrintNumber
	ld a,$61
	ld [hl],a

	; PrintNumber expects big-endian input. Keep the same scratch convention as
	; the internal form renderer and leave hDexWeight untouched.
	ld a,[wBuffer + 17]
	ld [wBuffer + 12],a
	ld a,[wBuffer + 16]
	ld [wBuffer + 13],a
	ld de,wBuffer + 12
	coord hl,11,8
	lb bc,2,5
	call PrintNumber
	coord hl,14,8
	ld a,[wBuffer + 13]
	sub 10
	ld a,[wBuffer + 12]
	sbc 0
	jr nc,.weightAtLeastTen
	ld [hl],"0"
.weightAtLeastTen
	inc hl
	ld a,[hli]
	ld [hld],a
	ld [hl],"⠄"
	ret
