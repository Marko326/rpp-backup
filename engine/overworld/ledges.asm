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
	cp JOHTO_UNION_CAVE
	jp z, .unionCaveB1F
    cp JOHTO_BURNED_TOWER_B1F
    jp z, .burnedTowerB1F
	and a ; original Kanto OVERWORLD
	ret nz
	ld hl, LedgeTiles
	jp .checkPairs
.unionCaveB1F
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	ret nz
	ld a, [wCurLocalMapID]
	cp JOHTO_UNION_CAVE_B1F_LOCAL_ID
	ret nz
	ld hl, JohtoUnionCaveB1FGoldHops
	jp .ruinsCoordinateHopLookup
.burnedTowerB1F
    ld a, [wCurRegion]
    cp MAP_REGION_JOHTO
    ret nz
    ld a, [wCurLocalMapID]
    cp JOHTO_BURNED_TOWER_B1F_LOCAL_ID
    ret nz
    ld hl, JohtoBurnedTowerB1FGoldHops
    jp .ruinsCoordinateHopLookup
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
	cp JOHTO_ROUTE_38_LOCAL_ID
	jp z, .route38Gold
	cp JOHTO_ROUTE_39_LOCAL_ID
	jp z, .route39Gold
	cp JOHTO_ECRUTEAK_CITY_LOCAL_ID
	jp z, .ecruteakGold
    cp JOHTO_MAHOGANY_TOWN_LOCAL_ID
    jp z, .mahoganyGold
    cp JOHTO_ROUTE_43_LOCAL_ID
    jp z, .route43Gold
    cp JOHTO_LAKE_OF_RAGE_LOCAL_ID
    jp z, .lakeOfRageGold
    cp JOHTO_ROUTE_44_LOCAL_ID
    jp z, .route44Gold
    cp JOHTO_BLACKTHORN_CITY_LOCAL_ID
    jp z, .blackthornGold
    cp JOHTO_ROUTE_45_LOCAL_ID
    jp z, .route45Gold
    cp JOHTO_ROUTE_46_LOCAL_ID
    jp z, .route46Gold
	cp JOHTO_RUINS_OF_ALPH_LOCAL_ID
	jr z, .ruinsHopTable
	ret nz
.route37Gold
	ld hl, JohtoRoute37GoldHops
	jp .ruinsCoordinateHopLookup
.route38Gold
	ld hl, JohtoRoute38GoldHops
	jp .ruinsCoordinateHopLookup
.route39Gold
	ld hl, JohtoRoute39GoldHops
	jp .ruinsCoordinateHopLookup
.ecruteakGold
	ld hl, JohtoEcruteakGoldHops
	jp .ruinsCoordinateHopLookup
.mahoganyGold
    ld hl, JohtoMahoganyGoldHops
    jp .ruinsCoordinateHopLookup
.route43Gold
    ld hl, JohtoRoute43GoldHops
    jp .ruinsCoordinateHopLookup
.lakeOfRageGold
    ld hl, JohtoLakeOfRageGoldHops
    jp .ruinsCoordinateHopLookup
.route44Gold
    ld hl, JohtoRoute44GoldHops
    jp .ruinsCoordinateHopLookup
.blackthornGold
    ld hl, JohtoBlackthornGoldHops
    jp .ruinsCoordinateHopLookup
.route45Gold
    ld hl, JohtoRoute45GoldHops
    jp .ruinsCoordinateHopLookup
.route46Gold
    ld hl, JohtoRoute46GoldHops
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

