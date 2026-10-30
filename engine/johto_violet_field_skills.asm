; Johto map-local field skills. The 8x8 compact art IDs are shared among
; water, walls and plants; only Gold collision coordinates may unlock a
; field action. Do not widen tilecoll. VioletCity is 40x36 cells; Cherrygrove
; and NewBarkTown are 40x18 and 20x18 cells respectively. Helper names retain
; their compatibility labels from earlier releases.
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
	; Bank $03 Surfboard remains untouched: this gateway forwards the exact
	; Route30/31/32 and NewBark contracts before checking Violet. All helpers
	; preserve BC/DE/HL.
	call JohtoRoute30WaterAhead
	ret c
	call JohtoRoute31WaterAhead
	ret c
	call JohtoRoute32WaterAhead
	ret c
	call JohtoRuinsWaterAhead
	ret c
	call JohtoNewBarkWaterAhead
	ret c
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

; New Bark Town's small eastern pond is now enabled after the complete
; active-map audit. The exact eight Gold WATER cells are kept map-local; do not
; infer permission from the shared water art tile.
JohtoNewBarkIsActive::
	ld a, [wCurMap]
	cp JOHTO_RUNTIME_MAP_HANDLE
	jp nz, .no
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	jp nz, .no
	ld a, [wCurLocalMapID]
	cp JOHTO_NEW_BARK_LOCAL_ID
	jp nz, .no
	scf
	ret
.no
	and a
	ret

; Carry = facing one of New Bark Town's eight Gold WATER cells.
; Preserves BC, DE and HL and rejects all other maps/coordinates.
JohtoNewBarkWaterAhead::
	push bc
	push de
	push hl
	call JohtoNewBarkIsActive
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
	cp 20
	jp nc, .noWater
	ld hl, JohtoNewBarkGoldWaterCells
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

JohtoNewBarkGoldWaterCells::
	db 6, 18
	db 6, 19
	db 7, 18
	db 7, 19
	db 8, 18
	db 8, 19
	db 9, 18
	db 9, 19
	db $ff
JohtoNewBarkGoldWaterCellsEnd::
ASSERT JohtoNewBarkGoldWaterCellsEnd - JohtoNewBarkGoldWaterCells == 8 * 2 + 1

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

; ROUTES-251: Gold water only, for two already-active Johto outdoor roads.
; Keep the three established Surf entrypoints; do not whitelist compact art IDs.

JohtoRoute30IsActive::
	ld a, [wCurMap]
	cp JOHTO_RUNTIME_MAP_HANDLE
	jp nz, .no
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	jp nz, .no
	ld a, [wCurLocalMapID]
	cp JOHTO_ROUTE_30_LOCAL_ID
	jp nz, .no
	scf
	ret
.no
	and a
	ret

; Carry = facing one of the 32 original Gold WATER cells.
; Preserve BC/DE/HL, including when no water or wrong map is selected.
JohtoRoute30WaterAhead::
	push bc
	push de
	push hl
	call JohtoRoute30IsActive
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
	cp 54
	jp nc, .noWater
	ld a, e
	cp 20
	jp nc, .noWater
	ld hl, JohtoRoute30GoldWaterCells
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

JohtoRoute30GoldWaterCells::
	db 38, 14
	db 38, 15
	db 38, 16
	db 38, 17
	db 39, 14
	db 39, 15
	db 39, 16
	db 39, 17
	db 40, 14
	db 40, 15
	db 40, 16
	db 40, 17
	db 41, 14
	db 41, 15
	db 41, 16
	db 41, 17
	db 42, 14
	db 42, 15
	db 42, 16
	db 42, 17
	db 43, 14
	db 43, 15
	db 43, 16
	db 43, 17
	db 50, 18
	db 50, 19
	db 51, 18
	db 51, 19
	db 52, 18
	db 52, 19
	db 53, 18
	db 53, 19
	db $ff
JohtoRoute30GoldWaterCellsEnd::
ASSERT JohtoRoute30GoldWaterCellsEnd - JohtoRoute30GoldWaterCells == 32 * 2 + 1

JohtoRoute31IsActive::
	ld a, [wCurMap]
	cp JOHTO_RUNTIME_MAP_HANDLE
	jp nz, .no
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	jp nz, .no
	ld a, [wCurLocalMapID]
	cp JOHTO_ROUTE_31_LOCAL_ID
	jp nz, .no
	scf
	ret
.no
	and a
	ret

