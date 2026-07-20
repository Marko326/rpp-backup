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
; Keep the apparent rpp-backup-flash cadence without writing rWY outside VBlank.
; Each downward pulse lasts 2 frames; the removed flash frame is replaced by
; one frame at the normal window position.
	call GetPredefRegisters
	ld a, 1
	ld [wDisableVBlankWYUpdate], a

; Play the first pulse, then preserve the longer first return interval.
	ld a, b
	ld c, 2
	call .SetWYForFrames
	dec b
	jr z, .finish
	xor a
	ld c, 7
	call .SetWYForFrames

.loop
	ld a, b
	ld c, 2
	call .SetWYForFrames
	dec b
	jr z, .finish
	xor a
	ld c, 4
	call .SetWYForFrames
	jr .loop

.finish
; Replace the final transition frame with a clean frame at the normal position.
	xor a
	ld c, 1
	call .SetWYForFrames

; Restore both the shadow register and normal VBlank updating.
	xor a
	ld [hWY], a
	ld [wDisableVBlankWYUpdate], a
	ret

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
