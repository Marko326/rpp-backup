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

; R35-5.62.223: Route36 east y8/9 remains open, south x17 reaches Route35.
; Route37 north and all other borders are still closed.
JohtoRoute36EdgeFence::
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
	cp JOHTO_ROUTE_36_HEIGHT * 2 - 1
	jr c, .clear
	ld a, [wXCoord]
	cp 17
	jr z, .clear
	jr .block
.north
	ld a, [wYCoord]
	and a
	jr z, .block
	jr .clear
.west
	ld a, [wXCoord]
	and a
	jr z, .block
	jr .clear
.east
	ld a, [wXCoord]
	cp JOHTO_ROUTE_36_WIDTH * 2 - 1
	jr c, .clear
	ld a, [wYCoord]
	cp 8
	jr z, .clear
	cp 9
	jr z, .clear
.block
	scf
	ret
.clear
	and a
	ret

; R36-5.62.218: reuse Gold 16x16 masked-step executor for Route36.
; Entrance carpets stay blocked pending gate implementations; no Sudowoodo
; object is spawned in this open-passage map stage (Gold battle deferred).
JohtoRoute36CanStepAhead::
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	jr nz, .blocked
	ld a, [wCurLocalMapID]
	cp JOHTO_ROUTE_36_LOCAL_ID
	jr nz, .blocked
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_DOWN
	jr nz, .checkEast
	ld a, [wYCoord]
	cp JOHTO_ROUTE_36_HEIGHT * 2 - 1
	jr nz, .normal
	ld a, [wXCoord]
	cp 17
	jr z, .allowed
.checkEast
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_RIGHT
	jr nz, .normal
	ld a, [wXCoord]
	cp JOHTO_ROUTE_36_WIDTH * 2 - 1
	jr nz, .normal
	ld a, [wYCoord]
	cp 8
	jr z, .allowed
	cp 9
	jr z, .allowed
.normal
	ld hl, JohtoRoute36BlockedRows
	ld d, JOHTO_ROUTE_36_WIDTH * 2
	ld e, 8
	jp JohtoModernMaskedStep
.allowed
	and a
	ret
.blocked
	scf
	ret

JohtoRoute36BlockedRows::
	INCBIN "maps/JohtoRoute36.blocked_mask.bin"

; R35-5.62.223: Gold 20x36 collision mask, no HOP cells.
; North x17 is the only active border; unfinished gates are sealed.
JohtoRoute35EdgeFence::
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
	cp JOHTO_ROUTE_35_WIDTH * 2 - 1
	jr nc, .block
	jr .clear
.north
	ld a, [wYCoord]
	and a
	jr nz, .clear
	ld a, [wXCoord]
	cp 17
	jr z, .clear
	jr .block
.south
	ld a, [wYCoord]
	cp JOHTO_ROUTE_35_HEIGHT * 2 - 1
	jr nc, .block
	jr .clear
.west
	ld a, [wXCoord]
	and a
	jr z, .block
.clear
	and a
	ret
.block
	scf
	ret

JohtoRoute35CanStepAhead::
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	jr nz, .blocked
	ld a, [wCurLocalMapID]
	cp JOHTO_ROUTE_35_LOCAL_ID
	jr nz, .blocked
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_UP
	jr nz, .normal
	ld a, [wYCoord]
	and a
	jr nz, .normal
	ld a, [wXCoord]
	cp 17
	jr z, .allowed
.normal
	; R35-5.62.223: the one CUT_TREE cell opens only after its live
	; metatile was replaced; the Gold mask remains unchanged on disk.
	call JohtoRoute35CutTreeCleared
	jr c, .allowed
	ld hl, JohtoRoute35BlockedRows
	ld d, JOHTO_ROUTE_35_WIDTH * 2
	ld e, 3
	jp JohtoModernMaskedStep
.allowed
	and a
	ret
.blocked
	scf
	ret

JohtoRoute35BlockedRows::
	INCBIN "maps/JohtoRoute35.blocked_mask.bin"

; R35-5.62.223: Gold Route35 CUT_TREE is the TOP-RIGHT quadrant
; (17,6) of metatile $5b at block coordinate (8,3).  New block $89 is
; $5b with only that 16x16 quadrant rendered as FLOOR ($05).
; Other quadrants, source .blk, headbutt trees and map connections persist.
; This uses the established Ilex Forest live-view Cut pointer (bank $43).
JohtoRoute35CutTreeInFront::
	call JohtoRoute35CutTreeFacing
	ret nc
	call JohtoCutFacingBlockPointer
	ld a, [hl]
	cp $5b
	jr z, .yes
	and a
	ret
.yes
	scf
	ret

JohtoRoute35CutTreeCleared::
	call JohtoRoute35CutTreeFacing
	ret nc
	call JohtoCutFacingBlockPointer
	ld a, [hl]
	cp $89
	jr z, .yes
	and a
	ret