; Carry = facing one of the 44 original Gold WATER cells.
; Preserve BC/DE/HL, including when no water or wrong map is selected.
JohtoRoute31WaterAhead::
	push bc
	push de
	push hl
	call JohtoRoute31IsActive
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
	ld hl, JohtoRoute31GoldWaterCells
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

JohtoRoute31GoldWaterCells::
	db 2, 16
	db 2, 17
	db 2, 18
	db 2, 19
	db 2, 20
	db 2, 21
	db 3, 16
	db 3, 17
	db 3, 18
	db 3, 19
	db 3, 20
	db 3, 21
	db 4, 16
	db 4, 17
	db 4, 18
	db 4, 19
	db 4, 20
	db 4, 21
	db 4, 22
	db 4, 23
	db 4, 24
	db 4, 25
	db 5, 16
	db 5, 17
	db 5, 18
	db 5, 19
	db 5, 20
	db 5, 21
	db 5, 22
	db 5, 23
	db 5, 24
	db 5, 25
	db 6, 20
	db 6, 21
	db 6, 22
	db 6, 23
	db 6, 24
	db 6, 25
	db 7, 20
	db 7, 21
	db 7, 22
	db 7, 23
	db 7, 24
	db 7, 25
	db $ff
JohtoRoute31GoldWaterCellsEnd::
ASSERT JohtoRoute31GoldWaterCellsEnd - JohtoRoute31GoldWaterCells == 44 * 2 + 1


; ROUTES-252: Route32, exactly 278 Gold WATER cells; source .blk
; and original johto_collision.asm, never compact art-ID guessing.
JohtoRoute32IsActive::
	ld a, [wCurMap]
	cp JOHTO_RUNTIME_MAP_HANDLE
	jp nz, .no
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	jp nz, .no
	ld a, [wCurLocalMapID]
	cp JOHTO_ROUTE_32_LOCAL_ID
	jp nz, .no
	scf
	ret
.no
	and a
	ret

JohtoRoute32WaterAhead::
	push bc
	push de
	push hl
	call JohtoRoute32IsActive
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
	cp 90
	jp nc, .noWater
	ld a, e
	cp 20
	jp nc, .noWater
	ld hl, JohtoRoute32GoldWaterCells
.loop
	ld a, [hli]
	cp $ff
	jr z, .noWater
	cp d
	jr nz, .skipX
	ld a, [hli]
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

