HandleLedges:
	ld a, [wd736]
	bit 6, a ; already jumping down ledge
	ret nz
	ld a, [wCurMapTileset]
	cp JOHTO_ILEX_FOREST
	jp z, .ilexForest
	cp JOHTO_MODERN
	jp z, .route33
	cp JOHTO
	jr z, .johto
	and a ; Kanto OVERWORLD
	ret nz
	ld hl, LedgeTiles
	jr .checkPairs
.johto
	; RUINS-5.62.224: original Johto tileset also serves Ruins Outside.
	; Its cliff-top graphic $06 is shared with normal terrain, so only
	; reviewed Gold coordinates can trigger a jump. Keep old routes and
	; the original shared HandleLedges executor/animation unchanged.
	ld a, [wCurMap]
	cp REGION_NATIVE_MAP_SLOT
	jr nz, .johtoLegacy
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	ret nz
	ld a, [wCurLocalMapID]
	cp JOHTO_RUINS_OF_ALPH_LOCAL_ID
	ret nz
	ld hl, .ruinsHops
	jp .modernHopLookup
.johtoLegacy
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
	jr z, .route31And32
	cp JOHTO_ROUTE_32
	ret nz
.route31And32
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
	jp .foundMatch
.nextLedgeTile1
	inc hl
.nextLedgeTile2
	inc hl
.nextLedgeTile3
	inc hl
	jr .loop

.ilexForest
	; ILEX-5.62.217: Forest's HOP tile pairs use the original shared dispatcher.
	; User verified all Forest jumps on phone; the .205-.208 failed trials
	; remain recorded in the historical issue, not in active runtime behavior.
	ld hl, JohtoIlexForestLedgeTiles
	jp .checkPairs

.route33
	; Only seven Gold HOP directions; no global modern tile whitelist.
	ld a, [wCurMap]
	cp REGION_NATIVE_MAP_SLOT
	ret nz
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	ret nz
	ld a, [wCurLocalMapID]
	cp JOHTO_ROUTE_33_LOCAL_ID
	jr z, .route33HopTable
	cp JOHTO_AZALEA_TOWN_LOCAL_ID
	ret nz
	ld hl, .azaleaHops
	jr .modernHopLookup
.route33HopTable
	ld hl, .route33Hops
.modernHopLookup
	ld a, [wXCoord]
	ld b, a
	ld a, [wYCoord]
	ld c, a
	ld a, [wPlayerDirection]
	ld d, a
.hopLoop
	ld a, [hli]
	cp $ff
	ret z
	cp b
	jr nz, .skipHopY
	ld a, [hli]
	cp c
	jr nz, .skipHopDirection
	ld a, [hl]
	cp d
	jr z, .matchHop
	inc hl
	jr .hopLoop
.skipHopY
	inc hl
.skipHopDirection
	inc hl
	jr .hopLoop
.matchHop
	; PLAYER_DIR_* is an overworld facing bit, whereas .foundMatch
	; expects the JOYPAD D_* held mask; never mix these two bitfields.
	ld a, d
	cp PLAYER_DIR_LEFT
	ld e, D_LEFT
	jr z, .route33HopReady
	cp PLAYER_DIR_RIGHT
	ld e, D_RIGHT
	jr z, .route33HopReady
	cp PLAYER_DIR_DOWN
	ld e, D_DOWN
	ret nz
.route33HopReady
	jp .foundMatch

.route33Hops
	db 9, 10, PLAYER_DIR_LEFT
	db 9, 11, PLAYER_DIR_LEFT
	db 9, 12, PLAYER_DIR_LEFT
	db 9, 12, PLAYER_DIR_DOWN
	db 10, 12, PLAYER_DIR_DOWN
	db 11, 12, PLAYER_DIR_DOWN
	db 12, 12, PLAYER_DIR_DOWN
	db $ff

; ILEX-5.62.217: all ten Gold Azalea HOP_DOWN takeoffs, including (10,6).
; The jump ends on the SECOND cell. A blocked third cell is not a reason
; to disable a legal jump; the shared ledge executor owns its finish.
.azaleaHops
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
	db $ff

; Ruins Outside: 16 physically valid Gold directed jumps. The upper
; southern cliff (y30) lands on the lower cliff's HOP top (y32), and
; can chain into the second jump (y34 landing). Gold also labels (9,30)
; HOP_DOWN, but its two-cell landing (9,32) is WALL: deliberately DO NOT
; trigger that unsafe candidate. Normal collision blocks the front tile.
.ruinsHops
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
	db $ff

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
	; ILEX-5.62.217: share the original RPP queue with all ledge maps.
	; Queued inputs are not a tile-distance formula; use Gold's two-cell
	; takeoff/landing geometry and the user's phone checks for acceptance.
	ld a, $2
	ld [wSimulatedJoypadStatesIndex], a
	call LoadHoppingShadowOAM
	ld a, SFX_LEDGE
	call PlaySound
	ret

	; (player direction) (tile player standing on) (ledge tile) (input required)
; Forest's original front-tile clones preserve its pixels/palette;
; only the ten Gold HOP approaches have these collision tile IDs.
JohtoIlexForestLedgeTiles:
	db SPRITE_FACING_DOWN,  $05,$40,D_DOWN
	db SPRITE_FACING_LEFT,  $05,$41,D_LEFT
	db SPRITE_FACING_RIGHT, $05,$42,D_RIGHT
	db $FF

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
