; Johto map-local field skills. The 8x8 compact art IDs are shared among
; water, walls and plants; only Gold collision coordinates may unlock a
; field action. Do not widen tilecoll. VioletCity is 40x36 cells; Cherrygrove
; is 40x18 cells. The helper names retain VIOLET-247 compatibility.
JohtoVioletIsActive::
	ld a, [wCurMap]
	cp JOHTO_RUNTIME_MAP_HANDLE
	jp nz, .no
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	jp nz, .no
	ld a, [wCurLocalMapID]
	cp JOHTO_VIOLET_CITY_LOCAL_ID
	jp nz, .no
	scf
	ret
.no
	and a
	ret

; Carry = Gold WATER immediately ahead (all other maps return clear).
; Preserves BC, DE and HL, same as the historical Union Cave Surf helper.
JohtoVioletWaterAhead::
	push bc
	push de
	push hl
	call JohtoVioletIsActive
	jp nc, .noWater
	ld a, [wYCoord]
	ld d, a
	ld a, [wXCoord]
	ld e, a
	ld a, [wSpriteStateData1 + 9]
	cp SPRITE_FACING_DOWN
	jr nz, .up
	inc d
	jr .bounds
.up
	cp SPRITE_FACING_UP
	jr nz, .left
	dec d
	jr .bounds
.left
	cp SPRITE_FACING_LEFT
	jr nz, .right
	dec e
	jr .bounds
.right
	cp SPRITE_FACING_RIGHT
	jp nz, .noWater
	inc e
.bounds
	ld a, d
	cp 36
	jp nc, .noWater
	ld a, e
	cp 40
	jp nc, .noWater
	ld hl, JohtoVioletGoldWaterCells
.loop
	ld a, [hli] ; y
	cp $ff
	jr z, .noWater
	cp d
	jr nz, .skipX
	ld a, [hli] ; x
	cp e
	jr z, .yesWater
	jr .loop
.skipX
	inc hl
	jr .loop
.yesWater
	scf
	jr .done
.noWater
	and a
.done
	pop hl
	pop de
	pop bc
	ret

; Cherrygrove City uses the same existing Surf entrypoints and shore scan as
; Violet City, but its Gold map is only 20x9 blocks (40x18 collision cells).
; Keep this predicate/map-specific table separate: shared 8x8 art IDs are not
; enough to authorize Surf on other maps.
JohtoCherrygroveIsActive::
	ld a, [wCurMap]
	cp JOHTO_RUNTIME_MAP_HANDLE
	jp nz, .no
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	jp nz, .no
	ld a, [wCurLocalMapID]
	cp JOHTO_CHERRYGROVE_LOCAL_ID
	jp nz, .no
	scf
	ret
.no
	and a
	ret

; Carry = Gold WATER immediately ahead in Cherrygrove City only.
; Preserves BC, DE and HL. The 142 entries are decoded from Gold's original
; CherrygroveCity.blk plus johto_collision.asm, not inferred from artwork.
JohtoCherrygroveWaterAhead::
	push bc
	push de
	push hl
	call JohtoCherrygroveIsActive
	jp nc, .noWater
	ld a, [wYCoord]
	ld d, a
	ld a, [wXCoord]
	ld e, a
	ld a, [wSpriteStateData1 + 9]
	cp SPRITE_FACING_DOWN
	jr nz, .up
	inc d
	jr .bounds
.up
	cp SPRITE_FACING_UP
	jr nz, .left
	dec d
	jr .bounds
.left
	cp SPRITE_FACING_LEFT
	jr nz, .right
	dec e
	jr .bounds
.right
	cp SPRITE_FACING_RIGHT
	jp nz, .noWater
	inc e
.bounds
	ld a, d
	cp 18
	jp nc, .noWater
	ld a, e
	cp 40
	jp nc, .noWater
	ld hl, JohtoCherrygroveGoldWaterCells
