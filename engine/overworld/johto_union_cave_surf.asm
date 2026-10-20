; SRF-5.62.187: Union Cave 1F uses Gold's 16x16 WATER collision cells.
; RPP's 8x8 art IDs are shared by WATER and WALL, so global water tile
; allow-lists cannot safely represent this map. Carry = water immediately
; ahead; no carry = shore/wall/off-map. Only the current Johto Union Cave
; map may use this special case. BC/DE/HL are preserved.
IsJohtoUnionCaveWaterAhead::
	push bc
	push de
	push hl
	ld a, [wCurMap]
	cp REGION_NATIVE_MAP_SLOT
	jr nz, .notWater
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	jr nz, .notWater
	ld a, [wCurLocalMapID]
	cp JOHTO_UNION_CAVE_1F_LOCAL_ID
	jr nz, .notWater
	ld a, [wYCoord]
	ld d, a
	ld a, [wXCoord]
	ld e, a
	ld a, [wSpriteStateData1 + 9]
	cp SPRITE_FACING_DOWN
	jr nz, .up
	inc d
	jr .bounded
.up
	cp SPRITE_FACING_UP
	jr nz, .left
	dec d
	jr .bounded
.left
	cp SPRITE_FACING_LEFT
	jr nz, .right
	dec e
	jr .bounded
.right
	cp SPRITE_FACING_RIGHT
	jr nz, .notWater
	inc e
.bounded
	ld a, d
	cp JOHTO_UNION_CAVE_1F_HEIGHT * 2
	jr nc, .notWater
	ld a, e
	cp JOHTO_UNION_CAVE_1F_WIDTH * 2
	jr nc, .notWater
	ld hl, JohtoUnionCaveWaterCells
.loop
	ld a, [hli] ; Gold 16x16 y
	cp $FF
	jr z, .notWater
	cp d
	jr nz, .skipX
	ld a, [hli] ; Gold 16x16 x
	cp e
	jr z, .water
	jr .loop
.skipX
	inc hl
	jr .loop
.water
	scf
	jr .done
.notWater
	and a
.done
	pop hl
	pop de
	pop bc
	ret

; Generated only from Gold maps/UnionCave1F.blk and
; data/tilesets/cave_collision.asm, not RPP's ambiguous 8x8 tile IDs.
; Format: y, x. $FF terminates; never place one byte of a pair on a line.
JohtoUnionCaveWaterCells::
	db 4, 6
	db 4, 7
	db 4, 8
	db 4, 9
	db 4, 10
	db 4, 11
	db 4, 12
	db 4, 13
	db 5, 6
	db 5, 7
	db 5, 8
	db 5, 9
	db 5, 10
	db 5, 11
	db 5, 12
	db 5, 13
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
	db 28, 2
	db 28, 3
	db 28, 4
	db 28, 5
	db 28, 12
	db 28, 13
	db 28, 14
	db 28, 15
	db 29, 2
	db 29, 3
	db 29, 4
	db 29, 5
	db 29, 12
	db 29, 13
	db 29, 14
	db 29, 15
	db 30, 2
	db 30, 3
	db 30, 4
	db 30, 5
	db 30, 12
	db 30, 13
	db 30, 14
	db 30, 15
	db 31, 2
	db 31, 3
	db 31, 4
	db 31, 5
	db 31, 12
	db 31, 13
	db 31, 14
	db 31, 15
	db $FF


; SRF-5.62.187: Return carry for water directly in front on the
; independently reviewed Johto maps, including Route35 with its Gold-reviewed water mask. Other maps fail closed. BC/DE/HL
; follow the original cave helper register-preservation contract.
IsJohtoSurfWaterAhead::
	ld a, [wCurMapTileset]
	cp JOHTO_UNION_CAVE
	jp z, IsJohtoUnionCaveWaterAhead
	cp JOHTO
	jr nz, .noWater
	ld a, [wCurMap]
	cp JOHTO_ROUTE_32
	jp z, IsJohtoRoute32WaterAhead
	; R35-5.62.223: other JOHTO maps also share native handle $FC;
	; the Route35 helper independently checks the exact local ID.
	cp REGION_NATIVE_MAP_SLOT
	jp z, IsJohtoNativeOutdoorWaterAhead
