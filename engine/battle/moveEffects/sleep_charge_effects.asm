; Sleep and charge-turn move effects moved out of capacity-constrained Bank F.
; Bank F keeps only SleepEffect / ChargeEffect jpab entries used by MoveEffectPointerTable.

SleepEffect_:
	ld de, wEnemyMonStatus
	ld bc, wEnemyBattleStatus2
	ld a, [H_WHOSETURN]
	and a
	jp z, .sleepEffect
	ld de, wBattleMonStatus
	ld bc, wPlayerBattleStatus2

.sleepEffect
	ld a, [bc]
	res NeedsToRecharge, a ; target no longer needs to recharge
	ld [bc], a
	ld a, [de]
	ld b, a
	and $7
	jr z, .notAlreadySleeping ; can't affect a mon that is already asleep
	ld hl, AlreadyAsleepText
	jp PrintText
.notAlreadySleeping
	ld a, b
	and a
	jr nz, .didntAffect ; can't affect a mon that is already statused
	push de
	callab MoveHitTest ; apply accuracy tests
	pop de
	ld a, [wMoveMissed]
	and a
	jr nz, .didntAffect
.setSleepCounter
; Externally induced sleep is measured by the target's actual action checks,
; not by elapsed natural battle rounds. Store 2-5; the status routine first
; decrements the counter, producing 1-4 skipped actions. The first check always
; prevents movement, and the check after the fourth skipped action always wakes.
; If inflicted before the target acts, the current round is the first check;
; if inflicted after it acted, the first check occurs on its next action.
.randomSleepTurns
	; BattleRandomFar returns the random byte in E, so preserve the target status
	; pointer in DE until the random result has been copied into A.
	push de
	callab BattleRandomFar
	ld a, e
	pop de
	and $3
	add 2
	ld [de], a
	callab PlayCurrentMoveAnimation2
	ld hl, FellAsleepText
	jp PrintText
.didntAffect
	jpab PrintDidntAffectText

FellAsleepText:
	TX_FAR _FellAsleepText
	db "@"

AlreadyAsleepText:
	TX_FAR _AlreadyAsleepText
	db "@"

ChargeEffect_:
	ld hl, wPlayerBattleStatus1
	ld de, wPlayerMoveEffect
	ld a, [H_WHOSETURN]
	and a
	ld b, XSTATITEM_ANIM
	jr z, .chargeEffect
	ld hl, wEnemyBattleStatus1
	ld de, wEnemyMoveEffect
	ld b, ANIM_AF
.chargeEffect
	set ChargingUp, [hl]
	ld a, [de]
	cp FLY_EFFECT
	jr nz, .notFly
	set Invulnerable, [hl] ; mon is now invulnerable to typical attacks (fly/dig)
	ld b, TELEPORT ; load Teleport's animation
.notFly
	call GetCurrentMoveID
	ld [wChargeMoveNum], a
	; DIVE is currently unused and intentionally has no dedicated
	; invulnerability/charge-text path yet.
	cp DIG
	jr nz, .notDigOrFly
	set Invulnerable, [hl] ; mon is now invulnerable to typical attacks (fly/dig)
	ld b, ANIM_C0
.notDigOrFly
	xor a
	ld [wAnimationType], a
	ld a, b
	; callab/Bankswitch clobbers A while switching ROM banks. Commit the chosen
	; animation ID to WRAM first, then use the memory-based animation entry.
	ld [wAnimationID], a
	callab PlayBattleAnimationGotID
	ld hl, ChargeMoveEffectText
	jp PrintText

ChargeMoveEffectText:
	TX_FAR _ChargeMoveEffectText
	TX_ASM
	ld a, [wChargeMoveNum]
	cp RAZOR_WIND
	ld hl, MadeWhirlwindText
	jr z, .gotText
	cp SOLARBEAM
	ld hl, TookInSunlightText
	jr z, .gotText
	cp SKULL_BASH
	ld hl, LoweredItsHeadText
	jr z, .gotText
	cp SKY_ATTACK
	ld hl, SkyAttackGlowingText
	jr z, .gotText
	cp FLY
	ld hl, FlewUpHighText
	jr z, .gotText
	cp DIG
	ld hl, DugAHoleText
.gotText
	ret

MadeWhirlwindText:
	TX_FAR _MadeWhirlwindText
	db "@"

TookInSunlightText:
	TX_FAR _TookInSunlightText
	db "@"

LoweredItsHeadText:
	TX_FAR _LoweredItsHeadText
	db "@"

SkyAttackGlowingText:
	TX_FAR _SkyAttackGlowingText
	db "@"

FlewUpHighText:
	TX_FAR _FlewUpHighText
	db "@"

DugAHoleText:
	TX_FAR _DugAHoleText
	db "@"
