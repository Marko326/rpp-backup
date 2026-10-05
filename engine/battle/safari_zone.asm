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
	; FORM-5.62.12: restore Catch Rate from the already-resolved enemy form.
	; Reloading the stock species header here would silently drop a regional form.
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