JohtoRoute32GoldWaterCells::
	db 8, 0
	db 8, 1
	db 9, 0
	db 9, 1
	db 10, 0
	db 10, 1
	db 11, 0
	db 11, 1
	db 40, 12
	db 40, 13
	db 40, 16
	db 40, 17
	db 40, 18
	db 40, 19
	db 41, 12
	db 41, 13
	db 41, 16
	db 41, 17
	db 41, 18
	db 41, 19
	db 42, 4
	db 42, 5
	db 42, 6
	db 42, 7
	db 42, 8
	db 42, 9
	db 42, 12
	db 42, 13
	db 42, 14
	db 42, 16
	db 42, 17
	db 43, 4
	db 43, 5
	db 43, 6
	db 43, 7
	db 43, 8
	db 43, 9
	db 43, 12
	db 43, 13
	db 43, 14
	db 43, 16
	db 43, 17
	db 44, 4
	db 44, 5
	db 44, 6
	db 44, 7
	db 44, 8
	db 44, 9
	db 44, 12
	db 44, 13
	db 44, 14
	db 44, 16
	db 44, 17
	db 44, 18
	db 44, 19
	db 45, 4
	db 45, 5
	db 45, 6
	db 45, 7
	db 45, 8
	db 45, 9
	db 45, 12
	db 45, 13
	db 45, 14
	db 45, 16
	db 45, 17
	db 45, 18
	db 45, 19
	db 46, 4
	db 46, 5
	db 46, 6
	db 46, 7
	db 46, 8
	db 46, 9
	db 46, 12
	db 46, 13
	db 46, 14
	db 46, 16
	db 46, 17
	db 46, 18
	db 46, 19
	db 47, 4
	db 47, 5
	db 47, 6
	db 47, 7
	db 47, 8
	db 47, 9
	db 47, 12
	db 47, 13
	db 47, 14
	db 47, 16
	db 47, 17
	db 47, 18
	db 47, 19
	db 48, 4
	db 48, 5
	db 48, 12
	db 48, 13
	db 48, 14
	db 48, 16
	db 48, 17
	db 48, 18
	db 48, 19
	db 49, 4
	db 49, 5
	db 49, 12
	db 49, 13
	db 49, 14
	db 49, 16
	db 49, 17
	db 49, 18
	db 49, 19
	db 50, 4
	db 50, 5
	db 50, 6
	db 50, 7
	db 50, 8
	db 50, 9
	db 50, 12
	db 50, 13
	db 50, 14
	db 50, 16
	db 50, 17
	db 50, 18
	db 50, 19
	db 51, 4
	db 51, 5
	db 51, 6
	db 51, 7
	db 51, 8
	db 51, 9
	db 51, 12
	db 51, 13
	db 51, 14
	db 51, 16
	db 51, 17
	db 51, 18
	db 51, 19
	db 52, 8
	db 52, 9
	db 52, 14
	db 52, 16
	db 52, 17
	db 52, 18
	db 52, 19
	db 53, 8
	db 53, 9
	db 53, 14
	db 53, 16
	db 53, 17
	db 53, 18
	db 53, 19
	db 54, 8
	db 54, 9
	db 54, 10
	db 54, 11
	db 54, 14
	db 54, 16
	db 54, 17
	db 54, 18
	db 54, 19
	db 55, 8
	db 55, 9
	db 55, 10
	db 55, 11
	db 55, 14
	db 55, 16
	db 55, 17
	db 55, 18
	db 55, 19
	db 56, 8
	db 56, 9
	db 56, 10
	db 56, 11
	db 56, 14
	db 56, 16
	db 56, 17
	db 56, 18
	db 56, 19
	db 57, 8
	db 57, 9
	db 57, 10
	db 57, 11
	db 57, 14
	db 57, 16
	db 57, 17
	db 57, 18
	db 57, 19
	db 58, 8
	db 58, 9
	db 58, 10
	db 58, 11
	db 58, 14
	db 58, 16
	db 58, 17
	db 58, 18
	db 58, 19
	db 59, 8
	db 59, 9
	db 59, 10
	db 59, 11
	db 59, 14
	db 59, 16
	db 59, 17
	db 59, 18
	db 59, 19
	db 60, 16
	db 60, 17
	db 60, 18
	db 60, 19
	db 61, 16
	db 61, 17
	db 61, 18
	db 61, 19
	db 62, 16
	db 62, 17
	db 62, 18
	db 62, 19
	db 63, 16
	db 63, 17
	db 63, 18
	db 63, 19
	db 64, 16
	db 64, 17
	db 64, 18
	db 64, 19
	db 65, 16
	db 65, 17
	db 65, 18
	db 65, 19
	db 66, 16
	db 66, 17
	db 66, 18
	db 66, 19
	db 67, 16
	db 67, 17
	db 67, 18
	db 67, 19
	db 68, 16
	db 68, 17
	db 68, 18
	db 68, 19
	db 69, 16
	db 69, 17
	db 69, 18
	db 69, 19
	db 70, 16
	db 70, 17
	db 70, 18
	db 70, 19
	db 71, 16
	db 71, 17
	db 71, 18
	db 71, 19
	db 72, 16
	db 72, 17
	db 72, 18
	db 72, 19
	db 73, 16
	db 73, 17
	db 73, 18
	db 73, 19
	db 74, 16
	db 74, 17
	db 74, 18
	db 74, 19
	db 75, 16
	db 75, 17
	db 75, 18
	db 75, 19
	db 76, 18
	db 76, 19
	db 77, 18
	db 77, 19
	db 78, 18
	db 78, 19
	db 79, 18
	db 79, 19
	db $ff
JohtoRoute32GoldWaterCellsEnd::
ASSERT JohtoRoute32GoldWaterCellsEnd - JohtoRoute32GoldWaterCells == 278 * 2 + 1

; Exact currently enabled Gold CUT_TREE cells, records (stable ID, y, x, original block).
; Routes 29 and 32 reuse the original $63/$5F clear-block clones ($8D/$8F),
; so no new swap entries in the Bank $03 Cut engine.
; On-screen block must still match; this blocks repeat Cut after the tile swap.
JohtoRoutesGoldCutCells::
	db JOHTO_ROUTE_29_LOCAL_ID, 9, 30, $63
	db JOHTO_ROUTE_29_LOCAL_ID, 11, 21, $5f
	db JOHTO_ROUTE_30_LOCAL_ID, 6, 8, $67
	db JOHTO_ROUTE_31_LOCAL_ID, 5, 13, $5f
	db JOHTO_ROUTE_31_LOCAL_ID, 10, 25, $5b
	db JOHTO_ROUTE_32_LOCAL_ID, 19, 10, $63
	db $ff
