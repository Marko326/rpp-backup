; MOVE-5.62.147: per-move Generation II+ effects without changing the
; shared Gen I effect constants. This file is included in fixed Bank $3E.

; Called from DrainHPEffect_ (Bank $1). Commit the result to wDamage because
; the cross-bank wrapper does not preserve result registers.
CalculateDrainRecovery:
	call GetStatSideEffectMoveID
	cp DRAININGKISS
	jr z, .drainingKiss
	; Standard drain: floor(damage / 2), minimum 1.
	ld hl, wDamage
	ld a, [hl]
	srl a
	ld [hli], a
	ld a, [hl]
	rr a
	ld [hld], a
	jr .minOne
.drainingKiss
	; Draining Kiss: floor(3 * damage / 4) = damage - ceil(damage/4).
	; Round the 16-bit quarter upward without overflowing at $ffff.
	ld hl, wDamage
	ld b, [hl]
	inc hl
	ld c, [hl]
	ld a, c
	and 3
	ld d, a
	srl b
	rr c
	srl b
	rr c
	ld a, d
	and a
	jr z, .quarterReady
	inc bc
.quarterReady
	ld a, [hl]
	sub c
	ld [hld], a
	ld a, [hl]
	sbc b
	ld [hl], a
.minOne
	ld a, [hli]
	or [hl]
	ret nz
	inc [hl]
	ret

; MOVE-5.62.148: on a broken Substitute, only Draining Kiss keeps
; its drain and recovers from the Substitute HP actually lost. On the
; low-byte damage path, AttackSubstitute has already stored (oldHP -
; damage) modulo 256; reconstruct oldHP by adding the damage back.
; When damage >= 256, AttackSubstitute skipped the subtraction, so
; the Substitute HP is still the original value. Return carry if and
; only if Draining Kiss was handled; Bankswitch preserves flags.
KeepDrainingKissDrainAfterSubBreak:
	call GetStatSideEffectMoveID
	cp DRAININGKISS
	jr nz, .notDrainingKiss
	ld hl, wEnemySubstituteHP
	ld a, [H_WHOSETURN]
	and a
	jr z, .getHP
	ld hl, wPlayerSubstituteHP
.getHP
	ld a, [wDamage]
	and a
	jr nz, .saveDamage ; >= 256; Substitute HP has not been reduced.
	ld a, [wDamage + 1]
	add [hl] ; restore HP prior to the subtraction, modulo 256
	jr .writeDamage
.saveDamage
	ld a, [hl]
.writeDamage
	ld [wDamage + 1], a
	xor a
	ld [wDamage], a
	scf ; preserve Draining Kiss's drain effect
	ret
.notDrainingKiss
	and a ; no new behavior for other moves
	ret

; Input E = current move type; output E = the side-effect immunity type.
; Bankswitch and CALLAB overwrite A/BC/HL but preserve DE. Use the same
; derived-move identity as the side-effect probability roller, so Metronome
; and Mirror Move are interpreted consistently during Test Battles.
GetStatusImmunityTypeFar:
	call GetStatSideEffectMoveID
	cp DRAGONBREATH
	ret nz
	ld e, ELECTRIC
	ret

; Input A = move effect, output E = normalized burn/freeze/paralyze effect,
; carry set only when the random side effect activates. The caller in Bank F
; copies E back to A after the bank switch (which overwrites A).
RollStatusSideEffectFar:
	cp SACRED_FIRE_EFFECT
	jr nz, .standard
	ld d, $80 ; Sacred Fire: 50% burn (unchanged)
	ld a, BURN_SIDE_EFFECT1
	jr .roll
.standard
	cp PARALYZE_SIDE_EFFECT1 + 1
	ld d, $1a ; original 10% category, including Gen I Thunder
	jr c, .modernParalyzeOdds
	cp PARALYZE_SIDE_EFFECT2 + 1
	jr c, .effect2
	; Keep fang-effect normalization and its original 10% status odds.
	sub $53
	ld d, $1a
	jr .roll
.effect2
	sub $1e
	ld d, $4d ; original 30% category
	jr .roll
.modernParalyzeOdds
	; Only later-introduced Dragonbreath and Discharge rise to 30%.
	ld e, a
	push de
	call GetStatSideEffectMoveID
	cp DRAGONBREATH
	jr z, .useThirty
	cp DISCHARGE
	jr nz, .useOriginal
.useThirty
	pop de
	ld d, $4d
	; A damaged Substitute (even if broken) absorbs modern side effects.
	ld a, [wMoveDidntMiss]
	bit 7, a
	jr z, .restoreEffect
	and a ; no additional status; clears carry
	ret
.useOriginal
	pop de
.restoreEffect
	ld a, e
.roll
	ld e, a
	push de
	callab BattleRandomFar
	ld a, e ; random result from the far helper
	pop de ; restore normalized effect and its threshold
	cp d ; keep carry for the Bank F caller
	ret

; Carry set when the confusion side effect succeeds. A is not returned.
RollConfusionSideEffectFar:
	call GetStatSideEffectMoveID
	ld d, $19 ; unchanged ~10% for Gen I moves / other callers
	cp WATER_PULSE
	jr z, .twenty
	cp HURRICANE
	jr z, .thirty
	jr .roll
.twenty
	ld d, $33 ; 51/256 = 19.92%
	jr .modernHit
.thirty
	ld d, $4d ; 77/256 = 30.08%
.modernHit
	; Do not confuse a target when the damage hit its Substitute.
	ld a, [wMoveDidntMiss]
	bit 7, a
	jr z, .roll
	and a ; no additional confusion; clears carry
	ret
.roll
	push de
	callab BattleRandomFar
	ld a, e
	pop de
	cp d
	ret