.loop
	ld a, [hli] ; y
	cp $ff
	jr z, .noWater
	cp d
	jr nz, .skipX
	ld a, [hli] ; x
	cp e
	jr z, .yesWater
	jr .loop
.skipX
	inc hl
	jr .loop
.yesWater
	scf
	jr .done
.noWater
	and a
.done
	pop hl
	pop de
	pop bc
	ret

; Gold Cherrygrove SW rock platform has eight FLOOR cells (x4..7,
; y12..13), rendered with compact tile $3c, which also appears on walls.
; This explicit Gold-only land table is shared by surf disembark and normal
; walking; do not add $3c to the global passable-tile whitelist.
; Carry = facing the exact registered FLOOR; registers BC/DE/HL preserved.
JohtoCherrygroveShoreFloorAhead::
	push bc
	push de
	push hl
	call JohtoCherrygroveIsActive
	jp nc, .noFloor
	ld a, [wYCoord]
	ld d, a
	ld a, [wXCoord]
	ld e, a
	ld a, [wSpriteStateData1 + 9]
	cp SPRITE_FACING_DOWN
	jr nz, .up
	inc d
	jr .lookup
.up
	cp SPRITE_FACING_UP
	jr nz, .left
	dec d
	jr .lookup
.left
	cp SPRITE_FACING_LEFT
	jr nz, .right
	dec e
	jr .lookup
.right
	cp SPRITE_FACING_RIGHT
	jr nz, .noFloor
	inc e
.lookup
	ld hl, JohtoCherrygroveShoreFloorCells
.loop
	ld a, [hli]
	cp $ff
	jr z, .noFloor
	cp d
	jr nz, .skipX
	ld a, [hli]
	cp e
	jr z, .yesFloor
	jr .loop
.skipX
	inc hl
	jr .loop
.yesFloor
	scf
	jr .done
.noFloor
	and a
.done
	pop hl
	pop de
	pop bc
	ret

JohtoCherrygroveShoreFloorCells::
	db 12, 4
	db 12, 5
	db 12, 6
	db 12, 7
	db 13, 4
	db 13, 5
	db 13, 6
	db 13, 7
	db $ff
JohtoCherrygroveShoreFloorCellsEnd::
ASSERT JohtoCherrygroveShoreFloorCellsEnd - JohtoCherrygroveShoreFloorCells == 8 * 2 + 1

; The only Gold CUT_TREE in Violet is at (x=36,y=19), directly next to a
; HEADBUTT_TREE at (37,19). The original block $63 must be present: once
; it is cut, $8d replaces it and a second cut must fail.
JohtoVioletCutTreeAhead::
	push bc
	push de
	push hl
	call JohtoVioletIsActive
	jp nc, .no
	ld a, [wXCoord]
	ld d, a
	ld a, [wYCoord]
	ld e, a
	ld a, [wSpriteStateData1 + 9]
	cp SPRITE_FACING_DOWN
	jr nz, .up
	ld a, d
	cp 36
	jp nz, .no
	ld a, e
	cp 18
	jr z, .candidate
	jp .no
.up
	cp SPRITE_FACING_UP
	jr nz, .left
	ld a, d
	cp 36
	jp nz, .no
	ld a, e
	cp 20
	jr z, .candidate
	jp .no
.left
	cp SPRITE_FACING_LEFT
	jr nz, .right
	ld a, d
	cp 37
	jp nz, .no
	ld a, e
	cp 19
	jr z, .candidate
	jp .no
.right
	cp SPRITE_FACING_RIGHT
	jp nz, .no
	ld a, d
	cp 35
	jp nz, .no
	ld a, e
	cp 19
	jp nz, .no