.yes
	scf
	ret

JohtoRoute35RemoveCutTree::
	call JohtoRoute35CutTreeFacing
	ret nc
	call JohtoCutFacingBlockPointer
	ld a, [hl]
	cp $5b
	ret nz
	ld a, $89
	ld [hl], a
	ret

JohtoRoute35CutTreeFacing:
	ld a, [wCurMap]
	cp REGION_NATIVE_MAP_SLOT
	jp nz, .no
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	jp nz, .no
	ld a, [wCurLocalMapID]
	cp JOHTO_ROUTE_35_LOCAL_ID
	jp nz, .no
	ld a, [wXCoord]
	cp 17
	jr z, .sameX
	cp 16
	jr z, .left
	cp 18
	jr z, .right
	jr .no
.sameX
	ld a, [wYCoord]
	cp 5
	jr z, .fromAbove
	cp 7
	jr z, .fromBelow
	jr .no
.fromAbove
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_DOWN
	jr z, .yes
	jr .no
.fromBelow
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_UP
	jr z, .yes
	jr .no
.left
	ld a, [wYCoord]
	cp 6
	jr nz, .no
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_RIGHT
	jr z, .yes
	jr .no
.right
	ld a, [wYCoord]
	cp 6
	jr nz, .no
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_LEFT
	jr z, .yes
.no
	and a
	ret
.yes
	scf
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

; ILEX-5.62.216: Gold Goldenrod north edge preview from original
; Route35 bottom three block rows. Display ONLY: Route35 remains unopened.
PatchJohtoGoldenrodNorthBorder::
	ld a, [wCurMap]
	cp REGION_NATIVE_MAP_SLOT
	ret nz
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	ret nz
	ld a, [wCurLocalMapID]
	cp JOHTO_GOLDENROD_CITY_LOCAL_ID
	ret nz
	ld de, .row0
	ld hl, wOverworldMap + MAP_BORDER + 5
	call .copyRow
	ld de, .row1
	ld hl, wOverworldMap + (JOHTO_GOLDENROD_CITY_WIDTH + 2 * MAP_BORDER) + MAP_BORDER + 5
	call .copyRow
	ld de, .row2
	ld hl, wOverworldMap + 2 * (JOHTO_GOLDENROD_CITY_WIDTH + 2 * MAP_BORDER) + MAP_BORDER + 5
.copyRow
	ld b, 10
.loop
	ld a, [de]
	inc de
	ld [hli], a
	dec b
	jr nz, .loop
	ret
.row0
	db $05, $05, $58, $59, $01, $78, $44, $05, $05, $05
.row1
	db $41, $41, $41, $42, $0c, $0d, $40, $41, $41, $41
.row2
	db $01, $01, $01, $46, $08, $09, $44, $01, $01, $01

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
	; ILEX-5.62.212: shared mask lookup takes the loaded map's actual cell height.
	; Route33/Azalea are 18 cells; Ilex Forest is 54 cells.
	ld a, [wCurrentMapHeight2]
	cp b
	jr z, .blocked
	jr c, .blocked
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

; ILEX-5.62.216: only central four Gold FLOOR columns have a safe
; two-way Route34 <-> Goldenrod boundary. Every other outdoor edge is closed.
JohtoRoute34NorthEdgeFence::
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_UP
	jr nz, .otherEdges
	ld a, [wYCoord]
	and a
	jr nz, .clear
	ld a, [wXCoord]
	cp 8
	jr c, .blocked
	cp 12
	jr nc, .blocked
	jr .clear
.otherEdges
	cp PLAYER_DIR_DOWN
	jr z, .south
	cp PLAYER_DIR_LEFT
	jr z, .west
	cp PLAYER_DIR_RIGHT
	jr nz, .clear
	ld a, [wXCoord]
	cp JOHTO_ROUTE_34_WIDTH * 2 - 1
	jr nc, .blocked
	jr .clear
.south
	ld a, [wYCoord]
	cp JOHTO_ROUTE_34_HEIGHT * 2 - 1
	jr nc, .blocked
	jr .clear
.west
	ld a, [wXCoord]
	and a
	jr z, .blocked
.clear
	and a
	ret
.blocked
	scf
	ret

JohtoGoldenrodEdgeFence::
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_DOWN
	jr z, .south
	cp PLAYER_DIR_UP
	jr z, .north
	cp PLAYER_DIR_LEFT
	jr z, .west
	cp PLAYER_DIR_RIGHT
	jr nz, .clear
	ld a, [wXCoord]
	cp JOHTO_GOLDENROD_CITY_WIDTH * 2 - 1
	jr nc, .blocked
	jr .clear
