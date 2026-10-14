StopInterruptedIntroSFX::
; SFX-5.62.140: stop active CH5-CH8 effects when an intro is skipped.
; Clear the sound-engine flags AND the matching hardware DACs; otherwise
; the old note can keep sounding after the animation has disappeared.
; Leave music CH1-CH4 software state, BGM volume and saved options intact.
	ld a, [wHaltAudio]
	push af
	ld a, 1
	ld [wHaltAudio], a
	call OpenSRAMForSound

	ld hl, Channel5 + Channel1Flags - Channel1
	bit 0, [hl]
	jr z, .channel6
	res 0, [hl]
	xor a
	ld [rNR12], a ; CH1 pulse DAC off
.channel6
	ld hl, Channel6 + Channel1Flags - Channel1
	bit 0, [hl]
	jr z, .channel7
	res 0, [hl]
	xor a
	ld [rNR22], a ; CH2 pulse DAC off
.channel7
	ld hl, Channel7 + Channel1Flags - Channel1
	bit 0, [hl]
	jr z, .channel8
	res 0, [hl]
	xor a
	ld [rNR30], a ; CH3 wave DAC off
.channel8
	ld hl, Channel8 + Channel1Flags - Channel1
	bit 0, [hl]
	jr z, .finish
	res 0, [hl]
	xor a
	ld [rNR42], a ; CH4 noise DAC off (shooting star)
.finish
	xor a
	ld [SFXPriority], a
	ld [CurSFX], a
	ld [NoiseSampleAddressLo], a
	ld [NoiseSampleAddressHi], a
	pop af
	ld [wHaltAudio], a
	ret
