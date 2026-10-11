; ANIM-5.62.109: axis-symmetric Horn-weight Twineedle graphics.
; Reuse the accepted Gold-style 2:1 trajectories and size-aware hit centers.
; Enemy art is the same symmetric shape aimed along the reverse trajectory.
; 97/98 per-hit feedback and poison logic are not modified.

TWINEEDLE_TILE_BASE EQU $70
TWINEEDLE_TILE_COUNT EQU 8 ; four 8x8 tiles per needle orientation
TWINEEDLE_FLIGHT_FRAMES EQU 20
TWINEEDLE_IMPACT_FRAMES EQU 4

IF TWINEEDLE_TILE_BASE + TWINEEDLE_TILE_COUNT > $80
	fail "Twineedle projectile OBJ graphics exceed battle animation VRAM"
ENDC

; Center each four-tile projectile about its path coordinate (B=X, C=Y).
; Inputs: H/L = normal offset, DE = next OAM entry.
MACRO TWINEEDLE_OAM_TILE
	ld a,c
	add l
	IF \2
	    sub 8
	ENDC
	ld [de],a
	inc de
	ld a,b
	add h
	IF \1
	    sub 8
	ENDC
	ld [de],a
	inc de
	ld a,\3
	ld [de],a
	inc de
	xor a
	ld [de],a
	inc de
ENDM

PlaySymmetricTwineedleAnimation::
	xor a
	ld [wWhichBattleAnimTileset],a
	callba LoadAnimationTileset
	call .LoadCustomNeedleTiles
	call .CacheEnemyFrontSize

	ld a,GSSFX_CUT
	call PlaySound
	xor a
	ld [wSubAnimCounter],a
.flightLoop
	call .GetFlightCoords
	call .DrawTwinNeedles
	call DelayFrame
	call ClearSprites
	ld hl,wSubAnimCounter
	inc [hl]
	ld a,[hl]
	cp TWINEEDLE_FLIGHT_FRAMES
	jr c,.flightLoop

	ld a,SFX_BATTLE_1E
	call PlaySound
	ld c,TWINEEDLE_IMPACT_FRAMES
.impactLoop
	push bc
	call .DrawTwinImpact
	call DelayFrame
	call ClearSprites
	pop bc
	dec c
	jr nz,.impactLoop
	xor a
	ld [wSubAnimCounter],a
	ld [wBattleAnimStageCarryTimer],a
	ret

.LoadCustomNeedleTiles
	; Eight private OBJ tiles; original Horn Attack / Poison Sting stay intact.
	ld hl,vSprites + TWINEEDLE_TILE_BASE * 16
	ld de,TwineedleCustomNeedleTiles
	ld b,BANK(TwineedleCustomNeedleTiles)
	ld c,TWINEEDLE_TILE_COUNT
	call CopyVideoData
	ld a,2
	ld [rSVBK],a
	ld hl,W2_SpritePaletteMap + TWINEEDLE_TILE_BASE
	ld b,TWINEEDLE_TILE_COUNT
	ld a,ATK_PAL_GREY
.paletteLoop
	ld [hli],a
	dec b
	jr nz,.paletteLoop
	ld a,1
	ld [W2_ForceOBPUpdate],a
	xor a
	ld [rSVBK],a
	ret

.CacheEnemyFrontSize
	; Read the enemy's displayed normal/regional 5x5,6x6,7x7 footprint.
	; Restore the header and wd0b5 before returning.
	ld a,[wd0b5]
	push af
	ld hl,wMonHeader
	ld b,wMonHPicBank + 1 - wMonHeader
.saveHeader
	ld a,[hli]
	push af
	dec b
	jr nz,.saveHeader
	ld a,[wEnemyMonSpecies]
	ld d,a
	ld a,[wEnemyMonForm]
	ld e,a
	callba RegionalFormLoadPokedexHeader
	ld a,[wMonHSpriteDim]
	and $f
	sub 5
	cp 3
	jr c,.sizeReady
	ld a,2
.sizeReady
	ld [wBattleAnimStageCarryTimer],a
	ld hl,wMonHPicBank + 1
	ld b,wMonHPicBank + 1 - wMonHeader
.restoreHeader
	dec hl
	pop af
	ld [hl],a
	dec b
	jr nz,.restoreHeader
	pop af
	ld [wd0b5],a
	ret

.GetFlightCoords
	ld a,[wSubAnimCounter]
	add a
	ld c,a
	ld b,0
	ld a,[H_WHOSETURN]
	and a
	ld hl,TwineedleEnemyFlight
	jr nz,.gotTable
	ld a,[wBattleAnimStageCarryTimer]
	and a
	ld hl,TwineedlePlayerFlight5x5
	jr z,.gotTable
	dec a
	ld hl,TwineedlePlayerFlight6x6
	jr z,.gotTable
	ld hl,TwineedlePlayerFlight7x7
.gotTable
	add hl,bc
	ld a,[hli]
	ld b,a
	ld c,[hl]
	ret