.noWater
	and a
	ret

; SRF-5.62.187: Route32 is an outdoor 10x45 Gold block map, or 20x90
; collision cells. A shared 8x8 tile ID is not proof of WATER. Instead
; look up the actual 16x16 target cell using a 3-byte-per-row bitmask.
; Deliberately limited to real Route32 ($FB), not the entire JOHTO tileset.
; Carry set = water; carry clear = land, wall or outside the map.
IsJohtoRoute32WaterAhead::
	push bc
	push de
	push hl
	ld a, [wCurMap]
	cp JOHTO_ROUTE_32
	jp nz, .notWater
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	jp nz, .notWater
	ld a, [wYCoord]
	ld d, a
	ld a, [wXCoord]
	ld e, a
	ld a, [wSpriteStateData1 + 9]
	cp SPRITE_FACING_DOWN
	jr nz, .up
	inc d
	jr .bounded
.up
	cp SPRITE_FACING_UP
	jr nz, .left
	dec d
	jr .bounded
.left
	cp SPRITE_FACING_LEFT
	jr nz, .right
	dec e
	jr .bounded
.right
	cp SPRITE_FACING_RIGHT
	jp nz, .notWater
	inc e
.bounded
	ld a, d
	cp JOHTO_ROUTE_32_HEIGHT * 2
	jp nc, .notWater
	ld a, e
	cp JOHTO_ROUTE_32_WIDTH * 2
	jp nc, .notWater
	; 3 bytes per row. Use 16-bit arithmetic: row 85 starts at 255.
	ld l, d
	ld h, 0
	add hl, hl
	ld c, d
	ld b, 0
	add hl, bc
	ld bc, JohtoRoute32WaterRows
	add hl, bc
	ld a, e
	cp 8
	jr c, .byteChosen
	sub 8
	inc hl
	cp 8
	jr c, .byteChosen
	sub 8
	inc hl
.byteChosen
	; Shift (x % 8) + 1 times. Last carry is exactly target bit.
	ld c, a
	inc c
	ld a, [hl]
.shift
	srl a
	dec c
	jr nz, .shift
	jr nc, .notWater
	scf
	jr .done
.notWater
	and a
.done
	pop hl
	pop de
	pop bc
	ret

