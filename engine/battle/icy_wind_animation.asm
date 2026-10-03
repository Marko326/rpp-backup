; ANM-5.61.81: Gold/Crystal Icy Wind renderer.
; Keeps the original six GrowingSparkle trajectories, Psychic SFX, 155-frame
; timing, BattlerObj_2Row isolation and 64-frame target-band Night Shade wave.
; Sparkle graphics use RPP's Ice-type OBJ palette; geometry and timing follow Gold.

ICY_WIND_SPEED_TILE_BASE EQU $60
ICY_WIND_SPEED_TILE_COUNT EQU 3
ICY_WIND_SPARKLE_LIFETIME EQU 17
ICY_WIND_BATTLER_TILE_BASE EQU $63
ICY_WIND_BATTLER_TILE_COUNT EQU 14 ; packed two-row battler cutout, max 7 columns
ICY_WIND_BATTLER_PAL EQU 4
ICY_WIND_BATTLER_ATTR EQU (1 << OAM_PRIORITY) | (1 << OAM_OBP_NUM) | ICY_WIND_BATTLER_PAL

PlayGoldIcyWindAnimation::
	xor a
	ld [wWhichBattleAnimTileset], a
	callba LoadAnimationTileset

	; Gold's GrowingSparkle only references processed SPEED tiles #0, #1 and #6.
	ld hl, vSprites + ICY_WIND_SPEED_TILE_BASE * 16
	ld de, GoldIcyWindSpeedTiles
	ld b, BANK(GoldIcyWindSpeedTiles)
	ld c, ICY_WIND_SPEED_TILE_COUNT
	call CopyVideoData

	; Keep the Gold geometry but use RPP's newer Ice move-type palette.
	ld d, ICE
	ld e, BATTLE_TYPE_PAL_TILESET1
	callba LoadBattleAnimTypePalette_Sprite
	ld a, 2
	ld [rSVBK], a
	ld hl, W2_SpritePaletteMap + ICY_WIND_SPEED_TILE_BASE
	ld b, ICY_WIND_SPEED_TILE_COUNT
	ld a, BATTLE_TYPE_PAL_TILESET1
.paletteLoop
	ld [hli], a
	dec b
	jr nz, .paletteLoop
	ld a, 1
	ld [W2_ForceOBPUpdate], a
	xor a
	ld [rSVBK], a

	; Mirror the battle tilemap to BG0 while the normal Window remains visible.
	call .StageTargetWaveBG

	ld a, GSSFX_PSYCHIC
	call PlaySound

	; Script frames 0..79: waits/spawns at 8,16,24 then 40,48,56.
	xor a
	ld [wSubAnimCounter], a
.sparklePhase
	call .UpdateGoldHueCycle
	call .QueueBattlerObjTileCopy
	ld a, [wSubAnimCounter]
	cp 77
	call z, .MaskBattlerOverlapInTilemap
	ld de, wOAMBuffer
	call .DrawActiveSparkles
	call DelayFrame
	call ClearSprites
	ld hl, wSubAnimCounter
	inc [hl]
	ld a, [hl]
	cp 80
	jr c, .sparklePhase

	; Gold isolates the user's overlapping two rows before the target wave.
	call .PrepareBattlerObj6
	ld a, SCREEN_HEIGHT_PIXELS
	ld [hWY], a
	ld [rWY], a

	; Gold BATTLE_BG_EFFECT_NIGHT_SHADE with param $08, followed by anim_wait 64.
	call .PlayTargetWave64

	; Restore the masked tilemap while the protection OBJ covers the handoff.
	call .RestoreBattlerOverlapTilemap
	call .RestoreTargetWaveWindow5
	call ClearSprites

	; Restore the shared animation OBJ palette state.
	callba LoadAnimationTilesetPalettes
	xor a
	ld [rSCY], a
	ld [hSCY], a
	ld [wSubAnimCounter], a
	ld a, $e4
	ld [rBGP], a
	ld [rOBP1], a
	callba AnimationResetScreenPalette
	ret

.StageTargetWaveBG
	ld a, LOW(vBGMap0)
	ld [H_AUTOBGTRANSFERDEST], a
	ld a, HIGH(vBGMap0)
	ld [H_AUTOBGTRANSFERDEST + 1], a
	ld a, 1
	ld [H_AUTOBGTRANSFERENABLED], a
	ret

.MaskBattlerOverlapInTilemap
	; Gold BattlerObj_2Row clears exactly these battle-tilemap rectangles.
	ldh a, [H_WHOSETURN]
	and a
	jr nz, .maskEnemyFeet
	coord hl, 2, 6
	lb bc, 2, 6
	jp ClearScreenArea
