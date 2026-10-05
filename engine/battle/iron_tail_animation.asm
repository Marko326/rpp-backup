; ANM-5.62.06: Gold-style Iron Tail rear half. Mirror the Window battle scene
; into BG0, keep the target's shared Y=48..55 row stationary as OBJ, and scroll
; only the user's native band with Gold's 32-frame radius-8 WOBBLE_MON pattern.
; HIT_BIG uses the Steel palette and Gold/Crystal Mega Kick impact SFX.

IRON_TAIL_HIT_TILE_BASE      EQU $60
IRON_TAIL_HIT_TILE_COUNT     EQU 4
IRON_TAIL_WOBBLE_FRAMES      EQU 32
IRON_TAIL_IMPACT_FRAME       EQU 16 ; Gold logical contact phase
IRON_TAIL_IMPACT_STAGE_FRAME EQU IRON_TAIL_IMPACT_FRAME - 1
IRON_TAIL_HIT_VISIBLE_END    EQU IRON_TAIL_IMPACT_STAGE_FRAME + 7
IRON_TAIL_RASTER_ACTIVE      EQU 4
IRON_TAIL_RASTER_STOP        EQU 5
IRON_TAIL_TARGET_TILE_BASE   EQU $64
IRON_TAIL_TARGET_TILE_COUNT  EQU 7 ; max: enemy feet row; player head uses 6
IRON_TAIL_TARGET_PAL         EQU 4
IRON_TAIL_TARGET_ATTR        EQU (1 << OAM_OBP_NUM) | IRON_TAIL_TARGET_PAL
; Iron Tail and Icy Wind are mutually exclusive, so reuse Icy Wind's scratch page
; for temporary HUD/target-row tile IDs instead of reserving additional WRAM.

PlayGoldIronTailFinishAnimation::
	xor a
	ld [wWhichBattleAnimTileset], a
	callba LoadAnimationTileset

	; GoldCrunchTiles starts with Cut tile #3, followed by the exact four
	; processed hit.png tiles #0-#3 used by BATTLE_ANIM_FRAMESET_HIT_BIG.
	ld hl, vSprites + IRON_TAIL_HIT_TILE_BASE * 16
	ld de, GoldCrunchTiles + 16
	ld b, BANK(GoldCrunchTiles)
	ld c, IRON_TAIL_HIT_TILE_COUNT
	call CopyVideoData

	; Keep Gold's hit geometry, but recolor these four private slots with RPP's
	; current Steel move-type palette.
	ld d, STEEL
	ld e, BATTLE_TYPE_PAL_TILESET1
	callba LoadBattleAnimTypePalette_Sprite
	ld a, 2
	ld [rSVBK], a
	ld hl, W2_SpritePaletteMap + IRON_TAIL_HIT_TILE_BASE
	ld b, IRON_TAIL_HIT_TILE_COUNT
	ld a, BATTLE_TYPE_PAL_TILESET1
.paletteLoop
	ld [hli], a
	dec b
	jr nz, .paletteLoop
	ld a, 1
	ld [W2_ForceOBPUpdate], a
	xor a
	ld [rSVBK], a

	call .PrepareGoldWobbleDisplay

	; Mode 4 stages one absolute SCX value per display frame. VBlank uses sparse
	; LYC -> HBlank handoffs at Gold's exact band edges, so SCX changes only after
	; the preceding scanline is fully drawn.
	xor a
	ld [wSubAnimCounter], a
	ldh a, [hSCX]
	ld [wBattleAnimRasterTableHigh], a
	ld a, IRON_TAIL_RASTER_ACTIVE
	ld [wBattleAnimRasterMode], a

.frameLoop
	call .StageWobbleSCX

	ld a, [wSubAnimCounter]
	cp IRON_TAIL_IMPACT_STAGE_FRAME
	jr nz, .noImpactSound
	ld a, GSSFX_MEGA_KICK
	call PlaySound