JohtoRoutesGoldCutCellsEnd::
ASSERT JohtoRoutesGoldCutCellsEnd - JohtoRoutesGoldCutCells == 6 * 4 + 1

JohtoRoutesCutTreeAhead::
	push bc
	push de
	push hl
	ld a, [wCurMap]
	cp JOHTO_RUNTIME_MAP_HANDLE
	jp nz, .no
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	jp nz, .no
	ld a, [wCurLocalMapID]
	cp JOHTO_ROUTE_29_LOCAL_ID
	jr z, .validMap
	cp JOHTO_ROUTE_30_LOCAL_ID
	jr z, .validMap
	cp JOHTO_ROUTE_31_LOCAL_ID
	jr z, .validMap
	cp JOHTO_ROUTE_32_LOCAL_ID
	jp nz, .no
.validMap
	ld b, a ; stable ID
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
	jp nz, .no
	inc e
.lookup
	ld hl, JohtoRoutesGoldCutCells
.loop
	ld a, [hli]
	cp $ff
	jp z, .no
	cp b
	jr nz, .skip3
	ld a, [hli] ; y
	cp d
	jr nz, .skip2
	ld a, [hli] ; x
	cp e
	jr nz, .skip1
	ld a, [hl] ; expected original block ID
	push af
	jr .checkLiveBlock
.skip3
	inc hl
.skip2
	inc hl
.skip1
	inc hl
	jr .loop
.checkLiveBlock
	; Identical front-facing block-map lookup to the established Violet Cut.
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
	jr .compareBlock
.leftOfCenter
	ld de, 1
	add hl, bc
	add hl, de
	jr .compareBlock
.rightBlock
	ld de, 3
	add hl, bc
	add hl, de
.compareBlock
	pop af
	cp [hl]
	jr nz, .no
	scf
	jr .done
.no
	and a
.done
	pop hl
	pop de
	pop bc
	ret

; One original Cut farcall suffices for Violet and Routes30/31. Keep all
; map-specific predicates fail-closed, and return the original carry result.
JohtoPilotCutTreeAhead::
	call JohtoVioletCutTreeAhead
	ret c
	jp JohtoRoutesCutTreeAhead

; ALPH-SOUTH-002: Gold Ruins exterior water (48 cells); same three Surf entrypoints.
JohtoRuinsIsActive::
	ld a, [wCurMap]
	cp JOHTO_RUNTIME_MAP_HANDLE
	jp nz, .no
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	jp nz, .no
	ld a, [wCurLocalMapID]
	cp JOHTO_RUINS_OF_ALPH_LOCAL_ID
	jp nz, .no
	scf
	ret
.no
	and a
	ret

JohtoRuinsWaterAhead::
	push bc
	push de
	push hl
	call JohtoRuinsIsActive
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
	cp 20
	jp nc, .noWater
	ld hl, JohtoRuinsGoldWaterCells
.loop
	ld a, [hli]
	cp $ff
	jr z, .noWater
	cp d
	jr nz, .skipX
	ld a, [hli]
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

JohtoRuinsGoldWaterCells::
	db 6, 2
	db 6, 3
	db 6, 4
	db 6, 5
	db 7, 2
	db 7, 3
	db 7, 4
	db 7, 5
	db 8, 2
	db 8, 3
	db 8, 4
	db 8, 5
	db 9, 2
	db 9, 3
	db 9, 4
	db 9, 5
	db 10, 2
	db 10, 3
	db 10, 4
	db 10, 5
	db 11, 2
	db 11, 3
	db 11, 4
	db 11, 5
	db 12, 2
	db 12, 3
	db 12, 4
	db 12, 5
	db 13, 2
	db 13, 3
	db 13, 4
	db 13, 5
	db 26, 12
	db 26, 13
	db 26, 14
	db 26, 15
	db 27, 12
	db 27, 13
	db 27, 14
	db 27, 15
	db 28, 12
	db 28, 13
	db 28, 14
	db 28, 15
	db 29, 12
	db 29, 13
	db 29, 14
	db 29, 15
	db $ff
JohtoRuinsGoldWaterCellsEnd::
ASSERT JohtoRuinsGoldWaterCellsEnd - JohtoRuinsGoldWaterCells == 48 * 2 + 1