; The sole jump collision bypass gate for Kanto and Johto. wd736.6
; lasts through the visual shadow, but the simulated two-step input may
; already have ended. Only wd730.7 allows a jump collision bypass.
; E=1 rejects the premature real step; E=0 continues the forced jump.
; For active Johto south hops, retain FIX-273's exact landing guard.
JohtoSouthHopLandingGuard::
    ld e, 1
    ld a, [wd730]
    bit 7, a
    ret z ; script ended: lock movement until _HandleMidJump clears wd736.6
    ld e, 0
    ld a, [wCurMap]
    cp JOHTO_RUNTIME_MAP_HANDLE
    ret nz ; Kanto forced hop: stock two moves, then normal collision
    ld a, [wCurRegion]
    cp MAP_REGION_JOHTO
    ret nz
    ld a, [wCurLocalMapID]
    cp JOHTO_ROUTE_33_LOCAL_ID
    jp z, .route33
    cp JOHTO_AZALEA_TOWN_LOCAL_ID
    jp z, .azalea
    cp JOHTO_ROUTE_37_LOCAL_ID
    jp z, .route37
    cp JOHTO_ROUTE_38_LOCAL_ID
    jp z, .route38
    cp JOHTO_ROUTE_39_LOCAL_ID
    jp z, .route39
    cp JOHTO_ECRUTEAK_CITY_LOCAL_ID
    jp z, .ecruteak
    cp JOHTO_MAHOGANY_TOWN_LOCAL_ID
    jp z, .mahogany
    cp JOHTO_ROUTE_43_LOCAL_ID
    jp z, .route43
    cp JOHTO_LAKE_OF_RAGE_LOCAL_ID
    jp z, .lakeOfRage
    cp JOHTO_ROUTE_44_LOCAL_ID
    jp z, .route44
    cp JOHTO_BLACKTHORN_CITY_LOCAL_ID
    jp z, .blackthorn
    cp JOHTO_ROUTE_45_LOCAL_ID
    jp z, .route45
    cp JOHTO_ROUTE_46_LOCAL_ID
    jp z, .route46
    cp JOHTO_UNION_CAVE_B1F_LOCAL_ID
    jp z, .unionCaveB1F
    cp JOHTO_BURNED_TOWER_B1F_LOCAL_ID
    jp z, .burnedTowerB1F
    cp JOHTO_ILEX_FOREST_LOCAL_ID
    ret nz
    ld hl, JohtoIlexForestGoldHops
    jp .scan
.unionCaveB1F
    ld hl, JohtoUnionCaveB1FGoldHops
    jp .scan
.burnedTowerB1F
    ld hl, JohtoBurnedTowerB1FGoldHops
    jp .scan
.route37
    ld hl, JohtoRoute37GoldHops
    jp .scan
.route38
    ld hl, JohtoRoute38GoldHops
    jp .scan
.route39
    ld hl, JohtoRoute39GoldHops
    jp .scan
.ecruteak
    ld hl, JohtoEcruteakGoldHops
    jp .scan
.mahogany
    ld hl, JohtoMahoganyGoldHops
    jp .scan
.route43
    ld hl, JohtoRoute43GoldHops
    jp .scan
.lakeOfRage
    ld hl, JohtoLakeOfRageGoldHops
    jp .scan
.route44
    ld hl, JohtoRoute44GoldHops
    jp .scan
.blackthorn
    ld hl, JohtoBlackthornGoldHops
    jp .scan
.route45
    ld hl, JohtoRoute45GoldHops
    jp .scan
.route46
    ld hl, JohtoRoute46GoldHops
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
JohtoUnionCaveB1FGoldHops:
    db 12, 10, PLAYER_DIR_RIGHT
    db 12, 11, PLAYER_DIR_RIGHT
    db $ff

