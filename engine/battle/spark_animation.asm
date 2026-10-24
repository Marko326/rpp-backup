; ANM-5.61.72: Gold/Crystal Spark port for move #013.
;
; Sequence retained from BattleAnim_Spark:
; - exact LIGHTNING / EXPLOSION sprite tiles and the Thunder Wave / spark-ring OAM;
; - Gold timing: 24-frame opening aura, 1-frame handoff, 6-frame TargetObj setup,
;   16-frame tackle window, 4+1-frame target restore, then 32-frame electric hit;
; - exact Zap Cannon, Spark and Thundershock SFX;
; - RELATIVE_X/fixY mirroring for enemy use.
;
; Gold's Tackle is a scanline BG shift. RPP's Gen1 renderer cannot reproduce that
; mechanism directly, so the already-established Sacred Fire one-tile lunge bridge
; is used while preserving the Gold timing window.

SPARK_LIGHTNING_TILE_BASE EQU $60
SPARK_LIGHTNING_TILE_COUNT EQU 17
SPARK_CORE_TILE_BASE EQU SPARK_LIGHTNING_TILE_BASE + SPARK_LIGHTNING_TILE_COUNT
SPARK_CORE_TILE_COUNT EQU 4

PlayGoldSparkAnimation::
	xor a
	ld [wWhichBattleAnimTileset], a
	callba LoadAnimationTileset

	ld hl, vSprites + SPARK_LIGHTNING_TILE_BASE * 16
	ld de, GoldSparkLightningTiles
	ld b, BANK(GoldSparkLightningTiles)
	ld c, SPARK_LIGHTNING_TILE_COUNT
	call CopyVideoData
	ld hl, vSprites + SPARK_CORE_TILE_BASE * 16
	ld de, GoldSparkCoreTiles
	ld b, BANK(GoldSparkCoreTiles)
	ld c, SPARK_CORE_TILE_COUNT
	call CopyVideoData

	; Use RPP's newer Electric move-type palette for Gold lightning; the
	; Thunderbolt core keeps the stock gray OBJ palette.
	ld d, ELECTRIC
	ld e, BATTLE_TYPE_PAL_TILESET1
	callba LoadBattleAnimTypePalette_Sprite
	ld a, 2
	ld [rSVBK], a
	ld hl, W2_SpritePaletteMap + SPARK_LIGHTNING_TILE_BASE
	ld b, SPARK_LIGHTNING_TILE_COUNT
	ld a, BATTLE_TYPE_PAL_TILESET1
.paletteLightning
	ld [hli], a
	dec b
	jr nz, .paletteLightning
	ld b, SPARK_CORE_TILE_COUNT
	ld a, ATK_PAL_GREY
.paletteCore
	ld [hli], a
	dec b
	jr nz, .paletteCore
	ld a, 1
	ld [W2_ForceOBPUpdate], a
	xor a
	ld [rSVBK], a

	ld a, GSSFX_ZAP_CANNON
	call PlaySound

	; Gold FLASH_INVERTED $0,$4,$3: normal -> inverted -> normal in 5-frame
	; phases. Restore normal BGP before the TargetObj/Tackle handoff.
	xor a
	ld [wSubAnimCounter], a
.openingLoop
	call .UpdateOpeningFlash
	call .DrawThunderWave
	call DelayFrame
	call ClearSprites
	ld hl, wSubAnimCounter
	inc [hl]
	ld a, [hl]
	cp 24
	jr c, .openingLoop
	ld a, $e4
	ld [rBGP], a

	; anim_setobj + anim_wait 1.
	call DelayFrame
	call ClearSprites

	; BattleAnim_TargetObj_1Row contributes six VBlanks before Tackle begins.
	ld c, 6
	call DelayFrames

	callba SacredFireShiftUserForwardNoDelay
	ld a, GSSFX_SPARK
	call PlaySound
	; Keep the established one-tile lunge for the first half of Gold's 16-frame
	; Tackle window, then restore for the second half.
	ld c, 8
	call DelayFrames
	callba SacredFireRestoreUserPositionNoDelay
	ld c, 8
	call DelayFrames

	; Gold SHOW_MON target + wait 4, incobj 2, wait 1.
	ld c, 5
	call DelayFrames

	ld a, GSSFX_THUNDERSHOCK
	call PlaySound
	xor a
	ld [wSubAnimCounter], a
