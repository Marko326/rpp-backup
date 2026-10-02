; EGG-A4-5.61.75: Egg Bomb uses Gold/Crystal's dedicated egg graphics, then
; hands off to the exact five-Explosion2 timeline already used by DynamicPunch.
; The projectile deliberately reuses Sludge Bomb's verified Gold throw arc so
; both player/enemy coordinate transforms stay compact and symmetrical.

EGG_BOMB_TILE_BASE    EQU $60
EGG_BOMB_TILE_COUNT   EQU 8
EGG_BOMB_THROW_FRAMES EQU 36

PlayGoldEggBombAnimation::
	; Initialize the ordinary animation palette state, then place only the eight
	; processed egg tiles needed by Gold's Frameset_Egg into private slots.
	xor a
	ld [wWhichBattleAnimTileset], a
	callba LoadAnimationTileset

	ld hl, vSprites + EGG_BOMB_TILE_BASE * 16
	ld de, GoldEggBombTiles
	ld b, BANK(GoldEggBombTiles)
	ld c, EGG_BOMB_TILE_COUNT
	call CopyVideoData

	; Gold itself always uses PAL_BATTLE_OB_GRAY for the egg. Egg Bomb now
	; inherits the acting mon's first type, so color only non-Normal eggs with
	; RPP's dedicated 18-type battle-animation palette. Normal deliberately
	; keeps the original gray egg instead of switching to the warm Normal table.
	ldh a, [H_WHOSETURN]
	and a
	ld a, [wPlayerMoveType]
	jr z, .gotEggType
	ld a, [wEnemyMoveType]
.gotEggType
	cp NORMAL
	jr z, .normalEggPalette
	ld d, a
	ld e, BATTLE_TYPE_PAL_TILESET1
	callba LoadBattleAnimTypePalette_Sprite
	ld c, BATTLE_TYPE_PAL_TILESET1
	jr .mapEggPalette
.normalEggPalette
	ld c, ATK_PAL_GREY
.mapEggPalette
	ld a, 2
	ld [rSVBK], a
	ld hl, W2_SpritePaletteMap + EGG_BOMB_TILE_BASE
	ld b, EGG_BOMB_TILE_COUNT
	ld a, c
.setEggPalette
	ld [hli], a
	dec b
	jr nz, .setEggPalette
	ld a, 1
	ld [W2_ForceOBPUpdate], a
	xor a
	ld [rSVBK], a

	; Option A4: Egg Bomb-only lower-pitch copy of the canonical Ball Toss
	; (约 -2 个半音); actual Poke Ball throws remain unchanged.
	ld a, GSSFX_EGG_BOMB_LAUNCH
	call PlaySound

	; A compact 36-VBlank throw: Gold-style +2 X / -1 Y motion and the already
	; verified amplitude-$10 arc used by Sludge Bomb. The egg tumbles through the
	; exact OAM-set order/durations of Gold Frameset_Egg while travelling.
	ld b, 64
	ld c, 92
	ld hl, GoldSludgeBombThrowOffsets
	xor a
	ld [wSubAnimCounter], a
	ld a, EGG_BOMB_THROW_FRAMES
.throwLoop
	push af
	ld a, b
	add 2
	ld b, a
	dec c
	ld a, [hli]
	ld d, a
	push hl
	push bc
	call .DrawEgg
	call DelayFrame
	call ClearSprites
	pop bc
	pop hl
	ld a, [wSubAnimCounter]
	inc a
	ld [wSubAnimCounter], a
	pop af
	dec a
	jr nz, .throwLoop

	; The projectile is gone before private VRAM $60-$68 is overwritten with
	; explosion graphics. The shared entry explicitly disables fist carry-over.
	jp PlayGoldDynamicPunchExplosionOnly

.DrawEgg
	; B/C = Gold logical base center, D = sine Y offset. Match the same RELATIVE_X
	; fixY=$90 transform used by Gold projectile objects.
	ld a, [H_WHOSETURN]
	and a
	jr nz, .enemyCenter
	ld a, b
	ld [wBaseCoordX], a
	ld a, c
	add d
	ld [wBaseCoordY], a
	jr .chooseFrame
.enemyCenter
	ld a, 180
	sub b
	ld [wBaseCoordX], a
	ld a, 144
	sub c
	add d
	ld [wBaseCoordY], a

.chooseFrame
	; Gold Frameset_Egg is a 24-frame loop:
	;   0A 10, 0B+X 3, 5D+X 3, 0B+XY 3, 0A+Y 2, 0B+Y 1, 5D 1, 0B 1.
	ld a, [wSubAnimCounter]
	cp 24
	jr c, .phaseReady
	sub 24
.phaseReady
	cp 10
	jr c, .frame0A
	cp 13
	jr c, .frame0BX
	cp 16
	jr c, .frame5DX
	cp 19
	jr c, .frame0BXY
	cp 21
	jr c, .frame0AY
	cp 22
	jr c, .frame0BY
	cp 23
	jr c, .frame5D
	jr .frame0B

