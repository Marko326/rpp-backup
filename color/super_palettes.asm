; Note: after calling this, you may need to set W2_ForceBGPUpdate/ForceOBPUpdate to nonzero.
; d = palette to load (see constants/palette_constants.), e = palette index
LoadSGBPalette:
	ld a,[rSVBK]
	ld b,a
	ld a,2
	ld [rSVBK],a
	push bc

	ld a,e
	ld l,d
	ld h,0
	add hl,hl
	add hl,hl
	add hl,hl
	ld de, SuperPalettes
	add hl,de

	ld de,W2_BgPaletteData
	jr startPaletteTransfer

LoadSGBPalette_Sprite:
	ld a,[rSVBK]
	ld b,a
	ld a,2
	ld [rSVBK],a
	push bc

	ld a,e
	ld l,d
	ld h,0
	add hl,hl
	add hl,hl
	add hl,hl
	ld de, SuperPalettes
	add hl,de

	ld de,W2_BgPaletteData + $40
	;jr startPaletteTransfer

startPaletteTransfer:
	add a
	add a
	add a
	add e
	ld e,a
	ld b,8
	
.palLoop
	ld a,[hli]
	ld [de],a
	inc de
	dec b
	jr nz,.palLoop

	pop af
	ld [rSVBK],a
	ret

LoadMoveDexTypePalette:
	; MoveDex 类型图标与 Pokémon 专用配色采用相同结构：
	; 数据表只保存中间两色，LoadPalette 自动补白色和黑色。
	ld hl, MoveDexTypePaletteTable
	jr LoadPalette

LoadBattleAnimTypePalette_Sprite:
	; d = move type ID, e = OBJ palette slot.
	; BattleAnimTypePaletteTable stores only the two visible middle colors;
	; LoadPalette_Sprite supplies transparent color 0 and black color 3.
	ld hl, BattleAnimTypePaletteTable
	jr LoadPalette_Sprite

LoadPokemonPalette:
	ld hl, PokemonPaletteTable
	jr LoadPalette

LoadShinyPokemonPalette:
	ld hl, ShinyPokemonPaletteTable
	jr LoadPalette

LoadTrainerPalette:
	ld hl, TrainerPaletteTable
	;jr LoadPalette

LoadPalette:
	ld a,[rSVBK]
	ld b,a
	ld a,2
	ld [rSVBK],a
	push bc

	push hl
	ld a,e
	ld l,d
	ld h,0
	add hl,hl
	add hl,hl
	pop de
	add hl,de

	ld de,W2_BgPaletteData
	jr startHalfPaletteTransfer

; ANM-5.61.39: keep the normal type light/dark pair in OBJ colors 1/2, but
; replace source color 3 (normally black) with the already-loaded type dark color.
; This lets black-heavy legacy material inherit the move type without flattening
; the whole sprite into one dark color.
; input: e = OBJ palette slot. DE may be clobbered; BC is preserved.
LoadBattleAnimTypeDarkPalette_Sprite:
	ld a,[rSVBK]
	push af
	ld a,2
	ld [rSVBK],a

	ld a,e
	add a
	add a
	add a
	add LOW(W2_BgPaletteData + $40 + 4) ; OBJ palette color 2
	ld l,a
	ld h,HIGH(W2_BgPaletteData + $40 + 4)
	ld a,[hli]
	ld d,a
	ld a,[hli]
	; HL now points at OBJ palette color 3.
	ld [hl],d
	inc hl
	ld [hl],a

	pop af
	ld [rSVBK],a
	ret

LoadPokemonPalette_Sprite:
	ld hl, PokemonPaletteTable
	jr LoadPalette_Sprite

LoadShinyPokemonPalette_Sprite:
	ld hl, ShinyPokemonPaletteTable
	jr LoadPalette_Sprite

LoadTrainerPalette_Sprite:
	ld hl, TrainerPaletteTable
	;jr LoadPalette_Sprite

LoadPalette_Sprite:

	ld a,[rSVBK]
	ld b,a
	ld a,2
	ld [rSVBK],a
	push bc

	push hl
	ld a,e
	ld l,d
	ld h,0
	add hl,hl
	add hl,hl
	pop de
	add hl,de

	ld de,W2_BgPaletteData + $40
	;jr startHalfPaletteTransfer

startHalfPaletteTransfer:
	add a
	add a
	add a
	add e
	ld e,a
	ld b,4

	ld a, $ff
	ld [de], a
	inc de
	ld a, $7f
	ld [de], a
	inc de
.palLoop
	ld a,[hli]
	ld [de],a
	inc de
	dec b
	jr nz,.palLoop
	xor a
	ld [de], a
	inc de
	ld [de], a
	inc de

	pop af
	ld [rSVBK],a
	ret

INCLUDE "data/super_palettes.asm"
