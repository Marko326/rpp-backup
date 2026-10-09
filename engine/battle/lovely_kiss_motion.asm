; ANIM-5.62.75: Lovely Kiss's nine authored FrameBlock anchors stay intact.
; The nine entries each use six existing DelayFrame waits; the regular OAM
; cleanup/next-frame redraw supplies the remaining interval between anchors.
; For each wait, X advances by 2px (or -2px when screen-flipped). Y uses a
; fixed signed six-step lookup table; it is NOT runtime cubic interpolation.
; At the next keyframe, the original base coordinate is redrawn exactly,
; so the per-keyframe Y difference can include a final correction of up to
; 3px. This is a step-table approximation, not zero-velocity Hermite motion.
;
; This is the base motion stage only; later tempo and wave refinements have
; not been merged. Ordinary LOVELY_KISS + Subanimation $12 + mode-0 only;
; other users of shared $12 keep the original animation and audio path.
; Nine authored draw/cleanup points and the original delay-6 timing stay.
; The final drawn heart continues at +/-3px X and +/-1px Y per frame.
; No extra WRAM or changes to battle move attributes / damage processing.
PlayLovelyKissCurvedMotion::
	ld a,[wSubAnimCounter]
	cp 1
	jp c,.legacyDelay
	cp 10
	jp nc,.legacyDelay
	ld e,a
	ld a,9
	sub e                            ; 0..8 in playback order
	ld e,a
	add a
	add e                            ; three times the entry index
	add a                            ; six signed Y steps per entry
	ld e,a
	ld d,0
	ld hl,.ySteps
	add hl,de

	; For this authored $69 Subanimation the player uses transform 0,
	; the enemy uses transform 3. Also honor the other screen X flips.
	ld e,2
	ld a,[wSubAnimTransform]
	cp 1
	jr z,.reverseX
	cp 2
	jr z,.reverseX
	cp 3
	jr nz,.xReady
.reverseX:
	ld e,-2
.xReady:
	ld a,[wSubAnimCounter]
	cp 1
	jr nz,.move
	; A slightly faster continuation of the last leg (not an abrupt stop).
	ld a,e
	bit 7,a
	jr nz,.exitLeft
	ld e,3
	jr .move
.exitLeft:
	ld e,-3
.move:
	ld b,6
.frame:
	push bc
	push de
	push hl
	call DelayFrame
	pop hl
	pop de
	pop bc
	ld a,[hli]
	ld d,a                           ; signed curved Y displacement
	ld a,[wSubAnimTransform]
	cp 1
	jr z,.reverseY
	cp 3
	jr nz,.readyY
.reverseY:
	xor a
	sub d
	ld d,a
.readyY:
	; Translate the four tiles of the already drawn heart in OAM.
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
	ld [hli],a                     ; Y
	ld a,[hl]
	add e
	ld [hli],a                     ; X
	inc hl                           ; tile and attributes stay unchanged
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

.ySteps:
	db  -3, -4, -3, -3, -4, -2 ; key 1: Y 88 -> 66
	db  -2, -2, -2, -2, -1, -1 ; key 2: Y 66 -> 56
	db   0,  1,  1,  2,  1,  2 ; key 3: Y 56 -> 64
	db   1,  2,  1,  2,  1,  1 ; key 4: Y 64 -> 72
	db   0, -1, -1, -2, -2, -2 ; key 5: Y 72 -> 62
	db  -3, -4, -4, -4, -4, -2 ; key 6: Y 62 -> 40
	db   0,  0,  0,  0,  0,  0 ; key 7: Y 40 -> 40
	db   0,  1,  1,  2,  1,  2 ; key 8: Y 40 -> 48
	db   1,  1,  1,  1,  1,  1 ; key 9: follow outgoing velocity; exit OAM edge
