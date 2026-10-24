; INDOOR-5.62.240: normal Gold House1 collision furniture.
; This routine runs in a relocatable ROMX bank and is called only from
; PrintBookshelfText's pre-sign A-button path (hidden items still win).
; Output [$ffdb]: 0=not found, otherwise TextPredefs ID; A is not a result
; register because the cross-bank trampoline overwrites it on return.
; Do NOT add the two bookshelf BG events here: they already use the RPP
; sign path and the right one can be blocked by the original NPC.

JohtoIndoorFurniturePredef::
	xor a
	ld [$ffdb], a
	ld a, [wCurMap]
	cp REGION_NATIVE_MAP_SLOT
	ret nz
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	ret nz
	ld a, [wCurLocalMapID]
	cp JOHTO_OLIVINE_PUNISHMENT_SPEECH_HOUSE_LOCAL_ID
	jr z, .sharedHouse1
	cp JOHTO_OLIVINE_TIMS_HOUSE_LOCAL_ID
	jr z, .sharedHouse1
	cp JOHTO_OLIVINE_GOOD_ROD_HOUSE_LOCAL_ID
	ret nz
.sharedHouse1
	ld a, [wCurMapTileset]
	cp JOHTO_HOUSE
	ret nz

	; Player 16x16 Gold coordinates, plus one step in facing direction.
	ld a, [wXCoord]
	ld d, a ; front X
	ld a, [wYCoord]
	ld e, a ; front Y
	ld a, [wSpriteStateData1 + 9]
	cp SPRITE_FACING_UP
	jr z, .up
	cp SPRITE_FACING_DOWN
	jr z, .down
	cp SPRITE_FACING_LEFT
	jr z, .left
	cp SPRITE_FACING_RIGHT
	ret nz
	inc d
	jr .lookUp
.up
	dec e
	jr .lookUp
.down
	inc e
	jr .lookUp
.left
	dec d
.lookUp
	; Table: Gold 16x16 front Y/X followed by text predef ID.
	; House1.blk: map(3,0), window(5,0), TV(2,1), radio(7,1).
	ld hl, JohtoOlivineHouseFurnitureCells
.loop
	ld a, [hli]
	cp $ff
	ret z
	cp e
	jr nz, .skipX
	ld a, [hli]
	cp d
	jr nz, .skipID
	ld a, [hl]
	ld [$ffdb], a
	ret
.skipX
	inc hl
.skipID
	inc hl
	jr .loop

JohtoOlivineHouseFurnitureCells:
	db 0, 3
	db_tx_pre JohtoIndoorTownMapText
	db 0, 5
	db_tx_pre MyReflectionText
	db 1, 2
	db_tx_pre JohtoIndoorTVText
	db 1, 7
	db_tx_pre JohtoIndoorRadioText
	db $ff