.impactLoop
	ld de, wOAMBuffer
	; Gold THUNDERBOLT_CORE: OAMSET_19 for 2 frames, then oamwait 2, repeat.
	ld a, [wSubAnimCounter]
	and 3
	cp 2
	call c, .DrawImpactCore
	call .DrawSparkCircle
	call DelayFrame
	call ClearSprites
	ld hl, wSubAnimCounter
	inc [hl]
	ld a, [hl]
	cp 32
	jr c, .impactLoop

	xor a
	ld [wSubAnimCounter], a
	callba AnimationResetScreenPalette
	ret

.UpdateOpeningFlash
	; BattleBGEffect_FlashContinue decrements the three-phase counter before
	; selecting the palette, so $0,$4,$3 is normal / inverted / normal.
	ld a, [wSubAnimCounter]
	cp 5
	jr c, .normal
	cp 10
	jr c, .invert
.normal
	ld a, $e4
	ld [rBGP], a
	ret
.invert
	ld a, $1b
	ld [rBGP], a
	ret

.DrawThunderWave
	; Gold BATTLE_ANIM_OBJ_THUNDER_WAVE at logical (48,92), RELATIVE_X |
	; OAM_XFLIP with fixY $90. Frames 0..7/8..15/16..23 use the first
	; 4/16/26 OAMData_3e entries respectively.
	ld a, [H_WHOSETURN]
	and a
	jr nz, .waveEnemy
	ld a, 48
	ld [wBaseCoordX], a
	ld a, 92
	ld [wBaseCoordY], a
	xor a
	ld [wDropletTile], a
	jr .waveCenterReady
.waveEnemy
	ld a, 132 ; 180 - 48
	ld [wBaseCoordX], a
	ld a, 52  ; 144 - 92
	ld [wBaseCoordY], a
	ld a, OAM_HFLIP
	ld [wDropletTile], a
.waveCenterReady
	ld a, [wSubAnimCounter]
	cp 8
	ld b, 4
	jr c, .waveLayout
	cp 16
	ld b, 16
	jr c, .waveLayout
	ld b, 26
.waveLayout
	ld hl, GoldSparkThunderWaveOAM
	ld de, wOAMBuffer
	jp .DrawGoldLayout

.DrawImpactCore
	; BATTLE_ANIM_OBJ_THUNDERBOLT_BALL at logical (136,56), radius 2.
	call .SetImpactCenter
	ld a, [wSubAnimCounter]
	and $1f
	add a
	ld c, a
	ld b, 0
	ld hl, SparkCoreCircleOffsets
	add hl, bc
	ld a, [hl]
	ld c, a
	ld a, [H_WHOSETURN]
	and a
	jr z, .coreXReady
	ld a, c
	cpl
	inc a
	ld c, a ; Gold RELATIVE_X negates XOFFSET for enemy animations.
.coreXReady
	ld a, [wBaseCoordX]
	add c
	ld [wBaseCoordX], a
	inc hl
	ld a, [wBaseCoordY]
	add [hl]
	ld [wBaseCoordY], a
	ld a, [H_WHOSETURN]
	and a
	jr z, .corePlayer
	ld a, OAM_HFLIP ; THUNDERBOLT_BALL is RELATIVE_X | OAM_XFLIP.
	jr .coreFlipReady
.corePlayer
	xor a
.coreFlipReady
	ld [wDropletTile], a
	ld hl, GoldSparkCoreOAM
	ld b, 16
	jp .DrawGoldLayout

.DrawSparkCircle
	call .SetImpactCenter
	ld a, [H_WHOSETURN]
	and a
	jr z, .sparkPlayer
	ld a, OAM_HFLIP
	ld [wDropletTile], a
	jr .sparkFlipReady
.sparkPlayer
	xor a
	ld [wDropletTile], a
.sparkFlipReady
	ld a, [wSubAnimCounter]
	and 7
	cp 4
	ld hl, GoldSparkCircleOAM46
	jr c, .sparkLayout
	ld hl, GoldSparkCircleOAM47
.sparkLayout
	ld b, 4
	jp .DrawGoldLayout

.SetImpactCenter
	ld a, [H_WHOSETURN]
	and a
	jr nz, .impactEnemy
	ld a, 136
	ld [wBaseCoordX], a
	ld a, 56
	ld [wBaseCoordY], a
	ret
.impactEnemy
	ld a, 44 ; 180 - 136
	ld [wBaseCoordX], a
	ld a, 88 ; 144 - 56
	ld [wBaseCoordY], a
	ret

