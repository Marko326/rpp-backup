; JPATROL-5.62.243: preserve RPP/Kanto WALK state machine and map collision;
; enforce only Gold's independent patrol radius for the six enabled Johto
; interior walkers. The Kanto object macro has no radius fields.
;
; Called with D/E = signed Y/X step from CanWalkOntoTile after its scripted
; movement bypass. Returns carry on denial (and performs the same delayed
; state transition as CanWalkOntoTile.impassable), clear carry otherwise.
; BC, HL, A may be clobbered; DE preserved. The bank-1 caller saves BC.
; All native Johto maps share map handle $FC: check region AND local ID.
;
; Bounds refer to c2x4/c2x5 16x16 map-cell coordinates (= Gold x/y + 4).
; The allowed interval includes both endpoints. The existing WALK axis
; restriction prevents cross-axis wandering; map collision still takes effect.
CheckJohtoNPCPatrolBounds::
	push de
	ld a, [wCurMap]
	cp REGION_NATIVE_MAP_SLOT
	jr nz, .allow
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	jr nz, .allow
	ld a, [wCurSpriteMovement2]
	cp 1                         ; Kanto WALK,1 = vertical
	jr z, .checkWalker
	cp 2                         ; Kanto WALK,2 = horizontal
	jr nz, .allow
.checkWalker
	; STAY and scripted moves must never be subject to this bound.
	ld h, wSpriteStateData2 / $100
	ld a, [H_CURRENTSPRITEOFFSET]
	add 6
	ld l, a
	ld a, [hl]                  ; c2x6 movement byte 1
	cp WALK                     ; only $fe random walking
	jr nz, .allow
	ld a, [wCurLocalMapID]
	ld c, a
	ld hl, .bounds
.lookup
	ld a, [hli]                 ; local map ID
	cp $ff
	jr z, .allow
	cp c
	jr z, .found
	inc hl                      ; skip lower bound
	inc hl                      ; skip upper bound
	jr .lookup
.found
	ld a, [hli]
	ld b, a                     ; inclusive minimum
	ld c, [hl]                  ; inclusive maximum
	ld h, wSpriteStateData2 / $100
	ld a, [H_CURRENTSPRITEOFFSET]
	add 4                       ; c2x4 = map Y, c2x5 = map X
	ld l, a
	ld a, [wCurSpriteMovement2]
	cp 2
	jr nz, .vertical
	inc l
	ld a, [hl]                  ; map X
	add e                       ; proposed next X
	jr .compare
.vertical
	ld a, [hl]                  ; map Y
	add d                       ; proposed next Y
.compare
	cp b
	jr c, .blocked
	cp c
	jr z, .allow
	jr nc, .blocked
.allow
	pop de
	and a                       ; success/clear carry
	ret
.blocked
	pop de
	; Reproduce the Kanto blocked-step transition, including its random
	; retry delay. Returning carry alone would leave NPCs spinning each frame.
	ld h, wSpriteStateData1 / $100
	ld a, [H_CURRENTSPRITEOFFSET]
	inc a
	ld l, a
	ld [hl], 2                  ; c1x1 = delayed
	inc l
	inc l
	xor a
	ld [hli], a                 ; c1x3 = zero Y delta
	inc l
	ld [hl], a                  ; c1x5 = zero X delta
	inc h
	ld a, [H_CURRENTSPRITEOFFSET]
	add 8
	ld l, a
	call Random
	ld a, [hRandomAdd]
	and $7f
	ld [hl], a                  ; c2x8 next movement delay
	scf
	ret

.bounds
	; Gold maps/*.asm object_event: x,y,move,range_x,range_y.
	; Every map below currently has exactly ONE WALK NPC; adding another
	; requires updating this table/lookup and the parity tests first.
	; map, min map-coordinate, max map-coordinate (both inclusive)
	db JOHTO_CHERRYGROVE_MART_LOCAL_ID,                 7+4-2, 7+4+2 ; male (7,6), LR radius 2
	db JOHTO_OLIVINE_MART_LOCAL_ID,                     6+4-2, 6+4+2 ; woman (6,2), LR radius 2
	db JOHTO_OLIVINE_POKECENTER_1F_LOCAL_ID,           8+4-1, 8+4+1 ; fisher (8,4), LR radius 1
	db JOHTO_OLIVINE_CAFE_LOCAL_ID,                     5+4-1, 5+4+1 ; fisher (1,5), UD radius 1
	db JOHTO_OLIVINE_PUNISHMENT_SPEECH_HOUSE_LOCAL_ID, 5+4-2, 5+4+2 ; girl (5,5), LR radius 2
	db JOHTO_CHERRYGROVE_GYM_SPEECH_HOUSE_LOCAL_ID,    5+4-1, 5+4+1 ; boy (5,5), LR radius 1
	db $ff
