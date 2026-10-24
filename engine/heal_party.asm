HealParty:
; Restore HP and PP.

	ld hl, wPartySpecies
	ld de, wPartyMon1HP
.healmon
	ld a, [hli]
	cp $ff
	jp z, .done

	push hl
	push de
	; Species list pointer is one past this Party index.
	; Cache its four extension bits across the inner PP table loop.
	ld a, l
	sub LOW(wPartySpecies + 1)
	ld c, a
	ld a, h
	sbc HIGH(wPartySpecies + 1)
	jr nz, .noExtendedMask
	ld a, c
	cp PARTY_LENGTH
	jr nc, .noExtendedMask
	ld b, 0
	ld hl, wExtendedPartyMoveFlags
	add hl, bc
	ld a, [hl]
	and $0f
	jr .gotExtendedMask
.noExtendedMask
	xor a
.gotExtendedMask
	ld [wExtendedMoveFlagsScratch], a

	ld hl, wPartyMon1Status - wPartyMon1HP
	add hl, de
	xor a
	ld [hl], a

	push de
	ld b, NUM_MOVES ; A Pokémon has 4 moves
.pp
	ld hl, wPartyMon1Moves - wPartyMon1HP
	add hl, de

	ld a, [hl]
	and a
	jr z, .nextmove

	dec a
	ld hl, wPartyMon1PP - wPartyMon1HP
	add hl, de

	push hl
	push de
	push bc
	; B counts 4,3,2,1, so the actual slot is (4-B).
	push af ; move ID minus one
	ld a, NUM_MOVES
	sub b
	ld c, a
	ld a, [wExtendedMoveFlagsScratch]
.extShift
	ld d, a
	ld a, c
	and a
	ld a, d
	jr z, .extBit
	srl a
	dec c
	jr .extShift
.extBit
	and 1
	jr z, .ordinaryBit
	pop af
	inc a ; one-based extended ordinal
	ld [wTempMoveID], a
	ld e, a
	callba LoadExtendedMoveStatsByOrdinalToCD6D
	jr c, .flaggedExtendedInvalid
	ld a, [wcd6d + 5]
	jr .haveBasePP
.flaggedExtendedInvalid
	ld a, [wTempMoveID]
	cp EXT_MOVE_SLOT_ESCAPE
	jr nz, .ordinaryMove
	ld a, 10 ; legacy $ff Power Whip compatibility only
	jr .haveBasePP
.ordinaryBit
	pop af
	cp EXT_MOVE_SLOT_ESCAPE - 1 ; already decremented in this loop
	jr nz, .ordinaryMove
	ld a, 10 ; legacy $ff Power Whip compatibility only
	jr .haveBasePP
.ordinaryMove
	ld hl, Moves
	ld bc, MoveEnd - Moves
	call AddNTimes
	ld de, wcd6d
	ld a, BANK(Moves)
	call FarCopyData
	ld a, [wcd6d + 5] ; PP is byte 5 of move data
.haveBasePP
	pop bc
	pop de
	pop hl

	inc de
	push bc
	ld b, a
	ld a, [hl]
	and $c0
	add b
	ld [hl], a
	pop bc

.nextmove
	dec b
	jr nz, .pp
	pop de

	ld hl, wPartyMon1MaxHP - wPartyMon1HP
	add hl, de
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hl]
	ld [de], a

	pop de
	pop hl

	push hl
	ld bc, wPartyMon2 - wPartyMon1
	ld h, d
	ld l, e
	add hl, bc
	ld d, h
	ld e, l
	pop hl
	jp .healmon

.done
	xor a
	ld [wWhichPokemon], a
	ld [wd11e], a

	ld a, [wPartyCount]
	ld b, a
.ppup
	push bc
	call RestoreBonusPP
	pop bc
	ld hl, wWhichPokemon
	inc [hl]
	dec b
	jr nz, .ppup
	ret
