; Lovely Kiss dedicated near/far wave profile. Preserve original X anchors,
; eight 7-VBlank legs, sounds, and total duration. Per-key OAM Y offsets
; make the close wave about 35px and the far wave about 26px; shared
; FrameBlock and Subanimation $12 data stay unchanged.
; Six signed (Y,X) delta pairs run between each pair of anchors; the
; next FrameBlock supplies the remaining step, then we bias its Y in OAM.
; The distant crest retains the short shallow arc and the last key keeps
; its outgoing (+1 Y, +3 X) step. This path is only for Lovely Kiss.
PlayLovelyKissCurvedMotion::
	ld a,[wSubAnimCounter]
	cp 1
	jp c,.legacyDelay
	cp 10
	jp nc,.legacyDelay
	ld e,a
	ld a,9
	sub e                            ; 0..8 in playback order
	ld e,a                           ; key 0..8 in flight order

	; Make the close wave slightly taller and the far wave
	; shallower, without touching shared Subanimation12 base coordinates.
	; Apply each anchor's Y bias before the first visible VBlank; the six
	; motion deltas below then lead into the next already-corrected anchor.
	ld d,0
	ld hl,.keyYOffsets
	add hl,de
	ld d,[hl]                        ; signed authored-anchor Y bias
	ld a,d
	and a
	jr z,.anchorReady
	ld a,[wSubAnimTransform]
	cp 1
	jr z,.flipAnchorY
	cp 3
	jr nz,.anchorSetup
.flipAnchorY:
	xor a
	sub d
	ld d,a
.anchorSetup:
	ld a,[wFBDestAddr + 1]
	ld l,a
	ld a,[wFBDestAddr]
	ld h,a
	ld a,[wNumFBTiles]
	ld c,a
.anchorTiles:
	ld a,[hl]
	add d
	ld [hli],a                       ; only OAM Y; X and tile unchanged
	inc hl                           ; X
	inc hl                           ; tile ID
	inc hl                           ; attributes
	dec c
	jr nz,.anchorTiles
.anchorReady:
	ld a,e
	add a
	add e                            ; 3 times the entry index
	add a
	add a                            ; 12 bytes per entry
	ld e,a
	ld d,0
	ld hl,.steps
	add hl,de

	ld b,6
.frame:
	push bc
	push hl
	call DelayFrame
	pop hl
	pop bc
	ld a,[hli]
	ld d,a                           ; signed wave Y displacement
	ld a,[hli]
	ld e,a                           ; re-timed X (always positive before flip)
	ld a,[wSubAnimTransform]
	cp 1
	jr z,.reverseBoth
	cp 3
	jr z,.reverseBoth
	cp 2
	jr z,.reverseX
	jr .ready
.reverseBoth:
	xor a
	sub d
	ld d,a
.reverseX:
	xor a
	sub e
	ld e,a
.ready:
	; Modify the tiles of the currently displayed heart in OAM only.
	push hl
	ld a,[wFBDestAddr + 1]
	ld l,a
	ld a,[wFBDestAddr]
	ld h,a
	ld a,[wNumFBTiles]
	ld c,a
.tile:
	ld a,[hl]
	add d
	ld [hli],a                    ; Y
	ld a,[hl]
	add e
	ld [hli],a                    ; X
	inc hl                          ; tile and attributes unchanged
	inc hl
	dec c
	jr nz,.tile
	pop hl
	dec b
	jr nz,.frame
	ret

.legacyDelay:
	ld a,[wSubAnimFrameDelay]
	ld c,a
	jp DelayFrames

; Per-key Y offsets relative to the unmodified shared FrameBlock bases.
; Near wave gains 3px, far wave loses 6px of rise; end drifts only +1px.
.keyYOffsets:
	db  0,  0, -3, -1, -2,  0,  4,  4,  1

.steps:
	db -5,  3, -3,  2, -4,  2, -3,  2, -3,  2, -3,  2 ; key 1: adjusted Y 88 -> 66
	db -1,  1, -2,  2, -3,  2, -3,  3, -2,  3, -1,  2 ; key 2: adjusted Y 66 -> 53
	db  0,  1,  1,  2,  1,  2,  1,  2,  2,  2,  2,  2 ; key 3: adjusted Y 53 -> 63
	db  2,  3,  1,  2,  1,  2,  1,  2,  1,  2,  1,  2 ; key 4: adjusted Y 63 -> 70
	db  0,  1, -1,  2, -1,  2, -1,  2, -1,  2, -2,  2 ; key 5: adjusted Y 70 -> 62
	db -4,  2, -4,  2, -3,  2, -2,  2, -2,  2, -2,  2 ; key 6: adjusted Y 62 -> 44
	db -1,  2, -1,  2, -1,  3,  0,  2,  1,  2,  1,  1 ; key 7: adjusted Y 44 -> 44; shallow far crest
	db  0,  2,  0,  2,  1,  2,  1,  2,  1,  2,  1,  2 ; key 8: adjusted Y 44 -> 49
	db  1,  3,  1,  3,  1,  3,  1,  3,  1,  3,  1,  3 ; key 9: exit +3 X, +1 Y per VBlank