.maskEnemyFeet
	coord hl, 12, 5
	lb bc, 2, 7
	jp ClearScreenArea

.PrepareBattlerObj6
	; Freeze the staged BG0 and keep Gold's six-frame BattlerObj handoff.
	xor a
	ld [H_AUTOBGTRANSFERENABLED], a
	call .InstallBattlerObjPalette
	ldh a, [H_WHOSETURN]
	and a
	jr nz, .prepareEnemyObj
	call .DrawPlayerHead2Row
	jr .waitBattlerObj6
.prepareEnemyObj
	call .DrawEnemyFeet2Row
.waitBattlerObj6
	ld b, 6
	jp .WaitFramesWithHue

.InstallBattlerObjPalette
	; Mirror the user's BG palette into OBJ slot 4 and route the cutout through OBP1.
	ld a, 2
	ld [rSVBK], a
	ldh a, [H_WHOSETURN]
	and a
	ld hl, W2_BgPaletteData
	jr z, .gotBattlerBGPalette
	ld hl, W2_BgPaletteData + 8
.gotBattlerBGPalette
	ld de, W2_SprPaletteData + ICY_WIND_BATTLER_PAL * 8
	ld bc, 8
	call CopyData

	; $63..$70 is private to the battler cutout; SPEED remains at $60..$62.
	ld hl, W2_SpritePaletteMap + ICY_WIND_BATTLER_TILE_BASE
	ld b, ICY_WIND_BATTLER_TILE_COUNT
	ld a, ICY_WIND_BATTLER_PAL
.battlerPalMapLoop
	ld [hli], a
	dec b
	jr nz, .battlerPalMapLoop
	ld a, 1
	ld [W2_UseOBP1], a
	ld [W2_ForceOBPUpdate], a
	xor a
	ld [rSVBK], a
	ret

.DrawPlayerHead2Row
	; 48x48 back pictures are centered inside the 7x7 battle buffer. Their
	; visible top two rows (source offsets 8/9, 15/16 ... 43/44) were packed here.
	ld b, 6
	ld c, $18               ; screen X 16 + OAM bias 8
	ld d, $40               ; screen Y 48 + OAM bias 16
	ld e, ICY_WIND_BATTLER_TILE_BASE
	jr .DrawBattlerObj2Row

.DrawEnemyFeet2Row
	; Enemy picture rows 5/6 (source offsets 5/6, 12/13 ... 47/48) use the same
	; packed OBJ range, with all seven battle-buffer columns represented.
	ld b, 7
	ld c, $68               ; screen X 96 + OAM bias 8
	ld d, $38               ; screen Y 40 + OAM bias 16
	ld e, ICY_WIND_BATTLER_TILE_BASE

.DrawBattlerObj2Row
	ld hl, wOAMBuffer
.battlerObjColumnLoop
	ld a, d
	ld [hli], a
	ld a, c
	ld [hli], a
	ld a, e
	ld [hli], a
	ld a, ICY_WIND_BATTLER_ATTR
	ld [hli], a

	ld a, d
	add 8
	ld [hli], a
	ld a, c
	ld [hli], a
	ld a, e
	inc a
	ld [hli], a
	ld a, ICY_WIND_BATTLER_ATTR
	ld [hli], a

	ld a, e
	add 2
	ld e, a
	ld a, c
	add 8
	ld c, a
	dec b
	jr nz, .battlerObjColumnLoop
	ret

.QueueBattlerObjTileCopy
	; Pack one protected 2-tile column per VBlank without extending the script.
	; Player: vBackPic 8/9 across 6 columns; enemy: vFrontPic 5/6 across 7.
	ldh a, [H_WHOSETURN]
	and a
	ld b, 6
	jr z, .gotBattlerCopyColumns
	ld b, 7
.gotBattlerCopyColumns
	ld a, [wSubAnimCounter]
	cp b
	jr z, .resumeTargetBGStage
	ret nc
	and a
	jr z, .initBattlerObjCopy

	; Skip the remaining five tiles in the 7-tile source column.
	ld a, [H_VBCOPYSRC]
	add 5 * 16
	ld [H_VBCOPYSRC], a
	jr nc, .queueBattlerObjColumn
	ld a, [H_VBCOPYSRC + 1]
	inc a
	ld [H_VBCOPYSRC + 1], a
	jr .queueBattlerObjColumn

