HandleLedges:
	ld a, [wd736]
	bit 6, a ; already jumping down ledge
	ret nz
	ld a, [wCurMapTileset]
	cp JOHTO_PILOT
	jr z, .johtoPilot
	and a ; original Kanto OVERWORLD
	ret nz
	ld hl, LedgeTiles
	jr .checkPairs
.johtoPilot
	; Source-audited Route29/30/31 use RPP-native cliff pairs.
	; Route31 has one additional right-hop pair; do not enable globally.
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	ret nz
	ld a, [wCurLocalMapID]
	cp JOHTO_ROUTE_29_LOCAL_ID
	jr z, .supportedJohtoLedges
	cp JOHTO_ROUTE_30_LOCAL_ID
	jr z, .supportedJohtoLedges
	cp JOHTO_ROUTE_31_LOCAL_ID
	ret nz
	ld hl, JohtoPilotRoute31LedgeTiles
	jr .checkPairs
.supportedJohtoLedges
	ld hl, JohtoPilotRoute29LedgeTiles
.checkPairs
	push hl ; predef destroys HL, keep the selected source pair table
	predef GetTileAndCoordsInFrontOfPlayer
	ld a, [wSpriteStateData1 + 9]
	ld b, a
	aCoord 8, 9
	ld c, a
	ld a, [wTileInFrontOfPlayer]
	ld d, a
	pop hl
.loop
	ld a, [hli]
	cp $ff
	ret z
	cp b
	jr nz, .nextLedgeTile1
	ld a, [hli]
	cp c
	jr nz, .nextLedgeTile2
	ld a, [hli]
	cp d
	jr nz, .nextLedgeTile3
	ld a, [hl]
	ld e, a
	jr .foundMatch
.nextLedgeTile1
	inc hl
.nextLedgeTile2
	inc hl
.nextLedgeTile3
	inc hl
	jr .loop
.foundMatch
	ld a, [hJoyHeld]
	and e
	ret z
	ld a, $ff
	ld [wJoyIgnore], a
	ld hl, wd736
	set 6, [hl] ; jumping down ledge
	call StartSimulatingJoypadStates
	ld a, e
	ld [wSimulatedJoypadStatesEnd], a
	ld [wSimulatedJoypadStatesEnd + 1], a
	ld a, $2
	ld [wSimulatedJoypadStatesIndex], a
	call LoadHoppingShadowOAM
	ld a, SFX_LEDGE
	call PlaySound
	ret

	; (player direction) (tile player standing on) (ledge tile) (input required)
LedgeTiles:
	db SPRITE_FACING_DOWN, $2C,$37,D_DOWN
	db SPRITE_FACING_DOWN, $39,$36,D_DOWN
	db SPRITE_FACING_DOWN, $39,$37,D_DOWN
	db SPRITE_FACING_LEFT, $2C,$27,D_LEFT
	db SPRITE_FACING_LEFT, $39,$27,D_LEFT
	db SPRITE_FACING_RIGHT,$2C,$0D,D_RIGHT
	db SPRITE_FACING_RIGHT,$2C,$1D,D_RIGHT
	db SPRITE_FACING_RIGHT,$39,$0D,D_RIGHT
	db $FF

; Exact source-branch Route29 pair mapping for unchanged Johto blockset/tiles.
; $20/$21 are copies of the cliff barriers, not legacy map IDs.
JohtoPilotRoute29LedgeTiles:
	db SPRITE_FACING_LEFT,  $05,$3B,D_LEFT
	db SPRITE_FACING_RIGHT, $05,$20,D_RIGHT
	db SPRITE_FACING_DOWN,  $05,$21,D_DOWN
	db SPRITE_FACING_DOWN,  $06,$21,D_DOWN
	db $FF

; Route31 adds the original Gold/RPP right hop from $06 onto $30.
JohtoPilotRoute31LedgeTiles:
	db SPRITE_FACING_LEFT,  $05,$3B,D_LEFT
	db SPRITE_FACING_RIGHT, $05,$20,D_RIGHT
	db SPRITE_FACING_RIGHT, $06,$30,D_RIGHT
	db SPRITE_FACING_DOWN,  $05,$21,D_DOWN
	db SPRITE_FACING_DOWN,  $06,$21,D_DOWN
	db $FF

LoadHoppingShadowOAM:
	ld hl, vChars1 + $7f0
	ld de, LedgeHoppingShadow
	lb bc, BANK(LedgeHoppingShadow), (LedgeHoppingShadowEnd - LedgeHoppingShadow) / $8
	call CopyVideoDataDouble
	ld a, $9
	lb bc, $54, $48 ; b, c = y, x coordinates of shadow
	ld de, LedgeHoppingShadowOAM
	call WriteOAMBlock
	ret

LedgeHoppingShadow:
	INCBIN "gfx/ledge_hopping_shadow.1bpp"
LedgeHoppingShadowEnd:

LedgeHoppingShadowOAM:
	db $FF,$10,$FF,$20
	db $FF,$40,$FF,$60
