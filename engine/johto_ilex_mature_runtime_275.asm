; FIX-275: NPC-243 ILEX-217 mature land/Cut implementation.
; Local map IDs/handle are the same. Data remains in its own ROMX bank.
; ILEX-5.62.212: Forest 16x16 collision delegates to the existing
; JohtoModernMaskedStep (same routine used by Route33/Azalea).
; Gold HOP front WALL cells remain blocked for ordinary walking; the
; common HandleLedges path sets wd736.6 before checking tile passability.
; ILEX-5.62.217: shared ledge dispatch restored; user phone-tested all
; Forest HOP routes. The old ILEX-LEDGE-001 failure stays in historical docs.
JohtoIlexForestCanStepAhead::
	ld a, [wCurMap]
	cp JOHTO_RUNTIME_MAP_HANDLE
	jp nz, .blocked
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	jp nz, .blocked
	ld a, [wCurLocalMapID]
	cp JOHTO_ILEX_FOREST_LOCAL_ID
	jp nz, .blocked
	; On the south double carpet one may switch lanes, without Warp.
	ld a, [wXCoord]
	cp 3
	jr nz, .approach
	ld a, [wYCoord]
	cp 42
	jr z, .upperCarpet
	cp 43
	jr nz, .approach
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_UP
	jr z, .allowed
	jr .approach
.upperCarpet
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_DOWN
	jr z, .allowed
.approach
	; Gold WARP_CARPET_RIGHT is conservatively blocked in the mask.
	; Permit the two west approaches and the exact north FLOOR approach.
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_RIGHT
	jr nz, .fromNorth
	ld a, [wXCoord]
	cp 2
	jr nz, .northDoorCheck
	ld a, [wYCoord]
	cp 42
	jr z, .allowed
	cp 43
	jr z, .allowed
	jr .northDoorCheck
.fromNorth
	; The ordinary floor at (3,41) must enter the upper carpet by DOWN.
	; Do not open other north approaches or the wall below (3,43).
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_DOWN
	jr nz, .northDoorCheck
	ld a, [wXCoord]
	cp 3
	jr nz, .northDoorCheck
	ld a, [wYCoord]
	cp 41
	jr z, .allowed
.northDoorCheck
	; The single Gold north door is a blocked DOOR cell in the source mask.
	; Only allow UP from the immediately southern floor onto (1,5), so a
	; second UP collision activates the already existing Warp executor.
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_UP
	jr nz, .northDoorDown
	ld a, [wXCoord]
	cp 1
	jr nz, .maskCheck
	ld a, [wYCoord]
	cp 6
	jr z, .allowed
	jr .maskCheck
.northDoorDown
	; Allow the player to leave the one-cell carpet without auto-Warp.
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_DOWN
	jr nz, .maskCheck
	ld a, [wXCoord]
	cp 1
	jr nz, .maskCheck
	ld a, [wYCoord]
	cp 5
	jr z, .allowed
.maskCheck
	; Gold CUT_TREE (8,25) stays blocked until its live block is cut.
	; Only that one quadrant is opened; the adjacent HEADBUTT_TREE
	; at (9,25) continues to use the unchanged Gold position mask.
	call JohtoIlexForestCutTreeCleared
	jr c, .allowed
	ld hl, JohtoIlexForestBlockedRows
	ld d, JOHTO_SOUTH_ILEXFOREST_WIDTH * 2
	ld e, 4
	jp JohtoModernMaskedStep
.allowed
	and a
	ret
.blocked
	scf
	ret

JohtoIlexForestBlockedRows::
	INCBIN "maps/johto_pilot/IlexForest.mature_blocked_mask.bin"

