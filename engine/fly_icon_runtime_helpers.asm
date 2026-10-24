; FLY-5.62.73: Keep the original bird's directional sheet for bird Fly users.
; Other Fly users keep Gold's two-frame party icons on the original flight paths.
; Active flight and the Fly-map cursor use the player's gender palette.

LoadFlyMonOverworldGraphics::
	ld a, 1
	ld [wFlyAnimationActive], a
	callba GetSelectedFlyIconSource
	ld a, l ; L = icon class; H = icon bank; DE = graphics pointer
	cp SPRITE_BIRD_M
	jr z, .classicBird
	ld b, h ; CALLBA restores B to the caller's bank, not to the icon bank
	push bc
	push de
	ld hl, vNPCSprites + $80 ; four tiles for facing $8/$c, frame 0
	ld c, 4
	call CopyVideoData
	pop de
	pop bc
	ld hl, $40 ; Gold/party icon's second 16x16 frame
	add hl, de
	ld e, l
	ld d, h
	ld hl, vNPCSprites2 + $80 ; four tiles for walking frame 1
	ld c, 4
	jp CopyVideoData

.classicBird
	; Restore all twelve original tiles, including separate left/right
	; wing poses that Gold's two-frame bird icon cannot provide.
	ld de, BirdSprite
	ld hl, vNPCSprites
	lb bc, BANK(BirdSprite), $0c
	call CopyVideoData
	ld de, BirdSprite + $c0
	ld hl, vNPCSprites2
	lb bc, BANK(BirdSprite), $0c
	jp CopyVideoData

LoadFlyTownMapIcon::
	callba GetSelectedFlyIconSource
	ld b, h
	ld hl, vSprites + $40 ; tiles 4-7 for Fly Map cursor
	ld c, 4
	jp CopyVideoData