.noImpactSound

	; Gold keeps the target's overlap row stationary as OBJ while the user's full
	; BG band scrolls underneath it. Append HIT_BIG after the protected row.
	ld de, wOAMBuffer
	call .DrawProtectedTargetRow
	ld a, [wSubAnimCounter]
	cp IRON_TAIL_IMPACT_STAGE_FRAME
	jr c, .skipHit
	cp IRON_TAIL_HIT_VISIBLE_END
	jr nc, .skipHit
	call .DrawImpact
.skipHit
	call DelayFrame
	call ClearSprites

	ld hl, wSubAnimCounter
	inc [hl]
	ld a, [hl]
	cp IRON_TAIL_WOBBLE_FRAMES
	jr c, .frameLoop

	; Mode 5 is consumed by the next VBlank, which restores baseline SCX before
	; the stationary target-row OBJ and normal Window are handed back.
	ld a, IRON_TAIL_RASTER_STOP
	ld [wBattleAnimRasterMode], a
	call .RestoreGoldWobbleDisplay
	ret

.PrepareGoldWobbleDisplay
	; The live full-screen Window remains visible throughout setup. BG0 is a private
	; wobble copy, so mask the acting HUD and Gold's protected target row there only.
	xor a
	ld [H_AUTOBGTRANSFERENABLED], a
	ld a, LOW(vBGMap0)
	ld [H_AUTOBGTRANSFERDEST], a
	ld a, HIGH(vBGMap0)
	ld [H_AUTOBGTRANSFERDEST + 1], a
	call .BackupUserHUD
	call .CopyProtectedTargetRowTiles
	call .InstallProtectedTargetPalette
	call .MaskProtectedTargetRow
	call .MaskUserHUD

	; Transfer all three six-row chunks (including CGB attributes) into BG0 while
	; Window still hides every intermediate state.
	ld a, 1
	ld [H_AUTOBGTRANSFERENABLED], a
	call Delay3
	xor a
	ld [H_AUTOBGTRANSFERENABLED], a
	call ClearSprites

	; Keep the wobble on the private full-screen BG copy. Moving WY part-way down
	; is not a crop: Window row 0 would restart there and duplicate upper battle
	; data into the lower half, so hide Window completely during the wobble.
	ld a, SCREEN_HEIGHT_PIXELS
	ld [hWY], a
	ret

.BackupUserHUD
	ldh a, [H_WHOSETURN]
	and a
	jr nz, .backupEnemyHUD
	coord hl, 9, 7
	lb bc, 5, 11
	jr .backupHUDReady
.backupEnemyHUD
	coord hl, 0, 0
	lb bc, 4, 12
.backupHUDReady
	ld de, wIcyWindWaveBufferA
.backupHUDRow
	push bc
.backupHUDColumn
	ld a, [hli]
	ld [de], a
	inc de
	dec c
	jr nz, .backupHUDColumn
	pop bc
	ld a, SCREEN_WIDTH
	sub c
	add l
	ld l, a
	jr nc, .backupHUDNoCarry
	inc h
.backupHUDNoCarry
	dec b
	jr nz, .backupHUDRow
	ret

.RestoreUserHUD
	ldh a, [H_WHOSETURN]
	and a
	jr nz, .restoreEnemyHUD
	coord de, 9, 7
	lb bc, 5, 11
	jr .restoreHUDReady
.restoreEnemyHUD
	coord de, 0, 0
	lb bc, 4, 12
.restoreHUDReady
	ld hl, wIcyWindWaveBufferA
.restoreHUDRow
	push bc
.restoreHUDColumn
	ld a, [hli]
	ld [de], a
	inc de
	dec c
	jr nz, .restoreHUDColumn
	pop bc
	ld a, SCREEN_WIDTH
	sub c
	add e
	ld e, a
	jr nc, .restoreHUDNoCarry
	inc d
.restoreHUDNoCarry
	dec b
	jr nz, .restoreHUDRow
	ret

.CopyProtectedTargetRowTiles
	call .ProtectedTargetIsHidden
	ret nz
	; Gold BATTLEROBJ_1ROW protects the TARGET at the shared Y=48..55 band:
	; player user -> enemy bottom row (7 tiles); enemy user -> player top row
	; (6 visible tiles in the centered 48x48 back picture). Read exact tile IDs.
	ldh a, [H_WHOSETURN]
	and a
	jr nz, .copyPlayerHead
	coord hl, 12, 6
	ld b, 7
	jr .copyProtectedRowReady
