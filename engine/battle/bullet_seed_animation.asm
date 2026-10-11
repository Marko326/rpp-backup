; ANIM-5.62.92: Ruby-style Bullet Seed for the narrower GB battle field.
; Reuse Energy Ball's 8x8 green charge-ring tile 6 and OAM/palette helpers.
; Every registered damage hit plays ten overlapping seeds at 5-frame gaps.
; Each seed flies 20 frames, sounds and briefly shakes on impact, then scatters
; upward for 16 frames. Keep established player/enemy target anchors.

BULLET_SEED_TILE_BASE       EQU $70
BULLET_SEED_TILE_COUNT      EQU 1
BULLET_SEED_SEED_COUNT      EQU 10
BULLET_SEED_LAUNCH_GAP      EQU 5
BULLET_SEED_FLIGHT_FRAMES   EQU 20
BULLET_SEED_SCATTER_FRAMES  EQU 16
BULLET_SEED_TOTAL_FRAMES    EQU 81 ; 9 * 5 + 20 + 16

PlayBulletSeedAnimation::
	call .LoadAssets
	; The battle engine calls this entry once for each registered damage hit.
	; Reuse the same burst on *every* invocation, regardless of hit index.
	call .PlayVolley
	; Follow Energy Ball's palette/OAM cleanup; do not leak private tile maps.
	callba _LoadAnimationTilesetPalettes
	ld a,$e4
	ld [rOBP0],a
	ld [rOBP1],a
	xor a
	ld [wSubAnimCounter],a
	ld [wBaseCoordX],a
	ld [wBaseCoordY],a
	ret

.LoadAssets
	xor a
	ld [wWhichBattleAnimTileset],a
	callba LoadAnimationTileset
	; Energy Ball's charge uses tile 6 for an 8x8 green ring. Reuse its
	; actual pixels and palette without rescaling or adding new tile art.
	ld hl,vSprites + BULLET_SEED_TILE_BASE * 16
	ld de,EnergyBallObjectTiles + 6 * 16
	ld b,BANK(EnergyBallObjectTiles)
	ld c,BULLET_SEED_TILE_COUNT
	call CopyVideoData
	; Use the exact Energy Ball greens, with the same bank-2 palette installer.
	ld a,2
	ld [rSVBK],a
	ld hl,BulletSeedGrassPalette
	ld de,W2_SprPaletteData + ATK_PAL_GREEN * 8
	ld bc,8
	call CopyData
	ld hl,W2_SpritePaletteMap + BULLET_SEED_TILE_BASE
	ld a,ATK_PAL_GREEN
	ld [hl],a
	ld a,1
	ld [W2_ForceOBPUpdate],a
	xor a
	ld [rSVBK],a
	ret

.PlayVolley
	ld b,BULLET_SEED_SEED_COUNT
	ld c,BULLET_SEED_TOTAL_FRAMES
.PlayBurst
	; B = seeds to launch, C = duration. Calls and sprite drawing clobber
	; BC, so preserve it around them instead of using shared WRAM state.
	push bc
	callba GoldBattleHorizontalShakeBegin
	pop bc
	xor a
	ld [wSubAnimCounter],a
.frameLoop
	push bc
	call .UpdateShake
	pop bc
	push bc
	call .DrawVolleyFrame
	pop bc
	push bc
	call DelayFrame
	call ClearSprites
	pop bc
	ld hl,wSubAnimCounter
	inc [hl]
	ld a,[hl]
	cp c
	jr c,.frameLoop
	; Ensure neutral Window X reached the VBlank handler before disarming.
	callba GoldBattleHorizontalShakeEnd
	xor a
	ld [wBattleAnimWX],a
	ret

.UpdateShake
	; One small 2-frame twitch for each projectile arrival (age 20).
	; With five frames between seeds, the phase is 5,9,7,7,7 (WX values).
	; Every one of the ten collisions produces the same two-frame twitch.
	ld a,b
	dec a
	ld c,a
	add a
	add a
	add c
	add 2
	ld b,a ; active relative frames = 5 * (count - 1) + 2
	ld a,[wSubAnimCounter]
	sub BULLET_SEED_FLIGHT_FRAMES
	jr c,.neutral
	cp b
	jr nc,.neutral
.phaseLoop
	cp BULLET_SEED_LAUNCH_GAP
	jr c,.phaseReady
	sub BULLET_SEED_LAUNCH_GAP
	jr .phaseLoop
.phaseReady
	and a
	jr z,.leftKick
	dec a
	jr z,.rightKick
.neutral
	ld a,7
	jr .writeWX
.leftKick
	ld a,5
	jr .writeWX
.rightKick
	ld a,9
.writeWX
	ld [wBattleAnimWX],a
	ret

.DrawVolleyFrame
	; Input B = projectile count; DE and BC are clobbered by drawing.
	push bc
	ld de,wOAMBuffer
	xor a
	ld [wBaseCoordY],a ; seed index
.seedLoop
	; Age = global frame - index * 5; skip seeds not yet launched.
	ld a,[wBaseCoordY]
	ld b,a
	add a
	add a
	add b
	ld b,a
	ld a,[wSubAnimCounter]
	sub b
	jr c,.nextSeed
	cp BULLET_SEED_FLIGHT_FRAMES + BULLET_SEED_SCATTER_FRAMES
	jr nc,.nextSeed
	ld [wBaseCoordX],a ; seed age
	cp BULLET_SEED_FLIGHT_FRAMES
	jr nz,.drawSeed
	; Match Ruby's bullet.c: SFX at impact, not at launch.
	push de
	ld a,SFX_BATTLE_1E
	call PlaySound
	pop de
