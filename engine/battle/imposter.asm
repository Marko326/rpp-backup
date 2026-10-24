; IMP-5.62.206 — Ditto's entry-only Imposter effect (no generic Ability data).
; Shared TransformEffect_ handles original Species/form/Fly-Dig rejection,
; battle data, move identity sidecars, temporary 5 PP and regional redraw.
;
; Hook order: trainer first enemy is drawn before the player enters, so both
; first-lead checks run after SendOutMon. Later EnemySendOut checks its own
; side and consumes only a *new* pending player entry caused by double-faint.
;
; The link battle still uses the same on-entry hooks, but dual-console
; synchronization and graphics require dedicated device testing.

ImposterOnPlayerSendOut:
	; Clear any older pending state even when a non-Ditto is now sent out.
	xor a
	ld [wImposterEntryFlags], a
	ld a, [wFirstMonsNotOutYet]
	and a
	jr z, .player
	; Trainer and wild enemy first appearances finish before the player
	; lead's SendOutMon; never attempt this from EnemySendOutFirstMon.
	call .enemyLead
.player
	ld a, [wBattleMonSpecies2]
	cp DITTO
	ret nz
	ld a, [wEnemyMonHP]
	ld b, a
	ld a, [wEnemyMonHP + 1]
	or b
	jr nz, .ready
	; Both mons fainted: wait until ReplaceFaintedEnemyMon installs
	; the actual target, not the outgoing zero-HP battler.
	ld hl, wImposterEntryFlags
	set 0, [hl]
	ret
.ready
	ld e, 0 ; player acts as Transform user (A is clobbered by Bankswitch)
	callba ImposterTransformEffect_
	jp SaveScreenTilesToBuffer1
.enemyLead
	ld a, [wEnemyMonSpecies2]
	cp DITTO
	ret nz
	ld a, [wBattleMonHP]
	ld b, a
	ld a, [wBattleMonHP + 1]
	or b
	ret z
	ld e, 1 ; enemy Transform user
	callba ImposterTransformEffect_
	jp SaveScreenTilesToBuffer1

ImposterOnEnemySendOut:
	; AI's ordinary mid-battle switch also sets wFirstMonsNotOutYet=1
	; temporarily to suppress the old Shift menu. Test for an actually
	; initialized player battler instead or AI-switched Ditto would be skipped.
	ld a, [wBattleMonSpecies]
	and a
	ret z ; first trainer enemy appears before the player lead is loaded
	; A just-sent-out player Ditto may have deferred due to zero enemy HP.
	; Consume the one-time token BEFORE invoking Transform animations.
	ld hl, wImposterEntryFlags
	bit 0, [hl]
	jr z, .enemy
	res 0, [hl]
	ld a, [wBattleMonSpecies2]
	cp DITTO
	jr nz, .enemy
	ld e, 0
	callba ImposterTransformEffect_
	call SaveScreenTilesToBuffer1
.enemy
	ld a, [wEnemyMonSpecies2]
	cp DITTO
	ret nz
	ld a, [wBattleMonHP]
	ld b, a
	ld a, [wBattleMonHP + 1]
	or b
	ret z
	ld e, 1
	callba ImposterTransformEffect_
	jp SaveScreenTilesToBuffer1

; Play the ordinary Transform move animation on entry, including its own
; SE_TRANSFORM_MON redraw, without overwriting the currently selected move.
; The manual move path continues to use PlayCurrentMoveAnimation unchanged.
PlayImposterTransformAnimation:
	ld a, [wAnimationID]
	push af
	ld a, [wAnimationType]
	push af
	xor a ; force the stock Transform script, not a staged extended move
	ld [wMoveAnimScriptLoaded], a
	ld [wAnimationType], a
	ld a, TRANSFORM
	ld [wAnimationID], a
	callab PlayBattleAnimationGotID
	pop af
	ld [wAnimationType], a
	pop af
	ld [wAnimationID], a
	ret

; Moved byte-for-byte from the saturated battle-core bank. The calling
; gateway and return flags are preserved by the Bankswitch ABI.
EndLowHealthAlarm_Impl:
	xor a
	ld [wDanger], a
	ld [wChannelSoundIDs + Ch4], a
	inc a
	ld [wLowHealthAlarmDisabled], a
	ret

AnyEnemyPokemonAliveCheck_Impl:
	ld a, [wEnemyPartyCount]
	ld b, a
	xor a
	ld hl, wEnemyMon1HP
	ld de, wEnemyMon2 - wEnemyMon1
.nextPokemon
	or [hl]
	inc hl
	or [hl]
	dec hl
	add hl, de
	dec b
	jr nz, .nextPokemon
	and a
	ret