.copyPlayerHead
	coord hl, 2, 6
	ld b, 6
.copyProtectedRowReady
	ld de, wIcyWindWaveBufferA + $40
	ld a, LOW(vSprites + IRON_TAIL_TARGET_TILE_BASE * 16)
	ld [H_VBCOPYDEST], a
	ld a, HIGH(vSprites + IRON_TAIL_TARGET_TILE_BASE * 16)
	ld [H_VBCOPYDEST + 1], a
.copyProtectedTile
	ld a, [hl]
	ld [de], a
	inc de
	push bc
	push hl
	push de
	call .SetVBCopySourceFromBattleTile
	ld a, 1
	ld [H_VBCOPYSIZE], a
	call DelayFrame
	pop de
	pop hl
	pop bc
	inc hl
	dec b
	jr nz, .copyProtectedTile
	ret

.SetVBCopySourceFromBattleTile
	; A = signed-BG tile ID. Battle mon IDs are positive and live at $9000 + A*16.
	ld c, a
	and $0f
	swap a
	ld [H_VBCOPYSRC], a
	ld a, c
	and $f0
	swap a
	add HIGH(vFrontPic)
	ld [H_VBCOPYSRC + 1], a
	ret

.InstallProtectedTargetPalette
	call .ProtectedTargetIsHidden
	ret nz
	; Mirror the TARGET's current BG palette into private OBJ slot 4.
	ld a, 2
	ld [rSVBK], a
	ldh a, [H_WHOSETURN]
	and a
	ld hl, W2_BgPaletteData + 8
	jr z, .gotTargetPalette
	ld hl, W2_BgPaletteData
.gotTargetPalette
	ld de, W2_SprPaletteData + IRON_TAIL_TARGET_PAL * 8
	ld bc, 8
	call CopyData
	ld hl, W2_SpritePaletteMap + IRON_TAIL_TARGET_TILE_BASE
	ld b, IRON_TAIL_TARGET_TILE_COUNT
	ld a, IRON_TAIL_TARGET_PAL
.targetPaletteMapLoop
	ld [hli], a
	dec b
	jr nz, .targetPaletteMapLoop
	ld a, 1
	ld [W2_UseOBP1], a
	ld [W2_ForceOBPUpdate], a
	xor a
	ld [rSVBK], a
	ret

.MaskProtectedTargetRow
	call .ProtectedTargetIsHidden
	ret nz
	ldh a, [H_WHOSETURN]
	and a
	jr nz, .maskPlayerHead
	coord hl, 12, 6
	lb bc, 1, 7
	jp ClearScreenArea
.maskPlayerHead
	coord hl, 2, 6
	lb bc, 1, 6
	jp ClearScreenArea

.RestoreProtectedTargetRow
	call .ProtectedTargetIsHidden
	ret nz
	ldh a, [H_WHOSETURN]
	and a
	jr nz, .restorePlayerHead
	coord de, 12, 6
	ld b, 7
	jr .restoreProtectedRowReady
.restorePlayerHead
	coord de, 2, 6
	ld b, 6
.restoreProtectedRowReady
	ld hl, wIcyWindWaveBufferA + $40
.restoreProtectedTile
	ld a, [hli]
	ld [de], a
	inc de
	dec b
	jr nz, .restoreProtectedTile
	ret

.ProtectedTargetIsHidden
	; Match Gold BattlerObj_1Row's Fly/Dig guard. Return NZ when target is hidden.
	ldh a, [H_WHOSETURN]
	and a
	ld a, [wEnemyBattleStatus1]
	jr z, .checkProtectedTargetHidden
	ld a, [wPlayerBattleStatus1]
.checkProtectedTargetHidden
	and 1 << Invulnerable
	ret

.MaskUserHUD
	; Clear only the acting HUD in the private BG0 source. The live Window map is
	; never modified, and exact tile IDs are restored from scratch afterwards.
	ldh a, [H_WHOSETURN]
	and a
	jr nz, .maskEnemyUserHUD
	coord hl, 9, 7
	lb bc, 5, 11
	jp ClearScreenArea
