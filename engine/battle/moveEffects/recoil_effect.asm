RecoilEffect_:
	; RCL-5.62.40: resolve recoil fraction by real Move ID in roomy Bank $3E.
	; The far helper returns the 16-bit recoil amount in DE because Bankswitch
	; uses A/B/C/HL while restoring the caller's ROM bank.
	callab CalculateRecoilDamage
	ld b, d
	ld c, e
	ld a, [H_WHOSETURN]
	and a
	ld hl, wBattleMonMaxHP
	jr z, .updateHP
	ld hl, wEnemyMonMaxHP
.updateHP
; subtract HP from user due to the recoil damage
	ld a, [hli]
	ld [wHPBarMaxHP+1], a
	ld a, [hl]
	ld [wHPBarMaxHP], a
	push bc
	ld bc, wBattleMonHP - wBattleMonMaxHP
	add hl, bc
	pop bc
	ld a, [hl]
	ld [wHPBarOldHP], a
	sub c
	ld [hld], a
	ld [wHPBarNewHP], a
	ld a, [hl]
	ld [wHPBarOldHP+1], a
	sbc b
	ld [hl], a
	ld [wHPBarNewHP+1], a
	jr nc, .getHPBarCoords
; if recoil damage is higher than the Pokemon's HP, set its HP to 0
	xor a
	ld [hli], a
	ld [hl], a
	ld hl, wHPBarNewHP
	ld [hli], a
	ld [hl], a
.getHPBarCoords
	coord hl, 10, 9
	ld a, [H_WHOSETURN]
	and a
	ld a, $1
	jr z, .updateHPBar
	coord hl, 2, 2
	xor a
.updateHPBar
	ld [wHPBarType], a
	predef UpdateHPBar2
	ld hl, HitWithRecoilText
	jp PrintText
HitWithRecoilText:
	TX_FAR _HitWithRecoilText
	db "@"
