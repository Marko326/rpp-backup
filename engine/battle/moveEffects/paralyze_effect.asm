ParalyzeEffect_:
	ld hl, wEnemyMonStatus
	; BAT-5.61.01: keep DE on the current move effect first. Move type is the
	; second byte after it, so the Nuzzle special case does not need another
	; H_WHOSETURN dispatch and bank 14 only grows minimally.
	ld de, wPlayerMoveEffect
	ld a, [H_WHOSETURN]
	and a
	jp z, .next
	ld hl, wBattleMonStatus
	ld de, wEnemyMoveEffect
.next
	ld a, [hl]
	and a ; does the target already have a status ailment?
	jr nz, .alreadyStatused
; check if the target is immune due to types
	inc de
	inc de ; MoveType follows MoveEffect + MovePower
	ld a, [de]
	cp ELECTRIC
	jr nz, .hitTest
	ld b, h
	ld c, l
	inc bc
	ld a, [bc]
	cp GROUND
	jr z, .doesntAffect
	inc bc
	ld a, [bc]
	cp GROUND
	jr z, .doesntAffect
.hitTest
	dec de
	dec de ; restore the current MoveEffect pointer across MoveHitTest
	push de
	push hl
	callab MoveHitTest
	pop hl
	pop de
	ld a, [wMoveMissed]
	and a
	jr nz, .didntAffect
	set PAR, [hl]
	callab HalveSpeedDueToParalysis
	; Damaging Nuzzle already played its hit animation. Only standalone
	; paralysis moves still need the deferred animation here.
	ld a, [de]
	cp PARALYZE_EFFECT
	jr nz, .skipAnimation
	callab PlayCurrentMoveAnimation
.skipAnimation
	ld c, 30
	call DelayFrames
	jpab PrintMayNotAttackText
.alreadyStatused
	; Nuzzle still deals damage; an existing major status only suppresses its
	; paralysis side effect, so do not print a false "didn't affect" message.
	ld a, [de]
	cp NUZZLE_EFFECT
	ret z
.didntAffect
	ld c, 50
	call DelayFrames
	jpab PrintDidntAffectText
.doesntAffect
	ld c, 50
	call DelayFrames
	jpab PrintDoesntAffectText
