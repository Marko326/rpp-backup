; MOVE-5.62.193: ordinary-species EXT level-up sources.
; Added without touching legacy packed learnsets, day-care/wild producers,
; Party/PC/SRAM layout, or regional-form independent learnsets.
;
; Row: species (1..NUM_POKEMON), level (1..100), ordinal (1..40).
; End: $ff species byte. The macro guarantees the per-species count.
; Data and lookup routines share one floating ROMX FRAGMENT section,
; so direct [HL] ROM reads use the correct currently-switched bank.

TryLearnExtendedLevelUpSources::
	ld hl,ExtendedLevelUpSources
.loop
	ld a,[hli]
	cp $ff
	jr z,.done
	ld b,a ; source species
	ld a,[hli]
	ld c,a ; source level
	ld a,[hli]
	ld e,a ; one-based EXT ordinal
	ld a,[wcf91]
	cp b
	jr nz,.loop
	ld a,[wCurEnemyLVL]
	cp c
	jr nz,.loop
	push hl
	push bc
	ld d,e ; packed slot byte == ordinal, not $ff
	callba TryLearnPartyLevelMove
	pop bc
	pop hl
	jr .loop
.done
	xor a
	ld [wExtendedLearningMoveOrdinal],a
	ld a,[wcf91]
	ld [wd11e],a
	ret

; Called after the normal relearner has built [wRelearnableMoves].
; Its selected Party member is in wWhichPokemon and current level wBuffer;
; wExtendedMoveFlagsScratch contains the Party's four-bit EXT slot mask.
AppendExtendedLevelUpRelearnMoves::
	ld hl,ExtendedLevelUpSources
.loop
	ld a,[hli]
	cp $ff
	jp z,.finish
	ld b,a ; candidate species
	ld a,[hli]
	ld c,a ; candidate level
	ld a,[hli]
	ld [wExtendedLearningMoveOrdinal],a ; candidate ordinal
	push hl
	ld a,[wWhichPokemon]
	ld e,a
	ld d,0
	ld hl,wPartySpecies
	add hl,de
	ld a,[hl]
	pop hl
	cp b
	jr nz,.loop
	ld a,[wBuffer]
	cp c
	jr c,.loop

	push hl
	ld a,[wWhichPokemon]
	ld hl,wPartyMon1Moves
	ld bc,wPartyMon2 - wPartyMon1
	call AddNTimes
	ld b,NUM_MOVES
	ld a,[wExtendedMoveFlagsScratch]
	ld c,a
.checkKnown
	ld a,[hli]
	ld d,a
	ld a,[wExtendedLearningMoveOrdinal]
	cp d
	jr nz,.nextKnown
	bit 0,c
	jr nz,.candidateHandled
.nextKnown
	srl c
	dec b
	jr nz,.checkKnown

	ld a,[wRelearnableMoves]
	cp MOVE_RELEARNER_MAX_MOVES
	jr nc,.candidateHandled
	ld e,a
	ld d,0
	ld hl,wRelearnableMoves + 1
	add hl,de
	ld a,[wExtendedLearningMoveOrdinal]
	ld [hl],a
	ld hl,wExtendedNPCListMoveOrdinals
	add hl,de
	ld [hl],a
	ld hl,wRelearnableMoves
	inc [hl]
.candidateHandled
	pop hl
	jp .loop
.finish
	xor a
	ld [wExtendedLearningMoveOrdinal],a
	ld a,[wRelearnableMoves]
	ld e,a
	ld d,0
	ld hl,wRelearnableMoves + 1
	add hl,de
	ld [hl],$ff
	ret
