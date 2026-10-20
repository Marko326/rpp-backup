; ANIM-5.62.97: global short horizontal hit feedback for enemy multi-hit moves.
; Lives in floating ROMX to avoid growing fixed animation bank $1E.
; The first strike has no AttackingMultipleTimes flag yet, so check its effect.
; Later strikes have the flag; Twineedle rewrites its effect after hit one.
; Store the choice in wAnimationType because the bank-switch trampoline
; does not preserve returned A. Status/miss reactions are filtered by the caller.
SelectGlobalDamageFeedbackType::
	; ANIM-5.62.197: the new ATTACK_DOWN_SIDE_EFFECT changes the generic
	; feedback type, but EXT02's approved 194C/196A visual must stay intact.
	; Keep its original no-side-effect hit reaction; the dedicated renderer
	; already includes its own horizontal shake. Do not bring back 194D.
	ld a, [wExtendedActiveMoveOrdinal]
	cp EXT_MOVE_LOW_PLAY_ROUGH
	jr nz, .otherMoves
	ld a, [H_WHOSETURN]
	and a
	ld a, 4 ; player: blink target, as with old NO_ADDITIONAL_EFFECT
	jr z, .keepPlayRoughFeedback
	ld a, 1 ; enemy: normal vertical reaction
.keepPlayRoughFeedback
	ld [wAnimationType], a
	ret
.otherMoves
	ld a,[H_WHOSETURN]
	and a
	jr z,.regular
	ld a,[wEnemyBattleStatus1]
	bit AttackingMultipleTimes,a
	jr nz,.multiHit
	ld a,[wEnemyMoveEffect]
	cp TWO_TO_FIVE_ATTACKS_EFFECT
	jr z,.multiHit
	cp ATTACK_TWICE_EFFECT
	jr z,.multiHit
	cp TWINEEDLE_EFFECT
	jr nz,.regular
.multiHit
	; Generic type 5 is the existing light horizontal window shake (B=2)
	; plus the normal damage/effectiveness SFX, one reaction per actual hit.
	; Do not alter the move's authored projectile, impact, or scatter animation.
	ld a,5
	ld [wAnimationType],a
	ret

.regular
	; Retain the previous explicit per-move exceptions for all other cases.
	call GetCurrentMoveID
	ld b,a
	ld hl,DamageFeedbackOverrides
.loop
	ld a,[hli]
	and a
	ret z
	cp b
	jr z,.found
	inc hl
	inc hl
	jr .loop
.found
	ld a,[H_WHOSETURN]
	and a
	jr nz,.enemy
	ld a,[hli]
	jr .finish
.enemy
	inc hl
	ld a,[hl]
.finish
	and a
	ret z
	ld [wAnimationType],a
	ret

; move, player-side override, enemy-side override
; 4 = BlinkEnemyMonSprite, 1 = ShakeScreenVertically, 0 = keep stock type.
DamageFeedbackOverrides:
	; MOVE-5.62.155: Bug Bite keeps Bite horizontal feedback without flinch.
	; Normal Bite already uses the same feedback in both directions.
	db BITE, 5, 2
	db SHADOW_BALL, 4, 1
	db VOLT_TACKLE, 0, 1 ; VTA-5.62.43: player stock; enemy vertical hit feedback.
	db ENERGY_BALL, 4, 1 ; ANM-5.62.05: custom impact is followed by standard blink/vertical hit feedback.
	db AURA_SPHERE, 4, 1 ; AUR-5.62.36: standard post-impact feedback
	db GUNK_SHOT, 0, 1 ; ANM-5.62.10: keep player feedback; enemy hit shakes the player vertically.
	db HURRICANE, 4, 1 ; HUR-5.62.32: avoid a redundant side-effect shake after the storm renderer.
	db SPARK, 4, 1 ; ANM-5.61.72: Gold-style hit reaction, matching Shadow Ball.
	db ICY_WIND, 4, 1 ; ANM-5.61.81: player hit blinks target; enemy hit shakes player vertically.
	db IRON_TAIL, 0, 1 ; ANM-5.62.07: keep player feedback; enemy hit shakes the player vertically.
	db STEEL_WING, 0, 1 ; SW-5.62.37: keep player feedback; enemy hit shakes the player vertically.
	db EARTH_POWER, 4, 1 ; ANM-5.61.102: avoid a redundant post-eruption side-effect shake.
	db SHADOW_PUNCH, 0, 1
	db FLAME_WHEEL, 0, 1
	db CRUNCH, 4, 1
	db EGG_BOMB, 0, 1 ; EGG-A4-5.61.75: enemy use shakes the player vertically.
	db 0
