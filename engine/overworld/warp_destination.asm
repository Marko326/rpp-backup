; WDP-5.49.00: reconstruct normal warp destination data from wWarpEntries.
; Map object files no longer need one 4-byte EVENT_DISP record per warp.
;
; Input: wDestinationWarpID = zero-based destination warp ID within the current map.
; Output: wCurrentTileBlockMapViewPointer = block-map pointer, Y, X.
ReconstructDestinationWarpPosition::
	; Bankswitch clobbers A, so reload the ID already stored by the warp logic.
	ld a, [wDestinationWarpID]
	; Each loaded warp entry is Y, X, destination warp ID, destination map.
	add a
	add a
	ld e, a
	ld d, $0
	ld hl, wWarpEntries
	add hl, de

	ld a, [hli]
	ld [wCurrentTileBlockMapViewPointer + 2], a
	ld b, a ; Y
	ld a, [hl]
	ld [wCurrentTileBlockMapViewPointer + 3], a
	ld c, a ; X

	; EVENT_DISP used:
	; wOverworldMap + 7 + width + (width + 6) * (Y >> 1) + (X >> 1).
	; Rearranged as wOverworldMap + 1 + (width + 6) * ((Y >> 1) + 1)
	; + (X >> 1), which avoids storing any per-warp pointer in ROM.
	ld hl, wOverworldMap + 1
	ld a, [wCurMapWidth]
	add MAP_BORDER * 2
	ld e, a
	ld d, $0
	ld a, b
	srl a
	inc a
.addRows
	add hl, de
	dec a
	jr nz, .addRows

	ld a, c
	srl a
	ld e, a
	add hl, de

	ld a, l
	ld [wCurrentTileBlockMapViewPointer], a
	ld a, h
	ld [wCurrentTileBlockMapViewPointer + 1], a
	ret