.drawSeed
	call .GetSeedCoords
	ld a,BULLET_SEED_TILE_BASE
	call .DrawSeed
.nextSeed
	ld hl,wBaseCoordY
	inc [hl]
	ld a,[hl]
	pop bc
	cp b
	ret nc
	push bc
	jr .seedLoop

.GetSeedCoords
	ld a,[wBaseCoordX]
	cp BULLET_SEED_FLIGHT_FRAMES
	jr nc,.GetScatterCoords
	; Table entries are already centered on the actual GB user/target anchors.
	; The two sides are not simply mirrored GBA pixels: enemy sprites stand
	; higher, and the targets must meet the established (128,64)/(48,104).
	add a
	ld l,a
	ld h,0
	ld bc,BulletSeedPlayerFlight
	ld a,[H_WHOSETURN]
	and a
	jr z,.haveFlightTable
	ld bc,BulletSeedEnemyFlight
.haveFlightTable
	add hl,bc
	ld a,[hli]
	ld b,a
	ld c,[hl]
	ret

.GetScatterCoords
	; Ruby's seeded Random() dispersal is approximated per projectile by
	; alternating X direction and two horizontal speeds. 16 sine-like Y
	; samples are scaled to 2/3 for the narrower Game Boy viewport.
	ld a,[wBaseCoordX]
	sub BULLET_SEED_FLIGHT_FRAMES
	add a
	ld l,a
	ld h,0
	ld bc,BulletSeedScatterArc
	add hl,bc
	ld a,[hli]
	ld b,a ; positive horizontal distance
	ld c,[hl] ; upward sine height
	ld a,[wBaseCoordY]
	bit 1,a
	jr z,.scatterSpeedReady
	ld a,b
	srl a
	add b
	ld b,a
.scatterSpeedReady
	ld a,[wBaseCoordY]
	bit 0,a
	jr z,.scatterDirectionReady
	ld a,b
	cpl
	inc a
	ld b,a
.scatterDirectionReady
	ld a,[H_WHOSETURN]
	and a
	jr nz,.enemyScatter
	ld a,128
	add b
	ld b,a
	ld a,64
	sub c
	ld c,a
	ret
.enemyScatter
	ld a,48
	add b
	ld b,a
	ld a,104
	sub c
	ld c,a
	ret

.DrawSeed
	; A = Energy Ball charge-ring tile, BC = center, DE = OAM destination.
	; An 8x8 ring needs one sprite instead of the previous four-sprite orb.
	; The coordinates match Energy Ball's own .DrawSingleTile helper.
	ld h,a
	ld a,c
	sub 4
	ld [de],a
	inc de
	ld a,b
	sub 4
	ld [de],a
	inc de
	ld a,h
	ld [de],a
	inc de
	ld a,ATK_PAL_GREEN
	ld [de],a
	inc de
	ret

BulletSeedGrassPalette:
	RGB 31,31,31
	RGB 27,31,5
	RGB 15,31,1
	RGB 9,25,0

; 20-frame linear paths, with 2/3-scale local distances on the GB screen.
; Ruby flies from InitAnimSpritePos(attacker,+20,0) toward target center.
BulletSeedPlayerFlight:
	db  64, 96 ; frame  0
	db  67, 94 ; frame  1
	db  70, 93 ; frame  2
	db  74, 91 ; frame  3
	db  77, 90 ; frame  4
	db  80, 88 ; frame  5
	db  83, 86 ; frame  6
	db  86, 85 ; frame  7
	db  90, 83 ; frame  8
	db  93, 82 ; frame  9
	db  96, 80 ; frame 10
	db  99, 78 ; frame 11
	db 102, 77 ; frame 12
	db 106, 75 ; frame 13
	db 109, 74 ; frame 14
	db 112, 72 ; frame 15
	db 115, 70 ; frame 16
	db 118, 69 ; frame 17
	db 122, 67 ; frame 18
	db 125, 66 ; frame 19

BulletSeedEnemyFlight:
	db 116, 56 ; frame  0
	db 113, 58 ; frame  1
	db 109, 61 ; frame  2
	db 106, 63 ; frame  3
	db 102, 66 ; frame  4
	db  99, 68 ; frame  5
	db  96, 70 ; frame  6
	db  92, 73 ; frame  7
	db  89, 75 ; frame  8
	db  85, 78 ; frame  9
	db  82, 80 ; frame 10
	db  79, 82 ; frame 11
	db  75, 85 ; frame 12
	db  72, 87 ; frame 13
	db  68, 90 ; frame 14
	db  65, 92 ; frame 15
	db  62, 94 ; frame 16
	db  58, 97 ; frame 17
	db  55, 99 ; frame 18
	db  51,102 ; frame 19

; 16-frame half-sine bounce, spread width ~8-12 px (Ruby scaled 2/3).
BulletSeedScatterArc:
	db  0, 0 ; frame  0
	db  1, 2 ; frame  1
	db  2, 4 ; frame  2
	db  3, 6 ; frame  3
	db  4, 8 ; frame  4
	db  4, 9 ; frame  5
	db  5,10 ; frame  6
	db  6,11 ; frame  7
	db  6,11 ; frame  8
	db  7,10 ; frame  9
	db  7, 9 ; frame 10
	db  8, 8 ; frame 11
	db  8, 6 ; frame 12
	db  8, 4 ; frame 13
	db  9, 2 ; frame 14
	db  9, 0 ; frame 15

ASSERT BULLET_SEED_TOTAL_FRAMES == (BULLET_SEED_SEED_COUNT - 1) * BULLET_SEED_LAUNCH_GAP + BULLET_SEED_FLIGHT_FRAMES + BULLET_SEED_SCATTER_FRAMES
