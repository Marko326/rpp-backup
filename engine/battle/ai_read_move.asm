_ReadMove:: ; moved into same bank as actual move data
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
