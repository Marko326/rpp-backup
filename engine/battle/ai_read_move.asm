_ReadMove:: ; moved into same bank as actual move data
	; MOVE-5.62.192: D=1 selects a validated one-based EXT candidate
	; in E. The second table lives in another ROM bank, so read into wcd6d.
	ld a, d
	and a
	jr z, .ordinary
	push de
	callba LoadExtendedMoveStatsByOrdinalToCD6D
	pop de
	ret c
	ld hl, wcd6d
	ld de, wEnemyMoveNum
	ld bc, MoveEnd - Moves
	call CopyData
	ret ; no ordinary ID-specific overlays for EXT
.ordinary
	; EGG-A4-5.61.75: preserve the candidate ID so dynamic move-type overrides are
	; visible while trainer AI compares candidate moves.
	ld a, e
	inc a
	push af
	dec a
	ld hl,Moves
	ld bc,6
	call AddNTimes
	ld de,wEnemyMoveNum
	call CopyData
	pop af
	ld c, a ; callba clobbers A, so pass the real move ID in C
	callba ApplyEnemyCandidatePrimaryTypeOverride
	ret
