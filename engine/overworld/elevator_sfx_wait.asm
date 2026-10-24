WaitForElevatorSFX::
; SFX-5.62.142: the elevator end cue is a single Crysaudio CH5 effect.
; Wait by frame so the audio engine can advance; bound the local wait to
; avoid hanging if its channel flag remains active unexpectedly.
	push bc
	push hl
	ld b, 180
.loop
	ld hl, Channel5 + Channel1Flags - Channel1
	bit 0, [hl]
	jr z, .done
	push bc
	call DelayFrame
	pop bc
	dec b
	jr nz, .loop
.done
	pop hl
	pop bc
	ret
