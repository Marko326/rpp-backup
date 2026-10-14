WaitForBattleAnimationSFX::
; SFX-5.62.141: Danger is an HP state, not proof that move SFX finished.
; Keep the original wait in ordinary HP cases; only replace the Danger
; shortcut while entering/exiting move animation or adding the hit sound.
	ld a, [wDanger]
	and a
	jp z, WaitForSoundToFinish
	ld a, [wSFXDontWait]
	and a
	ret nz

	push bc
	push hl
	ld b, 180 ; max three seconds, never hang on a stuck channel
.loop
	ld hl, Channel5 + Channel1Flags - Channel1
	bit 0, [hl]
	jr nz, .pending
	ld hl, Channel6 + Channel1Flags - Channel1
	bit 0, [hl]
	jr nz, .pending
	ld hl, Channel7 + Channel1Flags - Channel1
	bit 0, [hl]
	jr nz, .pending
	ld hl, Channel8 + Channel1Flags - Channel1
	bit 0, [hl]
	jr z, .done
.pending
	call DelayFrame ; audio continues in VBlank, unlike a tight busy loop
	dec b
	jr nz, .loop
.done
	pop hl
	pop bc
	ret