.DrawGoldLayout
	; HL = signed y/x/absolute tile/attr entries, B=count, DE=OAM output.
	; wDropletTile carries object-level H flip.
.layoutLoop
	ld a, [hli]
	ld c, a
	ld a, [wBaseCoordY]
	add c
	ld [de], a
	inc de

	ld a, [hli]
	ld c, a
	ld a, [wDropletTile]
	and OAM_HFLIP
	ld a, c
	jr z, .xReady
	add 8
	cpl
	inc a
.xReady
	ld c, a
	ld a, [wBaseCoordX]
	add c
	ld [de], a
	inc de

	ld a, [hli]
	ld [de], a
	inc de

	ld a, [hli]
	ld c, a
	ld a, [wDropletTile]
	xor c
	ld [de], a
	inc de
	dec b
	jr nz, .layoutLoop
	ret

; OAMData_3e, converted from Gold dbsprite tile units to signed pixel offsets.
GoldSparkThunderWaveOAM:
	; ANM-5.61.72: exact dbsprite Y conversion from Gold OAMData_3e.
	; The prior port dropped part of each tile-row Y term, compressing the lower
	; rows and leaving a visible gap through the middle of the opening current.
	db 12,-16,SPARK_LIGHTNING_TILE_BASE + $00,OAM_VFLIP
	db 12,-8,SPARK_LIGHTNING_TILE_BASE + $02,OAM_VFLIP
	db 12,0,SPARK_LIGHTNING_TILE_BASE + $02,OAM_HFLIP | OAM_VFLIP
	db 12,8,SPARK_LIGHTNING_TILE_BASE + $00,OAM_HFLIP | OAM_VFLIP
	db -4,-24,SPARK_LIGHTNING_TILE_BASE + $09,OAM_HFLIP
	db -4,-16,SPARK_LIGHTNING_TILE_BASE + $08,OAM_HFLIP
	db -4,-8,SPARK_LIGHTNING_TILE_BASE + $06,0
	db -4,0,SPARK_LIGHTNING_TILE_BASE + $07,0
	db -4,8,SPARK_LIGHTNING_TILE_BASE + $08,0
	db -4,16,SPARK_LIGHTNING_TILE_BASE + $09,0
	db 4,-24,SPARK_LIGHTNING_TILE_BASE + $01,OAM_HFLIP
	db 4,-16,SPARK_LIGHTNING_TILE_BASE + $00,OAM_HFLIP
	db 4,-8,SPARK_LIGHTNING_TILE_BASE + $0c,0
	db 4,0,SPARK_LIGHTNING_TILE_BASE + $0d,0
	db 4,8,SPARK_LIGHTNING_TILE_BASE + $00,0
	db 4,16,SPARK_LIGHTNING_TILE_BASE + $01,0
	db -20,-16,SPARK_LIGHTNING_TILE_BASE + $00,0
	db -20,-8,SPARK_LIGHTNING_TILE_BASE + $02,0
	db -20,0,SPARK_LIGHTNING_TILE_BASE + $02,OAM_HFLIP
	db -20,8,SPARK_LIGHTNING_TILE_BASE + $00,OAM_HFLIP
	db -12,-24,SPARK_LIGHTNING_TILE_BASE + $03,OAM_HFLIP
	db -12,-16,SPARK_LIGHTNING_TILE_BASE + $02,OAM_HFLIP
	db -12,-8,SPARK_LIGHTNING_TILE_BASE + $04,0
	db -12,0,SPARK_LIGHTNING_TILE_BASE + $05,0
	db -12,8,SPARK_LIGHTNING_TILE_BASE + $02,0
	db -12,16,SPARK_LIGHTNING_TILE_BASE + $03,0

; Gold OAMData_46 / _47 with OAM-set lightning vtile base $0e folded out.
GoldSparkCircleOAM46:
	db -20,-4,SPARK_LIGHTNING_TILE_BASE + 14 + $02,0
	db 12,-4,SPARK_LIGHTNING_TILE_BASE + 14 + $02,OAM_HFLIP | OAM_VFLIP
	db -4,-20,SPARK_LIGHTNING_TILE_BASE + 14 + $01,0
	db -4,12,SPARK_LIGHTNING_TILE_BASE + 14 + $01,OAM_HFLIP | OAM_VFLIP