.maskEnemyUserHUD
	coord hl, 0, 0
	lb bc, 4, 12
	jp ClearScreenArea

.RestoreGoldWobbleDisplay
	; Keep Gold's stationary target protection row present through the VBlank in
	; which mode 5 restores baseline SCX.
	ld de, wOAMBuffer
	call .DrawProtectedTargetRow
	call DelayFrame
	call ClearSprites

	; vBGMap1 was never touched during wobble. Restore only the WRAM source, point
	; normal auto-transfer back at Window, and reveal it atomically next VBlank.
	call .RestoreProtectedTargetRow
	call .RestoreUserHUD
	ld a, LOW(vBGMap1)
	ld [H_AUTOBGTRANSFERDEST], a
	ld a, HIGH(vBGMap1)
	ld [H_AUTOBGTRANSFERDEST + 1], a
	ld a, 1
	ld [H_AUTOBGTRANSFERENABLED], a
	callba LoadAnimationTilesetPalettes
	xor a
	ld [hWY], a
	call ClearSprites
	call DelayFrame
	ret

.DrawProtectedTargetRow
	call .ProtectedTargetIsHidden
	ret nz
	ldh a, [H_WHOSETURN]
	and a
	jr nz, .drawPlayerHead
	ld b, 7
	ld c, $68 ; enemy screen X 96 + OAM bias 8
	jr .drawProtectedSetup
.drawPlayerHead
	ld b, 6
	ld c, $18 ; player screen X 16 + OAM bias 8
.drawProtectedSetup
	ld h, $40 ; shared row screen Y 48 + OAM bias 16
	ld l, IRON_TAIL_TARGET_TILE_BASE
.drawProtectedLoop
	ld a, h
	ld [de], a
	inc de
	ld a, c
	ld [de], a
	inc de
	ld a, l
	ld [de], a
	inc de
	ld a, IRON_TAIL_TARGET_ATTR
	ld [de], a
	inc de
	inc l
	ld a, c
	add 8
	ld c, a
	dec b
	jr nz, .drawProtectedLoop
	ret

.GetWobbleOffset
	ld a, [wSubAnimCounter]
	and $0f
	ld e, a
	ld d, 0
	ld hl, GoldIronTailWobbleOffsets
	add hl, de
	ld a, [hl]
	ret

.StageWobbleSCX
	call .GetWobbleOffset
	ld e, a
	ldh a, [hSCX]
	add e
	ld [wBattleAnimRasterTableHigh], a
	ret

.DrawImpact
	; Gold Iron Tail uses HIT_BIG_YFIX at logical (136,48), not (144,48).
	ld a, [H_WHOSETURN]
	and a
	jr nz, .enemyImpact
	ld a, 136
	ld [wBaseCoordX], a
	ld a, 48
	jr .coordReady
.enemyImpact
	ld a, 44 ; 180 - 136
	ld [wBaseCoordX], a
	ld a, 88 ; 48 + 5 tiles for fixY $ff
.coordReady
	ld [wBaseCoordY], a
	ld a, IRON_TAIL_HIT_TILE_BASE
	ld [wDropletTile], a
	ld hl, GoldCrunchHitBigOAM
	ld b, 16
.drawLoop
	ld a, [wBaseCoordY]
	add [hl]
	inc hl
	ld [de], a
	inc de
	ld a, [wBaseCoordX]
	add [hl]
	inc hl
	ld [de], a
	inc de
	ld a, [wDropletTile]
	add [hl]
	inc hl
	ld [de], a
	inc de
	ld a, [hli]
	ld [de], a
	inc de
	dec b
	jr nz, .drawLoop
	ret

GoldIronTailWobbleOffsets:
	db 0, 3, 5, 7, 8, 7, 5, 3
	db 0,-3,-5,-7,-8,-7,-5,-3
GoldIronTailWobbleOffsetsEnd:
	IF GoldIronTailWobbleOffsetsEnd - GoldIronTailWobbleOffsets != 16
		fail "Gold Iron Tail wobble table must contain exactly 16 frames"
	ENDC
