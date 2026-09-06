; Position the elevator floor menu on the floor represented by the elevator's
; current exit map. The copied warp-map table uses the same order as wItemList,
; so matching the map ID gives the absolute floor-list index directly.
;
; DisplayListMenuID shows three rows. Keep early floors at their natural row;
; for later floors, scroll just enough to place the current floor on row 2.
; If the current map is not found, keep the caller's default position (row 0).
RestoreElevatorFloorMenuPosition::
	ld a, [wWarpEntries + 3]
	ld c, a ; map currently represented by the elevator exit
	ld a, [wItemList]
	ld b, a ; number of real floor entries
	ld hl, wElevatorWarpMaps + 1 ; first map-id byte
	ld d, 0 ; absolute floor-list index
.scan
	ld a, b
	and a
	ret z
	ld a, [hl]
	cp c
	jr z, .found
	inc hl
	inc hl
	inc d
	dec b
	jr .scan
.found
	ld a, d
	cp 3
	jr c, .storeRow
	sub 2
	ld [wListScrollOffset], a
	ld a, 2
.storeRow
	ld [wCurrentMenuItem], a
	ret
