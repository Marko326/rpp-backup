; REF-363: both player and enemy trainer exits use palette-safe atomic BG rows.
; Keep the old entry in packed battle bank $0f; this implementation floats in
; ROMX so the animation change cannot overflow bank $0f. No new HRAM/WRAM.
; A=9 player moves left; A=8 enemy moves right. HL is top-row tilemap start.
; Preserve the old two-frame-per-step animation cadence and both return paths.

SlideTrainerPicOffScreen_Impl::
	; The bank-$0f bridge saved A to hSlideAmount and HL in DE before jpab.
	ld h, d
	ld l, e
	ld a, [hSlideAmount]
	ld c, a
	; Both directions must suspend the one-third AutoBG writer while all seven
	; rows are committed together. Save and restore its exact prior state.
	ld a, [H_AUTOBGTRANSFERENABLED]
	push af
	xor a
	ld [H_AUTOBGTRANSFERENABLED], a
.slideStepLoop
	push bc
	push hl
	ld b, 7
.rowLoop
	push hl
	ld a, [hSlideAmount]
	ld c, a
.columnLoop
	ld a, [hSlideAmount]
	cp 8
	jr z, .slideRight
.slideLeft
	ld a, [hld]
	ld [hli], a
	inc hl
	jr .nextColumn
.slideRight
	ld a, [hli]
	ld [hld], a
	dec hl
.nextColumn
	dec c
	jr nz, .columnLoop
	pop hl
	ld de, SCREEN_WIDTH
	add hl, de
	dec b
	jr nz, .rowLoop

	; REF-363: both trainer exits stage all 7 rows in one VBlank using
	; tile-only mode. Battle palettes are a screen-coordinate attribute map;
	; WindowTransferBgRowsAndColors indexes W2_TilesetPaletteMap by tile ID.
	; Copy only BG tile IDs so the established CGB attributes remain untouched.
	; The player occupies rows 5..11; the enemy occupies rows 0..6.
	; H_VBCOPYBGSRC low byte is the enable flag: clear first and arm it LAST.
	xor a
	ld [H_VBCOPYBGSRC], a
	ld a, [hSlideAmount]
	cp 9
	jr nz, .enemyRows
	coord hl, 0, 5
	ld a, h
	ld [H_VBCOPYBGSRC + 1], a
	ld a, 5 * BG_MAP_WIDTH
	jr .setDestinationLow
.enemyRows
	coord hl, 0, 0
	ld a, h
	ld [H_VBCOPYBGSRC + 1], a
	xor a
.setDestinationLow
	ld [H_VBCOPYBGDEST], a
	ld a, [H_AUTOBGTRANSFERDEST + 1]
	ld [H_VBCOPYBGDEST + 1], a
	ld a, $87 ; 7 rows + bit 7: tile-only, preserve existing CGB attributes
	ld [H_VBCOPYBGNUMROWS], a
	ld a, l
	ld [H_VBCOPYBGSRC], a
	call DelayFrame
	ld c, 1  ; one more frame, total 2 frames like the original
.wait
	call DelayFrames
	pop hl
	pop bc
	dec c
	jp nz, .slideStepLoop
	pop af
	ld [H_AUTOBGTRANSFERENABLED], a
	ret
