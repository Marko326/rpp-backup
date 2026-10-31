INCLUDE "color/data/map_palettes.asm"
INCLUDE "color/data/map_palette_sets.asm"
INCLUDE "color/data/map_palette_assignments.asm"
INCLUDE "color/data/roofpalettes.asm"

; Load colors for new map and tile placement
LoadTilesetPalette:
	push bc
	push de
	push hl
	ld a,[rSVBK]
	ld d,a
	xor a
	ld [rSVBK],a
	ld a,[wCurMapTileset] ; Located in wram bank 1
	ld b,a
	ld a,$02
	ld [rSVBK],a
	push de ; push previous wram bank

	ld a,1
	ld [W2_TileBasedPalettes],a

	ld a,b ; Get wCurMapTileset
	push af
	; FIX-267: retain the high byte of the tileset*8 palette-table offset.
	; ID $20 starts at $0100, not $0000 (the old SLA E wrapped).
	ld l,a
	ld h,0
	add hl,hl ; 2 * ID
	add hl,hl ; 4 * ID
	add hl,hl ; 8 * ID, full 16-bit
	ld de,MapPaletteSets
	add hl,de
	ld d,h
	ld e,l
	ld hl,W2_BgPaletteData ; palette data to be copied to wram at hl
	ld b,$08
.nextPalette
	ld c,$08
	ld a,[de] ; # at de is the palette index for MapPalettes
	inc de
	push de
	ld d,0
	ld e,a
	sla e
	rl d
	sla e
	rl d
	sla e
	rl d
	push hl
	ld hl, MapPalettes
	add hl,de
	ld d,h
	ld e,l ; de now points to map's palette data
	pop hl
.nextColor
	ld a,[de]
	inc de
	ld [hli],a
	dec c
	jr nz,.nextColor
	pop de
	dec b
	jr nz,.nextPalette

	; Start copying palette assignments
	pop af	; Retrieve wCurMapTileset
	ld hl,$0000
	cp $00
	jr z,.doneMultiplication
	ld c,a
	ld de,$0060	; Each palette assignment takes $60 bytes
.addLoop
	add hl,de
	dec c
	jr nz,.addLoop
.doneMultiplication:
	ld bc, MapPaletteAssignments
	add hl,bc
	push hl
	pop de ; de points to MapPaletteAssignments
	ld hl, W2_TilesetPaletteMap
	ld b,$60
.copyLoop
	ld a,[de]
	inc de
	ld [hli],a
	dec b
	jr nz,.copyLoop

	; HAX: set route gate roofs (outside the tileset) to GRAY
	xor a ; GRAY
	rept 8
	ld [hli], a
	endr

	; Set the remaining values to CRYS_TEXTBOX for text
	ld b,$98 ;a0 - 8
	ld a,7;CRYS_TEXTBOX
.fillLoop
	ld [hli],a
	dec b
	jr nz,.fillLoop

	; There used to be special-case code for tile $78 here (pokeball in pc), but now
	; it uses palette 7 as well. Those areas still need to load the variant of the
	; textbox palette (PC_POKEBALL_PAL).

	; Switch to wram bank 1 just to read wCurMap
	xor a
	ld [rSVBK],a
	ld a,[wCurMap]
	ld b,a
	ld a,2
	ld [rSVBK],a

	; b holds the current Map ID
	; There used to be code here to hard-code different palette assignments in Celadon Mart
	; They were removed, as they do not apply to the new tileset
	; Any new map-specific overrides could be added here

    ; Restore Gold RGB5 roof colors for the local Johto map group.
    ; The GBC background roof lives in palette six; no map recolor for Kanto.
    call ApplyJohtoGoldRoofPalette269

	; Retrieve former wram bank
	pop af
	ld b,a

	xor a
	ld [rSVBK],a
	ld a,[wCurMapTileset]
	ld c,a

	ld a,b
	ld [rSVBK],a ; Restore previous wram bank

	ld a,c
	and a ; Check whether tileset 0 is loaded
	call z, LoadTownPalette
	cp PLATEAU ; tileset 0 isn't the only outside tileset
	call z, LoadTownPalette

	; Snowy 模式只覆盖与普通版不同的调色板和 tile palette 分配。
	callba ApplySnowPaletteOverrides

	pop hl
	pop de
	pop bc
	ret

 ; This helper is entered with WRAM bank 2 selected and leaves it selected.
