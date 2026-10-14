WaitForTrainerFaintFallSFX::
; SFX-5.62.143: the trainer faint fall effect uses Crysaudio CH5.
; Wait only while this specific effect owns CH5; an unrelated SFX or
; Danger alarm must not hold up the thud. Bound the wait to 180 frames.
	push bc
	push hl
	ld b, 180
.loop
	ld hl, Channel5 + Channel1Flags - Channel1
	bit 0, [hl]
	jr z, .done
	ld hl, Channel5 + Channel1MusicID - Channel1
	ld a, [hli]
	cp SFX_FAINT_FALL
	jr nz, .done
	ld a, [hl]
	and a
	jr nz, .done
	push bc
	call DelayFrame
	pop bc
	dec b
	jr nz, .loop
.done
	pop hl
	pop bc
	ret