; ILEX-5.62.212: Ilex Forest has exactly one Gold CUT_TREE quadrant:
; (x=8, y=25), the bottom-left quadrant of metatile $0f at (4,12).
; A full $0f->generic floor replacement would destroy the neighboring
; HEADBUTT_TREE at (9,25).  Block $2d is a clone of $0f with ONLY
; bottom-left 8x8 tiles changed to Gold's plain FLOOR tile $05.
; The cut persists while the map view is live, as in RPP's existing CUT;
; reloading the map restores the source $0f and its normal collision.
;
; No permanent event flag or WRAM layout changes are required.

JohtoIlexForestCutTreeInFront::
	call JohtoIlexForestCutTreeFacingTarget
	ret nc
	call JohtoIlexForestGetFacingBlockPointer
	ld a, [hl]
	cp $0f
	jr z, .yes
	and a
	ret
.yes
	scf
	ret

JohtoIlexForestCutTreeCleared::
	call JohtoIlexForestCutTreeFacingTarget
	ret nc
	call JohtoIlexForestGetFacingBlockPointer
	ld a, [hl]
	cp $2d
	jr z, .yes
	and a
	ret
.yes
	scf
	ret

JohtoIlexForestRemoveCutTree::
	call JohtoIlexForestCutTreeFacingTarget
	ret nc
	call JohtoIlexForestGetFacingBlockPointer
	ld a, [hl]
	cp $0f
	ret nz
	ld a, $2d
	ld [hl], a
	ret

JohtoIlexForestCutTreeFacingTarget:
	ld a, [wXCoord]
	cp 8
	jr z, .sameX
	cp 7
	jr z, .left
	cp 9
	jr z, .right
	jr .no
.sameX
	ld a, [wYCoord]
	cp 24
	jr z, .fromAbove
	cp 26
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
	cp 25
	jr nz, .no
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_RIGHT
	jr z, .yes
	jr .no
.right
	ld a, [wYCoord]
	cp 25
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

; Same live view pointer computation as the established RPP
; ReplaceTreeTileBlock in engine/overworld/cut.asm (bank $03).
; Duplicate this tiny pointer calculation in Forest's bank $43,
; not the bank-$03 code, because the older bank is effectively full.
JohtoCutFacingBlockPointer::
JohtoIlexForestGetFacingBlockPointer:
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
	and a
	jr z, .down
	cp SPRITE_FACING_UP
	jr z, .up
	cp SPRITE_FACING_LEFT
	jr z, .left
	ld a, [wXBlockCoord]
	and a
	jr z, .centerTileBlock
	jr .rightOfCenter
.down
	ld a, [wYBlockCoord]
	and a
	jr z, .centerTileBlock
	jr .belowCenter
.up
	ld a, [wYBlockCoord]
	and a
	jr z, .aboveCenter
	jr .centerTileBlock
.left
	ld a, [wXBlockCoord]
	and a
	jr z, .leftOfCenter
	jr .centerTileBlock
.belowCenter
	add hl, bc
.centerTileBlock
	add hl, bc
.aboveCenter
	ld de, 2
	add hl, de
	ret
.leftOfCenter
	ld de, 1
	add hl, bc
	add hl, de
	ret
.rightOfCenter
	ld de, 3
	add hl, bc
	add hl, de
	ret

; R35-5.62.223: forest and Route35 share the map-scoped Cut policy;
; retain legacy Kanto Cascade Badge elsewhere. A-button and party-menu Cut MUST share this routine.
; Carry SET = permitted; carry CLEAR = denied.
; Cut move availability is checked by each caller separately.

; Exact proven shared packed-mask walker from NPC-243.
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



; FIX-275: NPC-243 GATE-202 outdoor west facade continuation.
PatchJohtoAzaleaWestGateBorder::
	ld a, [wCurMap]
	cp JOHTO_RUNTIME_MAP_HANDLE
	ret nz
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	ret nz
	ld a, [wCurLocalMapID]
	cp JOHTO_AZALEA_TOWN_LOCAL_ID
	ret nz
	ld hl, wOverworldMap + (MAP_BORDER + 4) * (JOHTO_SOUTH_AZALEATOWN_WIDTH + 2 * MAP_BORDER) + MAP_BORDER - 1
	ld [hl], $08 ; Gold LEFT roof half, paired with (0,4) $09
	ld hl, wOverworldMap + (MAP_BORDER + 5) * (JOHTO_SOUTH_AZALEATOWN_WIDTH + 2 * MAP_BORDER) + MAP_BORDER - 1
	ld [hl], $1c ; Gold LEFT facade half, paired with (0,5) $1e
	ret

