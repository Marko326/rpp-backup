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

	; ANM-5.61.94: the upper Gold ring legitimately reaches SCY -1/-2 at LY=0. Prepare the
	; off-screen bottom BG row as blank well before the wave starts so that wrap
	; samples are empty pixels instead of stale VRAM. Only the visible 20 tiles
	; are needed; the ordinary color row-copy path also writes safe attributes.
	ld hl, wTempPic
	ld bc, SCREEN_WIDTH
	ld a, " "
	call FillMemory
	ld a, HIGH(wTempPic)
	ld [H_VBCOPYBGSRC + 1], a
	ld a, LOW(vBGMap0 + 31 * 32)
	ld [H_VBCOPYBGDEST], a
	ld a, HIGH(vBGMap0 + 31 * 32)
	ld [H_VBCOPYBGDEST + 1], a
	ld a, 1
	ld [H_VBCOPYBGNUMROWS], a
	ld a, LOW(wTempPic) ; low byte is nonzero and therefore arms VBlankCopyBgMap
	ld [H_VBCOPYBGSRC], a
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
	call .GetGoldHueCycleValue
	ld [rBGP], a
	ld [rOBP1], a
	ret

.StageGoldHueCycle
	; During the interrupt-driven wave, commit hue only at VBlank so visible
	; scanlines never see the next frame's BGP/OBP1 half-way down the screen.
	call .GetGoldHueCycleValue
	ld [wIcyWindRasterHue], a
	ret

.GetGoldHueCycleValue
	; Gold ALTERNATE_HUES starts on the normal palette for one update; after
	; that, each next entry lasts three updates and the eight-entry list loops.
	ld a, [wSubAnimCounter]
	and a
	jr nz, .hueAfterFirst
	ld a, $e4
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
	; ANM-5.61.94: keep Gold's raw rotating ring separate from the two displayed SCY tables.
	; While one page is consumed by the HBlank ISR, the other can be prepared for
	; the next frame without changing any scanline that is currently being drawn.
	xor a
	ld hl, wIcyWindWaveRaw
	ld bc, SCREEN_HEIGHT_PIXELS
	call FillMemory
	ld hl, wIcyWindWaveRaw
	call .BuildInitialWaveBuffer

	; Prime display frame 0 in page A and frame 1 in page B. The raw ring is then
	; left at frame 2 so every later visible frame can prepare exactly one page.
	ld hl, wIcyWindWaveRaw
	ld de, wIcyWindWaveBufferA
	call .CopyWaveFrameForDisplay
	call .RotateWaveTargetBandInPlace
	ld hl, wIcyWindWaveRaw
	ld de, wIcyWindWaveBufferB
	call .CopyWaveFrameForDisplay
	call .RotateWaveTargetBandInPlace

	; The VBlank handler toggles the page before presenting a frame, so seed it
	; with B to make the first toggle select A. Mode-0 STAT remains disabled until
	; the first target VBlank has atomically selected a complete display page.
	call .StageGoldHueCycle
	ld a, HIGH(wIcyWindWaveBufferB)
	ld [wBattleAnimRasterTableHigh], a
	ld a, 2
	ld [wBattleAnimRasterMode], a
	xor a
	ld [hSCY], a
	ld [rSCY], a
	; Keep the LCD interrupt enabled, but do not arm mode-0 yet: doing that from
	; the animation thread could expose a partial wave in the current frame. The
	; first target VBlank preloads line 0 and then arms mode-0 atomically.
	ld a, [rIE]
	or 1 << LCD_STAT
	ld [rIE], a

	; First VBlank presents frame 0. Frame 1 is already waiting in the other page.
	call .WaitIcyWindVBlank
	ld hl, wSubAnimCounter
	inc [hl]
	call .StageGoldHueCycle
	ld d, 1

