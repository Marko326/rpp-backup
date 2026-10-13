; DEX-5.62.123 / S7-002: facing-aware picture loading, without UI commits.
; This code runs only after the caller has hidden the picture palette and
; resolved the current Species + Form header. It does not own the BG map swap,
; description page, arrow, or palette producer/consumer timing.
;
; The initial Pokédex page uses the stock home front-loader. HOME may redirect
; that specific call here only while the internal Info bit (7) is set.
PokedexData_LoadFacingPic::
	ld a,[wPokedexFacingPreference]
	bit 0,a
	jr nz,PokedexData_LoadBackPic
	coord hl,1,1
	jp LoadFlippedFrontSpriteByMonIndex

PokedexData_LoadBackPic::
	; The header already belongs to the exact viewed Species + Form. Both
	; sprite paths write 49 centered tiles into vFrontPic; back pictures must
	; not inherit the front loader's flip flag or stale base tile ID.
	xor a
	ld [wSpriteFlipped],a
	ld [hStartTileID],a
	ld hl,wMonHBackSprite - wMonHeader
	call UncompressMonSprite
	ld a,$66
	ld c,a
	ld de,vFrontPic
	call LoadUncompressedSpriteData
	coord hl,1,1
	xor a
	ld b,7
.column
	push bc
	push hl
	ld c,7
.row
	ld [hli],a
	; The stock 7x7 picture tile layout is column-major, not row-major.
	dec hl
	ld de,SCREEN_WIDTH
	add hl,de
	inc a
	dec c
	jr nz,.row
	pop hl
	inc hl
	pop bc
	dec b
	jr nz,.column
	ret