; Gold Burned Tower B1F directed HOPs (source X,Y,direction).
; HOP_DOWN_LEFT at (15,4) supports both Gold directions.
JohtoBurnedTowerB1FGoldHops:
    db 2, 4, PLAYER_DIR_DOWN
    db 3, 4, PLAYER_DIR_DOWN
    db 4, 4, PLAYER_DIR_DOWN
    db 5, 4, PLAYER_DIR_DOWN
    db 15, 4, PLAYER_DIR_DOWN
    db 15, 4, PLAYER_DIR_LEFT
    db 15, 2, PLAYER_DIR_LEFT
    db 15, 3, PLAYER_DIR_LEFT
    db 17, 6, PLAYER_DIR_LEFT
    db 17, 7, PLAYER_DIR_LEFT
    db 15, 12, PLAYER_DIR_LEFT
    db 15, 13, PLAYER_DIR_LEFT
    db 15, 14, PLAYER_DIR_LEFT
    db 15, 15, PLAYER_DIR_LEFT
    db 4, 12, PLAYER_DIR_RIGHT
    db 4, 13, PLAYER_DIR_RIGHT
    db 4, 14, PLAYER_DIR_RIGHT
    db 4, 15, PLAYER_DIR_RIGHT
    db 8, 8, PLAYER_DIR_DOWN
    db 9, 8, PLAYER_DIR_DOWN
    db 10, 8, PLAYER_DIR_DOWN
    db 11, 8, PLAYER_DIR_DOWN
    db 6, 10, PLAYER_DIR_DOWN
    db 7, 10, PLAYER_DIR_DOWN
    db 8, 10, PLAYER_DIR_DOWN
    db 9, 10, PLAYER_DIR_DOWN
    db 10, 10, PLAYER_DIR_DOWN
    db 11, 10, PLAYER_DIR_DOWN
    db 12, 10, PLAYER_DIR_DOWN
    db 13, 10, PLAYER_DIR_DOWN
    db $ff

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
JohtoRoute38GoldHops:
    db 11, 8, PLAYER_DIR_LEFT
    db 11, 9, PLAYER_DIR_LEFT
    db 6, 10, PLAYER_DIR_RIGHT
    db 11, 10, PLAYER_DIR_LEFT
    db 6, 11, PLAYER_DIR_RIGHT
    db 11, 11, PLAYER_DIR_LEFT
    db 6, 12, PLAYER_DIR_RIGHT
    db 11, 12, PLAYER_DIR_DOWN
    db 11, 12, PLAYER_DIR_LEFT
    db 12, 12, PLAYER_DIR_DOWN
    db 13, 12, PLAYER_DIR_DOWN
    db 14, 12, PLAYER_DIR_DOWN
    db 15, 12, PLAYER_DIR_DOWN
    db 16, 12, PLAYER_DIR_DOWN
    db 17, 12, PLAYER_DIR_DOWN
    db 18, 12, PLAYER_DIR_DOWN
    db 19, 12, PLAYER_DIR_DOWN
    db 20, 12, PLAYER_DIR_DOWN
    db 20, 12, PLAYER_DIR_RIGHT
    db 6, 13, PLAYER_DIR_RIGHT
    db 4, 14, PLAYER_DIR_DOWN
    db 5, 14, PLAYER_DIR_DOWN
    db 6, 14, PLAYER_DIR_DOWN
    db 6, 14, PLAYER_DIR_RIGHT
    db $ff
JohtoRoute39GoldHops:
    db 7, 20, PLAYER_DIR_LEFT
    db 7, 21, PLAYER_DIR_LEFT
    db 7, 22, PLAYER_DIR_DOWN
    db 7, 22, PLAYER_DIR_LEFT
    db 10, 22, PLAYER_DIR_DOWN
    db 11, 22, PLAYER_DIR_DOWN
    db 12, 22, PLAYER_DIR_DOWN
    db 13, 22, PLAYER_DIR_DOWN
    db 7, 24, PLAYER_DIR_DOWN
    db 7, 24, PLAYER_DIR_LEFT
    db 10, 24, PLAYER_DIR_DOWN
    db 11, 24, PLAYER_DIR_DOWN
    db 12, 24, PLAYER_DIR_DOWN
    db 13, 24, PLAYER_DIR_DOWN
    db 7, 26, PLAYER_DIR_DOWN
    db 7, 26, PLAYER_DIR_LEFT
    db 10, 26, PLAYER_DIR_DOWN
    db 11, 26, PLAYER_DIR_DOWN
    db 12, 26, PLAYER_DIR_DOWN
    db 13, 26, PLAYER_DIR_DOWN
    db $ff
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

