; Fly-only helpers kept in expansion bank $35 so the capacity-constrained
; overworld/Town Map/special-warp banks do not need to grow.



LoadPlayerSpriteGraphicsForFlyTownMap::
; Fly Map temporarily forces hTilesetType = 0. Keep the original loader for
; Walking/Bike, but reload only the four Surf tiles used by the current-player
; Town Map marker so Surf is not converted to Walking. BirdSprite starts at
; vSprites + $40 (tile 4), so these tiles do not overlap the Fly cursor.
	ld a, [wWalkBikeSurfState]
	cp 2
	jp nz, LoadPlayerSpriteGraphics
	ld de, SeelSprite
	ld hl, vNPCSprites
	lb bc, BANK(SeelSprite), 4
	jp CopyVideoData

InitTownMapLocationFromPlayerMap::
; Initialize ordinary Town Map Up/Down browsing from the player's displayed
; Town Map position rather than from Pallet Town.
;
; in: E = map/selector currently used to draw the player's Town Map position
; out: wWhichTownMapLocation = matching/nearest TownMapOrder index
;
; E is used deliberately: callab/callba replace A with the destination ROM bank,
; while DE survives Bankswitch. First use an exact selector match. If the player
; is on an interior map that is not itself in TownMapOrder, fall back to the
; nearest Town Map coordinates.
	ld d, e ; preserve displayed selector for the exact-ID scan
	xor a
	ld [wBuffer + 1], a ; current TownMapOrder index
	ld hl, TownMapOrderAnchorMapIDs
.exactLoop
	ld a, [hli]
	cp $ff
	jr z, .findByCoords
	cp d
	jr z, .storeCurrentIndex
	ld a, [wBuffer + 1]
	inc a
	ld [wBuffer + 1], a
	jr .exactLoop
.storeCurrentIndex
	ld a, [wBuffer + 1]
	ld [wWhichTownMapLocation], a
	ret
.findByCoords
	ld e, d
	callba LoadTownMapEntryFromE
	ld a, d
	ld [wBuffer + 2], a ; player's Town Map y
	ld a, e
	ld [wBuffer + 3], a ; player's Town Map x
	ld a, $ff
	ld [wBuffer], a ; best Manhattan distance seen so far
	xor a
	ld [wBuffer + 1], a
	ld [wWhichTownMapLocation], a ; safe fallback = Pallet Town
	ld hl, TownMapOrderAnchorMapIDs
.coordLoop
	ld a, [hli]
	cp $ff
	ret z
	ld e, a ; E survives the far-call bankswitch
	push hl
	callba LoadTownMapEntryFromE ; returns D = y, E = x
	ld a, [wBuffer + 2]
	ld c, a
	ld a, d
	sub c
	jr nc, .haveYDistance
	cpl
	inc a
.haveYDistance
	ld h, a
	ld a, [wBuffer + 3]
	ld c, a
	ld a, e
	sub c
	jr nc, .haveXDistance
	cpl
	inc a
.haveXDistance
	add h
	jr z, .exactCoords
	ld c, a ; C = Manhattan distance for this TownMapOrder entry
	ld a, [wBuffer]
	cp c
	jr c, .next ; existing best is smaller
	jr z, .next ; keep the earlier entry when distances tie
	ld a, c
	ld [wBuffer], a
	ld a, [wBuffer + 1]
	ld [wWhichTownMapLocation], a
.next
	pop hl
	ld a, [wBuffer + 1]
	inc a
	ld [wBuffer + 1], a
	jr .coordLoop
.exactCoords
	ld a, [wBuffer + 1]
	ld [wWhichTownMapLocation], a
	pop hl
	ret

; Mirror TownMapOrder in this roomy expansion bank. The entries come from the
; same macro as the real list, so geographic-order edits cannot make them drift.
TownMapOrderAnchorMapIDsLeadingSentinel:
	db $ff
TownMapOrderAnchorMapIDs:
	TownMapOrderEntries
