HandleLedges:
	ld a, [wd736]
	bit 6, a ; already jumping down ledge
	ret nz
	ld a, [wCurMapTileset]
	cp JOHTO_MODERN
	jr z, .route33Modern
	cp JOHTO_ILEX_FOREST
	jp z, .ilexForestModern
	cp JOHTO_PILOT
	jr z, .johtoPilot
	and a ; original Kanto OVERWORLD
	ret nz
	ld hl, LedgeTiles
	jp .checkPairs
.route33Modern
	ld a, [wCurLocalMapID]
	cp JOHTO_ROUTE_33_LOCAL_ID
	jp z, .route33Gold
	cp JOHTO_AZALEA_TOWN_LOCAL_ID
	ret nz
	ld hl, JohtoAzaleaGoldHops
	jp .ruinsCoordinateHopLookup
.route33Gold
	ld hl, JohtoRoute33Hops
	jp .ruinsCoordinateHopLookup
.ilexForestModern
	ld a, [wCurLocalMapID]
	cp JOHTO_ILEX_FOREST_LOCAL_ID
	ret nz
	; Accepted .217 Forest: cloned front tile + original shared hop executor.
	ld hl, JohtoIlexForestLedgeTiles
	jp .checkPairs
.johtoPilot
	; Source-audited Route29/30/31/32 and Violet use RPP-native cliff pairs.
	; Route31/32 share the additional right-hop pair; do not enable globally.
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	ret nz
	ld a, [wCurLocalMapID]
	cp JOHTO_ROUTE_29_LOCAL_ID
	jp z, .supportedJohtoLedges
	cp JOHTO_ROUTE_30_LOCAL_ID
	jp z, .supportedJohtoLedges
	; Gold Violet has three HOP_DOWN quadrants using $06 -> $21.
	cp JOHTO_VIOLET_CITY_LOCAL_ID
	jp z, .supportedJohtoLedges
	cp JOHTO_ROUTE_31_LOCAL_ID
	jp z, .route31PairTable
	cp JOHTO_ROUTE_32_LOCAL_ID
	jp z, .route31PairTable
	; MAP-294: coordinate+facing jumps from mature NPC/Gold.
	cp JOHTO_ROUTE_37_LOCAL_ID
	jp z, .route37Gold
	cp JOHTO_ECRUTEAK_CITY_LOCAL_ID
	jp z, .ecruteakGold
	cp JOHTO_RUINS_OF_ALPH_LOCAL_ID
	jr z, .ruinsHopTable
	ret nz
.route37Gold
	ld hl, JohtoRoute37GoldHops
	jp .ruinsCoordinateHopLookup
.ecruteakGold
	ld hl, JohtoEcruteakGoldHops
	jp .ruinsCoordinateHopLookup
.ruinsHopTable
	ld hl, JohtoAlphSouthHops
	jr .ruinsCoordinateHopLookup
.ruinsCoordinateHopLookup
	; Gold source coordinates are 8x8-cell coordinates. The same collision
	; role can describe different safe directions at different locations.
	ld a, [wXCoord]
	ld b, a
	ld a, [wYCoord]
	ld c, a
	ld a, [wPlayerDirection]
	ld d, a
.ruinsHopLoop
	ld a, [hli]
	cp $ff
	ret z
	cp b
	jr nz, .ruinsSkipHopY
	ld a, [hli]
	cp c
	jr nz, .ruinsSkipHopDirection
	ld a, [hl]
	cp d
	jr z, .ruinsHopMatch
	inc hl
	jr .ruinsHopLoop
.ruinsSkipHopY
	inc hl
.ruinsSkipHopDirection
	inc hl
	jr .ruinsHopLoop
.ruinsHopMatch
	; Convert the facing bit to the joypad bit expected by .foundMatch.
	ld a, d
	cp PLAYER_DIR_LEFT
	ld e, D_LEFT
	jr z, .ruinsHopReady
	cp PLAYER_DIR_RIGHT
	ld e, D_RIGHT
	jr z, .ruinsHopReady
	cp PLAYER_DIR_DOWN
	ld e, D_DOWN
	ret nz
.ruinsHopReady
	jp .foundMatch
.route31PairTable
	; Route31/32 preserve the already accepted pair family.
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

; FIX-273: guard a finished two-cell south hop while the shared animation
; still holds wd736.6.  With the current south spatial collision dispatcher,
; a pending simulated direction could otherwise start a THIRD movement through
; trees before _HandleMidJump releases that flag.  This is a compatibility
; guard, NOT a different hop animator/queue. E=1 only at a Gold landing.
JohtoSouthHopLandingGuard::
    ld e, 0
    ld a, [wCurRegion]
    cp MAP_REGION_JOHTO
    ret nz
    ld a, [wCurLocalMapID]
    cp JOHTO_ROUTE_33_LOCAL_ID
    jr z, .route33
    cp JOHTO_AZALEA_TOWN_LOCAL_ID
    jr z, .azalea
    cp JOHTO_ROUTE_37_LOCAL_ID
    jp z, .route37
    cp JOHTO_ECRUTEAK_CITY_LOCAL_ID
    jp z, .ecruteak
    cp JOHTO_ILEX_FOREST_LOCAL_ID
    ret nz
    ld hl, JohtoIlexForestGoldHops
    jp .scan
.route37
    ld hl, JohtoRoute37GoldHops
    jp .scan
.ecruteak
    ld hl, JohtoEcruteakGoldHops
    jp .scan
