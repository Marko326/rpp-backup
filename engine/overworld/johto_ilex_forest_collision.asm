; ILEX-5.62.212: Forest 16x16 collision delegates to the existing
; JohtoModernMaskedStep (same routine used by Route33/Azalea).
; ILEX-5.62.212: Gold HOP front WALL cells remain blocked by this mask.
; Forest jump dispatch is explicitly disabled (ILEX-LEDGE-001).
JohtoIlexForestCanStepAhead::
	ld a, [wCurMap]
	cp REGION_NATIVE_MAP_SLOT
	jr nz, .blocked
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	jr nz, .blocked
	ld a, [wCurLocalMapID]
	cp JOHTO_ILEX_FOREST_LOCAL_ID
	jr nz, .blocked
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
	jr nz, .normal
	ld a, [wYCoord]
	cp 42
	jr z, .allowed
	cp 43
	jr z, .allowed
	jr .normal
.fromNorth
	; The ordinary floor at (3,41) must enter the upper carpet by DOWN.
	; Do not open other north approaches or the wall below (3,43).
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_DOWN
	jr nz, .normal
	ld a, [wXCoord]
	cp 3
	jr nz, .normal
	ld a, [wYCoord]
	cp 41
	jr z, .allowed
.normal
	; Gold CUT_TREE (8,25) stays blocked until its live block is cut.
	; Only that one quadrant is opened; the adjacent HEADBUTT_TREE
	; at (9,25) continues to use the unchanged Gold position mask.
	call JohtoIlexForestCutTreeCleared
	jr c, .allowed
	ld hl, JohtoIlexForestBlockedRows
	ld d, JOHTO_ILEX_FOREST_WIDTH * 2
	ld e, 4
	jp JohtoModernMaskedStep
.allowed
	and a
	ret
.blocked
	scf
	ret

JohtoIlexForestBlockedRows::
	INCBIN "maps/JohtoIlexForest.blocked_mask.bin"

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

; ILEX-5.62.212: mirror SRF-5.62.187's temporary, map-scoped badge-free
; permission policy. A-button and party-menu Cut MUST share this routine.
; Carry SET = permitted; carry CLEAR = denied.
; Cut move availability is checked by each caller separately.
JohtoCutBadgeAllowed::
	ld a, [wCurMapTileset]
	cp JOHTO_ILEX_FOREST
	jr nz, .kanto
	ld a, [wCurMap]
	cp REGION_NATIVE_MAP_SLOT
	jr nz, .kanto
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	jr nz, .kanto
	ld a, [wCurLocalMapID]
	cp JOHTO_ILEX_FOREST_LOCAL_ID
	jr nz, .kanto
	; Forest has no live badge-award story during map expansion.
	scf
	ret
.kanto
	ld a, [wObtainedKantoBadges]
	bit 1, a ; CASCADE_BADGE, preserve the existing Kanto rule
	jr z, .denied
	scf
	ret
.denied
	and a
	ret