TownMapOrderAnchorMapIDsEnd:
	db $ff

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
	; Seafoam 1F has two Route 20 entrances. If the latest external entrance was
	; the west/red-side entrance, show the dedicated west Fly selector instead of
	; the original east-side Seafoam selector.
	cp SEAFOAM_ISLANDS_1
	jr nz, .scanOverrides
	ld a, [wSeafoamEntranceSource]
	cp 1
	jr nz, .scanOverrides
	ld d, UNUSED_MAP_F1 ; pseudo selector reserved for Seafoam west entrance
	ret
.scanOverrides
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
	db ROUTE_2,        9, 12, DIGLETTS_CAVE_EXIT ; Diglett's Cave Route 2 side
	db ROUTE_11,       5,  4, DIGLETTS_CAVE_ENTRANCE ; Diglett's Cave Route 11 side

	; Additional real entrances that share the same Town Map landmark. These do
	; not change Fly destinations; they only make ordinary Town Map display
	; consistent where that extra entrance is intentionally treated as the same
	; landmark. Victory Road intentionally keeps only its Fly-side Route 23 anchor.
	db ROUTE_4,        5, 18, MT_MOON_3
	db ROUTE_4,        5, 24, MT_MOON_3
	db ROUTE_10,      17,  8, ROCK_TUNNEL_1
	db ROUTE_10,      53,  8, ROCK_TUNNEL_1
	db ROUTE_20,       5, 48, UNUSED_MAP_F1 ; Seafoam west/red-side entrance
	db $ff


UpdateSeafoamEntranceSource::
; Remember which Route 20 side was used to enter Seafoam Islands 1F and unlock
; only that entrance's Fly destination. This keeps the two entrances independent:
; wWarpedFromWhichWarp is the zero-based index of the source Route 20 warp:
;   source index 0 / Route 20 (48,5) = west/red-side Seafoam Fly point (flag2 bit 1)
;   source index 1 / Route 20 (58,9) = original east-side Seafoam Fly point (flag1 bit 4)
; The source byte is temporary; the unlock bits themselves are saved permanently.
; Only overwrite the source on a real Route 20 -> Seafoam 1F transition. Internal
; Seafoam floor changes must preserve the latest external entrance.
	ld a, [wCurMap]
	cp SEAFOAM_ISLANDS_1
	ret nz
	ld a, [wWarpedFromWhichMap]
	cp ROUTE_20
	ret nz
	ld a, [wWarpedFromWhichWarp]
	and a ; Route 20 source warp index 0 = (48,5), west/red side
	jr z, .west
	cp 1 ; Route 20 source warp index 1 = (58,9), east side
	ret nz
	ld a, 2
	ld [wSeafoamEntranceSource], a
	ld hl, wSpecialFlyVisitedFlag
	set 4, [hl] ; original/east Seafoam destination
	ret
.west
	ld a, 1
	ld [wSeafoamEntranceSource], a
	ld hl, wSpecialFlyVisitedFlag2
	set 1, [hl] ; west/red-side Seafoam destination
	ret

FindCityFlyLocationFromSpecialAnchor::
; Switch from the Fly special axis back to the city axis without losing the
; current geographic position.
;
; in:  D = 0 for Down/previous, 1 for Up/next
;      E = currently selected special Fly selector
;      wBuffer = already rebuilt city Fly list
; out: DE = pointer to the selected visited city entry in wBuffer
;
; Find the special selector's explicit TownMapOrder anchor, then walk normal
; Town Map geography in the requested direction. City map IDs are the original
; contiguous PALLET_TOWN..SAFFRON_CITY Fly entries, so wBuffer + 1 + map ID is
; their availability slot. Locked/unvisited cities are skipped; wrap happens
; only after reaching the corresponding end of TownMapOrder.
	ld a, d
	push af ; direction
	ld c, e ; special selector
	ld hl, SpecialFlyLocationEntries
.findSpecialRow
	ld a, [hli]
	cp $ff
	jp z, .fallback
	cp c
	jr z, .haveSpecialRow
	inc hl ; TownMapOrder anchor
	inc hl ; flag-byte offset
	inc hl ; bit mask
	jr .findSpecialRow