.route33
    ld hl, JohtoRoute33Hops
    jr .scan
.azalea
    ld hl, JohtoAzaleaGoldHops
.scan
    ld a, [hli]
    cp $ff
    ret z
    ld b, a ; Gold takeoff X
    ld a, [hli]
    ld c, a ; Gold takeoff Y
    ld a, [hli]
    ld d, a ; Gold takeoff facing
    ld a, [wPlayerDirection]
    cp d
    jp nz, .scan
    ld a, d
    cp PLAYER_DIR_DOWN
    jr z, .down
    cp PLAYER_DIR_LEFT
    jr z, .left
    cp PLAYER_DIR_RIGHT
    jp nz, .scan
    inc b
    inc b
    jr .compare
.left
    dec b
    dec b
    jr .compare
.down
    inc c
    inc c
.compare
    ld a, [wXCoord]
    cp b
    jp nz, .scan
    ld a, [wYCoord]
    cp c
    jp nz, .scan
    ld e, 1
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

; Ruins of Alph uses Gold's directed HOP coordinates, not generic tile pairs.
; Some compact graphics/collision tiles are shared by safe and unsafe ledges.
; Keep the Gold source coordinate AND facing direction together so the
; (9,30) HOP_DOWN with a WALL landing at (9,32) remains blocked.
; Gold Route33 one-way HOP coordinates: source tile + direction.
JohtoRoute33Hops:
	db 9, 10, PLAYER_DIR_LEFT
	db 9, 11, PLAYER_DIR_LEFT
	db 9, 12, PLAYER_DIR_LEFT
	db 9, 12, PLAYER_DIR_DOWN
	db 10, 12, PLAYER_DIR_DOWN
	db 11, 12, PLAYER_DIR_DOWN
	db 12, 12, PLAYER_DIR_DOWN
	db $FF

; Exact Gold directed safe hops for the first south batch. A HOP role
; alone must not allow crossing a cliff toward an unsafe landing.
JohtoAzaleaGoldHops:
	db 6, 6, PLAYER_DIR_DOWN
	db 7, 6, PLAYER_DIR_DOWN
	db 8, 6, PLAYER_DIR_DOWN
	db 10, 6, PLAYER_DIR_DOWN
	db 11, 6, PLAYER_DIR_DOWN
	db 28, 10, PLAYER_DIR_DOWN
	db 29, 10, PLAYER_DIR_DOWN
	db 30, 10, PLAYER_DIR_DOWN
	db 32, 10, PLAYER_DIR_DOWN
	db 33, 10, PLAYER_DIR_DOWN
	db $FF

JohtoIlexForestLedgeTiles:
    db SPRITE_FACING_DOWN,  $05, $40, D_DOWN
    db SPRITE_FACING_LEFT,  $05, $41, D_LEFT
    db SPRITE_FACING_RIGHT, $05, $42, D_RIGHT
    db $ff

; Retain the independent Gold-coordinate oracle for regression checking.
JohtoIlexForestGoldHops:
	db 15, 14, PLAYER_DIR_LEFT
	db 15, 15, PLAYER_DIR_LEFT
	db 22, 2, PLAYER_DIR_DOWN
	db 23, 22, PLAYER_DIR_DOWN
	db 23, 22, PLAYER_DIR_LEFT
	db 24, 2, PLAYER_DIR_DOWN
	db 24, 22, PLAYER_DIR_DOWN
	db 25, 2, PLAYER_DIR_DOWN
	db 26, 22, PLAYER_DIR_DOWN
	db 26, 22, PLAYER_DIR_RIGHT
	db $FF

; MAP-294: exact mature NPC Gold-directed safe hop coordinates.
; Do NOT make the five Ecruteak HOP_DOWNs a generic hop-right rule.
JohtoRoute37GoldHops:
    db 12, 2, PLAYER_DIR_DOWN
    db 13, 2, PLAYER_DIR_DOWN
    db 4, 6, PLAYER_DIR_DOWN
    db 5, 6, PLAYER_DIR_DOWN
    db 8, 6, PLAYER_DIR_DOWN
    db 9, 6, PLAYER_DIR_DOWN
    db $ff
JohtoEcruteakGoldHops:
    db 4, 10, PLAYER_DIR_DOWN
    db 5, 10, PLAYER_DIR_DOWN
    db 6, 10, PLAYER_DIR_DOWN
    db 7, 10, PLAYER_DIR_DOWN
    db 8, 10, PLAYER_DIR_DOWN
    db 8, 10, PLAYER_DIR_RIGHT
    db $ff

JohtoAlphSouthHops:
	db 2, 18, PLAYER_DIR_DOWN
	db 5, 30, PLAYER_DIR_DOWN
	db 5, 30, PLAYER_DIR_LEFT
	db 6, 30, PLAYER_DIR_DOWN
	db 7, 30, PLAYER_DIR_DOWN
	db 8, 30, PLAYER_DIR_DOWN
	db 10, 30, PLAYER_DIR_DOWN
	db 10, 30, PLAYER_DIR_RIGHT
	db 2, 32, PLAYER_DIR_DOWN
	db 3, 32, PLAYER_DIR_DOWN
	db 4, 32, PLAYER_DIR_DOWN
	db 5, 32, PLAYER_DIR_DOWN
	db 6, 32, PLAYER_DIR_DOWN
	db 7, 32, PLAYER_DIR_DOWN
	db 8, 32, PLAYER_DIR_DOWN
	db 8, 32, PLAYER_DIR_RIGHT
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
