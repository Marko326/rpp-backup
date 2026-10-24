; DUAL-5.19.30: Blue++ keeps the generic menu UI on its version palette, while
; Pokédex Own and MoveDex Use Poké Balls continue using palette 1 (PAL_REDBAR).
; Only those seven list cells are assigned palette 1, so the right-side divider
; and all other menu cells remain on the Blue++ generic palette 0.

SetBluePokedexListPokeballPalettes:
	; Pokédex Own marker: x=3, y=3/5/7/...
	ld hl, W2_TilesetPaletteMap + 3 * SCREEN_WIDTH + 3
	jr SetBlueDexListPokeballPalettes

SetBlueMoveDexListPokeballPalettes:
	; MoveDex Use marker: x=1, y=3/5/7/...
	ld hl, W2_TilesetPaletteMap + 3 * SCREEN_WIDTH + 1

SetBlueDexListPokeballPalettes:
	ld a, 2
	ld [rSVBK], a
	ld de, 2 * SCREEN_WIDTH
	ld b, 7
	ld a, 1
.loop
	ld [hl], a
	add hl, de
	dec b
	jr nz, .loop
	ld a, 3
	ld [W2_StaticPaletteMapChanged], a
	xor a
	ld [rSVBK], a
	callab LoadPokedexTilePatterns
	ret
