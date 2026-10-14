HandleLedges:
	ld a, [wd736]
	bit 6, a ; already jumping down ledge
	ret nz
	ld a, [wCurMapTileset]
	cp JOHTO
	jr z, .johto
	and a ; Kanto OVERWORLD
	ret nz
	ld hl, LedgeTiles
	jr .checkPairs
.johto
	; Routes 29/30 convert Gold cliffs into dedicated
	; RPP collision tile IDs. Use the same tile-pair matching as Kanto.
	ld a, [wCurMap]
	cp JOHTO_ROUTE_29
	jr z, .johtoLedgePairs
	cp JOHTO_ROUTE_30
	jr z, .johtoLedgePairs
	cp JOHTO_VIOLET_CITY
	jr z, .johtoLedgePairs ; Gold Violet has three HOP_DOWN ($06->$21)
	cp JOHTO_ROUTE_31
	ret nz
	ld hl, JohtoRoute31LedgeTiles
	jr .checkPairs
.johtoLedgePairs
	ld hl, JohtoRoute29LedgeTiles
.checkPairs
	push hl ; predef may overwrite the selected tile-pair table pointer
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
	ld a, $2 ; Kanto original hopping simulation for both regions
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

; The Johto map converter reserves $20/$21 as pixel-identical copies
; of $05/$4c for right/down cliff barriers. $3b is already blocked.
; Normal entry into these tiles fails through the RPP passability table,
; while HandleLedges uses the same action/step count as Kanto.
; Shared by Route 29 and Route 30 (including $06 downhill takeoffs).
JohtoRoute29LedgeTiles:
	db SPRITE_FACING_LEFT,  $05,$3B,D_LEFT
	db SPRITE_FACING_RIGHT, $05,$20,D_RIGHT
	db SPRITE_FACING_DOWN,  $05,$21,D_DOWN
	db SPRITE_FACING_DOWN,  $06,$21,D_DOWN ; Route 30 Gold HOP_DOWN
	db $FF

; Route31 adds $06->$30 right hops. The other four pairs are identical.
JohtoRoute31LedgeTiles:
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
