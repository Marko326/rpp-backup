; MOVE-5.62.179: TM/HM and Tutor teach ordinary moves. A matching low
; byte only counts as already known when that Party slot's extended bit is clear.
; Keep scanning after a flagged collision (e.g. ordinary Swords Dance versus
; expanded ordinal 14). Preserve DE for callers; carry remains the result.
CheckIfMoveIsKnown:
	push de
	ld a, [wWhichPokemon]
	ld hl, wPartyMon1Moves
	ld bc, wPartyMon2 - wPartyMon1
	call AddNTimes
	ld a, [wWhichPokemon]
	ld e, a
	ld d, 0
	push hl
	ld hl, wExtendedPartyMoveFlags
	add hl, de
	ld d, [hl] ; bit 0 = first move slot
	pop hl
	ld a, [wMoveNum]
	ld b, a
	ld c, NUM_MOVES
.loop
	ld a, [hli]
	cp b
	jr nz, .nextSlot
	bit 0, d
	jr z, .alreadyKnown ; matching ordinary identity
.nextSlot
	srl d
	dec c
	jr nz, .loop
	pop de
	and a ; not known: carry clear
	ret
.alreadyKnown
	pop de
	ld hl, AlreadyKnowsText
	call PrintText
	scf
	ret

AlreadyKnowsText:
	TX_FAR _AlreadyKnowsText
	db "@"