.initBattlerObjCopy
	xor a
	ld [H_AUTOBGTRANSFERENABLED], a
	ldh a, [H_WHOSETURN]
	and a
	ld hl, vBackPic + 8 * 16
	jr z, .gotBattlerObjCopySource
	ld hl, vFrontPic + 5 * 16
.gotBattlerObjCopySource
	ld a, l
	ld [H_VBCOPYSRC], a
	ld a, h
	ld [H_VBCOPYSRC + 1], a
	ld a, LOW(vSprites + ICY_WIND_BATTLER_TILE_BASE * 16)
	ld [H_VBCOPYDEST], a
	ld a, HIGH(vSprites + ICY_WIND_BATTLER_TILE_BASE * 16)
	ld [H_VBCOPYDEST + 1], a
.queueBattlerObjColumn
	ld a, 2
	ld [H_VBCOPYSIZE], a
	ret
.resumeTargetBGStage
	ld a, 1
	ld [H_AUTOBGTRANSFERENABLED], a
	ret

.RestoreBattlerOverlapTilemap
	; Recreate the two rows cleared before the wave.  Battle pictures use a 7x7
	; column-major tile dictionary: +7 moves one tile to the right, +1 one row.
	ldh a, [H_WHOSETURN]
	and a
	jr nz, .restoreEnemyFeet
	coord hl, 2, 6
	ld d, $39               ; $31 + (column 1 * 7) + row 1
	ld e, 6
	jr .restoreBattlerRows
.restoreEnemyFeet
	coord hl, 12, 5
	ld d, 5
	ld e, 7
.restoreBattlerRows
	ld b, 2
.restoreBattlerRowLoop
	ld a, d
	ld c, e
.restoreBattlerTileLoop
	ld [hli], a
	add 7
	dec c
	jr nz, .restoreBattlerTileLoop
	ld a, SCREEN_WIDTH
	sub e
	add l
	ld l, a
	jr nc, .restoreBattlerNoCarry
	inc h
.restoreBattlerNoCarry
	inc d
	dec b
	jr nz, .restoreBattlerRowLoop
	ret

.RestoreTargetWaveWindow5
	; Keep the Window hidden until all three thirds of BG map 1 have been
	; refreshed.  The raster loop has already restored SCY to zero before this
	; handoff, so the normal Window can return without inheriting any wave offset.
	ld a, LOW(vBGMap1)
	ld [H_AUTOBGTRANSFERDEST], a
	ld a, HIGH(vBGMap1)
	ld [H_AUTOBGTRANSFERDEST + 1], a
	ld a, 1
	ld [H_AUTOBGTRANSFERENABLED], a
	ld b, 3
	call .WaitFramesWithHue
	xor a
	ld [hWY], a
	ld b, 2
	jp .WaitFramesWithHue

.WaitFramesWithHue
	ld a, b
	and a
	ret z
.waitLoop
	push bc
	call .UpdateGoldHueCycle
	call DelayFrame
	pop bc
	ld hl, wSubAnimCounter
	inc [hl]
	dec b
	jr nz, .waitLoop
	ret

.UpdateGoldHueCycle
	; Gold ALTERNATE_HUES starts on the normal palette for one update; after
	; that, each next entry lasts three updates and the eight-entry list loops.
	ld a, [wSubAnimCounter]
	and a
	jr nz, .hueAfterFirst
	ld a, $e4
	ld [rBGP], a
	ld [rOBP1], a
	ret
.hueAfterFirst
	dec a
.mod24
	cp 24
	jr c, .hueIndexReady
	sub 24
	jr .mod24
.hueIndexReady
	ld c, a
	ld b, 0
	ld hl, GoldIcyWindHueCycleAfterFirst
	add hl, bc
	ld a, [hl]
	ld [rBGP], a
	ld [rOBP1], a
	ret

.DrawActiveSparkles
	ld hl, GoldIcyWindSparkleSchedule
.scheduleLoop
	ld a, [hli]
	cp $ff
	ret z
	ld b, a                 ; spawn frame
	ld a, [hli]
	ld c, a                 ; logical start Y
	ld a, [wSubAnimCounter]
	sub b
	jr c, .scheduleLoop
	cp ICY_WIND_SPARKLE_LIFETIME
	jr nc, .scheduleLoop
	push hl
	push bc
	call .DrawSparkleAge
	pop bc
	pop hl
	jr .scheduleLoop

