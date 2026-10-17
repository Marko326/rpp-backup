; R33-5.62.191: Route33 Gold 16x16 collision per coordinate, not per 8x8 art.
; Cave (11,9) has exact northward approach exception; Azalea remains fenced.
; Direct call from JohtoNativeCollisionFence, returns carry=blocked.
JohtoRoute33EdgeFence::
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_UP
	jr z, .north
	cp PLAYER_DIR_DOWN
	jr z, .south
	cp PLAYER_DIR_LEFT
	jr z, .west
	cp PLAYER_DIR_RIGHT
	jr nz, .clear
	ld a, [wXCoord]
	cp JOHTO_ROUTE_33_WIDTH * 2 - 1
	jr nc, .block
	jr .clear
.north
	ld a, [wYCoord]
	and a
	jr nz, .clear
	ld a, [wXCoord]
	cp 15
	jr c, .clear
	jr .block
.west
	ld a, [wXCoord]
	and a
	jr nz, .clear
	ld a, [wYCoord]
	cp 14
	jr c, .block
	cp 16
	jr c, .clear
	jr .block
.south
	ld a, [wYCoord]
	cp JOHTO_ROUTE_33_HEIGHT * 2 - 1
	jr c, .clear
.block
	scf
	ret
.clear
	and a
	ret

; MAP-5.62.195: all Azalea borders closed except Gold's Route33 east road.
JohtoAzaleaEdgeFence::
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_RIGHT
	jr z, .east
	cp PLAYER_DIR_LEFT
	jr z, .west
	cp PLAYER_DIR_UP
	jr z, .north
	cp PLAYER_DIR_DOWN
	jr nz, .clear
	ld a, [wYCoord]
	cp JOHTO_AZALEA_TOWN_HEIGHT * 2 - 1
	jr nc, .block
	jr .clear
.north
	ld a, [wYCoord]
	and a
	jr z, .block
	jr .clear
.west
	ld a, [wXCoord]
	and a
	jr z, .block ; Route34 remains closed
	jr .clear
.east
	ld a, [wXCoord]
	cp JOHTO_AZALEA_TOWN_WIDTH * 2 - 1
	jr c, .clear
	ld a, [wYCoord]
	cp 14
	jr c, .block
	cp 16
	jr nc, .block
	jr .clear
.block
	scf
	ret
.clear
	and a
	ret

; R33-5.62.191: can enter the precise Gold collision quadrant ahead.
; Input: wCurMap $FC / Johto local 9. Result: carry=blocked, clear=allowed.
; Call via callba; do not enter if not on the exact native Route33 map.
JohtoRoute33CanStepAhead::
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	jp nz, .blocked
	ld a, [wCurLocalMapID]
	cp JOHTO_ROUTE_33_LOCAL_ID
	jp nz, .blocked
	; Preserve the already accepted Gold cave mouth and north connection.
	ld a, [wXCoord]
	cp 11
	jr nz, .normalStep
	ld a, [wYCoord]
	cp 10
	jr nz, .normalStep
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_UP
	jp z, .allowed
.normalStep
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_LEFT
	jr nz, .northSeam
	ld a, [wXCoord]
	and a
	jr nz, .normal
	ld a, [wYCoord]
	cp 14
	jr c, .normal
	cp 16
	jr c, .allowed
.northSeam
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_UP
	jr nz, .normal
	ld a, [wYCoord]
	and a
	jr nz, .normal
	ld a, [wXCoord]
	cp 15
	jr c, .allowed
.normal
	ld hl, JohtoRoute33BlockedRows
	ld d, JOHTO_ROUTE_33_WIDTH * 2
	ld e, 3
	jp JohtoModernMaskedStep
.allowed
	and a
	ret
.blocked
	scf
	ret

; The second map reuses exactly the same Gold position-mask logic.
; Its six DOOR/CAVE cells remain blocked because destination interiors are absent.
JohtoAzaleaCanStepAhead::
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	jr nz, .blocked
	ld a, [wCurLocalMapID]
	cp JOHTO_AZALEA_TOWN_LOCAL_ID
	jr nz, .blocked
	; GATE-5.62.202: the two Gold doorway carpet cells are a single
	; vertically walkable pair, although their Gold collision role is WARP.
	; Do not open north of y=10 or south of y=11 (both remain WALL).
	ld a, [wXCoord]
	cp 2
	jr nz, .enterGate
	ld a, [wYCoord]
	cp 10
	jr z, .upperCarpet
	cp 11
	jr nz, .enterGate
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_UP
	jr z, .allowed
	jr .enterGate