.haveSpecialRow
	ld c, [hl] ; TownMapOrder anchor
	ld hl, TownMapOrderAnchorMapIDs
.findAnchor
	ld a, [hli]
	cp $ff
	jp z, .fallback
	cp c
	jr nz, .findAnchor
	dec hl ; point at the matched special anchor
	pop af ; direction
	and a
	jr nz, .scanNext

.scanPrevious
	dec hl
	ld a, [hl]
	cp $ff
	jr z, .wrapPrevious
	call .tryCity
	jr nc, .scanPrevious
	ret
.wrapPrevious
	ld hl, TownMapOrderAnchorMapIDsEnd
	jr .scanPrevious

.scanNext
	inc hl
	ld a, [hl]
	cp $ff
	jr z, .wrapNext
	call .tryCity
	jr nc, .scanNext
	ret
.wrapNext
	ld hl, TownMapOrderAnchorMapIDsLeadingSentinel
	jr .scanNext

.tryCity
; in: A = TownMapOrder map ID, HL = scan pointer
; out: carry set and DE = city-list pointer when this is a visited Fly city;
;      carry clear otherwise. HL scan pointer is preserved on failure.
	cp SAFFRON_CITY + 1
	jr nc, .notCity
	push hl
	ld e, a
	ld d, 0
	ld hl, wBuffer + 1
	add hl, de
	ld a, [hl]
	cp $fe
	jr z, .unavailableCity
	cp $ff
	jr z, .unavailableCity
	ld d, h
	ld e, l
	pop hl
	scf
	ret
.unavailableCity
	pop hl
.notCity
	and a ; clear carry
	ret

.fallback
; Defensive fallback for a future special selector/anchor table mismatch.
; Normal saves always have at least Pallet Town available.
	pop af
	ld hl, wBuffer + 1
.findFirstVisitedCity
	ld a, [hli]
	cp $ff
	jr z, .fallbackPallet
	cp $fe
	jr z, .findFirstVisitedCity
	dec hl
	ld d, h
	ld e, l
	ret
.fallbackPallet
	ld de, wBuffer + 1
	ret

BuildSpecialFlyLocationsList::
; Build the special horizontal-axis list in the same geographic browsing order
; as TownMapOrder, rather than in historical feature/bit-assignment order.
; Each table row is: selector, TownMapOrder anchor, flag-byte offset from
; wSpecialFlyVisitedFlag2, bit mask. The saved bit assignments stay unchanged.
	ld hl, wBuffer
	ld [hl], $ff
	inc hl
	ld de, SpecialFlyLocationEntries
.loop
	ld a, [de]
	inc de
	cp $ff
	jr z, .done
	ld c, a ; selector
	inc de ; skip TownMapOrder anchor
	ld a, [de]
	inc de
	push hl
	ld hl, wSpecialFlyVisitedFlag2
	and a
	jr z, .gotFlagByte
	inc hl ; offset 1 = wSpecialFlyVisitedFlag
.gotFlagByte
	ld a, [hl]
	pop hl
	ld b, a
	ld a, [de]
	inc de
	and b
	ld a, $fe
	jr z, .store
	ld a, c
.store
	ld [hli], a
	jr .loop
.done
	ld [hl], $ff
	ret

BuildSpecialFlyLocationsListFromCityAnchor::
; Switch from the Fly city axis to the special axis without losing the current
; geographic position. Special selectors do not always equal their TownMapOrder
; entry (Mt. Moon, Rock Tunnel, Safari, Seafoam, and Victory Road use aliases),
; so every special row carries an explicit TownMapOrder anchor.
;
; in:  D = 0 for Left/previous, 1 for Right/next
;      E = currently selected city map
; out: DE = list boundary pointer for the existing moveSpecialLeft/Right loops
;      carry set = Right, carry clear = Left
;      wBuffer rebuilt as the special Fly list
	push de
	call BuildSpecialFlyLocationsList
	pop de
	ld a, d
	push af ; direction
	ld c, e ; selected city selector
	ld hl, TownMapOrderAnchorMapIDs
	ld de, SpecialFlyLocationEntries
	ld b, 0 ; number of special anchors before the selected city