.GetImpactCoords
	ld a,[H_WHOSETURN]
	and a
	jr nz,.targetPlayer
	ld a,[wBattleAnimStageCarryTimer]
	ld e,a
	ld d,0
	ld hl,TwineedleTargetX
	add hl,de
	ld b,[hl]
	ld hl,TwineedleTargetY
	add hl,de
	ld c,[hl]
	ret
.targetPlayer
	ld b,48
	ld c,88
	ret

.DrawTwinNeedles
	ld de,wOAMBuffer
	ld a,[H_WHOSETURN]
	and a
	jr nz,.enemyNeedles
	; Offset vector (+/-3,+/-6) is normal to the Gold-style 2:1 path.
	; Two track center lines remain approximately 13.4 pixels apart.
	ld h,-3
	ld l,-6
	call .DrawPlayerNeedle
	ld h,3
	ld l,6
	jp .DrawPlayerNeedle
.enemyNeedles
	ld h,3
	ld l,6
	call .DrawEnemyNeedle
	ld h,-3
	ld l,-6
	jp .DrawEnemyNeedle

.DrawPlayerNeedle
	TWINEEDLE_OAM_TILE 1,1,TWINEEDLE_TILE_BASE + 0
	TWINEEDLE_OAM_TILE 0,1,TWINEEDLE_TILE_BASE + 1
	TWINEEDLE_OAM_TILE 1,0,TWINEEDLE_TILE_BASE + 2
	TWINEEDLE_OAM_TILE 0,0,TWINEEDLE_TILE_BASE + 3
	ret

.DrawEnemyNeedle
	; Enemy tip faces down-left, with the same balanced profile about its axis.
	TWINEEDLE_OAM_TILE 1,1,TWINEEDLE_TILE_BASE + 4
	TWINEEDLE_OAM_TILE 0,1,TWINEEDLE_TILE_BASE + 5
	TWINEEDLE_OAM_TILE 1,0,TWINEEDLE_TILE_BASE + 6
	TWINEEDLE_OAM_TILE 0,0,TWINEEDLE_TILE_BASE + 7
	ret

.DrawTwinImpact
	call .GetImpactCoords
	ld de,wOAMBuffer
	ld a,[H_WHOSETURN]
	and a
	jr nz,.enemyImpact
	ld h,-3
	ld l,-6
	call .DrawImpactAtOffset
	ld h,3
	ld l,6
	jp .DrawImpactAtOffset
.enemyImpact
	ld h,3
	ld l,6
	call .DrawImpactAtOffset
	ld h,-3
	ld l,-6
	jp .DrawImpactAtOffset

.DrawImpactAtOffset
	ld a,c
	add l
	sub 4
	ld [de],a
	inc de
	ld a,b
	add h
	sub 4
	ld [de],a
	inc de
	ld a,$4d ; existing small hit spark
	ld [de],a
	inc de
	xor a
	ld [de],a
	inc de
	ret

TwineedleTargetX:
	db 132,136,132
TwineedleTargetY:
	db  52, 48, 44

; Accepted 20-frame straight paths (5x5/6x6/7x7 + mirrored enemy),
; each with |rise/run|=0.5. Only the needle silhouette is new.
TwineedlePlayerFlight5x5:
	db  60, 88,  64, 86,  68, 84,  71, 82,  75, 80
	db  79, 79,  83, 77,  87, 75,  90, 73,  94, 71
	db  98, 69, 102, 67, 105, 65, 109, 63, 113, 61
	db 117, 60, 121, 58, 124, 56, 128, 54, 132, 52

TwineedlePlayerFlight6x6:
	db  60, 86,  64, 84,  68, 82,  72, 80,  76, 78
	db  80, 76,  84, 74,  88, 72,  92, 70,  96, 68
	db 100, 66, 104, 64, 108, 62, 112, 60, 116, 58
	db 120, 56, 124, 54, 128, 52, 132, 50, 136, 48

TwineedlePlayerFlight7x7:
	db  60, 80,  64, 78,  68, 76,  71, 74,  75, 72
	db  79, 71,  83, 69,  87, 67,  90, 65,  94, 63
	db  98, 61, 102, 59, 105, 57, 109, 55, 113, 53
	db 117, 52, 121, 50, 124, 48, 128, 46, 132, 44

TwineedleEnemyFlight:
	db 116, 54, 112, 56, 109, 58, 105, 59, 102, 61
	db  98, 63,  95, 65,  91, 67,  87, 68,  84, 70
	db  80, 72,  77, 74,  73, 75,  69, 77,  66, 79
	db  62, 81,  59, 83,  55, 84,  52, 86,  48, 88

; Private 16x32 2bpp sheet: tiles 0-3 player, 4-7 enemy.
TwineedleCustomNeedleTiles:
	INCBIN "gfx/twineedle_projectiles.2bpp"
TwineedleCustomNeedleTilesEnd:
	ASSERT TwineedleCustomNeedleTilesEnd - TwineedleCustomNeedleTiles == TWINEEDLE_TILE_COUNT * 16