; Gold maps/Route32.blk + data/tilesets/johto_collision.asm.
; Each row is a low-bit-first 20-cell mask, three bytes per Y.
; 90 rows, 270 bytes, 278 WATER cells. Unused upper 4 bits are zero.
JohtoRoute32WaterRows::
	db $00, $00, $00 ; y=00
	db $00, $00, $00 ; y=01
	db $00, $00, $00 ; y=02
	db $00, $00, $00 ; y=03
	db $00, $00, $00 ; y=04
	db $00, $00, $00 ; y=05
	db $00, $00, $00 ; y=06
	db $00, $00, $00 ; y=07
	db $03, $00, $00 ; y=08
	db $03, $00, $00 ; y=09
	db $03, $00, $00 ; y=10
	db $03, $00, $00 ; y=11
	db $00, $00, $00 ; y=12
	db $00, $00, $00 ; y=13
	db $00, $00, $00 ; y=14
	db $00, $00, $00 ; y=15
	db $00, $00, $00 ; y=16
	db $00, $00, $00 ; y=17
	db $00, $00, $00 ; y=18
	db $00, $00, $00 ; y=19
	db $00, $00, $00 ; y=20
	db $00, $00, $00 ; y=21
	db $00, $00, $00 ; y=22
	db $00, $00, $00 ; y=23
	db $00, $00, $00 ; y=24
	db $00, $00, $00 ; y=25
	db $00, $00, $00 ; y=26
	db $00, $00, $00 ; y=27
	db $00, $00, $00 ; y=28
	db $00, $00, $00 ; y=29
	db $00, $00, $00 ; y=30
	db $00, $00, $00 ; y=31
	db $00, $00, $00 ; y=32
	db $00, $00, $00 ; y=33
	db $00, $00, $00 ; y=34
	db $00, $00, $00 ; y=35
	db $00, $00, $00 ; y=36
	db $00, $00, $00 ; y=37
	db $00, $00, $00 ; y=38
	db $00, $00, $00 ; y=39
	db $00, $30, $0F ; y=40
	db $00, $30, $0F ; y=41
	db $F0, $73, $03 ; y=42
	db $F0, $73, $03 ; y=43
	db $F0, $73, $0F ; y=44
	db $F0, $73, $0F ; y=45
	db $F0, $73, $0F ; y=46
	db $F0, $73, $0F ; y=47
	db $30, $70, $0F ; y=48
	db $30, $70, $0F ; y=49
	db $F0, $73, $0F ; y=50
	db $F0, $73, $0F ; y=51
	db $00, $43, $0F ; y=52
	db $00, $43, $0F ; y=53
	db $00, $4F, $0F ; y=54
	db $00, $4F, $0F ; y=55
	db $00, $4F, $0F ; y=56
	db $00, $4F, $0F ; y=57
	db $00, $4F, $0F ; y=58
	db $00, $4F, $0F ; y=59
	db $00, $00, $0F ; y=60
	db $00, $00, $0F ; y=61
	db $00, $00, $0F ; y=62
	db $00, $00, $0F ; y=63
	db $00, $00, $0F ; y=64
	db $00, $00, $0F ; y=65
	db $00, $00, $0F ; y=66
	db $00, $00, $0F ; y=67
	db $00, $00, $0F ; y=68
	db $00, $00, $0F ; y=69
	db $00, $00, $0F ; y=70
	db $00, $00, $0F ; y=71
	db $00, $00, $0F ; y=72
	db $00, $00, $0F ; y=73
	db $00, $00, $0F ; y=74
	db $00, $00, $0F ; y=75
	db $00, $00, $0C ; y=76
	db $00, $00, $0C ; y=77
	db $00, $00, $0C ; y=78
	db $00, $00, $0C ; y=79
	db $00, $00, $00 ; y=80
	db $00, $00, $00 ; y=81
	db $00, $00, $00 ; y=82
	db $00, $00, $00 ; y=83
	db $00, $00, $00 ; y=84
	db $00, $00, $00 ; y=85
	db $00, $00, $00 ; y=86
	db $00, $00, $00 ; y=87
	db $00, $00, $00 ; y=88
	db $00, $00, $00 ; y=89

; Dispatch shared native $FC by local map ID; never allow ruins water on other maps.
IsJohtoNativeOutdoorWaterAhead::
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	jr nz, .noWater
	ld a, [wCurLocalMapID]
	cp JOHTO_ROUTE_35_LOCAL_ID
	jp z, IsJohtoRoute35WaterAhead
	cp JOHTO_RUINS_OF_ALPH_LOCAL_ID
	jp z, IsJohtoRuinsWaterAhead
	cp JOHTO_ECRUTEAK_CITY_LOCAL_ID
	jp z, IsJohtoEcruteakWaterAhead
.noWater
	and a
	ret

; Gold EcruteakCity pond: exactly 20 WATER quadrants, no generic
; JOHTO tile IDs. Rows y12/13 have x22..27, rows y14/15 x24..27.
; Land, walls and the 50 HEADBUTT_TREE quadrants are not Surf water.
IsJohtoEcruteakWaterAhead::
	push bc
	push de
	push hl
	ld a, [wCurMap]
	cp REGION_NATIVE_MAP_SLOT
	jr nz, .notWater
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	jr nz, .notWater
	ld a, [wCurLocalMapID]
	cp JOHTO_ECRUTEAK_CITY_LOCAL_ID
	jr nz, .notWater
	ld a, [wYCoord]
	ld d, a
	ld a, [wXCoord]
	ld e, a
	ld a, [wSpriteStateData1 + 9]
	cp SPRITE_FACING_DOWN
	jr nz, .up
	inc d
	jr .check
