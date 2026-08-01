; b = new colour for BG colour 0 (usually white) for 4 frames
ChangeBGPalColor0_4Frames:
	call GetPredefRegisters
	ld a, [rBGP]
	or b
	ld [rBGP], a
	ld c, 4
	call DelayFrames
	ld a, [rBGP]
	and %11111100
	ld [rBGP], a
	ret

PredefShakeScreenVertically:
; Keep the original 3-frame mutation cadence, but latch every WY change in
; VBlank instead of writing rWY while the LCD may be drawing.
	call GetPredefRegisters

; The original routine returns to the shadow WY value. Preserve it rather than
; assuming that the normal window position is always 0.
	ld a, [hWY]
	push af
	ld a, 1
	ld [wDisableVBlankWYUpdate], a
	xor a

.loop
; Retain the original state machine exactly. Its first iteration is b -> 0;
; later iterations are 0 -> b as b decreases.
	ld [$ff96], a
	call .MutateWY
	call .MutateWY
	dec b
	ld a, b
	jr nz, .loop

; Restore the caller's shadow WY and let the next VBlank copy it safely.
	pop af
	ld [hWY], a
	xor a
	ld [wDisableVBlankWYUpdate], a
	ret

.MutateWY
	ld a, [$ff96]
	xor b
	ld [$ff96], a
	ld c, 3
	jp .SetWYForFrames

.SetWYForFrames
; Latch WY during VBlank, then keep it fixed for the remaining frames.
	ld [hWY], a
	push bc
	xor a
	ld [wDisableVBlankWYUpdate], a
	ld c, 1
	call DelayFrames
	ld a, 1
	ld [wDisableVBlankWYUpdate], a
	pop bc
	dec c
	ret z
	jp DelayFrames

PredefShakeScreenHorizontally:
; Moves the window right and then back in a sequence of progressively smaller
; numbers of pixels, starting at b.
	call GetPredefRegisters
	xor a
.loop
	ld [$ff97], a
	call .MutateWX
	ld c, 1
	call DelayFrames
	call .MutateWX
	dec b
	ld a, b
	jr nz, .loop

; restore normal WX
	ld a, 7
	ld [rWX], a
	ret

.MutateWX
	ld a, [$ff97]
	xor b
	ld [$ff97], a
	bit 7, a
	jr z, .skipZeroing
	xor a ; zero a if it's negative
.skipZeroing
	add 7
	ld [rWX], a
	ld c, 4
	jp DelayFrames
