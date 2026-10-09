; Dedicated heart OAM motion (ordinary Lovely Kiss / scripted Draining Kiss).
; Lovely Kiss preserves 9 X anchors, 8 movement legs and near/far Y biases:
; close wave about 35px, far wave about 26px; the shared $12 data is unchanged.
; Draining Kiss uses 7 separate $39 anchors, Fairy palette and original Absorb
; contraction/return; the last three heart legs use actor-specific tables.
; Each moving leg advances six signed (Y,X) steps, then the next FrameBlock
; supplies the seventh; the displayed heart tiles are adjusted only in OAM.
PlayLovelyKissCurvedMotion::
	; Ordinary Lovely Kiss keeps nine keys; scripted Draining Kiss uses seven.
	ld a,[wMoveAnimScriptLoaded]
	and a
	jr nz,.drainingIndex
	ld a,[wSubAnimCounter]
	cp 1
	jp c,.legacyDelay
	cp 10
	jp nc,.legacyDelay
	ld e,a
	ld a,9
	sub e                            ; 0..8 in playback order
	ld e,a
	ld hl,.keyYOffsets
	jr .anchorOffset
.drainingIndex
	ld a,[wSubAnimCounter]
	cp 1
	jp c,.legacyDelay
	cp 8
	jp nc,.legacyDelay
	ld e,a
	ld a,7
	sub e                            ; 0..6 in playback order
	ld e,a
	ld a,[wSubAnimTransform]
	and a
	ld hl,.drainingYOffsets
	jr z,.anchorOffset
	ld hl,.drainingEnemyYOffsets
.anchorOffset
	; Draining Kiss has its own two-direction wave into Absorb; it uses dedicated
	; player/enemy curve anchors to arrive naturally at the Absorb center.
	ld d,0
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
	ld a,[wMoveAnimScriptLoaded]
	and a
	jr z,.normalSteps
	ld a,e
	cp 4
	jr c,.drainingSelectSteps
	; Ease Draining Kiss X anchors from wave two to the
	; drain center. Use screen-space offsets for both transforms.
	push de
	ld d,0
	ld a,[wSubAnimTransform]
	and a
	ld hl,.drainingPlayerXOffsets
	jr z,.drainingXReady
	ld hl,.drainingEnemyXOffsets
.drainingXReady
	add hl,de
	ld d,[hl]
	ld a,[wFBDestAddr + 1]
	ld l,a
	ld a,[wFBDestAddr]
	ld h,a
	ld a,[wNumFBTiles]
	ld c,a
.drainingXTile
	inc hl                           ; X of this OAM tile
	ld a,[hl]
	add d
	ld [hl],a
	inc hl                           ; tile ID
	inc hl                           ; attributes
	inc hl                           ; next Y
	dec c
	jr nz,.drainingXTile
	pop de
.drainingSelectSteps
	ld a,e
	cp 6
	jp z,.drainingArrival
	cp 3
	jr c,.normalSteps
	; Keys 3/4/5 each have one complete 7-VBlank leg: six
	; incremental moves, then the adjusted next FrameBlock anchor.
	sub 3
	ld e,a
	add a
	add e
	add a
	add a                            ; 12 bytes per leg
	ld e,a
	ld d,0
	ld a,[wSubAnimTransform]
	and a
	ld hl,.drainingPlayerSteps
	jr z,.drainingStepTable
	ld hl,.drainingEnemySteps
.drainingStepTable
	add hl,de
	jr .runSteps
.normalSteps
	ld a,e
	add a
	add e                            ; 3 times the entry index
	add a
	add a                            ; 12 bytes per entry
	ld e,a
	ld d,0
	ld hl,.steps
	add hl,de
.runSteps
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

.drainingArrival:
	; The last $39 heart center aligns with the visual center of
	; Absorb's opening contraction, with no last-frame repositioning.
	ld c,2
	jp DelayFrames

.legacyDelay:
	ld a,[wSubAnimFrameDelay]
	ld c,a
	jp DelayFrames

; Per-key Y offsets relative to the unmodified shared FrameBlock bases.
; Near wave gains 3px, far wave loses 6px of rise; end drifts only +1px.
.keyYOffsets:
	db  0,  0, -3, -1, -2,  0,  4,  4,  1

; Draining Kiss keeps the second wave, and the last key's OAM
; alignment compensates for the different visual centers of the heart
; and Absorb's four contraction particles.
; Player frame-base keys 3..6: (90,71), (102,76), (113,57), (129,40).
.drainingYOffsets:
	db  0,  0, -3, -1, -4, -13, -8

; Enemy transform 3 flips Y/X. Key 5 crests before descending into
; the unchanged final visual center: (94,81), (78,74), (61,69), (47,80).
.drainingEnemyYOffsets:
	db  0,  0, -3, -1, -2,  13,  24

; Absolute screen-space OAM X biases (not transform-relative).
; X biases are independent for player and enemy center alignment.
.drainingPlayerXOffsets:
	db  0,  0,  0,  0, -2, -5, -3
.drainingEnemyXOffsets:
	db  0,  0,  0,  0, -2, -5, -5

; Three full DK legs (key 3->4, 4->5, 5->6), six signed (Y,X) steps
; each. The seventh step comes from the next corrected frame anchor.
.drainingPlayerSteps:
	db  1,  2,  1,  2,  1,  2,  1,  2,  0,  2,  0,  1
	db -2,  2, -3,  2, -3,  1, -3,  2, -3,  2, -3,  1
	db -2,  3, -3,  3, -3,  3, -3,  2, -3,  2, -2,  2

; Authored deltas are sign-reversed by transform 3 in the renderer.
; Enemy's last two legs crest, then descend into the same arrival point;
; X eases from -3px toward -1px instead of sliding at -2px throughout.
.drainingEnemySteps:
	db  1,  2,  1,  2,  1,  3,  1,  2,  1,  3,  1,  2
	db  1,  3,  1,  2,  1,  3,  1,  2,  1,  3,  0,  2
	db  0,  3, -1,  2, -2,  2, -2,  2, -2,  2, -2,  2

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
