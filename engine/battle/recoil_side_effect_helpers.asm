; RCL-5.62.40: move-specific recoil policy for damaging recoil moves.
; Keep the stock Gen I 1/4 fallback, Struggle at 1/2, and modern heavy recoil
; moves at 1/3 without multiplying effect IDs for each recoil fraction.

CalculateRecoilDamage:
	call GetDamageSideEffectMoveID
	ld c, a
	ld hl, RecoilDivisorTable
.findMove
	ld a, [hli]
	cp -1
	jr z, .defaultQuarter
	cp c
	jr z, .foundMove
	inc hl ; skip divisor byte
	jr .findMove
.foundMove
	ld a, [hl]
	jr .divide
.defaultQuarter
	ld a, 4
.divide
	ld [H_DIVISOR], a
	ld a, [wDamage]
	ld [H_DIVIDEND], a
	ld a, [wDamage + 1]
	ld [H_DIVIDEND + 1], a
	ld b, 2
	call Divide
	ld a, [H_QUOTIENT + 2]
	ld d, a
	ld a, [H_QUOTIENT + 3]
	ld e, a
	or d
	ret nz
	inc e ; minimum recoil damage is 1
	ret

RecoilDivisorTable:
	db STRUGGLE,    2
	db FLARE_BLITZ, 3
	db VOLT_TACKLE, 3
	db WOOD_HAMMER, 3
	db -1

; SUB-5.62.42: all normal damaging recoil resolves immediately after damage,
; before any attacker Substitute sprite is restored. The ordinary effect-based
; recoil uses RECOIL_EFFECT; burn/paralysis recoil moves use real Move ID.
HandlePostDamageRecoil:
	ld hl, wPlayerMoveEffect
	ld a, [H_WHOSETURN]
	and a
	jr z, .checkEffect
	ld hl, wEnemyMoveEffect
.checkEffect
	ld a, [hl]
	cp RECOIL_EFFECT
	jr z, .applyRecoil

	call GetDamageSideEffectMoveID
	cp FLARE_BLITZ
	jr z, .applyRecoil
	cp VOLT_TACKLE
	ret nz
.applyRecoil
	callab RecoilEffect_
	ret
