; MOVE-5.62.178: common Party level-up move learner.
; Input: D = stored move byte, E = extended ordinal (0 = ordinary).
; A/BC/HL are not far-call arguments. Preserve BC/DE/HL for both parsers.
; Matching a known move requires BOTH its low byte and extension bit.
; wExtendedLearningMoveOrdinal is temporary and cleared on every exit.
; This does not parse learnsets or register moves with the relearner.
TryLearnPartyLevelMove::
	push bc
	push hl
	push de
	ld a,e
	and a
	jr z,.validCandidate
	cp NUM_EXTENDED_MOVES + 1
	jp nc,.done
	cp d ; extended slot byte must equal its one-based ordinal
	jp nz,.done
.validCandidate
	ld a,[wWhichPokemon]
	cp PARTY_LENGTH
	jp nc,.done
	ld e,a
	ld d,0
	ld hl,wExtendedPartyMoveFlags
	add hl,de
	ld a,[hl]
	push af
	ld hl,wPartyMon1Moves
	ld a,[wWhichPokemon]
	ld bc,wPartyMon2 - wPartyMon1
	call AddNTimes
	pop af
	ld c,a ; lower four bits identify extended slots
	pop de ; recover requested D=move, E=ordinal
	push de
	ld b,NUM_MOVES
.scan
	ld a,[hli]
	cp d
	jr nz,.nextSlot
	ld a,c
	and 1
	ld a,e
	jr z,.ordinarySlot
	and a
	jp nz,.done ; extended identity already held
	jr .nextSlot
.ordinarySlot
	and a
	jp z,.done ; ordinary identity already held
.nextSlot
	srl c
	dec b
	jr nz,.scan

	; The same prompt and LearnMove path serves ordinary and expanded IDs.
	ld a,e
	ld [wExtendedLearningMoveOrdinal],a
	ld a,d
	ld [wMoveNum],a
	ld [wd11e],a
	ld a,e
	and a
	jr z,.ordinaryName
	callba LoadExtendedMoveNameByOrdinalToCD6D
	jp c,.done
	jr .copyName
.ordinaryName
	call GetMoveName
	callab MaybeRenameRockPolishLearningMoveName
.copyName
	; Extended name loader leaves DE after '@'; always reset explicitly.
	ld de,wcd6d
	call CopyStringToCF4B
	predef LearnMove
.done
	xor a
	ld [wExtendedLearningMoveOrdinal],a
	pop de
	pop hl
	pop bc
	ret