.candidate
	; Validate the live map block (not just the original position), so a
	; removed tree does not return after a second Cut in the same view.
	ld a, [wCurMapWidth]
	add 6
	ld c, a
	ld b, 0
	ld hl, wCurrentTileBlockMapViewPointer
	ld a, [hli]
	ld h, [hl]
	ld l, a
	add hl, bc
	ld a, [wSpriteStateData1 + 9]
	cp SPRITE_FACING_DOWN
	jr z, .downBlock
	cp SPRITE_FACING_UP
	jr z, .upBlock
	cp SPRITE_FACING_LEFT
	jr z, .leftBlock
	ld a, [wXBlockCoord]
	and a
	jr z, .centerBlock
	jr .rightBlock
.downBlock
	ld a, [wYBlockCoord]
	and a
	jr z, .centerBlock
	jr .belowBlock
.upBlock
	ld a, [wYBlockCoord]
	and a
	jr z, .aboveBlock
	jr .centerBlock
.leftBlock
	ld a, [wXBlockCoord]
	and a
	jr z, .leftOfCenter
	jr .centerBlock
.belowBlock
	add hl, bc
.centerBlock
	add hl, bc
.aboveBlock
	ld de, 2
	add hl, de
	jr .checkBlock
.leftOfCenter
	ld de, 1
	add hl, bc
	add hl, de
	jr .checkBlock
.rightBlock
	ld de, 3
	add hl, bc
	add hl, de
.checkBlock
	ld a, [hl]
	cp $63
	jp nz, .no
	scf
	jr .finish
.no
	and a
.finish
	pop hl
	pop de
	pop bc
	ret

; Gold source collision table lists exactly 140 WATER quadrants.
; Each record is (y, x); terminator is $ff. No generic water whitelist.
JohtoVioletGoldWaterCells::
	db 0, 10
	db 0, 11
	db 0, 12
	db 0, 13
	db 0, 14
	db 0, 15
	db 0, 16
	db 0, 17
	db 1, 10
	db 1, 11
	db 1, 12
	db 1, 13
	db 1, 14
	db 1, 15
	db 1, 16
	db 1, 17
	db 2, 10
	db 2, 11
	db 2, 12
	db 2, 13
	db 2, 14
	db 2, 15
	db 2, 16
	db 2, 17
	db 2, 30
	db 2, 31
	db 2, 32
	db 2, 33
	db 3, 10
	db 3, 11
	db 3, 12
	db 3, 13
	db 3, 14
	db 3, 15
	db 3, 16
	db 3, 17
	db 3, 30
	db 3, 31
	db 3, 32
	db 3, 33
	db 4, 14
	db 4, 15
	db 4, 16
	db 4, 17
	db 4, 30
	db 4, 31
	db 4, 32
	db 4, 33
	db 5, 14
	db 5, 15
	db 5, 16
	db 5, 17
	db 5, 30
	db 5, 31
	db 5, 32
	db 5, 33
	db 6, 14
	db 6, 15
	db 6, 16
	db 6, 17
	db 6, 30
	db 6, 31
	db 6, 32
	db 6, 33
	db 7, 14
	db 7, 15
	db 7, 16
	db 7, 17
	db 7, 30
	db 7, 31
	db 7, 32
	db 7, 33
	db 8, 14
	db 8, 15
	db 8, 16
	db 8, 17
	db 8, 30
	db 8, 31
	db 8, 32
	db 8, 33
	db 9, 14
	db 9, 15
	db 9, 16
	db 9, 17
	db 9, 30
	db 9, 31
	db 9, 32
	db 9, 33
	db 10, 14
	db 10, 15
	db 10, 16
	db 10, 17
	db 10, 26
	db 10, 27
	db 10, 28
	db 10, 29
	db 10, 30
	db 10, 31
	db 10, 32
	db 10, 33
	db 11, 14
	db 11, 15
	db 11, 16
	db 11, 17
	db 11, 26
	db 11, 27
	db 11, 28
	db 11, 29
	db 11, 30
	db 11, 31
	db 11, 32
	db 11, 33
	db 12, 14
	db 12, 15
	db 12, 16
	db 12, 17
	db 12, 26
	db 12, 27
	db 12, 28
	db 12, 29
	db 12, 30
	db 12, 31
	db 12, 32
	db 12, 33
	db 13, 14
	db 13, 15
	db 13, 16
	db 13, 17
	db 13, 26
	db 13, 27
	db 13, 28
	db 13, 29
	db 13, 30
	db 13, 31
	db 13, 32
	db 13, 33
	db 14, 14
	db 14, 15
	db 15, 14
	db 15, 15
	db $ff
