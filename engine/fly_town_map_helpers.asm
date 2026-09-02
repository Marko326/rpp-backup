; Fly-only helpers kept in expansion bank $35 so the capacity-constrained
; overworld/Town Map/special-warp banks do not need to grow.

GetFlyTownMapPlayerMap::
; Some special Fly selectors land on a nearby outdoor map instead of loading the
; landmark map itself. For Town Map display, treat configured landmark anchors
; and the tile immediately below each anchor as the landmark selector.
;
; The table contains both Fly landing anchors (including the legacy Mt. Moon and
; Rock Tunnel Pokemon Center landing points) and real landmark entrances. This
; keeps Fly -> Town Map naming consistent without losing the other entrances.
;
; out: D = map ID whose Town Map coordinates/name should be used for the player.
	ld a, [wCurMap]
	ld d, a
	ld hl, FlyTownMapPlayerOverrides
.loop
	ld a, [hli]
	cp $ff
	ret z
	cp d
	jr nz, .skipMapEntry
	ld a, [hli]
	ld e, a ; anchor y
	ld a, [wYCoord]
	cp e
	jr z, .checkX
	inc e ; also accept the tile immediately below the anchor
	cp e
	jr nz, .skipXAndSelector
.checkX
	ld a, [hli]
	ld e, a
	ld a, [wXCoord]
	cp e
	jr nz, .skipSelector
	ld d, [hl]
	ret
.skipMapEntry
	inc hl ; anchor y
	inc hl ; x
	inc hl ; selector map
	jr .loop
.skipXAndSelector
	inc hl ; x
	inc hl ; selector map
	jr .loop
.skipSelector
	inc hl ; selector map
	jr .loop

FlyTownMapPlayerOverrides:
	; actual map, anchor y, anchor x, Town Map selector
	; The immediately lower tile is also treated as the same landmark.
	;
	; Fly landing anchors. Mt. Moon and Rock Tunnel intentionally retain their
	; legacy Pokemon Center landing points so opening Town Map after Fly keeps the
	; selected landmark name/position.
	db ROUTE_4,        5, 11, MT_MOON_3
	db ROUTE_10,      19, 11, ROCK_TUNNEL_1
	db ROUTE_10,      39,  6, POWER_PLANT
	db ROUTE_20,       9, 58, SEAFOAM_ISLANDS_1
	db CERULEAN_CITY, 11,  4, UNKNOWN_DUNGEON_1
	db ROUTE_25,       3, 45, BILLS_HOUSE
	db FUCHSIA_CITY,   3, 18, SAFARI_ZONE_ENTRANCE
	db ROUTE_23,      31,  4, VICTORY_ROAD_1

	; Additional real entrances that share the same Town Map landmark. These do
	; not change Fly destinations; they only make ordinary Town Map display
	; consistent where that extra entrance is intentionally treated as the same
	; landmark. Victory Road intentionally keeps only its Fly-side Route 23 anchor.
	db ROUTE_4,        5, 18, MT_MOON_3
	db ROUTE_4,        5, 24, MT_MOON_3
	db ROUTE_10,      17,  8, ROCK_TUNNEL_1
	db ROUTE_10,      53,  8, ROCK_TUNNEL_1
	db ROUTE_20,       5, 48, SEAFOAM_ISLANDS_1
	db $ff

BuildSpecialFlyLocationsList::
; Build the special horizontal-axis list. The first eight selectors map directly
; to bits 0-7 of the original saved byte; Victory Road uses bit 0 of the second.
	ld hl, wFlyLocationsList - 1
	ld [hl], $ff
	inc hl
	ld de, SpecialFlyLocationMapIDs
	ld a, [wSpecialFlyVisitedFlag]
	ld c, a
	ld b, 8
.firstFlagByteLoop
	srl c
	ld a, $fe
	jr nc, .storeFirstByteEntry
	ld a, [de]
.storeFirstByteEntry
	ld [hli], a
	inc de
	dec b
	jr nz, .firstFlagByteLoop

	ld a, [wSpecialFlyVisitedFlag2]
	srl a
	ld a, $fe
	jr nc, .storeSecondByteEntry
	ld a, [de]
.storeSecondByteEntry
	ld [hli], a
	ld [hl], $ff
	ret