GoldSparkCircleOAM47:
	db -16,-16,SPARK_LIGHTNING_TILE_BASE + 14 + $00,OAM_HFLIP
	db -16,8,SPARK_LIGHTNING_TILE_BASE + 14 + $00,0
	db 8,-16,SPARK_LIGHTNING_TILE_BASE + 14 + $00,OAM_HFLIP | OAM_VFLIP
	db 8,8,SPARK_LIGHTNING_TILE_BASE + 14 + $00,OAM_VFLIP

; Gold OAMData_00, with OAMSET_19's explosion vtile base +1 folded into
; GoldSparkCoreTiles (which contains processed explosion tiles #1..#4).
GoldSparkCoreOAM:
	db -16,-16,SPARK_CORE_TILE_BASE + $00,0
	db -16,-8,SPARK_CORE_TILE_BASE + $01,0
	db -8,-16,SPARK_CORE_TILE_BASE + $02,0
	db -8,-8,SPARK_CORE_TILE_BASE + $03,0
	db -16,0,SPARK_CORE_TILE_BASE + $01,OAM_HFLIP
	db -16,8,SPARK_CORE_TILE_BASE + $00,OAM_HFLIP
	db -8,0,SPARK_CORE_TILE_BASE + $03,OAM_HFLIP
	db -8,8,SPARK_CORE_TILE_BASE + $02,OAM_HFLIP
	db 0,-16,SPARK_CORE_TILE_BASE + $02,OAM_VFLIP
	db 0,-8,SPARK_CORE_TILE_BASE + $03,OAM_VFLIP
	db 8,-16,SPARK_CORE_TILE_BASE + $00,OAM_VFLIP
	db 8,-8,SPARK_CORE_TILE_BASE + $01,OAM_VFLIP
	db 0,0,SPARK_CORE_TILE_BASE + $03,OAM_HFLIP | OAM_VFLIP
	db 0,8,SPARK_CORE_TILE_BASE + $02,OAM_HFLIP | OAM_VFLIP
	db 8,0,SPARK_CORE_TILE_BASE + $01,OAM_HFLIP | OAM_VFLIP
	db 8,8,SPARK_CORE_TILE_BASE + $00,OAM_HFLIP | OAM_VFLIP

; Radius-2 circular motion for the core over the first half-turn used by Spark's
; 32-frame wait. Pairs are signed X,Y pixel offsets.
SparkCoreCircleOffsets:
	; Gold builds with RGBASM -Q8. These are the exact d=2 outputs of
	; BattleAnim_Cosine/BattleAnim_Sine for VAR1 angles $00..$1f.
	db  2,0,  1,0,  1,0,  1,0,  1,0,  1,0,  1,1,  1,1
	db  1,1,  1,1,  1,1,  0,1,  0,1,  0,1,  0,1,  0,1
	db  0,2,  0,1,  0,1,  0,1,  0,1,  0,1, -1,1, -1,1
	db -1,1, -1,1, -1,1, -1,0, -1,0, -1,0, -1,0, -1,0

; Exact RGBGFX 2bpp conversion of Gold lightning.png after --remove-whitespace.
; Spark uses processed lightning tiles #0..#16.
GoldSparkLightningTiles:
	db $01,$02,$03,$04,$06,$09,$03,$04,$07,$08,$06,$09,$0c,$12,$18,$64
	db $80,$40,$00,$80,$00,$00,$00,$80,$00,$80,$00,$00,$00,$00,$00,$00
	db $70,$8c,$1c,$e3,$07,$18,$00,$07,$00,$01,$00,$01,$00,$01,$01,$02
	db $00,$00,$00,$80,$80,$70,$f0,$08,$30,$c8,$60,$90,$80,$60,$80,$40
	db $00,$03,$00,$00,$00,$00,$00,$01,$01,$02,$03,$04,$03,$04,$01,$02
	db $c0,$30,$70,$88,$40,$b0,$80,$40,$00,$80,$00,$80,$80,$40,$c0,$20
	db $01,$02,$03,$04,$03,$04,$00,$03,$00,$00,$00,$01,$01,$02,$03,$04
	db $c0,$20,$00,$f8,$f0,$08,$30,$c8,$60,$90,$c0,$20,$80,$40,$00,$80
	db $01,$02,$01,$02,$00,$01,$00,$1f,$0f,$10,$06,$09,$03,$04,$01,$02
	db $00,$80,$80,$40,$c0,$30,$30,$c8,$d8,$24,$70,$88,$00,$f0,$80,$60
	db $00,$01,$00,$01,$01,$02,$03,$04,$03,$04,$01,$02,$01,$02,$00,$01
	db $e0,$10,$60,$90,$c0,$20,$00,$c0,$00,$80,$00,$80,$80,$40,$80,$40
	db $00,$01,$01,$02,$02,$05,$02,$05,$03,$04,$01,$02,$00,$01,$00,$01
	db $80,$40,$80,$40,$00,$80,$00,$00,$00,$80,$80,$40,$80,$40,$80,$40
	db $0f,$00,$3e,$00,$fc,$00,$60,$00,$38,$00,$3c,$00,$3c,$00,$f0,$00
	db $60,$00,$7c,$00,$3f,$00,$93,$00,$d9,$00,$fc,$00,$7e,$00,$00,$00
	db $30,$00,$32,$00,$76,$00,$7f,$00,$73,$00,$67,$00,$2c,$00,$0c,$00
GoldSparkLightningTilesEnd:
	IF GoldSparkLightningTilesEnd - GoldSparkLightningTiles != SPARK_LIGHTNING_TILE_COUNT * 16
		fail "Gold Spark lightning data must contain exactly 17 tiles"
	ENDC

; Exact processed explosion tiles #1..#4 used by THUNDERBOLT_BALL / OAMSET_19.
GoldSparkCoreTiles:
	db $00,$00,$00,$00,$00,$00,$03,$03,$07,$07,$0f,$0f,$1f,$1f,$1f,$1f
	db $0f,$0f,$3f,$3f,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
	db $3f,$3f,$3f,$3f,$7f,$7f,$7f,$7f,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
	db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
GoldSparkCoreTilesEnd:
	IF GoldSparkCoreTilesEnd - GoldSparkCoreTiles != SPARK_CORE_TILE_COUNT * 16
		fail "Gold Spark core data must contain exactly 4 tiles"
	ENDC

; ANM-5.62.29: public asset-only bridge for Volt Tackle. This intentionally
; loads the exact already-verified Gold Spark lightning/core tiles and Electric
; palette without playing Spark's own aura/tackle/impact timeline.
LoadGoldSparkElectricAssets::
	xor a
	ld [wWhichBattleAnimTileset], a
	callba LoadAnimationTileset

	ld hl, vSprites + SPARK_LIGHTNING_TILE_BASE * 16
	ld de, GoldSparkLightningTiles
	ld b, BANK(GoldSparkLightningTiles)
	ld c, SPARK_LIGHTNING_TILE_COUNT
	call CopyVideoData
	ld hl, vSprites + SPARK_CORE_TILE_BASE * 16
	ld de, GoldSparkCoreTiles
	ld b, BANK(GoldSparkCoreTiles)
	ld c, SPARK_CORE_TILE_COUNT
	call CopyVideoData

	ld d, ELECTRIC
	ld e, BATTLE_TYPE_PAL_TILESET1
	callba LoadBattleAnimTypePalette_Sprite
	ld a, 2
	ld [rSVBK], a
	ld hl, W2_SpritePaletteMap + SPARK_LIGHTNING_TILE_BASE
	ld b, SPARK_LIGHTNING_TILE_COUNT
	ld a, BATTLE_TYPE_PAL_TILESET1
.paletteLightning
	ld [hli], a
	dec b
	jr nz, .paletteLightning
	ld b, SPARK_CORE_TILE_COUNT
	ld a, ATK_PAL_GREY
.paletteCore
	ld [hli], a
	dec b
	jr nz, .paletteCore
	ld a, 1
	ld [W2_ForceOBPUpdate], a
	xor a
	ld [rSVBK], a
	ret

; VTA-5.62.43: Volt Tackle reuses the real first 24 frames of Gold Spark's
; Thunder Wave charge before Quick Attack vanishes. No inverted BG flash here:
; the project's prior artificial pre-vanish flicker is intentionally gone.
; Caller must have loaded Gold Spark assets and palette before entering.
PlayGoldSparkVoltTackleCharge::
	ld a,GSSFX_ZAP_CANNON
	call PlaySound
	xor a
	ld [wSubAnimCounter],a
.chargeLoop
	call PlayGoldSparkAnimation.DrawThunderWave
	call DelayFrame
	call ClearSprites
	ld hl,wSubAnimCounter
	inc [hl]
	ld a,[hl]
	cp 24
	jr c,.chargeLoop
	xor a
	ld [wSubAnimCounter],a
	ret
