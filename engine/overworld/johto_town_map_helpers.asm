; SPID ROM0 recovery: shared Town Map helpers and their 23-byte index table
; live together in fixed Johto ROMX Bank $40, NOT in ROM0 or full Bank $1C.
; Bank $1C calls the far entry via its old local get-index label, while
; ROM0 and Bank $1C both far-call the blinking animation. The far entry
; returns the index in E: Bankswitch destroys A/BC/HL on return.
; The path below is deliberately relocated from home/johto_town_map_rom0.asm.

; Active-slot -> Town Map landmark; physical stable IDs are NOT row indices.
JohtoNativeTownMapIndices::
	db 0, 1, 2, 3, 4, 5, 5, 7, 9, 10, 11, 14, 13, 14, 14, 15, 19, 17, 17, 19, 8, 20, 21, 24, 24, 32, 32, 34, 25, 26, 28, 30, 31 ; completed Route40/41/Cianwood chain
	db 35, 36, 35, 35 ; north gate, Lake, Route43, middle gate
 db 18, 17, 19 ; Gold National Park, Route35, Route36 landmarks
 db 7 ; Gold Route32 45-landmark browse slot, neutral gate
 db 37, 39, 41, 43, 1 ; Route44, BlackthornCity, Route45, Route46, Route29/46 Gate neutral Route29
 db 26 ; Olivine house inherits Olivine City landmark
 db 26 ; OlivineTimsHouse inherits Olivine City landmark
 db 26 ; OlivineGoodRodHouse inherits Olivine City landmark
JohtoNativeTownMapIndicesEnd::
ASSERT JohtoNativeTownMapIndicesEnd - JohtoNativeTownMapIndices == NUM_JOHTO_MAPS

; Cross-bank ABI: E carries return value to Bank $1C's near-call wrapper.
GetJohtoTownMapCurrentIndexFar::
	call GetJohtoTownMapCurrentIndexCore
	ld e, a
	ret

GetJohtoTownMapCurrentIndexCore:
	ld a, [wCurMap]
	cp REGION_NATIVE_MAP_SLOT
	jr nz, .legacyID
	ld a, [wCurLocalMapID]
	push de
	ld e, a
	call GetJohtoActiveSlot
	ld a, e
	pop de
	cp JOHTO_INVALID_ACTIVE_SLOT
	jr z, .inactiveNative
	ld c, a
	ld b, 0
	ld hl, JohtoNativeTownMapIndices
	add hl, bc
	ld a, [hl]
	ret
.inactiveNative
	xor a ; bounded Town Map marker only; physical ID unchanged
	ret
.legacyID
	cp JOHTO_ROUTE_29
	jr z, .route29
	cp JOHTO_CHERRYGROVE_CITY
	jr z, .cherrygrove
	cp JOHTO_ROUTE_30
	jr z, .route30
	cp JOHTO_ROUTE_31
	jr z, .route31
	cp JOHTO_ROUTE_32
	jr z, .route32
	cp JOHTO_VIOLET_CITY
	jr nc, .violet ; indoor gate shares city's map marker
	xor a ; current supported Johto fallback: New Bark Town
	ret
.route29
	ld a, 1
	ret
.cherrygrove
	ld a, 2
	ret
.route30
	ld a, 3
	ret
.route31
	ld a, 4
	ret
.route32:
	ld a, 7
	ret
.violet
	ld a, 5
	ret


TownMapSpriteBlinkingAnimation:
	ld a, [wAnimCounter]
	inc a
	cp 25
	jr z, .hideSprites
	cp 50
	jr nz, .done
; show sprites when the counter reaches 50
	ld hl, wTileMapBackup
	ld de, wOAMBuffer
	ld bc, $90
	call CopyData
	xor a
	jr .done
.hideSprites
	ld hl, wOAMBuffer
	ld b, $24
	ld de, $4
.hideSpritesLoop
	ld [hl], $a0
	add hl, de
	dec b
	jr nz, .hideSpritesLoop
	ld a, 25
.done
	ld [wAnimCounter], a
	jp DelayFrame
