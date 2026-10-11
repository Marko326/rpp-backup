; ANIM-5.62.94: two independent poison rolls for Twineedle.
; Called after a successful non-Substitute hit only. The battle loop retains
; Twineedle's original TWO-HIT effect setup, and skips its old final poison roll.
; The current move ID is checked by both callers before banking here.
TryTwineedlePoisonAfterHit::
	ld a, [wMoveMissed]
	and a
	ret nz
	ld a, [wDamage]
	ld b, a
	ld a, [wDamage + 1]
	or b
	ret z

	; A KO ends the multi-hit sequence; do not poison a fainted target.
	ld a, [H_WHOSETURN]
	and a
	ld hl, wEnemyMonHP
	jr z, .checkTargetHP
	ld hl, wBattleMonHP
.checkTargetHP
	ld a, [hli]
	or [hl]
	ret z

	; First hit still has TWINEEDLE_EFFECT; subsequent hits have
	; POISON_SIDE_EFFECT1. Preserve and restore the original effect so
	; TwoToFiveAttacksEffect can initialize / finish the two-hit loop.
	ld a, [H_WHOSETURN]
	and a
	ld hl, wPlayerMoveEffect
	jr z, .setPoisonEffect
	ld hl, wEnemyMoveEffect
.setPoisonEffect
	push hl
	ld a, [hl]
	push af
	ld [hl], POISON_SIDE_EFFECT1
	callab PoisonEffect_
	pop af
	pop hl
	ld [hl], a
	ret