; Mahogany Town: exact 12 mature Gold directed safe HOP takeoffs.
JohtoMahoganyGoldHops:
    db 5, 4, PLAYER_DIR_DOWN
    db 5, 4, PLAYER_DIR_LEFT
    db 6, 4, PLAYER_DIR_DOWN
    db 8, 4, PLAYER_DIR_DOWN
    db 9, 4, PLAYER_DIR_DOWN
    db 14, 6, PLAYER_DIR_DOWN
    db 15, 6, PLAYER_DIR_DOWN
    db 2, 10, PLAYER_DIR_DOWN
    db 3, 10, PLAYER_DIR_DOWN
    db 10, 10, PLAYER_DIR_DOWN
    db 12, 10, PLAYER_DIR_DOWN
    db 13, 10, PLAYER_DIR_DOWN
    db $ff

; REF-315: original Route43 two east ledge rows; north/south landing audited.
JohtoRoute43GoldHops:
    db 12, 32, PLAYER_DIR_DOWN
    db 13, 32, PLAYER_DIR_DOWN
    db 14, 32, PLAYER_DIR_DOWN
    db 15, 32, PLAYER_DIR_DOWN
    db 12, 34, PLAYER_DIR_DOWN
    db 13, 34, PLAYER_DIR_DOWN
    db 14, 34, PLAYER_DIR_DOWN
    db 15, 34, PLAYER_DIR_DOWN
    db $ff

; Gold Lake of Rage six HOP_DOWN quadrants. Coordinate/facing gating avoids
; making the shared visual block globally jumpable.
JohtoLakeOfRageGoldHops:
    db 4, 28, PLAYER_DIR_DOWN
    db 5, 28, PLAYER_DIR_DOWN
    db 6, 28, PLAYER_DIR_DOWN
    db 4, 30, PLAYER_DIR_DOWN
    db 6, 30, PLAYER_DIR_DOWN
    db 7, 30, PLAYER_DIR_DOWN
    db $ff

; DEV-324: Gold original directed Route44 safe ledge takeoffs.
JohtoRoute44GoldHops:
    db 47, 6, PLAYER_DIR_LEFT
    db 47, 7, PLAYER_DIR_LEFT
    db 47, 8, PLAYER_DIR_LEFT
    db 51, 8, PLAYER_DIR_DOWN
    db 51, 8, PLAYER_DIR_LEFT
    db 52, 8, PLAYER_DIR_DOWN
    db 53, 8, PLAYER_DIR_DOWN
    db 54, 8, PLAYER_DIR_DOWN
    db 55, 8, PLAYER_DIR_DOWN
    db 56, 8, PLAYER_DIR_DOWN
    db 57, 8, PLAYER_DIR_DOWN
    db 47, 9, PLAYER_DIR_LEFT
    db 47, 10, PLAYER_DIR_LEFT
    db 47, 11, PLAYER_DIR_LEFT
    db 47, 12, PLAYER_DIR_DOWN
    db 47, 12, PLAYER_DIR_LEFT
    db 48, 12, PLAYER_DIR_DOWN
    db 50, 12, PLAYER_DIR_DOWN
    db 51, 12, PLAYER_DIR_DOWN
    db 52, 12, PLAYER_DIR_DOWN
    db 53, 12, PLAYER_DIR_DOWN
    db $ff


