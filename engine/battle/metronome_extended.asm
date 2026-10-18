; MOVE-5.62.187: Metronome child is a temporary full move identity, not a
; replacement of the actor's learned/Transform/Mimic slot. Both sides share
; the exact same 9-bit rejection sampler (ordinary 1..DIVE-1 + EXT 1..40).
; Uniform over 290 candidates before rejecting the original two exclusions:
; METRONOME and STRUGGLE. Legacy Dive and later IDs stay excluded.
; BattleRandomFar returns its byte in E; far calls overwrite A/B/C/HL.
SECTION "Metronome Full Identity Selector", ROMX

MetronomePickFullIdentity_::
.pickMoveLoop
	callab BattleRandomFar
	ld d, e ; low eight random bits survive the second far call
	callab BattleRandomFar
	ld a, e
	and 1 ; one more random bit gives a 0..511 uniform draw
	jr nz, .highRange
	ld a, d
	cp DIVE - 1 ; indices 0..249 are ordinary move IDs 1..250
	jr c, .ordinary
	; lower 250..255 represent EXT ordinals 1..6
	sub DIVE - 2
	jr .extended
.highRange
	ld a, d
	; upper 256..289 represent EXT ordinals 7..40
	cp NUM_EXTENDED_MOVES - (256 - (DIVE - 1))
	jr nc, .pickMoveLoop
	add 256 - (DIVE - 1) + 1
.extended
	ld [wExtendedActiveMoveOrdinal], a
	jr .storeChild
.ordinary
	inc a
	cp METRONOME
	jr z, .pickMoveLoop
	cp STRUGGLE
	jr z, .pickMoveLoop
	push af
	xor a
	ld [wExtendedActiveMoveOrdinal], a
	pop af
.storeChild
	; A is both the ordinary byte and the one-based EXT ordinal. The
	; identity is carried separately, never written to the four slot bits.
	ld [wd11e], a
	ldh a, [H_WHOSETURN]
	and a
	ld hl, wPlayerSelectedMove
	ld de, wPlayerMoveNum
	jr z, .reload
	ld hl, wEnemySelectedMove
	ld de, wEnemyMoveNum
.reload
	ld a, [wd11e]
	ld [hl], a
	dec a
	ld hl, Moves
	ld bc, MoveEnd - Moves
	call AddNTimes
	ld a, BANK(Moves)
	call FarCopyData
	; Metronome's own PP is already paid. A second child call must not
	; consume the root slot again (the old ReloadMoveData convention).
	callab IncrementMovePP
	; The resolved ordinal must NOT be recomputed from a root slot.
	jpba FinalizeMirroredMoveData