.findBoundary
	ld a, [hli]
	cp $ff
	jr z, .cityNotFound
	cp c
	jr z, .haveBoundary
	; IMPORTANT: SpecialFlyLocationEntries is kept in TownMapOrder order. When this Town Map
	; entry is the next special anchor, advance the special boundary by one row.
	push bc
	push af
	ld a, [de]
	cp $ff
	jr z, .noMoreSpecialAnchors
	inc de
	ld a, [de]
	ld b, a ; next special TownMapOrder anchor
	dec de
	pop af
	cp b
	pop bc
	jr nz, .findBoundary
	inc b
	inc de
	inc de
	inc de
	inc de ; next 4-byte special row
	jr .findBoundary
.noMoreSpecialAnchors
	pop af
	pop bc
	jr .findBoundary
.cityNotFound
	; Defensive fallback. City-axis selectors should all exist in TownMapOrder; if
	; a future entry does not, treat it as being before the first special anchor.
	ld b, 0
.haveBoundary
	; Convert the special count to a pointer at the city/special boundary.
	; Right's existing loop increments first, so it starts at wBuffer + count.
	; Left's loop decrements first, so it starts one byte later.
	ld hl, wBuffer
	ld c, b
.positionBoundary
	ld a, c
	and a
	jr z, .boundaryReady
	inc hl
	dec c
	jr .positionBoundary
.boundaryReady
	pop af ; direction
	and a
	jr nz, .returnRight
	inc hl ; Left pre-decrements to the previous special entry
	ld d, h
	ld e, l
	and a ; clear carry = Left
	ret
.returnRight
	ld d, h
	ld e, l
	scf ; carry = Right
	ret

SpecialFlyLocationEntries:
	; selector, TownMapOrder anchor, flag-byte offset (0=flag2, 1=flag1), bit mask
	; Order follows normal Town Map geography. The anchor column makes aliases
	; explicit instead of assuming every Fly selector appears directly in the order.
	db VIRIDIAN_FOREST,         VIRIDIAN_FOREST,          0, %00000100 ; flag2 bit 2
	db DIGLETTS_CAVE_EXIT,      DIGLETTS_CAVE_EXIT,       0, %00001000 ; flag2 bit 3, Route 2 side
	db MT_MOON_3,               MT_MOON_1,                1, %00000001 ; flag1 bit 0
	db MT_MOON_SQUARE,          MT_MOON_SQUARE,           1, %00000010 ; flag1 bit 1
	db UNKNOWN_DUNGEON_1,       UNKNOWN_DUNGEON_1,        1, %00100000 ; flag1 bit 5, Cerulean Cave
	db BILLS_HOUSE,             BILLS_HOUSE,              1, %01000000 ; flag1 bit 6, Sea Cottage
	db DIGLETTS_CAVE_ENTRANCE, DIGLETTS_CAVE_ENTRANCE,  0, %00010000 ; flag2 bit 4, Route 11 side
	db ROCK_TUNNEL_1,           ROCK_TUNNEL_POKECENTER,   1, %00000100 ; flag1 bit 2
	db POWER_PLANT,             POWER_PLANT,              1, %00001000 ; flag1 bit 3
	db CELADON_MART_ROOF,       CELADON_MART_ROOF,        0, %00100000 ; flag2 bit 5
	db SAFARI_ZONE_ENTRANCE,    SAFARI_ZONE_EAST,         1, %10000000 ; flag1 bit 7
	db SEAFOAM_ISLANDS_1,       SEAFOAM_ISLANDS_2,        1, %00010000 ; flag1 bit 4, east side
	db UNUSED_MAP_F1,           UNUSED_MAP_F1,            0, %00000010 ; flag2 bit 1, west/red side
	db VICTORY_ROAD_1,          VICTORY_ROAD_3,           0, %00000001 ; flag2 bit 0
SpecialFlyLocationEntriesEnd:
	db $ff


