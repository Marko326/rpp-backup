TransformEffect_:
	ld hl, wBattleMonSpecies
	ld de, wEnemyMonSpecies
	ld bc, wEnemyBattleStatus3
	ld a, [H_WHOSETURN]
	and a
	jr z, .playerUser
	; BTL-5.62.19: enemy user targets the player, so the Fly/Dig test must
	; inspect the player's BattleStatus1 instead of the turn selector itself.
	ld a, [wPlayerBattleStatus1]
	jr .hitTest
.playerUser
	ld hl, wEnemyMonSpecies
	ld de, wBattleMonSpecies
	ld bc, wPlayerBattleStatus3
	ld [wPlayerMoveListIndex], a
	; Player user targets the enemy; preserve the target's BattleStatus1 for the
	; Invulnerable test after the Transform identity checks.
	ld a, [wEnemyBattleStatus1]
.hitTest
	; TRN-5.62.18: reject a second Transform before any animation/data copy, and
	; reject an already-identical Species + runtime form. Same Species with a
	; different regional form is still a meaningful Transform and remains allowed.
	push af
	ld a, [bc]
	bit Transformed, a
	jr nz, .identityFailed
	call .sameSpeciesAndForm
	jr nz, .differentIdentity
.identityFailed
	pop af
	jp .failed
.differentIdentity
	pop af
	bit Invulnerable, a ; is mon invulnerable to typical attacks? (fly/dig)
	jp nz, .failed
	push hl
	push de
	push bc
	; TRN-5.62.18: all failure conditions have passed. Cache the user's exact
	; pre-transform palette before the animation changes Species/Form. A short-lived
	; staging bit makes palette reloads during the animation use this cache without
	; changing the stock timing of the battle-status Transformed flag.
	callba CacheTransformUserPalette
	ld hl, wPlayerBattleStatus2
	ld a, [H_WHOSETURN]
	and a
	jr z, .transformEffect
	ld hl, wEnemyBattleStatus2
.transformEffect
; animation(s) played are different if target has Substitute up
	bit HasSubstituteUp, [hl]
	push af
	ld hl, HideSubstituteShowMonAnim
	ld b, BANK(HideSubstituteShowMonAnim)
	call nz, Bankswitch
	ld a, [wOptions]
	add a
	ld hl, PlayCurrentMoveAnimation
	ld b, BANK(PlayCurrentMoveAnimation)
	jr nc, .gotAnimToPlay
	ld hl, AnimationTransformMon
	ld b, BANK(AnimationTransformMon)
.gotAnimToPlay
	call Bankswitch
	ld hl, ReshowSubstituteAnim
	ld b, BANK(ReshowSubstituteAnim)
	pop af
	call nz, Bankswitch
	pop bc
	ld a, [bc]
	set Transformed, a ; mon is now Transformed
	ld [bc], a
	; The permanent battle-status bit now owns palette restoration.
	callba ClearTransformPaletteStaging
	pop de
	pop hl
	push hl
; transform user into opposing Pokemon
; species
	ld a, [hl]
	ld [de], a
; type 1, type 2, catch rate, and moves
	ld bc, $5
	add hl, bc
	inc de
	inc de
	inc de
	inc de
	inc de
	inc bc
	inc bc
	call CopyData
	ld a, [H_WHOSETURN]
	and a
	jr z, .next
; save enemy mon DVs at wTransformedEnemyMonOriginalDVs
	ld a, [de]
	ld [wTransformedEnemyMonOriginalDVs], a
	inc de
	ld a, [de]
	ld [wTransformedEnemyMonOriginalDVs + 1], a
	dec de
.next
; DVs
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hli]
	ld [de], a
	inc de
; Attack, Defense, Speed, and Special stats
	inc hl
	inc hl
	inc hl
	inc de
	inc de
	inc de
	ld bc, $8
	call CopyData
	ld bc, wBattleMonMoves - wBattleMonPP
	add hl, bc ; ld hl, wBattleMonMoves
	ld b, NUM_MOVES
.copyPPLoop
; 5 PP for all moves
	ld a, [hli]
	and a
	jr z, .lessThanFourMoves
	ld a, $5
	ld [de], a
	inc de
	dec b
	jr nz, .copyPPLoop
	jr .copyStats
.lessThanFourMoves
; 0 PP for blank moves
	xor a
	ld [de], a
	inc de
	dec b
	jr nz, .lessThanFourMoves
.copyStats
; original (unmodified) stats and stat mods
	pop hl
	ld a, [hl]
	ld [wd11e], a
	call GetMonName
	ld hl, wEnemyMonUnmodifiedAttack
	ld de, wPlayerMonUnmodifiedAttack
	call .copyBasedOnTurn ; original (unmodified) stats
	ld hl, wEnemyMonStatMods
	ld de, wPlayerMonStatMods
	call .copyBasedOnTurn ; stat mods
	ld hl, TransformedText
	jp PrintText

.sameSpeciesAndForm
; Return Z only when both active battle slots have the same Species and runtime
; regional form. Preserve the Transform copy pointers used by the caller.
	push bc
	push de
	push hl
	ld a, [wEnemyMonSpecies]
	ld d, a
	ld a, [wBattleMonSpecies]
	cp d
	jr nz, .identityCompared
	ld e, 0 ; player battle slot
	callba RegionalFormGetBattleSlotFormIdentity
	ld a, d
	push af
	ld e, 1 ; enemy battle slot
	callba RegionalFormGetBattleSlotFormIdentity
	ld e, d
	pop af
	cp e
.identityCompared
	pop hl
	pop de
	pop bc
	ret

.copyBasedOnTurn
	ld a, [H_WHOSETURN]
	and a
	jr z, .gotStatsOrModsToCopy
	push hl
	ld h, d
	ld l, e
	pop de
.gotStatsOrModsToCopy
	ld bc, $8
	jp CopyData

.failed
	; BTL-5.62.19: ResidualEffects1 skips the common post-move pause. Match
	; other direct-failure effects so the move-use text remains readable first.
	ld c, 50
	call DelayFrames
	ld hl, PrintButItFailedText_
	jp BankswitchEtoF

TransformedText:
	TX_FAR _TransformedText
	db "@"
