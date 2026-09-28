; BATTLE-5.61.20: poison-family move effects moved out of Bank F.
; PoisonEffect remains the local MoveEffectPointerTable entry; this body preserves
; the existing Poison/Toxic/Poison Fang behavior, including text-pointer safety.

PoisonEffect_:
	ld hl, wEnemyMonStatus
	ld de, wPlayerMoveEffect
	ld a, [H_WHOSETURN]
	and a
	jr z, .poisonEffect
	ld hl, wBattleMonStatus
	ld de, wEnemyMoveEffect
.poisonEffect
	; CheckTargetSubstitute lives in Bank F and returns only flags. Reproduce its
	; tiny target test locally so a far call does not destroy the result contract.
	push hl
	ld hl, wEnemyBattleStatus2
	ld a, [H_WHOSETURN]
	and a
	jr z, .gotTargetBattleStatus
	ld hl, wPlayerBattleStatus2
.gotTargetBattleStatus
	bit HasSubstituteUp, [hl]
	pop hl
	jp nz, .noEffect

	ld a, [hli]
	ld b, a
	and a
	jp nz, .noEffect
	ld a, [hli]
	cp POISON
	jp z, .noEffect
	cp STEEL
	jp z, .noEffect
	ld a, [hld]
	cp POISON
	jp z, .noEffect
	cp STEEL
	jp z, .noEffect

	ld a, [de]
	cp POISON_SIDE_EFFECT1
	ld b, $34
	jr z, .sideEffectTest
	cp POISON_SIDE_EFFECT2
	ld b, $67
	jr z, .sideEffectTest
	cp POISON_FANG_EFFECT
	ld b, $67
	jr z, .sideEffectTest

	push hl
	push de
	callab MoveHitTest
	pop de
	pop hl
	ld a, [wMoveMissed]
	and a
	jr nz, .didntAffect
	jr .inflictPoison

.sideEffectTest
	push hl
	push de
	push bc
	callab BattleRandomFar
	ld a, e
	pop bc
	pop de
	pop hl
	cp b
	ret nc

.inflictPoison
	dec hl
	set 3, [hl]
	push de
	ld a, [H_WHOSETURN]
	and a
	ld b, ANIM_C7
	ld hl, wPlayerBattleStatus3
	ld de, wPlayerToxicCounter
	jr nz, .gotToxicState
	ld b, ANIM_A9
	ld hl, wEnemyBattleStatus3
	ld de, wEnemyToxicCounter
.gotToxicState
	call GetCurrentMoveID
	cp POISON_FANG
	jr z, .badlyPoison
	cp TOXIC
	jr nz, .normalPoison
.badlyPoison
	set BadlyPoisoned, [hl]
	xor a
	ld [de], a
	ld hl, BadlyPoisonedText
	jr .continue
.normalPoison
	ld hl, PoisonedText
.continue
	pop de
	ld a, [de]
	cp POISON_EFFECT
	jr z, .regularPoisonEffect

	; PlayBattleAnimation2 used to receive B through a same-bank call. Commit the
	; animation ID/type to WRAM before the far call and preserve the result text HL.
	ld a, b
	ld [wAnimationID], a
	ld a, [H_WHOSETURN]
	and a
	ld a, $6
	jr z, .storeAnimationType
	ld a, $3
.storeAnimationType
	ld [wAnimationType], a
	push hl
	callab PlayBattleAnimationGotID
	pop hl
	jp PrintText

.regularPoisonEffect
	; Preserve the existing result-text pointer across the banked move animation.
	push hl
	callab PlayCurrentMoveAnimation2
	pop hl
	jp PrintText

.noEffect
	ld a, [de]
	cp POISON_EFFECT
	ret nz
.didntAffect
	ld c, 50
	call DelayFrames
	jpab PrintDidntAffectText

PoisonedText:
	TX_FAR _PoisonedText
	db "@"

BadlyPoisonedText:
	TX_FAR _BadlyPoisonedText
	db "@"