; FIX-279: keep the original GATE-202 Azalea fix, and restore the mature
; ILEX-216 Goldenrod north buffer. Called after both map load paths via the
; existing single ROM0 far-call (no new ROM0 allocation).
PatchJohtoSouthBordersAfterBlockLoad::
    call PatchJohtoAzaleaWestGateBorder
    call PatchJohtoGoldenrodNorthBorder
    jp PatchJohtoRoute35SouthBorder

; Render only: the three rows NORTH of Goldenrod are the last three Gold
; Route35 rows. No direct, walkable connection is activated.
; Reference: NPC-5.62.243/engine/overworld/johto_route33_collision.asm,
; PatchJohtoGoldenrodNorthBorder; positions and bytes unchanged.
PatchJohtoGoldenrodNorthBorder::
    ld a, [wCurMap]
    cp JOHTO_RUNTIME_MAP_HANDLE
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
    ld hl, wOverworldMap + (JOHTO_SOUTH_GOLDENRODCITY_WIDTH + 2 * MAP_BORDER) + MAP_BORDER + 5
    call .copyRow
    ld de, .row2
    ld hl, wOverworldMap + 2 * (JOHTO_SOUTH_GOLDENRODCITY_WIDTH + 2 * MAP_BORDER) + MAP_BORDER + 5
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


; FIX-284: NPC-243/GATE-224 accepted Route35 SOUTH out-of-map preview.
; Gold's Route35 south neighbor is GoldenrodCity at offset -5, even
; though the playable transfer remains the registered two-carpet Warp.
; Do not insert raw JOHTO_MODERN block IDs into JOHTO_ROUTE35's JOHTO
; tileset: $06 and $67 have no identical block crosswalk. This row map
; is the mature, source-checked JOHTO-safe representation.
; Loaded AFTER the full/connected-map block buffer, in ROMX Bank $4E.
PatchJohtoRoute35SouthBorder::
    ld a, [wCurMap]
    cp JOHTO_RUNTIME_MAP_HANDLE
    ret nz
    ld a, [wCurRegion]
    cp MAP_REGION_JOHTO
    ret nz
    ld a, [wCurLocalMapID]
    cp JOHTO_ROUTE_35_LOCAL_ID
    ret nz
    ld de, .row0
    ld hl, wOverworldMap + (MAP_BORDER + JOHTO_ROUTE35_HEIGHT) * (JOHTO_ROUTE35_WIDTH + 2 * MAP_BORDER) + MAP_BORDER
    call .copyRow
    ld de, .row1
    ld hl, wOverworldMap + (MAP_BORDER + JOHTO_ROUTE35_HEIGHT + 1) * (JOHTO_ROUTE35_WIDTH + 2 * MAP_BORDER) + MAP_BORDER
    call .copyRow
    ld de, .row2
    ld hl, wOverworldMap + (MAP_BORDER + JOHTO_ROUTE35_HEIGHT + 2) * (JOHTO_ROUTE35_WIDTH + 2 * MAP_BORDER) + MAP_BORDER
.copyRow
    ld b, JOHTO_ROUTE35_WIDTH
.loop
    ld a, [de]
    inc de
    ld [hli], a
    dec b
    jr nz, .loop
    ret
.row0
    db $12, $15, $01, $46, $16, $1e, $44, $01, $01, $12
.row1
    db $01, $12, $15, $46, $01, $01, $44, $01, $01, $04
.row2
    db $15, $12, $18, $19, $01, $01, $18, $1f, $19, $02