.DrawSparkleAge
	; A = age 0..16, C = Gold logical start Y, DE = next OAM slot.
	; DoBattleAnimFrame runs before OAM update in Gold, so the first visible
	; position is already one +4/-2 step from the scripted spawn coordinate.
	push af
	inc a
	add a                    ; 2 * (age + 1)
	ld b, a
	ld a, c
	sub b
	ld [wBaseCoordY], a
	pop af
	push af
	inc a
	add a
	add a                    ; 4 * (age + 1)
	add 64
	ld [wBaseCoordX], a

	ld a, [H_WHOSETURN]
	and a
	jr z, .sparklePlayer
	ld a, [wBaseCoordX]
	ld b, a
	ld a, 180
	sub b
	ld [wBaseCoordX], a
	ld a, [wBaseCoordY]
	ld b, a
	ld a, 144
	sub b
	ld [wBaseCoordY], a
	ld a, OAM_HFLIP
	ld [wDropletTile], a
	jr .sparkleFacingReady
.sparklePlayer
	xor a
	ld [wDropletTile], a
.sparkleFacingReady
	pop af
	cp 4
	jr nc, .largeSparkle
	and 1
	jr z, .smallTile0
	ld hl, GoldIcyWindSmallSparkle1
	jr .smallReady
.smallTile0
	ld hl, GoldIcyWindSmallSparkle0
.smallReady
	ld b, 1
	jp .DrawGoldLayout
.largeSparkle
	ld hl, GoldIcyWindLargeSparkle
	ld b, 4
	jp .DrawGoldLayout

.PlayTargetWave64
	; Reuse RPP's established HBlank-polling path for Gold's per-line SCY wave.
	xor a
	ld hl, wTempPic + $18
	ld bc, SCREEN_HEIGHT_PIXELS
	call FillMemory
	ld hl, wTempPic + $18
	call .BuildInitialWaveBuffer

	ld d, 64
.waveFrame
	call .UpdateGoldHueCycle
	call .RenderTargetWaveFrameForTurn
	ld hl, wSubAnimCounter
	inc [hl]
	dec d
	jr z, .waveDone
	push de
	call .RotateWaveTargetBandInPlace
	pop de
	jr .waveFrame

.waveDone
	xor a
	ld [rSCY], a
	ld [hSCY], a
	ret

.RenderTargetWaveFrameForTurn
	; ANM-5.61.86: RPP keeps the player HUD at Y=56. The upper wave ends
	; at Y=54, so only its +2 peak can sample the first HUD row. Clamp that
	; displayed edge value to +1, then restore the ring before it rotates.
	ldh a, [H_WHOSETURN]
	and a
	jr nz, .renderTargetWave
	ld hl, wTempPic + $18 + $36
	ld a, [hl]
	cp 2
	jr nz, .renderTargetWave
	dec [hl]
	call .RenderTargetWaveFrame
	ld hl, wTempPic + $18 + $36
	inc [hl]
	ret
.renderTargetWave
	jp .RenderTargetWaveFrame

.RenderTargetWaveFrame
	; Entered during VBlank. Follow every visible line through HBlank, exactly as
	; AnimationWavyScreen does. The table is zero outside Gold's target band, so
	; HUD/text rows cannot inherit the target's ±2-pixel offset.
.waitVisible
	ld a, [rLY]
	cp SCREEN_HEIGHT_PIXELS
	jr nc, .waitVisible
.lineLoop
.waitHBlank
	ld a, [rSTAT]
	and $3
	jr nz, .waitHBlank
	ld a, [rLY]
	ld c, a
	cp SCREEN_HEIGHT_PIXELS - 1
	jr z, .frameDone
	; HBlank on line N stages SCY for visible line N+1. Line 0 deliberately
	; stays at baseline zero; from line 1 onward this matches Gold's absolute LY
	; table without ever preloading a frame-wide nonzero SCY in VBlank.
	inc c
	ld b, 0
	ld hl, wTempPic + $18
	add hl, bc
	ld a, [hl]
	ld [rSCY], a
.waitHBlankEnd
	ld a, [rSTAT]
	and $3
	jr z, .waitHBlankEnd
	jr .lineLoop
.frameDone
	; Always enter VBlank at baseline SCY so no per-frame offset can leak into
	; the whole battle field.
	xor a
	ld [rSCY], a
.waitVBlankStart
	; Do not let the next 64-frame iteration re-consume the tail of line 143.
	; Waiting for the VBlank range is safe because LY only has to cross a range,
	; not hit one exact scanline value.
	ld a, [rLY]
	cp SCREEN_HEIGHT_PIXELS
	jr c, .waitVBlankStart
	ret

