PrintSafariZoneBattleText:
	ld hl, wSafariBaitFactor
	ld a, [hl]
	and a
	jr z, .asm_4284
	dec [hl]
	ld hl, SafariZoneEatingText
	jr .asm_429f
.asm_4284
	dec hl
	ld a, [hl]
	and a
	ret z
	dec [hl]
	ld hl, SafariZoneAngryText
	jr nz, .asm_429f
	push hl
	; FRM-5.61.46: restore the catch rate from the already-resolved enemy form.
	; Reloading the stock header here could silently revert a regional encounter.
	callba RegionalFormLoadCurrentEnemyHeader
	ld a, [wMonHCatchRate]
	ld [wEnemyMonCatchRate], a
	pop hl
.asm_429f
	push hl
	call LoadScreenTilesFromBuffer1
	pop hl
	jp PrintText

SafariZoneEatingText:
	TX_FAR _SafariZoneEatingText
	db "@"

SafariZoneAngryText:
	TX_FAR _SafariZoneAngryText
	db "@"