; DEV-326: exactly Gold Blackthorn City directed takeoff cells.
JohtoBlackthornGoldHops:
    db 34, 10, PLAYER_DIR_DOWN
    db 36, 10, PLAYER_DIR_DOWN
    db 37, 10, PLAYER_DIR_DOWN
    db 34, 14, PLAYER_DIR_DOWN
    db 36, 14, PLAYER_DIR_DOWN
    db 37, 14, PLAYER_DIR_DOWN
    db 10, 16, PLAYER_DIR_DOWN
    db 11, 16, PLAYER_DIR_DOWN
    db 12, 16, PLAYER_DIR_DOWN
    db 14, 16, PLAYER_DIR_DOWN
    db 15, 16, PLAYER_DIR_DOWN
    db 24, 16, PLAYER_DIR_DOWN
    db 25, 16, PLAYER_DIR_DOWN
    db 6, 20, PLAYER_DIR_DOWN
    db 7, 20, PLAYER_DIR_DOWN
    db 8, 20, PLAYER_DIR_DOWN
    db 10, 20, PLAYER_DIR_DOWN
    db 11, 20, PLAYER_DIR_DOWN
    db 16, 20, PLAYER_DIR_DOWN
    db 17, 20, PLAYER_DIR_DOWN
    db 18, 20, PLAYER_DIR_DOWN
    db 22, 20, PLAYER_DIR_DOWN
    db 23, 20, PLAYER_DIR_DOWN
    db 24, 20, PLAYER_DIR_DOWN
    db 25, 20, PLAYER_DIR_DOWN
    db 32, 20, PLAYER_DIR_DOWN
    db 34, 20, PLAYER_DIR_DOWN
    db 35, 20, PLAYER_DIR_DOWN
    db 6, 22, PLAYER_DIR_DOWN
    db 7, 22, PLAYER_DIR_DOWN
    db 8, 22, PLAYER_DIR_DOWN
    db 9, 22, PLAYER_DIR_DOWN
    db 10, 22, PLAYER_DIR_DOWN
    db 11, 22, PLAYER_DIR_DOWN
    db 12, 22, PLAYER_DIR_DOWN
    db 14, 22, PLAYER_DIR_DOWN
    db 15, 22, PLAYER_DIR_DOWN
    db 16, 22, PLAYER_DIR_DOWN
    db 17, 22, PLAYER_DIR_DOWN
    db 18, 22, PLAYER_DIR_DOWN
    db 19, 22, PLAYER_DIR_DOWN
    db 20, 22, PLAYER_DIR_DOWN
    db 21, 22, PLAYER_DIR_DOWN
    db 22, 22, PLAYER_DIR_DOWN
    db 23, 22, PLAYER_DIR_DOWN
    db 24, 22, PLAYER_DIR_DOWN
    db 25, 22, PLAYER_DIR_DOWN
    db $ff


