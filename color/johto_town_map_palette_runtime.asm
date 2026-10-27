; P3-005 / TEST-231: copied native Gold/RPP Johto Town Map palette scheme.
; Both region sets and loader sit in floating ROMX, keeping bank $1C small.
; Uses the existing wFlyLocationsAxis selector for ordinary Town Map AND Fly.
SetPal_TownMap_Regional::
	ld a,2
	ld [rSVBK],a

	; Exact reference branch Gold palette data for Johto; Kanto unchanged.
	ld hl, TownMapPals
	ld bc, TownMapPalsEnd - TownMapPals
	ld a, [wFlyLocationsAxis]
	and a
	jr z, .paletteBytesReady
	ld hl, JohtoTownMapPals
	ld bc, JohtoTownMapPalsEnd - JohtoTownMapPals
.paletteBytesReady
	ld de, W2_BgPaletteData
	call CopyData

	ld a,1
	ld [W2_TileBasedPalettes],a

	ld de, TownMapPalAssignments
	ld a, [wFlyLocationsAxis]
	and a
	jr z, .paletteIdsReady
	ld de, JohtoTownMapPalAssignments
.paletteIdsReady
	ld hl, W2_TilesetPaletteMap
	ld b, $40
.copyLoop
	ld a, [de]
	inc de
	ld [hli], a
	dec b
	jr nz, .copyLoop

	; Set the remaining tiles (the font) to pal 0
	ld b, $c0
	xor a
.fillLoop
	ld [hli], a
	dec b
	jr nz, .fillLoop

	xor a
	ld [rSVBK],a
	ret


INCLUDE "color/town_map_pals.asm"
INCLUDE "color/town_map_pal_assignments.asm"

ASSERT TownMapPalsEnd - TownMapPals == 8 * 4 * 2
ASSERT JohtoTownMapPalsEnd - JohtoTownMapPals == 8 * 4 * 2
ASSERT JohtoTownMapPalAssignments - TownMapPalAssignments == $40
ASSERT @ - JohtoTownMapPalAssignments == $40
