; F23.12n Town Map geography for Route 20 and all Seafoam interior floors.
; Kept out of bank $35 because that bank has almost no free space.
;
; in:  D = current real map ID
; out: carry set   -> handled, D = logical Town Map selector
;      carry clear -> not handled, D unchanged
ClassifyRoute20SeafoamTownMap::
	ld a, [wCurMap]
	cp ROUTE_20
	jr z, .route20

	; Seafoam 1F is map $C0. Floors 2-5 are the contiguous $9F-$A2 range.
	; All interior floors inherit the most recent Route 20 external entrance.
	cp SEAFOAM_ISLANDS_1
	jr z, .seafoamInterior
	sub SEAFOAM_ISLANDS_2
	cp SEAFOAM_ISLANDS_5 - SEAFOAM_ISLANDS_2 + 1
	jr c, .seafoamInterior
	and a ; clear carry: generic Town Map logic should handle this map
	ret

.seafoamInterior
	ld a, [wSeafoamEntranceSource]
	cp 1
	jr z, .seafoamWest
	ld d, SEAFOAM_ISLANDS_1 ; east / unknown fallback
	scf
	ret
.seafoamWest
	ld d, UNUSED_MAP_F1
	scf
	ret

.route20
	ld a, [wWalkBikeSurfState]
	cp 2
	jr z, .water

	; Route 20 has small non-Seafoam standing land. Gate the old west/east
	; island split to the two actual Seafoam island bodies only.
	; West island body: 44 <= x < 55 and y < 10.
	; East island body: 55 <= x < 68 and 6 <= y < 18.
	ld a, [wXCoord]
	cp 44
	jr c, .seaRoute20
	cp 55
	jr c, .checkWestIsland
	cp 68
	jr nc, .seaRoute20
	ld a, [wYCoord]
	cp 6
	jr c, .seaRoute20
	cp 18
	jr nc, .seaRoute20
	ld d, SEAFOAM_ISLANDS_1
	scf
	ret

.checkWestIsland
	ld a, [wYCoord]
	cp 10
	jr nc, .seaRoute20
	ld d, UNUSED_MAP_F1
	scf
	ret

.water
	; Follow the fence/shoreline boundary, with the upper-island Surf edge using
	; X=62 so its first east-side water step belongs to SeaRoute 19. The vertically
	; aligned lower water stays on SeaRoute 20 through the later Y bands.
	; 62 -> 64 -> 65 -> 66 -> 64 as Y increases.
	ld a, [wYCoord]
	cp 10
	jr c, .boundary62
	cp 12
	jr c, .boundary64
	cp 14
	jr c, .boundary65
	cp 16
	jr c, .boundary66
	ld b, 64
	jr .checkBoundary
.boundary62
	ld b, 62
	jr .checkBoundary
.boundary64
	ld b, 64
	jr .checkBoundary
.boundary65
	ld b, 65
	jr .checkBoundary
.boundary66
	ld b, 66
.checkBoundary
	ld a, [wXCoord]
	cp b
	jr nc, .seaRoute19
.seaRoute20
	ld d, UNUSED_MAP_F2
	scf
	ret
.seaRoute19
	ld d, UNUSED_MAP_F3
	scf
	ret
