ParalyzeEffect_:
	ld hl, wEnemyMonStatus
	; MOVE-5.62.114: the former Bank $14 body lives alongside the other
	; move-specific helpers in Bank $3E. Keep DE at the current move effect.
	ld de, wPlayerMoveEffect
	ld a, [H_WHOSETURN]
	and a
	jp z, .next
	ld hl, wBattleMonStatus
	ld de, wEnemyMoveEffect
.next
	ld a, [de]
	cp NUZZLE_EFFECT
	jr nz, .checkStatus
	; MOVE-5.62.114: wMoveDidntMiss bit 7 records the Substitute
	; before damage, including the hit that breaks it. Never paralyze
	; the real target after striking a Substitute.
	ld a, [wMoveDidntMiss]
	bit 7, a
	ret nz
	; Electric Pokemon are immune to paralysis even when Nuzzle
	; successfully deals damage (ordinary Thunder Wave is unchanged).
	push hl
	inc hl ; target type 1 follows target status
	ld a, [hli]
	cp ELECTRIC
	jr z, .nuzzleImmune
	ld a, [hl]
	cp ELECTRIC
	jr z, .nuzzleImmune
	pop hl
	jr .checkStatus
.nuzzleImmune
	pop hl
	ret
.checkStatus
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
	ld a, [de]
	cp NUZZLE_EFFECT
	jr z, .alreadyHit ; damaging Nuzzle already passed its accuracy test
	push de
	push hl
	callab MoveHitTest
	pop hl
	pop de
	ld a, [wMoveMissed]
	and a
	jr nz, .didntAffect
.alreadyHit
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