ApplyJohtoGoldRoofPalette269:
    xor a
    ld [rSVBK],a
    ld a,[wCurMap]
    cp JOHTO_RUNTIME_MAP_HANDLE
    jp nz,.done
    ld a,[wCurRegion]
    cp MAP_REGION_JOHTO
    jp nz,.done
    ld a,[wCurMapTileset]
    cp JOHTO_PILOT
    jp z,.select
    cp JOHTO_MODERN
    jp nz,.done
.select
    ld a,[wCurLocalMapID]
    cp JOHTO_ROUTE_33_LOCAL_ID
    jp z,.azalea
    cp JOHTO_AZALEA_TOWN_LOCAL_ID
    jp z,.azalea
    cp JOHTO_ROUTE_34_LOCAL_ID
    jp z,.goldenrod
    cp JOHTO_GOLDENROD_CITY_LOCAL_ID
    jp z,.goldenrod
    cp JOHTO_VIOLET_CITY_LOCAL_ID
    jp z,.violet
    cp JOHTO_ROUTE_32_LOCAL_ID
    jp z,.violet
    cp JOHTO_ROUTE_36_LOCAL_ID
    jp z,.violet
    cp JOHTO_CHERRYGROVE_LOCAL_ID
    jp z,.cherrygrove
    cp JOHTO_ROUTE_30_LOCAL_ID
    jp z,.cherrygrove
    cp JOHTO_ROUTE_31_LOCAL_ID
    jp z,.cherrygrove
    cp JOHTO_NEW_BARK_LOCAL_ID
    jp z,.newbark
    cp JOHTO_ROUTE_29_LOCAL_ID
    jp nz,.done
.newbark
    ld de,JohtoNewBarkRoofPalette269
    jp .copy
.cherrygrove
    ld de,JohtoCherrygroveRoofPalette269
    jp .copy
.violet
    ld de,JohtoVioletRoofPalette269
    jp .copy
.azalea
    ld de,JohtoAzaleaRoofPalette269
    jp .copy
.goldenrod
    ld de,JohtoGoldenrodRoofPalette269
.copy
    ld a,2
    ld [rSVBK],a
    ld hl,W2_BgPaletteData + 6 * 8
    ld b,8
.loop
    ld a,[de]
    ld [hli],a
    inc de
    dec b
    jp nz,.loop
    ret
.done
    ld a,2
    ld [rSVBK],a
    ret

; Gold gfx/tilesets/roofs.pal; RGB5 units (do not interpolate).
JohtoNewBarkRoofPalette269:
    RGB 27,31,27
    RGB 20,31,14
    RGB 11,23,05
    RGB 07,07,07
JohtoCherrygroveRoofPalette269:
    RGB 27,31,27
    RGB 31,14,28
    RGB 31,05,21
    RGB 07,07,07
JohtoVioletRoofPalette269:
    RGB 27,31,27
    RGB 24,14,31
    RGB 13,07,21
    RGB 07,07,07
JohtoAzaleaRoofPalette269:
    RGB 27,31,27
    RGB 22,20,10
    RGB 17,14,03
    RGB 07,07,07
JohtoGoldenrodRoofPalette269:
    RGB 27,31,27
    RGB 25,25,00
    RGB 20,17,08
    RGB 07,07,07

; Towns have different roof colors while using the same tileset
LoadTownPalette:
	ld a,[rSVBK]
	ld b,a
	xor a
	ld [rSVBK],a

	; Get the current map.
	ld a,[wCurMap]
	ld c,a
	cp MT_MOON_SQUARE ; Uses Pewter City roof
	jr nz, .notMtMoonSquare
	ld c, PEWTER_CITY
.notMtMoonSquare
	cp ROUTE_6 ; Route 6 has 2 rows in saffron city; check if player is there or not.
	jr nz, .notRoute6
	ld a,[wYCoord]
	cp 2
	jr nc, .notRoute6
	ld c,SAFFRON_CITY
.notRoute6
	ld a,c
	add a
	ld c,a

	ld a,$02
	ld [rSVBK],a
	push bc ; push previous wram bank

	push de
	push hl
	ld hl, RoofPalettes
	ld b, 0
	add hl, bc
	ld e, [hl]
	inc hl
	ld d, [hl]
	ld hl, W2_BgPaletteData + $32
	ld b,$04
.copyLoop
	ld a,[de]
	inc de
	ld [hli],a
	dec b
	jr nz,.copyLoop
	pop hl
	pop de

	ld a, [wCurMap]
	ld [W2_TownMapLoaded],a

	pop af
	ld [rSVBK],a ; Restore wram bank
	ret