.frame0A
	xor a
	ld [wDropletTile], a
	ld hl, GoldEggBombOAM0A
	jr .drawLayout
.frame0BX
	ld a, OAM_HFLIP
	ld [wDropletTile], a
	ld hl, GoldEggBombOAM0B
	jr .drawLayout
.frame5DX
	ld a, OAM_HFLIP
	ld [wDropletTile], a
	ld hl, GoldEggBombOAM5D
	jr .drawLayout
.frame0BXY
	ld a, OAM_HFLIP | OAM_VFLIP
	ld [wDropletTile], a
	ld hl, GoldEggBombOAM0B
	jr .drawLayout
.frame0AY
	ld a, OAM_VFLIP
	ld [wDropletTile], a
	ld hl, GoldEggBombOAM0A
	jr .drawLayout
.frame0BY
	ld a, OAM_VFLIP
	ld [wDropletTile], a
	ld hl, GoldEggBombOAM0B
	jr .drawLayout
.frame5D
	xor a
	ld [wDropletTile], a
	ld hl, GoldEggBombOAM5D
	jr .drawLayout
.frame0B
	xor a
	ld [wDropletTile], a
	ld hl, GoldEggBombOAM0B

.drawLayout
	ld de, wOAMBuffer
	ld b, 4
.spriteLoop
	; Frame-level Y flip mirrors the 16x16 quadrant and toggles each tile's flip.
	ld a, [hli]
	ld c, a
	ld a, [wDropletTile]
	and OAM_VFLIP
	jr z, .gotYOffset
	ld a, -8
	sub c
	ld c, a
.gotYOffset
	ld a, [wBaseCoordY]
	add c
	ld [de], a
	inc de

	; Same treatment for X. -8 <-> 0 keeps the four sprite quadrants centered.
	ld a, [hli]
	ld c, a
	ld a, [wDropletTile]
	and OAM_HFLIP
	jr z, .gotXOffset
	ld a, -8
	sub c
	ld c, a
.gotXOffset
	ld a, [wBaseCoordX]
	add c
	ld [de], a
	inc de

	ld a, EGG_BOMB_TILE_BASE
	add [hl]
	inc hl
	ld [de], a
	inc de
	ld a, [hli]
	ld c, a
	ld a, [wDropletTile]
	xor c
	ld [de], a
	inc de
	dec b
	jr nz, .spriteLoop
	ret

; Exact processed Gold OAM sets used by Frameset_Egg.
GoldEggBombOAM0A:
	db -8,-8,0,0
	db -8, 0,0,OAM_HFLIP
	db  0,-8,1,0
	db  0, 0,1,OAM_HFLIP
GoldEggBombOAM0B:
	db -8,-8,2,0
	db -8, 0,3,0
	db  0,-8,4,0
	db  0, 0,5,0
GoldEggBombOAM5D:
	db -8,-8,6,0
	db -8, 0,7,0
	db  0,-8,6,OAM_VFLIP
	db  0, 0,7,OAM_VFLIP

; Exact RGBGFX 2bpp conversion of pokegold gfx/battle_anims/egg.png after
; --remove-whitespace. Only processed tiles 0-7 are referenced by Frameset_Egg;
; cracked/Softboiled-only tiles are intentionally omitted.
GoldEggBombTiles:
	db $00,$00,$03,$03,$07,$04,$0f,$08,$1f,$10,$1f,$10,$3f,$20,$3f,$20
	db $7f,$40,$7f,$40,$7f,$40,$7f,$40,$3f,$20,$3f,$20,$1f,$18,$07,$07
	db $00,$00,$1f,$1f,$3f,$20,$7f,$40,$7f,$40,$7f,$40,$7f,$40,$7f,$40
	db $00,$00,$00,$00,$e0,$e0,$f8,$18,$fc,$04,$fe,$02,$fe,$02,$ff,$01
	db $3f,$20,$3f,$20,$3f,$20,$1f,$10,$1f,$10,$0f,$08,$07,$06,$01,$01
	db $ff,$01,$ff,$01,$fe,$02,$fe,$02,$fc,$04,$f8,$08,$f0,$30,$c0,$c0
	db $00,$00,$00,$00,$03,$03,$0f,$0c,$1f,$10,$3f,$20,$7f,$40,$7f,$40
	db $00,$00,$f0,$f0,$fc,$0c,$fe,$02,$fe,$02,$ff,$01,$ff,$01,$ff,$01
GoldEggBombTilesEnd:
	IF GoldEggBombTilesEnd - GoldEggBombTiles != EGG_BOMB_TILE_COUNT * 16
		fail "Gold Egg Bomb tile data must contain exactly 8 processed tiles"
	ENDC