.south
	ld a, [wYCoord]
	cp JOHTO_GOLDENROD_CITY_HEIGHT * 2 - 1
	jr c, .clear
	ld a, [wXCoord]
	cp 18
	jr c, .blocked
	cp 22
	jr nc, .blocked
	jr .clear
.north
	ld a, [wYCoord]
	and a
	jr z, .blocked
	jr .clear
.west
	ld a, [wXCoord]
	and a
	jr z, .blocked
.clear
	and a
	ret
.blocked
	scf
	ret

; ILEX-5.62.215: Route34 only uses the existing Gold 16x16 masked-step engine.
; Nonexistent Goldenrod and unfinished Azalea west-side connections stay closed.
JohtoRoute34CanStepAhead::
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	jp nz, .blocked
	ld a, [wCurLocalMapID]
	cp JOHTO_ROUTE_34_LOCAL_ID
	jp nz, .blocked
	; ILEX-5.62.216: central north seam uses the approved Gold floor
	; cells, despite the mask lookup seeing one step outside the map.
	ld a, [wYCoord]
	and a
	jr nz, .gate
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_UP
	jr nz, .gate
	ld a, [wXCoord]
	cp 8
	jr c, .gate
	cp 12
	jp c, .allowed
.gate
	; Gold (13,37)/(14,37) are WARP_CARPET_DOWN (blocked in mask).
	; Admit just the two approaches from the north, and lateral lane shift.
	ld a, [wYCoord]
	cp 36
	jp nz, .atCarpet
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_DOWN
	jp nz, .normal
	ld a, [wXCoord]
	cp 13
	jp z, .allowed
	cp 14
	jp z, .allowed
	jp .normal
.atCarpet
	cp 37
	jp nz, .normal
	ld a, [wXCoord]
	cp 13
	jp z, .leftLane
	cp 14
	jp nz, .normal
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_LEFT
	jp z, .allowed
	jp .normal
.leftLane
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_RIGHT
	jp z, .allowed
.normal
	ld hl, JohtoRoute34BlockedRows
	ld d, JOHTO_ROUTE_34_WIDTH * 2
	ld e, 3
	jp JohtoModernMaskedStep
.allowed
	and a
	ret
.blocked
	scf
	ret

; ILEX-5.62.216: exact Gold city blocked positions, 40x36 cells.
; Keep its 15 unimplemented door tiles solid; do not import their Warps.
JohtoGoldenrodCanStepAhead::
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	jr nz, .blocked
	ld a, [wCurLocalMapID]
	cp JOHTO_GOLDENROD_CITY_LOCAL_ID
	jr nz, .blocked
	ld a, [wYCoord]
	cp JOHTO_GOLDENROD_CITY_HEIGHT * 2 - 1
	jr nz, .normal
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_DOWN
	jr nz, .normal
	ld a, [wXCoord]
	cp 18
	jr c, .normal
	cp 22
	jr c, .allowed
.normal
	ld hl, JohtoGoldenrodBlockedRows
	ld d, JOHTO_GOLDENROD_CITY_WIDTH * 2
	ld e, 5
	jp JohtoModernMaskedStep
.allowed
	and a
	ret
.blocked
	scf
	ret

JohtoGoldenrodBlockedRows::
	INCBIN "maps/JohtoGoldenrodCity.blocked_mask.bin"

JohtoRoute34BlockedRows::
	INCBIN "maps/JohtoRoute34.blocked_mask.bin"

; ILEX-5.62.215: only the new NorthSouthGate uses this Gold 16x16 role mask.
; Existing JOHTO_GATE / Kanto Gate_Coll and two accepted gate rooms unchanged.
JohtoRoute34GateCanStepAhead::
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	jp nz, .blocked
	ld a, [wCurLocalMapID]
	cp JOHTO_ROUTE34_ILEX_GATE_LOCAL_ID
	jp nz, .blocked
	; Gold lower warp carpet permits entry from the left/right floor cells
	; as well as moving between the two carpet lanes. Upper DOOR is stricter.
	ld a, [wYCoord]
	cp 7
	jp z, .bottomCarpet
	ld a, [wXCoord]
	cp 4
	jp z, .lane
	cp 5
	jp nz, .normal
.lane
	ld a, [wYCoord]
	cp 1
	jp nz, .bottomApproach
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_UP
	jp z, .allowed
	jp .normal
.bottomApproach
	cp 6
	jp nz, .edgeLanes
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_DOWN
	jp z, .allowed
	jp .normal
.edgeLanes
	and a
	jp nz, .normal
	; Upper door: lane change only, no sideways entry through its walls.
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_LEFT
	jp nz, .topRight
	ld a, [wXCoord]
	cp 5
	jp z, .allowed
	jp .normal
.topRight
	cp PLAYER_DIR_RIGHT
	jp nz, .normal
	ld a, [wXCoord]
	cp 4
	jp z, .allowed
	jp .normal