.up
	cp SPRITE_FACING_UP
	jr nz, .left
	dec d
	jr .check
.left
	cp SPRITE_FACING_LEFT
	jr nz, .right
	dec e
	jr .check
.right
	cp SPRITE_FACING_RIGHT
	jr nz, .notWater
	inc e
.check
	ld a, d
	cp 12
	jr c, .notWater
	cp 16
	jr nc, .notWater
	cp 14
	jr nc, .lower
	ld a, e
	cp 22
	jr c, .notWater
	cp 28
	jr nc, .notWater
	jr .water
.lower
	ld a, e
	cp 24
	jr c, .notWater
	cp 28
	jr nc, .notWater
.water
	scf
	jr .done
.notWater
	and a
.done
	pop hl
	pop de
	pop bc
	ret

; Ecruteak HEADBUTT_TREE 50 cells from Gold native JOHTO collision roles.
; Reuse the exact facing-grid ABI as Surf; the raw JOHTO 8x8 image ID is
; shared with walls and MUST NOT be a generic Headbutt whitelist.
; Called from both A-button interaction and the existing party-menu routine.
IsJohtoEcruteakHeadbuttTreeAhead::
	push bc
	push de
	push hl
	ld a, [wCurMap]
	cp REGION_NATIVE_MAP_SLOT
	jr nz, .notTree
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	jr nz, .notTree
	ld a, [wCurLocalMapID]
	cp JOHTO_ECRUTEAK_CITY_LOCAL_ID
	jr nz, .notTree
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
	jr nz, .notTree
	inc e
.lookup
	ld hl, JohtoEcruteakHeadbuttCells
.loop
	ld a, [hli]
	cp $ff
	jr z, .notTree
	cp d
	jr nz, .skipX
	ld a, [hli]
	cp e
	jr z, .tree
	jr .loop
.skipX
	inc hl
	jr .loop
.tree
	scf
	jr .done
.notTree
	and a
.done
	pop hl
	pop de
	pop bc
	ret

JohtoEcruteakHeadbuttCells::
	db 0, 4
	db 0, 5
	db 0, 6
	db 0, 7
	db 0, 16
	db 0, 17
	db 0, 18
	db 0, 19
	db 8, 12
	db 8, 13
	db 8, 14
	db 8, 15
	db 8, 16
	db 8, 17
	db 8, 18
	db 8, 19
	db 8, 20
	db 8, 21
	db 14, 4
	db 14, 5
	db 14, 6
	db 14, 7
	db 14, 12
	db 14, 13
	db 14, 14
	db 14, 15
	db 18, 22
	db 18, 23
	db 18, 24
	db 18, 25
	db 24, 12
	db 24, 13
	db 24, 14
	db 24, 15
	db 24, 28
	db 24, 29
	db 24, 30
	db 24, 31
	db 30, 16
	db 30, 19
	db 31, 16
	db 31, 19
	db 32, 16
	db 32, 19
	db 33, 16
	db 33, 19
	db 34, 16
	db 34, 19
	db 35, 16
	db 35, 19
	db $ff

; Ruins water: Gold x2..5,y6..13 plus x12..15,y26..29, 48 cells.
IsJohtoRuinsWaterAhead::
	push bc
	push de
	push hl
	ld a, [wYCoord]
	ld d, a
	ld a, [wXCoord]
	ld e, a
	ld a, [wSpriteStateData1 + 9]
	cp SPRITE_FACING_DOWN
	jr nz, .up
	inc d
	jr .check
