; ILEX-5.62.216: Gold mapgroup-dependent 9-tile roof art for all completed Johto
; towns and the routes in their original map groups (Gold LoadMapGroupRoof).
PatchGoldenrodRoofAfterTilesetLoad::
	call SelectGoldenrodRoofSource
	ret nc
	ld d, h
	ld e, l ; source HL -> DE for preserving the pointer
	ld hl, vTileset + $0a * $10
	push hl
	ld h, d
	ld l, e
	pop de
	ld bc, 9 * $10
	jp FarCopyData2 ; a=bank, hl=source, de=dest

PatchGoldenrodRoofOnConnection::
	call SelectGoldenrodRoofSource
	ret nc
	ld d,h
	ld e,l ; source
	ld hl, vTileset + $0a * $10
	ld b,a ; bank
	ld c,9 ; tiles, VBlank-safe copy
	jp CopyVideoData

; ILEX-5.62.216: Reuse Gold's mapgroup roof sets on every completed Johto exterior,
; not just GoldenrodCity. Every route inherits its original city group.
; Group index: 0 New Bark, 1 Cherrygrove, 2 Violet, 3 Azalea, 4 Goldenrod;
; $ff is indoors/non-rooftop and must not alter its palette or tiles.
JohtoRoofGroupForLocalMap:
	db 0 ; 00 NewBarkTown, Gold group 24
	db 0 ; 01 Route29, Gold group 24
	db 1 ; 02 CherrygroveCity, Gold group 26
	db 1 ; 03 Route30, Gold group 26
	db 1 ; 04 Route31, Gold group 26
	db 2 ; 05 VioletCity, Gold group 10
	db $ff ; 06 Route31/Violet indoor gate
	db 2 ; 07 Route32, Gold group 10
	db $ff ; 08 Union Cave
	db 3 ; 09 Route33, Gold group 8
	db 3 ; 0a AzaleaTown, Gold group 8
	db $ff ; 0b Ilex/Azalea indoor gate
	db $ff ; 0c Ilex Forest
	db $ff ; 0d Route34/Ilex indoor gate
	db 4 ; 0e Route34, Gold group 11
	db 4 ; 0f GoldenrodCity, Gold group 11
	db 2 ; 10 Route36, Gold Violet group 10
	db 2 ; 11 Route35, Gold Violet group 10
	db $ff ; 12 Route35GoldenrodGate, indoor, no roof group
	db $ff ; 13 Ruins gate, indoor
	db $ff ; 14 Ruins outside, outdoor map with no roof sprites
	db 2 ; 15 Route37, Gold Violet group 10
JohtoRoofGroupForLocalMapEnd:
ASSERT JohtoRoofGroupForLocalMapEnd - JohtoRoofGroupForLocalMap == NUM_JOHTO_MAPS

SelectGoldenrodRoofSource:
	ld a,[wCurMapTileset]
	cp JOHTO
	jr z,.johtoTileset
	cp JOHTO_MODERN
	jr nz,.no
.johtoTileset
	ld a,[wCurRegion]
	cp MAP_REGION_JOHTO
	jr nz,.no
	ld a,[wCurLocalMapID]
	cp NUM_JOHTO_MAPS
	jr nc,.no
	ld e,a
	ld d,0
	ld hl,JohtoRoofGroupForLocalMap
	add hl,de
	ld a,[hl]
	cp $ff
	jr z,.no
	cp 2
	jr z,.violet
	cp 3
	jr z,.azalea
	cp 4
	jr z,.goldenrod
	; Groups 0 and 1 both have Gold new_bark roof graphics.
	ld a,[wCurMapTileset]
	cp JOHTO_MODERN
	jr z,.modernBase
	ld hl,NewBark_GFX + $0a * $10
	ld a,BANK(NewBark_GFX)
	jr .yes
.modernBase
	ld hl,JohtoModern_GFX + $0a * $10
	ld a,BANK(JohtoModern_GFX)
	jr .yes
.violet
	ld hl,JohtoVioletRoofs_GFX
	ld a,BANK(JohtoVioletRoofs_GFX)
	jr .yes
.azalea
	ld hl,JohtoAzaleaRoofs_GFX
	ld a,BANK(JohtoAzaleaRoofs_GFX)
	jr .yes
.goldenrod
	ld hl,JohtoGoldenrodRoofs_GFX
	ld a,BANK(JohtoGoldenrodRoofs_GFX)
.yes
	scf
	ret
.no
	and a
	ret