.bottomCarpet
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_LEFT
	jp nz, .bottomRight
	ld a, [wXCoord]
	cp 5
	jp z, .allowed
	cp 6
	jp z, .allowed
	jp .normal
.bottomRight
	cp PLAYER_DIR_RIGHT
	jp nz, .normal
	ld a, [wXCoord]
	cp 3
	jp z, .allowed
	cp 4
	jp z, .allowed
.normal
	ld hl, JohtoRoute34GateBlockedRows
	ld d, 10
	ld e, 2
	jp JohtoModernMaskedStep
.allowed
	and a
	ret
.blocked
	scf
	ret

JohtoRoute34GateBlockedRows::
	INCBIN "maps/JohtoRoute34IlexForestGate.blocked_mask.bin"

; ILEX-5.62.215: Reuse existing RPP step-on Warp executor for Gold's vertical
; north gate. Called ONLY after CheckWarpsNoCollisionLoop has matched an actual
; Warp record and armed the standing bit. A sideways approach never triggers;
; historical east/west gates remain collision-only. Carry = valid approach.
JohtoNorthGateStepWarpAllowed::
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	jr nz, .deny
	ld a, [wCurLocalMapID]
	cp JOHTO_ILEX_FOREST_LOCAL_ID
	jr z, .forest
	cp JOHTO_ROUTE_34_LOCAL_ID
	jr z, .route34
	cp JOHTO_ROUTE34_ILEX_GATE_LOCAL_ID
	jr nz, .deny
	ld a, [wYCoord]
	and a
	jr z, .up
	cp 7
	jr z, .down
	jr .deny
.forest
	ld a, [wYCoord]
	cp 5
	jr z, .up
	jr .deny
.route34
	ld a, [wYCoord]
	cp 37
	jr z, .down
	jr .deny
.up
	ld a, PLAYER_DIR_UP
	jr .match
.down
	ld a, PLAYER_DIR_DOWN
.match
	ld b, a
	ld a, [wPlayerDirection]
	cp b
	jr nz, .deny
	scf
	ret
.deny
	and a
	ret

; ILEX-5.62.215: share one collision-only Warp rule across accepted old
; south gate and new north/south gate. Called only for registered Warp cells,
; with preserved region-local identity. carry = correct approach.
JohtoGateCollisionDirectionAllowed::
	ld a, [wCurLocalMapID]
	cp JOHTO_AZALEA_TOWN_LOCAL_ID
	jr z, .left
	cp JOHTO_ILEX_FOREST_LOCAL_ID
	jr z, .forest
	cp JOHTO_ROUTE_34_LOCAL_ID
	jr z, .down
	cp JOHTO_ROUTE34_ILEX_GATE_LOCAL_ID
	jr z, .northGate
	; Historical south gate west x0, east x9.
	ld a, [wXCoord]
	and a
	jr z, .left
	jr .right
.forest
	ld a, [wYCoord]
	cp 5
	jr z, .up
	jr .right
.northGate
	ld a, [wYCoord]
	and a
	jr z, .up
	jr .down
.left
	ld a, PLAYER_DIR_LEFT
	jr .compare
.right
	ld a, PLAYER_DIR_RIGHT
	jr .compare
.up
	ld a, PLAYER_DIR_UP
	jr .compare
.down
	ld a, PLAYER_DIR_DOWN
.compare
	ld b, a
	ld a, [wPlayerDirection]
	cp b
	jr nz, .denied
	scf
	ret
.denied
	and a
	ret

; Gold Forest x1/y5 is one north door, unlike the historical south double
; mouth x3/y42-43. Route34 bottom entrance x13/14/y37 is also interior.
JohtoInternalDoorFacingCheck::
	ld a, [wCurLocalMapID]
	cp JOHTO_ILEX_FOREST_LOCAL_ID
	jr z, .forest
	cp JOHTO_ROUTE_34_LOCAL_ID
	jr nz, .denied
	ld a, [wYCoord]
	cp 37
	jr nz, .denied
	ld a, [wXCoord]
	cp 13
	jr z, .routeDirection
	cp 14
	jr nz, .denied
.routeDirection
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_DOWN
	jr z, .allowed
	jr .denied
.forest
	ld a, [wXCoord]
	cp 1
	jr nz, .southForest
	ld a, [wYCoord]
	cp 5
	jr nz, .southForest
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_UP
	jr z, .allowed
	jr .denied
.southForest
	ld a, [wXCoord]
	cp 3
	jr nz, .denied
	ld a, [wYCoord]
	cp 42
	jr z, .southDirection
	cp 43
	jr nz, .denied
.southDirection
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_RIGHT
	jr nz, .denied
.allowed
	scf
	ret
.denied
	and a
	ret