; DEV-328: exact Gold safe directional ledge takeoffs.
JohtoRoute45GoldHops:
    db 10, 8, PLAYER_DIR_DOWN
    db 11, 8, PLAYER_DIR_DOWN
    db 12, 8, PLAYER_DIR_DOWN
    db 13, 8, PLAYER_DIR_DOWN
    db 14, 8, PLAYER_DIR_DOWN
    db 15, 8, PLAYER_DIR_DOWN
    db 10, 12, PLAYER_DIR_DOWN
    db 11, 12, PLAYER_DIR_DOWN
    db 16, 12, PLAYER_DIR_DOWN
    db 17, 12, PLAYER_DIR_DOWN
    db 10, 16, PLAYER_DIR_DOWN
    db 11, 16, PLAYER_DIR_DOWN
    db 16, 18, PLAYER_DIR_DOWN
    db 17, 18, PLAYER_DIR_DOWN
    db 6, 20, PLAYER_DIR_RIGHT
    db 6, 21, PLAYER_DIR_RIGHT
    db 2, 22, PLAYER_DIR_DOWN
    db 3, 22, PLAYER_DIR_DOWN
    db 4, 22, PLAYER_DIR_DOWN
    db 5, 22, PLAYER_DIR_DOWN
    db 6, 22, PLAYER_DIR_DOWN
    db 6, 22, PLAYER_DIR_RIGHT
    db 12, 24, PLAYER_DIR_DOWN
    db 13, 24, PLAYER_DIR_DOWN
    db 2, 28, PLAYER_DIR_DOWN
    db 3, 28, PLAYER_DIR_DOWN
    db 4, 28, PLAYER_DIR_DOWN
    db 5, 28, PLAYER_DIR_DOWN
    db 12, 28, PLAYER_DIR_DOWN
    db 13, 28, PLAYER_DIR_DOWN
    db 7, 32, PLAYER_DIR_LEFT
    db 7, 33, PLAYER_DIR_LEFT
    db 7, 34, PLAYER_DIR_DOWN
    db 7, 34, PLAYER_DIR_LEFT
    db 8, 34, PLAYER_DIR_DOWN
    db 9, 34, PLAYER_DIR_DOWN
    db 10, 34, PLAYER_DIR_DOWN
    db 11, 34, PLAYER_DIR_DOWN
    db 4, 40, PLAYER_DIR_DOWN
    db 5, 40, PLAYER_DIR_DOWN
    db 10, 44, PLAYER_DIR_DOWN
    db 11, 44, PLAYER_DIR_DOWN
    db 12, 44, PLAYER_DIR_DOWN
    db 13, 44, PLAYER_DIR_DOWN
    db 10, 46, PLAYER_DIR_DOWN
    db 11, 46, PLAYER_DIR_DOWN
    db 12, 46, PLAYER_DIR_DOWN
    db 13, 46, PLAYER_DIR_DOWN
    db 9, 50, PLAYER_DIR_LEFT
    db 9, 51, PLAYER_DIR_LEFT
    db 9, 52, PLAYER_DIR_DOWN
    db 9, 52, PLAYER_DIR_LEFT
    db 10, 52, PLAYER_DIR_DOWN
    db 11, 52, PLAYER_DIR_DOWN
    db 12, 52, PLAYER_DIR_DOWN
    db 13, 52, PLAYER_DIR_DOWN
    db 14, 52, PLAYER_DIR_DOWN
    db 15, 52, PLAYER_DIR_DOWN
    db 2, 54, PLAYER_DIR_DOWN
    db 3, 54, PLAYER_DIR_DOWN
    db 8, 58, PLAYER_DIR_DOWN
    db 9, 58, PLAYER_DIR_DOWN
    db 16, 58, PLAYER_DIR_DOWN
    db 17, 58, PLAYER_DIR_DOWN
    db 8, 60, PLAYER_DIR_DOWN
    db 9, 60, PLAYER_DIR_DOWN
    db 2, 62, PLAYER_DIR_DOWN
    db 3, 62, PLAYER_DIR_DOWN
    db 6, 64, PLAYER_DIR_RIGHT
    db 6, 65, PLAYER_DIR_RIGHT
    db 2, 66, PLAYER_DIR_DOWN
    db 3, 66, PLAYER_DIR_DOWN
    db 4, 66, PLAYER_DIR_DOWN
    db 5, 66, PLAYER_DIR_DOWN
    db 6, 66, PLAYER_DIR_DOWN
    db 6, 66, PLAYER_DIR_RIGHT
    db 14, 66, PLAYER_DIR_DOWN
    db 15, 66, PLAYER_DIR_DOWN
    db 16, 66, PLAYER_DIR_DOWN
    db 17, 66, PLAYER_DIR_DOWN
    db 12, 70, PLAYER_DIR_DOWN
    db 13, 70, PLAYER_DIR_DOWN
    db 3, 76, PLAYER_DIR_DOWN
    db 3, 76, PLAYER_DIR_LEFT
    db 4, 76, PLAYER_DIR_DOWN
    db 5, 76, PLAYER_DIR_DOWN
    db 10, 84, PLAYER_DIR_DOWN
    db 11, 84, PLAYER_DIR_DOWN
    db $ff
JohtoRoute46GoldHops:
    db 12, 10, PLAYER_DIR_DOWN
    db 13, 10, PLAYER_DIR_DOWN
    db 14, 10, PLAYER_DIR_DOWN
    db 15, 10, PLAYER_DIR_DOWN
    db 9, 12, PLAYER_DIR_LEFT
    db 9, 13, PLAYER_DIR_LEFT
    db 10, 14, PLAYER_DIR_DOWN
    db 11, 14, PLAYER_DIR_DOWN
    db 2, 18, PLAYER_DIR_DOWN
    db 3, 18, PLAYER_DIR_DOWN
    db 7, 20, PLAYER_DIR_LEFT
    db 7, 21, PLAYER_DIR_LEFT
    db 7, 22, PLAYER_DIR_DOWN
    db 7, 22, PLAYER_DIR_LEFT
    db 8, 22, PLAYER_DIR_DOWN
    db 9, 22, PLAYER_DIR_DOWN
    db 10, 22, PLAYER_DIR_DOWN
    db 11, 22, PLAYER_DIR_DOWN
    db 12, 22, PLAYER_DIR_DOWN
    db 13, 22, PLAYER_DIR_DOWN
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