.BuildInitialWaveBuffer
	; HL = wTempPic+$18. Gold leaves the configured start line at zero while the
	; sine phase advances on every absolute line, then rotates start..end as a ring.
	ld d, h
	ldh a, [H_WHOSETURN]
	and a
	jr nz, .initialLower
	ld e, $01
	ld b, $36               ; Gold writes $01..$36; $00 remains zero.
	ld c, 1
	jr .initialLoop
.initialLower
	ld e, $30
	ld b, $2f               ; Gold writes $30..$5e; $2f remains zero.
	ld c, $30 & 7
.initialLoop
	push bc
	ld b, 0
	ld hl, GoldIcyWindWaveOffsets
	add hl, bc
	ld a, [hl]
	pop bc
	ld [de], a
	inc e
	inc c
	ld a, c
	and 7
	ld c, a
	dec b
	jr nz, .initialLoop
	ret

.RotateWaveTargetBandInPlace
	; Exact Gold WavyScreenFX shift-and-wrap, performed after the visible frame.
	ld hl, wTempPic + $18
	ld d, h
	ldh a, [H_WHOSETURN]
	and a
	jr nz, .rotateLower
	ld l, $00
	ld e, $01
	ld b, $36               ; $36-$00
	jr .rotateReady
.rotateLower
	ld l, $2f
	ld e, $30
	ld b, $2f               ; $5e-$2f
.rotateReady
	ld a, [hl]
	ld c, a
.rotateLoop
	ld a, [de]
	inc de
	ld [hli], a
	dec b
	jr nz, .rotateLoop
	ld a, c
	ld [hl], a
	ret

.DrawGoldLayout
	; HL = signed y/x/absolute tile/attr entries, B=count, DE=OAM output.
	; wDropletTile carries the object-level H flip from RELATIVE_X|OAM_XFLIP.
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

; Spawn times and scripted logical Y coordinates from BattleAnim_IcyWind.
GoldIcyWindSparkleSchedule:
	db 8, 88
	db 16, 80
	db 24, 96
	db 40, 88
	db 48, 80
	db 56, 96
	db $ff

; Frameset_GrowingSparkle: OAMSET_14,15,14,15, then OAMSET_74 for 13 ticks.
; OAMData_0f's first dbsprite is (-4,-4); OAMData_02 is the 2x2 expansion.
GoldIcyWindSmallSparkle0:
	db -4, -4, ICY_WIND_SPEED_TILE_BASE + 0, 0
GoldIcyWindSmallSparkle1:
	db -4, -4, ICY_WIND_SPEED_TILE_BASE + 1, 0
GoldIcyWindLargeSparkle:
	db -8, -8, ICY_WIND_SPEED_TILE_BASE + 2, 0
	db -8,  0, ICY_WIND_SPEED_TILE_BASE + 2, OAM_HFLIP
	db  0, -8, ICY_WIND_SPEED_TILE_BASE + 2, OAM_VFLIP
	db  0,  0, ICY_WIND_SPEED_TILE_BASE + 2, OAM_HFLIP | OAM_VFLIP

; Exact amplitude-2 sine samples for Gold's phase increment $08.
GoldIcyWindWaveOffsets:
	db 0, 1, 2, 1, 0, -1, -2, -1

; BATTLE_BG_EFFECT_ALTERNATE_HUES after its one-frame initial $e4 update.
; Each following palette is held for three updates; the 24-byte run then loops.
GoldIcyWindHueCycleAfterFirst:
	db $f8,$f8,$f8
	db $fc,$fc,$fc
	db $f8,$f8,$f8
	db $e4,$e4,$e4
	db $90,$90,$90
	db $40,$40,$40
	db $90,$90,$90
	db $e4,$e4,$e4

; Exact RGBGFX 2bpp bytes for Gold speed.png processed tiles #0, #1 and #6.
GoldIcyWindSpeedTiles:
	db $00,$00,$00,$10,$00,$10,$10,$28,$38,$c6,$10,$28,$00,$10,$00,$10
	db $00,$00,$00,$00,$00,$10,$10,$00,$38,$44,$10,$00,$00,$10,$00,$00
	db $00,$01,$00,$01,$00,$01,$01,$02,$01,$02,$03,$04,$07,$18,$1f,$e0
GoldIcyWindSpeedTilesEnd:
	IF GoldIcyWindSpeedTilesEnd - GoldIcyWindSpeedTiles != ICY_WIND_SPEED_TILE_COUNT * 16
		fail "Gold Icy Wind speed data must contain exactly 3 tiles"
	ENDC
