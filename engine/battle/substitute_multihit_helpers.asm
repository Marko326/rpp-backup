; SUB-5.62.42: keep a Substitute user's real sprite visible through the full
; damaging move resolution. Multi-hit moves hide the doll only once and keep
; the real mon visible between hits. Normal completion restores the doll only
; after target damage plus any recoil have resolved. A recoil-fainted user stays
; visible so the normal faint path can remove the real sprite directly.

PrepareAttackerSubstituteForMoveAnimation:
	ld a, [H_WHOSETURN]
	and a
	jr nz, .enemy
	ld a, [wPlayerBattleStatus2]
	bit HasSubstituteUp, a
	ret z
	ld a, [wPlayerBattleStatus1]
	bit AttackingMultipleTimes, a
	ret nz
	callab HideSubstituteShowMonAnim
	ret
.enemy
	ld a, [wEnemyBattleStatus2]
	bit HasSubstituteUp, a
	ret z
	ld a, [wEnemyBattleStatus1]
	bit AttackingMultipleTimes, a
	ret nz
	callab HideSubstituteShowMonAnim
	ret

FinishAttackerSubstituteAfterDamage:
	ld a, [H_WHOSETURN]
	and a
	jr nz, .enemy
	; Recoil can faint the attacker before post-hit processing completes. Keep
	; the real mon visible at 0 HP and let the existing faint path remove it.
	ld hl, wBattleMonHP
	ld a, [hli]
	or [hl]
	ret z
	ld a, [wPlayerBattleStatus2]
	bit HasSubstituteUp, a
	ret z
	ld a, [wPlayerBattleStatus1]
	bit AttackingMultipleTimes, a
	jr nz, .playerMultiHit
	ld a, [wPlayerMoveEffect]
	jr .checkFirstHit
.playerMultiHit
	ld a, [wPlayerNumAttacksLeft]
	cp 1
	jr z, .reshow
	ret
.enemy
	ld hl, wEnemyMonHP
	ld a, [hli]
	or [hl]
	ret z
	ld a, [wEnemyBattleStatus2]
	bit HasSubstituteUp, a
	ret z
	ld a, [wEnemyBattleStatus1]
	bit AttackingMultipleTimes, a
	jr nz, .enemyMultiHit
	ld a, [wEnemyMoveEffect]
	jr .checkFirstHit
.enemyMultiHit
	ld a, [wEnemyNumAttacksLeft]
	cp 1
	jr z, .reshow
	ret
.checkFirstHit
	; Explosion/Selfdestruct applies the user's HP=0 in its effect handler after
	; target damage. Do not redraw a Substitute that will immediately faint.
	cp EXPLODE_EFFECT
	ret z
	; The multi-hit flag is only established by the effect handler after the
	; first hit's damage has resolved. Keep the real mon visible for that first
	; hit so the later hits can continue without swapping back to the doll.
	cp TWO_TO_FIVE_ATTACKS_EFFECT
	ret z
	cp ATTACK_TWICE_EFFECT
	ret z
	cp TWINEEDLE_EFFECT
	ret z
.reshow
	callab ReshowSubstituteAnim
	ret

RestoreAttackerSubstituteIfMultiHitActive:
	ld a, [H_WHOSETURN]
	and a
	jr nz, .enemy
	ld a, [wPlayerBattleStatus1]
	bit AttackingMultipleTimes, a
	ret z
	ld a, [wPlayerNumAttacksLeft]
	cp 2
	ret c ; final hit already restored after its damage; 0 is normal completion
	ld a, [wPlayerBattleStatus2]
	jr .checkSubstitute
.enemy
	ld a, [wEnemyBattleStatus1]
	bit AttackingMultipleTimes, a
	ret z
	ld a, [wEnemyNumAttacksLeft]
	cp 2
	ret c ; final hit already restored after its damage; 0 is normal completion
	ld a, [wEnemyBattleStatus2]
.checkSubstitute
	bit HasSubstituteUp, a
	ret z
	; If an earlier hit ends the sequence by KO, its damage has already resolved;
	; restore the doll here before leaving the move.
	callab ReshowSubstituteAnim
	ret
