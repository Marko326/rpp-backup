; Lovely Kiss-only OAM tempo pass: keep the nine authored FrameBlock
; anchors, shared Subanimation $12, and the same six waits per entry.
; Each entry now uses six signed (Y,X) delta pairs, not runtime physics or
; continuous Hermite interpolation. The horizontal pace changes by entry;
; the equal-height upper anchors gain a shallow 3px vertical micro-arc.
; The next FrameBlock redraws its authored anchor exactly: any final X/Y
; correction (up to 3px in these eight intervals) remains a visible risk.
; The last entry still moves +/-3px X and +/-1px Y per wait to exit.
; No new WRAM, timing frames, SFX, battle properties or shared-$12 edits.
; This tempo pass is not the subsequent near/far wave visual finalization.
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

.steps:
	db -5,  3, -3,  2, -4,  2, -3,  2, -3,  2, -3,  2 ; key 1: Y 88 -> 66
	db -1,  1, -2,  2, -2,  2, -3,  3, -1,  3, -1,  2 ; key 2: Y 66 -> 56
	db  0,  1,  1,  2,  1,  2,  1,  2,  1,  2,  2,  2 ; key 3: Y 56 -> 64
	db  2,  3,  2,  2,  1,  2,  1,  2,  1,  2,  1,  2 ; key 4: Y 64 -> 72
	db  0,  1, -1,  2, -1,  2, -1,  2, -2,  2, -2,  2 ; key 5: Y 72 -> 62
	db -4,  2, -4,  2, -4,  2, -3,  2, -3,  2, -2,  2 ; key 6: Y 62 -> 40
	db -1,  2, -1,  2, -1,  3,  0,  2,  1,  2,  1,  1 ; key 7: Y 40 -> 40; shallow upper arc
	db  1,  2,  1,  2,  1,  2,  1,  2,  1,  2,  1,  2 ; key 8: Y 40 -> 48
	db  1,  3,  1,  3,  1,  3,  1,  3,  1,  3,  1,  3 ; key 9: exit +3 X, +1 Y per VBlank