JohtoVioletGoldWaterCellsEnd::
ASSERT JohtoVioletGoldWaterCellsEnd - JohtoVioletGoldWaterCells == 140 * 2 + 1

; Gold CherrygroveCity WATER collision cells (40x18). Source coordinates are
; compared by tools/johto_surf_preflight.py against the original Gold assets.
JohtoCherrygroveGoldWaterCells::
	db 0, 34
	db 0, 35
	db 0, 36
	db 0, 37
	db 1, 34
	db 1, 35
	db 1, 36
	db 1, 37
	db 4, 0
	db 4, 1
	db 4, 4
	db 4, 5
	db 4, 6
	db 4, 7
	db 5, 0
	db 5, 1
	db 5, 4
	db 5, 5
	db 5, 6
	db 5, 7
	db 6, 0
	db 6, 1
	db 6, 2
	db 6, 4
	db 6, 5
	db 6, 6
	db 6, 7
	db 6, 8
	db 6, 9
	db 7, 0
	db 7, 1
	db 7, 2
	db 7, 4
	db 7, 5
	db 7, 6
	db 7, 7
	db 7, 8
	db 7, 9
	db 8, 4
	db 8, 5
	db 8, 6
	db 8, 7
	db 8, 8
	db 8, 9
	db 9, 2
	db 9, 3
	db 9, 4
	db 9, 5
	db 9, 6
	db 9, 7
	db 9, 8
	db 9, 9
	db 10, 1
	db 10, 2
	db 10, 3
	db 10, 6
	db 10, 7
	db 10, 8
	db 10, 9
	db 10, 10
	db 10, 11
	db 10, 12
	db 10, 13
	db 11, 1
	db 11, 2
	db 11, 3
	db 11, 6
	db 11, 7
	db 11, 8
	db 11, 9
	db 11, 10
	db 11, 11
	db 11, 12
	db 11, 13
	db 12, 1
	db 12, 2
	db 12, 3
	db 12, 8
	db 12, 9
	db 12, 10
	db 12, 11
	db 12, 12
	db 12, 13
	db 12, 14
	db 12, 15
	db 13, 1
	db 13, 2
	db 13, 3
	db 13, 8
	db 13, 9
	db 13, 10
	db 13, 11
	db 13, 12
	db 13, 13
	db 13, 14
	db 13, 15
	db 14, 1
	db 14, 2
	db 14, 3
	db 14, 4
	db 14, 5
	db 14, 6
	db 14, 7
	db 14, 8
	db 14, 9
	db 14, 10
	db 14, 11
	db 14, 16
	db 14, 17
	db 15, 1
	db 15, 2
	db 15, 3
	db 15, 4
	db 15, 5
	db 15, 6
	db 15, 7
	db 15, 8
	db 15, 9
	db 15, 10
	db 15, 11
	db 15, 13
	db 15, 16
	db 15, 17
	db 16, 2
	db 16, 3
	db 16, 8
	db 16, 9
	db 16, 10
	db 16, 11
	db 16, 13
	db 16, 14
	db 16, 15
	db 16, 16
	db 16, 17
	db 17, 0
	db 17, 5
	db 17, 6
	db 17, 13
	db 17, 14
	db 17, 15
	db 17, 16
	db 17, 17
	db $ff
JohtoCherrygroveGoldWaterCellsEnd::
ASSERT JohtoCherrygroveGoldWaterCellsEnd - JohtoCherrygroveGoldWaterCells == 142 * 2 + 1