MarkSpecialFlyLocationVisited::
; Unlock extra Fly destinations only when the player actually loads the chosen
; landmark map. Diglett's Cave remains entrance-based because its two ends are
; distinct Fly destinations. Bits 0-7 use wSpecialFlyVisitedFlag; bit indices 8+ map
; to the corresponding bits of wSpecialFlyVisitedFlag2. Seafoam is handled separately by
; UpdateSeafoamEntranceSource so each Route 20 entrance unlocks independently.
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
	; first/entrance floor. Seafoam is intentionally absent here because its two
	; Route 20 entrances now have separate unlock bits.
	db MT_MOON_1, 0
	db MT_MOON_SQUARE, 1
	db ROCK_TUNNEL_1, 2
	db POWER_PLANT, 3
	db UNKNOWN_DUNGEON_1, 5
	db BILLS_HOUSE, 6
	db SAFARI_ZONE_ENTRANCE, 7
	db VIRIDIAN_FOREST, 10 ; flag2 bit 2
	db DIGLETTS_CAVE_EXIT, 11 ; flag2 bit 3, Route 2 side
	db DIGLETTS_CAVE_ENTRANCE, 12 ; flag2 bit 4, Route 11 side
	db CELADON_MART_ROOF, 13 ; flag2 bit 5
	db VICTORY_ROAD_1, 8
	db $ff

TryLoadSpecialTownMapEntry::
; Exact Town Map entries for selector/entrance/interior IDs that must not be inserted into
; InternalMapEntries (that table intentionally uses range/upper-bound semantics).
; in: E = map/selector ID
; out on match: carry set, D = y, E = x, HL = name pointer
; out on miss: carry clear
	ld a, e
	cp UNUSED_MAP_F1
	jr z, .seafoamWest
	cp DIGLETTS_CAVE_EXIT
	jr z, .diglettRoute2
	cp DIGLETTS_CAVE_ENTRANCE
	jr z, .diglettRoute11
	cp CELADON_MART_ROOF
	jr z, .celadonMartRoof
	and a ; clear carry
	ret
.seafoamWest
	ld d, 140
	ld e, 72
	ld hl, SeafoamIslandsName
	scf
	ret
.diglettRoute2
	ld d, 68
	ld e, 68
	ld hl, DiglettsCaveName
	scf
	ret
.diglettRoute11
	ld d, 84
	ld e, 124
	ld hl, DiglettsCaveName
	scf
	ret
.celadonMartRoof
	ld d, 68
	ld e, 92
	ld hl, CeladonDeptRoofName
	scf
	ret

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
	db CELADON_MART_ROOF, CELADON_MART_ROOF
	; Land two steps below the vending machine and two steps right of the nearby man.
	FLYWARP_DATA CELADON_MART_ROOF_WIDTH, 4, 12
	db SEAFOAM_ISLANDS_1, ROUTE_20
	FLYWARP_DATA ROUTE_20_WIDTH, 10, 58
	db UNUSED_MAP_F1, ROUTE_20 ; Seafoam west/red-side pseudo selector
	FLYWARP_DATA ROUTE_20_WIDTH, 6, 48
	db UNKNOWN_DUNGEON_1, CERULEAN_CITY
	FLYWARP_DATA CERULEAN_CITY_WIDTH, 12, 4
	db BILLS_HOUSE, ROUTE_25
	FLYWARP_DATA ROUTE_25_WIDTH, 4, 45
	db SAFARI_ZONE_ENTRANCE, FUCHSIA_CITY
	FLYWARP_DATA FUCHSIA_CITY_WIDTH, 4, 18
	db VIRIDIAN_FOREST, VIRIDIAN_FOREST
	; Match the normal south-gate entry after its automatic step into the forest.
	FLYWARP_DATA VIRIDIAN_FOREST_WIDTH, 46, 16
	db DIGLETTS_CAVE_EXIT, ROUTE_2
	FLYWARP_DATA ROUTE_2_WIDTH, 10, 12
	db DIGLETTS_CAVE_ENTRANCE, ROUTE_11
	FLYWARP_DATA ROUTE_11_WIDTH, 6, 4
	db VICTORY_ROAD_1, ROUTE_23
	FLYWARP_DATA ROUTE_23_WIDTH, 32, 4
	db $ff