.waveFrame
	; Each VBlank atomically switches to the page prepared on the prior frame.
	; Once that happens, the old page is free to receive raw frame D+1.
	call .WaitIcyWindVBlank
	ld a, d
	cp 63
	jr z, .lastWaveFrame
	push de
	call .PrepareNextWaveBuffer
	pop de
	ld hl, wSubAnimCounter
	inc [hl]
	call .StageGoldHueCycle
	inc d
	jr .waveFrame

.lastWaveFrame
	; Keep the fast HBlank path alive for frame 63, but tell the following VBlank
	; to restore baseline SCY and disable mode-0 STAT before a 65th wave can start.
	ld hl, wSubAnimCounter
	inc [hl]
	ld a, 3
	ld [wBattleAnimRasterMode], a
	call .WaitIcyWindVBlank
	xor a
	ld [wBattleAnimRasterTableHigh], a
	ld [rSCY], a
	ld [hSCY], a
	ret

.WaitIcyWindVBlank
	; Do not use DelayFrame here: its OAM hook would disturb the protected battler
	; objects. HBlank/LCD interrupts may wake HALT early, so wait on VBlank's flag.
	ld a, 1
	ld [H_VBLANKOCCURRED], a
.waitVBlank
	halt
	ld a, [H_VBLANKOCCURRED]
	and a
	jr nz, .waitVBlank
	ret

.PrepareNextWaveBuffer
	ld a, [wBattleAnimRasterTableHigh]
	cp HIGH(wIcyWindWaveBufferA)
	ld de, wIcyWindWaveBufferB
	jr z, .gotInactiveWaveBuffer
	ld de, wIcyWindWaveBufferA
.gotInactiveWaveBuffer
	ld hl, wIcyWindWaveRaw
	call .CopyWaveFrameForDisplay
	jp .RotateWaveTargetBandInPlace

.CopyWaveFrameForDisplay
	; HL = raw 144-line table, DE = inactive page. Preserve the page base so the
	; existing HUD/message-box edge rules can be applied only to displayed data.
	push de
	ld bc, SCREEN_HEIGHT_PIXELS
	call CopyData
	pop hl

.ApplyWaveDisplayEdges
	ldh a, [H_WHOSETURN]
	and a
	jr nz, .applyLowerTargetEdge

	; ANM-5.61.95: the enemy front picture reaches Y=55, immediately above the
	; player HUD at Y=56. Keep Y=54 safe from +2 -> Y=56 sampling, then let
	; Y=55 inherit only negative/upward offsets so its last scanline can move
	; without ever pulling the player name's top pixels into the wave.
	ld l, $36
	ld a, [hl]
	ld b, a
	cp 2
	jr nz, .upperEdge54Ready
	dec [hl]
.upperEdge54Ready
	ld a, b
	bit 7, a
	jr nz, .upperEdge55Ready
	xor a
.upperEdge55Ready
	inc l
	ld [hl], a
	ret

.applyLowerTargetEdge
	; RPP's 48x48 back picture reaches Y=95 immediately above the message box.
	; Preserve the raw ring elsewhere, clamp Y=94 +2 to +1 for display, and let
	; Y=95 inherit only negative/upward offsets so it can never sample Y=96+.
	ld l, $5e
	ld a, [hl]
	ld b, a
	cp 2
	jr nz, .lowerEdge94Ready
	dec [hl]
.lowerEdge94Ready
	ld a, b
	bit 7, a
	jr nz, .lowerEdge95Ready
	xor a
.lowerEdge95Ready
	inc l
	ld [hl], a
	ret

.BuildInitialWaveBuffer
	; HL is the page-aligned raw table. Gold leaves the configured start line at
	; zero while the sine phase advances on every absolute line, then rotates the
	; target start..end range as one ring after each displayed frame.
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
	; Exact Gold WavyScreenFX shift-and-wrap on the unclamped raw ring. Keeping
	; this separate from the display pages prevents edge safety clamps from
	; feeding back into later phases.
	ld hl, wIcyWindWaveRaw
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