SpecialFlyLocationMapIDs:
	; Town Map selector IDs in Left/Right cycling order.
	db MT_MOON_3
	db MT_MOON_SQUARE
	db ROCK_TUNNEL_1
	db POWER_PLANT
	db SEAFOAM_ISLANDS_1
	db UNKNOWN_DUNGEON_1
	db BILLS_HOUSE
	db SAFARI_ZONE_ENTRANCE
	db VICTORY_ROAD_1

MarkSpecialFlyLocationVisited::
; Unlock extra Fly destinations only when the player actually loads the chosen
; landmark/entrance map. Bits 0-7 use wSpecialFlyVisitedFlag; bit 8 maps to bit
; 0 of wSpecialFlyVisitedFlag2.
	ld a, [wCurMap]
	ld d, a
	ld hl, SpecialFlyVisitedMaps
.loop
	ld a, [hli]
	cp $ff
	ret z
	cp d
	jr z, .found
	inc hl ; skip destination bit index
	jr .loop
.found
	ld c, [hl]
	ld hl, wSpecialFlyVisitedFlag
	ld a, c
	cp 8
	jr c, .setFlag
	sub 8
	ld c, a
	ld hl, wSpecialFlyVisitedFlag2
.setFlag
	ld b, FLAG_SET
	predef FlagActionPredef
	ret

SpecialFlyVisitedMaps:
	; map, special Fly bit index
	; Mt. Moon, Rock Tunnel, and Cerulean Cave unlock only from their canonical
	; first/entrance floor. Seafoam keeps its established all-floor behavior.
	db MT_MOON_1, 0
	db MT_MOON_SQUARE, 1
	db ROCK_TUNNEL_1, 2
	db POWER_PLANT, 3
	db SEAFOAM_ISLANDS_1, 4
	db SEAFOAM_ISLANDS_2, 4
	db SEAFOAM_ISLANDS_3, 4
	db SEAFOAM_ISLANDS_4, 4
	db SEAFOAM_ISLANDS_5, 4
	db UNKNOWN_DUNGEON_1, 5
	db BILLS_HOUSE, 6
	db SAFARI_ZONE_ENTRANCE, 7
	db VICTORY_ROAD_1, 8
	db $ff

TryLoadSpecialFlyWarpData::
; in: D = Fly selector map ID
; out: carry set if D is an extra Fly selector and its destination/warp data
;      have been copied; carry clear if the caller should use the original
;      town/blackout FlyWarpDataPtr table.
	ld hl, SpecialFlyWarpData
.loop
	ld a, [hli]
	cp $ff
	ret z ; CP equality clears carry
	cp d
	jr z, .found
	ld bc, 7 ; actual map + six FLYWARP_DATA bytes
	add hl, bc
	jr .loop
.found
	ld a, [hli]
	ld [wDestinationMap], a
	ld [wCurMap], a
	ld de, wCurrentTileBlockMapViewPointer
	ld c, 6
.copyWarpData
	ld a, [hli]
	ld [de], a
	inc de
	dec c
	jr nz, .copyWarpData
	scf
	ret

SpecialFlyWarpData:
	; selector map, actual destination map, six-byte FLYWARP_DATA record
	db MT_MOON_3, ROUTE_4
	FLYWARP_DATA ROUTE_4_WIDTH, 6, 11
	db MT_MOON_SQUARE, MT_MOON_SQUARE
	FLYWARP_DATA MT_MOON_SQUARE_WIDTH, 10, 19
	db ROCK_TUNNEL_1, ROUTE_10
	FLYWARP_DATA ROUTE_10_WIDTH, 20, 11
	db POWER_PLANT, ROUTE_10
	FLYWARP_DATA ROUTE_10_WIDTH, 40, 6
	db SEAFOAM_ISLANDS_1, ROUTE_20
	FLYWARP_DATA ROUTE_20_WIDTH, 10, 58
	db UNKNOWN_DUNGEON_1, CERULEAN_CITY
	FLYWARP_DATA CERULEAN_CITY_WIDTH, 12, 4
	db BILLS_HOUSE, ROUTE_25
	FLYWARP_DATA ROUTE_25_WIDTH, 4, 45
	db SAFARI_ZONE_ENTRANCE, FUCHSIA_CITY
	FLYWARP_DATA FUCHSIA_CITY_WIDTH, 4, 18
	db VICTORY_ROAD_1, ROUTE_23
	FLYWARP_DATA ROUTE_23_WIDTH, 32, 4
	db $ff
