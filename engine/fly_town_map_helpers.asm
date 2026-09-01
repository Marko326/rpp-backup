; Fly-only Town Map display helpers kept in expansion bank $35 so the
; capacity-constrained Town Map bank does not need to grow.

GetFlyTownMapPlayerMap::
; The special Fly selectors can land on a nearby outdoor map. At the exact
; landing tile, return the selector map in D so the player marker overlaps the
; bird marker instead of using the route/city Town Map coordinate.
;
; out: D = map ID whose Town Map coordinates should be used for the player.
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
	ld e, a
	ld a, [wYCoord]
	cp e
	jr nz, .skipYAndSelector
	ld a, [hli]
	ld e, a
	ld a, [wXCoord]
	cp e
	jr nz, .skipSelector
	ld d, [hl]
	ret
.skipMapEntry
	inc hl ; y
	inc hl ; x
	inc hl ; selector map
	jr .loop
.skipYAndSelector
	inc hl ; x
	inc hl ; selector map
	jr .loop
.skipSelector
	inc hl ; selector map
	jr .loop

FlyTownMapPlayerOverrides:
	; actual map, landing y, landing x, Town Map selector
	db ROUTE_4,        6, 11, MT_MOON_3
	db ROUTE_10,      20, 11, ROCK_TUNNEL_1
	db ROUTE_10,      40,  6, POWER_PLANT
	db ROUTE_20,      10, 58, SEAFOAM_ISLANDS_1
	db CERULEAN_CITY, 12,  4, UNKNOWN_DUNGEON_1
	db $ff