.upperCarpet
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_DOWN
	jr z, .allowed
.enterGate
	; Reuse the existing Gold path from x=3 towards the west doorway.
	; Other Gold doors/well remain blocked by the unchanged binary mask.
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_LEFT
	jr nz, .eastConnection
	ld a, [wXCoord]
	cp 3
	jr nz, .eastConnection
	ld a, [wYCoord]
	cp 10
	jr z, .allowed
	cp 11
	jr z, .allowed
.eastConnection
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_RIGHT
	jr nz, .normal
	ld a, [wXCoord]
	cp JOHTO_AZALEA_TOWN_WIDTH * 2 - 1
	jr nz, .normal
	ld a, [wYCoord]
	cp 14
	jr c, .normal
	cp 16
	jr c, .allowed
.normal
	ld hl, JohtoAzaleaBlockedRows
	ld d, JOHTO_AZALEA_TOWN_WIDTH * 2
	ld e, 5
	jp JohtoModernMaskedStep
.allowed
	and a
	ret
.blocked
	scf
	ret

 ; GATE-5.62.202: render-only Azalea west border continuation. The Gold
; 20x9 in-map layout is untouched, as are collision and Warp coordinates.
; LoadTileBlockMap has filled the 3-block border. Only the west neighbor
; of Gold blocks (0,4) and (0,5) needs LEFT roof/wall halves, not clones.
; If the map header or dimensions change, revisit both offsets.
PatchJohtoAzaleaWestGateBorder::
	ld a, [wCurMap]
	cp REGION_NATIVE_MAP_SLOT
	ret nz
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	ret nz
	ld a, [wCurLocalMapID]
	cp JOHTO_AZALEA_TOWN_LOCAL_ID
	ret nz
	ld hl, wOverworldMap + (MAP_BORDER + 4) * (JOHTO_AZALEA_TOWN_WIDTH + 2 * MAP_BORDER) + MAP_BORDER - 1
	ld [hl], $08 ; Gold LEFT roof half, paired with (0,4) $09
	ld hl, wOverworldMap + (MAP_BORDER + 5) * (JOHTO_AZALEA_TOWN_WIDTH + 2 * MAP_BORDER) + MAP_BORDER - 1
	ld [hl], $1c ; Gold LEFT facade half, paired with (0,5) $1e
	ret

; Shared 16x16 Gold block mask lookup; HL=mask, D=width cells, E=row bytes.
; Both current maps are 9 blocks (18 quadrants) high. The caller verifies map key.
JohtoModernMaskedStep::
	ld a, [wXCoord]
	ld c, a
	ld a, [wYCoord]
	ld b, a
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_UP
	jr z, .up
	cp PLAYER_DIR_DOWN
	jr z, .down
	cp PLAYER_DIR_LEFT
	jr z, .left
	cp PLAYER_DIR_RIGHT
	jr nz, .blocked
	inc c
	jr .position
.left
	dec c
	jr .position
.down
	inc b
	jr .position
.up
	dec b
.position
	ld a, b
	cp JOHTO_ROUTE_33_HEIGHT * 2
	jr nc, .blocked
	ld a, c
	cp d
	jr nc, .blocked
	ld a, b
	ld d, 0
	and a
	jr z, .column
.row
	add hl, de
	dec a
	jr nz, .row
.column
	ld a, c
	ld b, a
	srl a
	srl a
	srl a
	ld e, a
	ld d, 0
	add hl, de
	ld c, [hl]
	ld a, b
	and 7
	ld b, a
	ld a, 1
	jr z, .maskReady
.shift
	add a
	dec b
	jr nz, .shift
.maskReady
	and c
	jr nz, .blocked
	and a
	ret
.blocked
	scf
	ret

; Audited against Gold Route33 20x18 16x16 collision map.
JohtoRoute33BlockedRows::
	INCBIN "maps/JohtoRoute33.blocked_mask.bin"

; MAP-5.62.195: same Gold modern data-driven collision, 40x18 cells.
JohtoAzaleaBlockedRows::
	INCBIN "maps/JohtoAzaleaTown.blocked_mask.bin"