.up
	cp SPRITE_FACING_UP
	jr nz, .left
	dec d
	jr .check
.left
	cp SPRITE_FACING_LEFT
	jr nz, .right
	dec e
	jr .check
.right
	cp SPRITE_FACING_RIGHT
	jr nz, .notWater
	inc e
.check
	ld a, d
	cp 6
	jr c, .notWater
	cp 14
	jr nc, .lower
	ld a, e
	cp 2
	jr c, .notWater
	cp 6
	jr nc, .notWater
	jr .water
.lower
	ld a, d
	cp 26
	jr c, .notWater
	cp 30
	jr nc, .notWater
	ld a, e
	cp 12
	jr c, .notWater
	cp 16
	jr nc, .notWater
.water
	scf
	jr .done
.notWater
	and a
.done
	pop hl
	pop de
	pop bc
	ret

; R35-5.62.223: Gold Route35 10x18 has exactly 32 WATER quadrants:
; rectangle x=4..7, y=24..31. Check region/local ID and facing coords;
; never widen JOHTO's shared 8x8 tile water whitelist.
IsJohtoRoute35WaterAhead::
	push bc
	push de
	push hl
	ld a, [wCurMap]
	cp REGION_NATIVE_MAP_SLOT
	jr nz, .notWater
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	jr nz, .notWater
	ld a, [wCurLocalMapID]
	cp JOHTO_ROUTE_35_LOCAL_ID
	jr nz, .notWater
	ld a, [wYCoord]
	ld d, a
	ld a, [wXCoord]
	ld e, a
	ld a, [wSpriteStateData1 + 9]
	cp SPRITE_FACING_DOWN
	jr nz, .up
	inc d
	jr .check
.up
	cp SPRITE_FACING_UP
	jr nz, .left
	dec d
	jr .check
.left
	cp SPRITE_FACING_LEFT
	jr nz, .right
	dec e
	jr .check
.right
	cp SPRITE_FACING_RIGHT
	jr nz, .notWater
	inc e
.check
	ld a, d
	cp 24
	jr c, .notWater
	cp 32
	jr nc, .notWater
	ld a, e
	cp 4
	jr c, .notWater
	cp 8
	jr nc, .notWater
	scf
	jr .done
.notWater
	and a
.done
	pop hl
	pop de
	pop bc
	ret

; R35-5.62.223: Until dual-region story badge policy exists, Surf on
; Route32, Route35 and Union Cave 1F needs no badge. Other maps retain the Kanto
; Soul Badge check. The field and party-menu paths share this policy.
; Carry = permission granted.
JohtoSurfBadgeAllowed::
	ld a, [wCurMapTileset]
	cp JOHTO_UNION_CAVE
	jr z, .johtoAllowed
	cp JOHTO
	jr nz, .kanto
	ld a, [wCurMap]
	cp JOHTO_ROUTE_32
	jr z, .route32
	cp REGION_NATIVE_MAP_SLOT
	jr nz, .kanto
	ld a, [wCurLocalMapID]
	cp JOHTO_ROUTE_35_LOCAL_ID
	jr z, .route32
	cp JOHTO_RUINS_OF_ALPH_LOCAL_ID
	jr z, .route32
	cp JOHTO_ECRUTEAK_CITY_LOCAL_ID
	jr nz, .kanto
.route32
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	jr nz, .kanto
.johtoAllowed
	scf
	ret
.kanto
	ld a, [wObtainedKantoBadges]
	bit 4, a ; SOUL_BADGE
	jr z, .denied
	scf
	ret
.denied
	and a
	ret

; R35-5.62.223: On the approved Johto maps, Surfboard/party
; water eligibility uses Gold collision geometry with no Johto badge.
; Carry CLEAR = water ahead; carry SET = reject. Other maps retain
; the existing RPP Surfboard / item rules.
JohtoSurfStartOnWater::
	call IsJohtoSurfWaterAhead
	ccf ; invert water-ahead carry for Surfboard convention
	ret
