; FLY-5.62.73: Party-menu OBJ palette follows player gender.
; Party icons use OBJ palette 0; the HP bars use separate BG palettes.
; Never return or use the stack while the banked WRAM stack is switched away.
LoadPartyGenderSpritePalettes::
	CALL_INDIRECT LoadOverworldSpritePalettes
	ld a, [rSVBK]
	ld c, a
	ld a, 1
	ld [rSVBK], a
	ld a, [wPlayerGender]
	ld b, a
	ld a, c
	ld [rSVBK], a
	ld a, b
	and a
	ret z ; male: OBJ palette 0 was freshly loaded as red

	; Female: change only OBJ palette 0, not the Party HP BG palettes.
	ld hl, W2_SprPaletteData + (PAL_OW_GREEN * 8)
	ld de, W2_SprPaletteData + (PAL_OW_RED * 8)
	ld bc, 8
	call CopyData
	ld a, 1
	ld [W2_ForceOBPUpdate], a
	ret
