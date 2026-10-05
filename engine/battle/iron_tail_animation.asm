; ANM-5.62.07: full Gold/Crystal Iron Tail timeline.
; The opening reproduces TargetObj_1Row + Metallic (Rage/Shine, user-only
; fade-to-black, two exact Harden/Reflect objects), then hands off unchanged to
; the verified target-row-protected 32-frame WOBBLE_MON + HIT_BIG rear half.

IRON_TAIL_REFLECT_TILE_BASE  EQU $60
IRON_TAIL_REFLECT_TILE_COUNT EQU 2
IRON_TAIL_REFLECT_PAL         EQU ATK_PAL_GREY
IRON_TAIL_METALLIC_BG_PAL    EQU 5
IRON_TAIL_HIT_TILE_BASE      EQU $60
IRON_TAIL_HIT_TILE_COUNT     EQU 4
IRON_TAIL_TARGETOBJ_FRAMES   EQU 19 ; Gold battlergfx_2row (13) + TargetObj wait (6)
IRON_TAIL_METALLIC_FRAMES    EQU 104
IRON_TAIL_HARDEN_1_START     EQU 8
IRON_TAIL_HARDEN_2_START     EQU 40
IRON_TAIL_HARDEN_LIFETIME    EQU 26
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
; for temporary HUD/target-row IDs and one saved BG palette instead of reserving WRAM.

PlayGoldIronTailAnimation::
	xor a
	ld [wWhichBattleAnimTileset], a
	callba LoadAnimationTileset

	; Gold starts with REFLECT gfx and OBP0=$00. HARDEN only uses processed tiles
	; #0/#1, so reuse Iron Tail's private $60/$61 slots and overwrite them with
	; HIT_BIG only after Metallic has completely finished.
	ld hl, vSprites + IRON_TAIL_REFLECT_TILE_BASE * 16
	ld de, GoldIronTailReflectTiles
	ld b, BANK(GoldIronTailReflectTiles)
	ld c, IRON_TAIL_REFLECT_TILE_COUNT
	call CopyVideoData
	call .SetReflectTilePalette
	call .BackupOBP0AndSetReflect

	; Prepare a private BG0 battle scene behind the live Window, then preserve
	; Gold's exact Rage -> Metallic gap. anim_battlergfx_2row spends 13 VBlanks
	; copying two battler rows and TargetObj_1Row waits another 6 frames. RPP only
	; needs the protected row, but keeps all 19 script frames for the same cadence.
	call .PrepareGoldIntro
	ld a, GSSFX_RAGE
	call PlaySound
	call .WaitGoldTargetObj19

	; BattleAnimSub_Metallic starts immediately after TargetObj_1Row. Hide Window
	; atomically on Metallic frame 0; all protected target tiles are already ready.
	ld a, SCREEN_HEIGHT_PIXELS
	ld [hWY], a
	call ClearSprites
	ld a, GSSFX_SHINE
	call PlaySound
	call .PlayMetallic
	call .WaitAndHandoffProtectedTarget

	; Gold loads HIT gfx after the four-frame pause. Keep the stationary target
	; row queued across CopyVideoData's VBlank so there is no one-frame hole while
	; $60/$61 are replaced by HIT_BIG tiles. OBP0 was restored on the handoff
	; frame, after the last HARDEN object had already expired.
	ld de, wOAMBuffer
	call .DrawProtectedTargetRow
	call .LoadHitTilesAndPalette
	call ClearSprites

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

.PrepareGoldIntro
	xor a
	ld [H_AUTOBGTRANSFERENABLED], a
	ld a, LOW(vBGMap0)
	ld [H_AUTOBGTRANSFERDEST], a
	ld a, HIGH(vBGMap0)
	ld [H_AUTOBGTRANSFERDEST + 1], a
	call .BackupUserHUD
	call .CaptureProtectedTargetRowIDs
	call .InstallProtectedTargetPalette
	call .BackupMetallicPalette
	call .SetMetallicPaletteIdentity
	call .MaskUserHUD
	call .SetPrivateUserPaletteMap

	; BG0 needs only the first three VBlanks of Gold's 19-frame battlergfx/TargetObj
	; interval, so finish the private copy while the live Window still hides it.
	ld a, 1
	ld [H_AUTOBGTRANSFERENABLED], a
	xor a
	ld [wSubAnimCounter], a
	ret

.WaitGoldTargetObj19
.handoffLoop
	ld a, [wSubAnimCounter]
	cp 3
	jr c, .handoffWait
	; Do not overlap VBlankCopy with the three BG0 auto-transfer VBlanks. Starting
	; at frame 3, copy one protected-row tile per VBlank; seven frames cover the
	; wider enemy row and still finish well inside Gold's 19-frame interval.
	sub 3
	call .StageProtectedTargetTile
.handoffWait
	call DelayFrame
	ld hl, wSubAnimCounter
	inc [hl]
	ld a, [hl]
	cp 3
	jr nz, .handoffCheckDone
	; All three BG0 thirds now contain the private palette attributes. Freeze BG0
	; and put the shared WRAM palette map back to its ordinary battle assignment.
	xor a
	ld [H_AUTOBGTRANSFERENABLED], a
	call .RestoreNormalUserPaletteMap
.handoffCheckDone
	ld a, [wSubAnimCounter]
	cp IRON_TAIL_TARGETOBJ_FRAMES
	jr c, .handoffLoop
	ret

.WaitAndHandoffProtectedTarget
	; Gold waits four frames between Metallic and loading HIT. Keep TARGET fully
	; resident in BG0 for the first three frames. On the fourth VBlank, install
	; the stationary target-row OBJ and blank only that row in BG0. This avoids
	; exposing a missing target row while Metallic's OBP0=$00 treatment is active.
	ld b, 3
.waitMetallicTail
	push bc
	call DelayFrame
	pop bc
	dec b
	jr nz, .waitMetallicTail

	; No HARDEN OBJ survives this point, so restoring OBP0 one frame before the
	; wobble has no visible effect except making the protected battler row safe on
	; every renderer. Convert BG -> OBJ atomically on the fourth wait frame.
	call .RestoreOBP0
	call .MaskProtectedTargetRow
	coord hl, 0, 6
	ld a, l
	ld [H_VBCOPYBGSRC], a
	ld a, h
	ld [H_VBCOPYBGSRC + 1], a
	ld a, LOW(vBGMap0 + 6 * 32)
	ld [H_VBCOPYBGDEST], a
	ld a, HIGH(vBGMap0 + 6 * 32)
	ld [H_VBCOPYBGDEST + 1], a
	ld a, $80 | 1 ; tile-only copy, one visible row
	ld [H_VBCOPYBGNUMROWS], a
	ld de, wOAMBuffer
	call .DrawProtectedTargetRow
	call DelayFrame
	ret

.PlayMetallic
	xor a
	ld [wSubAnimCounter], a
.metallicLoop
	ld a, [wSubAnimCounter]
	cp 6
	call z, .SetMetallicPaletteMiddle
	ld a, [wSubAnimCounter]
	cp 11
	call z, .SetMetallicPaletteBlack

	ld de, wOAMBuffer
	ld a, [wSubAnimCounter]
	call .DrawActiveHarden
	call DelayFrame
	call ClearSprites

	ld hl, wSubAnimCounter
	inc [hl]
	ld a, [hl]
	cp IRON_TAIL_METALLIC_FRAMES
	jr c, .metallicLoop

	; Gold anim_incbgeffect ends FadeMonToBlack here, before the parent's 4-frame
	; pause that leads into WOBBLE_MON.
	call .SetMetallicPaletteIdentity
	ret

.DrawActiveHarden
	; A = Metallic timeline frame. Gold spawns identical 26-frame Harden objects
	; at t=8 and t=40; they never overlap.
	cp IRON_TAIL_HARDEN_1_START
	ret c
	cp IRON_TAIL_HARDEN_1_START + IRON_TAIL_HARDEN_LIFETIME
	jr c, .firstHarden
	cp IRON_TAIL_HARDEN_2_START
	ret c
	cp IRON_TAIL_HARDEN_2_START + IRON_TAIL_HARDEN_LIFETIME
	ret nc
	sub IRON_TAIL_HARDEN_2_START
	jr .drawHardenAge
.firstHarden
	sub IRON_TAIL_HARDEN_1_START

.drawHardenAge
	; Gold frame duration 1 means each of the 13 Reflect frames lasts two ticks.
	srl a
	ld b, a ; stage 0..12

	; Object base OAM_XFLIP is only active for the enemy-user coordinate-fixed
	; version. Frames 7..12 XOR an additional XFLIP|YFLIP.
	xor a
	ld c, a
	ldh a, [H_WHOSETURN]
	and a
	jr z, .gotBaseHardenFlags
	ld c, OAM_HFLIP
.gotBaseHardenFlags
	ld a, b
	cp 7
	jr c, .gotHardenSet
	ld a, 12
	sub b
	ld b, a
	ld a, c
	xor OAM_HFLIP | OAM_VFLIP
	ld c, a
.gotHardenSet
	ld a, c
	ld [wDropletTile], a

	ldh a, [H_WHOSETURN]
	and a
	jr nz, .enemyHardenCenter
	ld a, 48
	ld [wBaseCoordX], a
	ld a, 84
	jr .gotHardenCenter
.enemyHardenCenter
	ld a, 132 ; 180 - 48
	ld [wBaseCoordX], a
	ld a, 44  ; Gold fixY $80: 128 - 84
.gotHardenCenter
	ld [wBaseCoordY], a

	ld a, b
	add a
	ld c, a
	ld b, 0
	ld hl, GoldIronTailHardenSetPointers
	add hl, bc
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld c, [hl]
	inc hl

.drawHardenSprite
	; Y offset, transformed exactly like Gold BattleAnimOAMUpdate when globally
	; flipped: -(offset + 8).
	ld a, [hli]
	ld b, a
	ld a, [wDropletTile]
	bit 6, a
	ld a, b
	jr z, .hardenYReady
	add 8
	cpl
	inc a
.hardenYReady
	ld b, a
	ld a, [wBaseCoordY]
	add b
	ld [de], a
	inc de

	ld a, [hli]
	ld b, a
	ld a, [wDropletTile]
	bit 5, a
	ld a, b
	jr z, .hardenXReady
	add 8
	cpl
	inc a
.hardenXReady
	ld b, a
	ld a, [wBaseCoordX]
	add b
	ld [de], a
	inc de

	ld a, [hli]
	add IRON_TAIL_REFLECT_TILE_BASE
	ld [de], a
	inc de

	ld a, [hli]
	ld b, a
	ld a, [wDropletTile]
	xor b
	and OAM_HFLIP | OAM_VFLIP
	or IRON_TAIL_REFLECT_PAL
	ld [de], a
	inc de

	dec c
	jr nz, .drawHardenSprite
	ret

.SetReflectTilePalette
	ld a, 2
	ld [rSVBK], a
	ld hl, W2_SpritePaletteMap + IRON_TAIL_REFLECT_TILE_BASE
	ld b, IRON_TAIL_REFLECT_TILE_COUNT
	xor a ; ATK_PAL_GREY
.reflectPaletteMapLoop
	ld [hli], a
	dec b
	jr nz, .reflectPaletteMapLoop
	xor a
	ld [rSVBK], a
	ret

.BackupOBP0AndSetReflect
	ld a, [rOBP0]
	ld [wIcyWindWaveBufferA + $58], a
	ld a, [rOBP1]
	ld [wIcyWindWaveBufferA + $59], a
	; ANM-5.62.08: Battle Party switching runs GBPalWhiteOut, while GBPalNormal restores only
	; BGP/OBP0. The protected target row uses OBJ palette 4 through OBP1, so a
	; stale $00 here maps every copied target-row color to white after a switch.
	ld a, $e4
	ld [rOBP1], a
	xor a ; Gold anim_obp0 $00
	ld [rOBP0], a
	ret

.RestoreOBP0
	ld a, [wIcyWindWaveBufferA + $58]
	ld [rOBP0], a
	ret

.RestoreOBP1
	ld a, [wIcyWindWaveBufferA + $59]
	ld [rOBP1], a
	ret

.LoadHitTilesAndPalette
	; Gold's anim_1gfx HIT replaces REFLECT after Metallic. GoldCrunchTiles starts
	; with Cut tile #3, followed by the exact four processed hit.png tiles #0-#3.
	ld hl, vSprites + IRON_TAIL_HIT_TILE_BASE * 16
	ld de, GoldCrunchTiles + 16
	ld b, BANK(GoldCrunchTiles)
	ld c, IRON_TAIL_HIT_TILE_COUNT
	call CopyVideoData

	; Keep Gold geometry while retaining RPP's current Steel move-type coloring.
	ld d, STEEL
	ld e, BATTLE_TYPE_PAL_TILESET1
	callba LoadBattleAnimTypePalette_Sprite
	ld a, 2
	ld [rSVBK], a
	ld hl, W2_SpritePaletteMap + IRON_TAIL_HIT_TILE_BASE
	ld b, IRON_TAIL_HIT_TILE_COUNT
	ld a, BATTLE_TYPE_PAL_TILESET1
.hitPaletteMapLoop
	ld [hli], a
	dec b
	jr nz, .hitPaletteMapLoop
	ld a, 1
	ld [W2_ForceOBPUpdate], a
	xor a
	ld [rSVBK], a
	ret

.BackupMetallicPalette
	; Slot 5 is private for this animation; preserve it so the helper leaves the
	; global CGB palette state exactly as it found it.
	ld a, 2
	ld [rSVBK], a
	ld hl, W2_BgPaletteData + IRON_TAIL_METALLIC_BG_PAL * 8
	ld de, wIcyWindWaveBufferA + $50
	ld bc, 8
	call CopyData
	xor a
	ld [rSVBK], a
	ret

.RestoreMetallicPalette
	ld a, 2
	ld [rSVBK], a
	ld hl, wIcyWindWaveBufferA + $50
	ld de, W2_BgPaletteData + IRON_TAIL_METALLIC_BG_PAL * 8
	ld bc, 8
	call CopyData
	ld a, 1
	ld [W2_ForceBGPUpdate], a
	xor a
	ld [rSVBK], a
	ret

.GetUserBGPalette
	ldh a, [H_WHOSETURN]
	and a
	ld hl, W2_BgPaletteData
	ret z
	ld hl, W2_BgPaletteData + 8
	ret

.SetMetallicPaletteIdentity
	ld a, 2
	ld [rSVBK], a
	call .GetUserBGPalette
	ld de, W2_BgPaletteData + IRON_TAIL_METALLIC_BG_PAL * 8
	ld bc, 8
	call CopyData
	jr .metallicPaletteUpdated

.SetMetallicPaletteMiddle
	; Gold DMG map $f8 = source colors [0,2,3,3].
	ld a, 2
	ld [rSVBK], a
	call .GetUserBGPalette
	ld de, W2_BgPaletteData + IRON_TAIL_METALLIC_BG_PAL * 8
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hli]
	ld [de], a
	inc de
	inc hl
	inc hl
	ld bc, 4
	call CopyData
	dec hl
	dec hl
	ld bc, 2
	call CopyData
	jr .metallicPaletteUpdated

.SetMetallicPaletteBlack
	; Gold DMG map $fc = source colors [0,3,3,3].
	ld a, 2
	ld [rSVBK], a
	call .GetUserBGPalette
	ld de, W2_BgPaletteData + IRON_TAIL_METALLIC_BG_PAL * 8
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hli]
	ld [de], a
	inc de
	inc hl
	inc hl
	inc hl
	inc hl
	ld b, [hl]
	inc hl
	ld c, [hl]
	ld a, b
	ld [de], a
	inc de
	ld a, c
	ld [de], a
	inc de
	ld a, b
	ld [de], a
	inc de
	ld a, c
	ld [de], a
	inc de
	ld a, b
	ld [de], a
	inc de
	ld a, c
	ld [de], a
.metallicPaletteUpdated
	ld a, 1
	ld [W2_ForceBGPUpdate], a
	xor a
	ld [rSVBK], a
	ret

.SetPrivateUserPaletteMap
	ld a, 2
	ld [rSVBK], a
	ldh a, [H_WHOSETURN]
	and a
	jr nz, .privateEnemyMap
	ld hl, W2_TilesetPaletteMap + 6 * SCREEN_WIDTH + 2
	lb bc, 6, 6
	jr .fillPrivateUserMap
.privateEnemyMap
	ld hl, W2_TilesetPaletteMap + 12
	lb bc, 7, 7
.fillPrivateUserMap
	ld a, IRON_TAIL_METALLIC_BG_PAL
	call .FillPaletteBox
	ld a, 3
	ld [W2_StaticPaletteMapChanged], a
	xor a
	ld [rSVBK], a
	ret

.RestoreNormalUserPaletteMap
	; Restore the WRAM palette map immediately after BG0 captured the private attrs.
	; BGMap1 was never modified, and the later destination switch refreshes its attrs.
	ld a, 2
	ld [rSVBK], a
	ldh a, [H_WHOSETURN]
	and a
	jr nz, .normalEnemyMap
	ld hl, W2_TilesetPaletteMap + 6 * SCREEN_WIDTH + 2
	lb bc, 6, 6
	xor a ; player palette 0
	jr .fillNormalUserMap
.normalEnemyMap
	ld hl, W2_TilesetPaletteMap + 12
	lb bc, 7, 7
	ld a, 1 ; enemy palette 1
.fillNormalUserMap
	call .FillPaletteBox
	xor a
	ld [rSVBK], a
	ret

.FillPaletteBox
	; Bank-local equivalent of color/color.asm FillBox. This helper runs from
	; ROMX bank $3D, so a plain call to the bank-$1C FillBox would execute the
	; wrong ROM bank at runtime even though the symbol resolves at link time.
	push af
	ld a, SCREEN_WIDTH
	sub c
	ld e, a
	ld d, 0
	pop af
	push bc
.fillPaletteBoxLoop
	ld [hli], a
	dec c
	jr nz, .fillPaletteBoxLoop
	add hl, de
	pop bc
	dec b
	push bc
	jr nz, .fillPaletteBoxLoop
	pop bc
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

.CaptureProtectedTargetRowIDs
	call .ProtectedTargetIsHidden
	jr nz, .initProtectedTargetCopyDest
	; Gold BATTLEROBJ_1ROW protects TARGET at shared Y=48..55. Capture exact tile
	; IDs now; graphics are copied one per TargetObj wait frame.
	ldh a, [H_WHOSETURN]
	and a
	jr nz, .capturePlayerHead
	coord hl, 12, 6
	ld b, 7
	jr .captureProtectedRowReady
.capturePlayerHead
	coord hl, 2, 6
	ld b, 6
.captureProtectedRowReady
	ld de, wIcyWindWaveBufferA + $40
.captureProtectedTile
	ld a, [hli]
	ld [de], a
	inc de
	dec b
	jr nz, .captureProtectedTile
.initProtectedTargetCopyDest
	ld a, LOW(vSprites + IRON_TAIL_TARGET_TILE_BASE * 16)
	ld [H_VBCOPYDEST], a
	ld a, HIGH(vSprites + IRON_TAIL_TARGET_TILE_BASE * 16)
	ld [H_VBCOPYDEST + 1], a
	ret

.StageProtectedTargetTile
	; A = target-row tile index. VBlankCopy advances the destination automatically.
	ld c, a
	call .ProtectedTargetIsHidden
	ret nz
	ldh a, [H_WHOSETURN]
	and a
	ld b, 7
	jr z, .gotProtectedTargetCount
	ld b, 6
.gotProtectedTargetCount
	ld a, c
	cp b
	ret nc
	ld e, a
	ld d, 0
	ld hl, wIcyWindWaveBufferA + $40
	add hl, de
	ld a, [hl]
	call .SetVBCopySourceFromBattleTile
	ld a, 1
	ld [H_VBCOPYSIZE], a
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
	call .RestoreMetallicPalette
	ld a, LOW(vBGMap1)
	ld [H_AUTOBGTRANSFERDEST], a
	ld a, HIGH(vBGMap1)
	ld [H_AUTOBGTRANSFERDEST + 1], a
	ld a, 1
	ld [H_AUTOBGTRANSFERENABLED], a
	callba LoadAnimationTilesetPalettes
	; ANM-5.62.08: the protected row is gone and palette slots 4..7 are back on OBP0; restore
	; the caller's exact OBP1 state instead of leaking Iron Tail's neutral map.
	call .RestoreOBP1
	xor a
	ld [hWY], a
	; ANM-5.62.07: enemy Iron Tail is followed by the stock vertical damage shake,
	; which can expose BG0 row 0 while the Window moves down. Restore that hidden
	; row to the normal blank battle backdrop before the Window is revealed.
	call .StageBlankBG0TopRowForEnemyFeedback
	call ClearSprites
	call DelayFrame
	ret

.StageBlankBG0TopRowForEnemyFeedback
	ldh a, [H_WHOSETURN]
	and a
	ret z ; player Iron Tail keeps its stock (non-vertical) damage feedback

	ld hl, wIcyWindWaveBufferA + $60
	ld b, SCREEN_WIDTH
	ld a, " "
.fillBlankBG0TopRow
	ld [hli], a
	dec b
	jr nz, .fillBlankBG0TopRow

	ld hl, wIcyWindWaveBufferA + $60
	ld a, l
	ld [H_VBCOPYBGSRC], a
	ld a, h
	ld [H_VBCOPYBGSRC + 1], a
	ld a, LOW(vBGMap0)
	ld [H_VBCOPYBGDEST], a
	ld a, HIGH(vBGMap0)
	ld [H_VBCOPYBGDEST + 1], a
	ld a, $80 | 1 ; tile-only copy of the one 8-pixel row vertical shake exposes
	ld [H_VBCOPYBGNUMROWS], a
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

; Exact processed REFLECT tiles #0/#1 used by Gold BATTLE_ANIM_OBJ_HARDEN.
GoldIronTailReflectTiles:
	db $00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff
	db $00,$00,$00,$80,$00,$c0,$00,$e0,$00,$f0,$00,$f8,$00,$fc,$00,$fe
GoldIronTailReflectTilesEnd:
	IF GoldIronTailReflectTilesEnd - GoldIronTailReflectTiles != IRON_TAIL_REFLECT_TILE_COUNT * 16
		fail "Gold Iron Tail reflect tiles must contain exactly two 2bpp tiles"
	ENDC

GoldIronTailHardenSetPointers:
	dw .set0
	dw .set1
	dw .set2
	dw .set3
	dw .set4
	dw .set5
	dw .set6
.set0
	db 1
	db -28,  12, $01, $60
.set1
	db 3
	db -28,  12, $00, $00
	db -28,   4, $01, $60
	db -20,  12, $01, $60
.set2
	db 6
	db -28,  12, $01, $00
	db -28,   4, $00, $00
	db -28,  -4, $01, $60
	db -20,  12, $00, $00
	db -20,   4, $01, $60
	db -12,  12, $01, $60
.set3
	db 9
	db -28, -12, $01, $60
	db -28,  -4, $00, $00
	db -28,   4, $01, $00
	db -20,  -4, $01, $60
	db -20,   4, $00, $00
	db -20,  12, $01, $00
	db -12,   4, $01, $60
	db -12,  12, $00, $00
	db  -4,  12, $01, $60
.set4
	db 12
	db -28, -20, $01, $60
	db -28, -12, $00, $00
	db -28,  -4, $01, $00
	db -20, -12, $01, $60
	db -20,  -4, $00, $00
	db -20,   4, $01, $00
	db -12,  -4, $01, $60
	db -12,   4, $00, $00
	db -12,  12, $01, $00
	db  -4,   4, $01, $60
	db  -4,  12, $00, $00
	db   4,  12, $01, $60
.set5
	db 14
	db -28, -20, $00, $00
	db -28, -12, $01, $00
	db -20, -20, $01, $60
	db -20, -12, $00, $00
	db -20,  -4, $01, $00
	db -12, -12, $01, $60
	db -12,  -4, $00, $00
	db -12,   4, $01, $00
	db  -4,  -4, $01, $60
	db  -4,   4, $00, $00
	db  -4,  12, $01, $00
	db   4,   4, $01, $60
	db   4,  12, $00, $00
	db  12,  12, $01, $60
.set6
	db 15
	db -28, -20, $01, $00
	db -20, -20, $00, $00
	db -20, -12, $01, $00
	db -12, -20, $01, $60
	db -12, -12, $00, $00
	db -12,  -4, $01, $00
	db  -4, -12, $01, $60
	db  -4,  -4, $00, $00
	db  -4,   4, $01, $00
	db   4,  -4, $01, $60
	db   4,   4, $00, $00
	db   4,  12, $01, $00
	db  12,   4, $01, $60
	db  12,  12, $00, $00
	db  20,  12, $01, $60

GoldIronTailWobbleOffsets:
	db 0, 3, 5, 7, 8, 7, 5, 3
	db 0,-3,-5,-7,-8,-7,-5,-3
GoldIronTailWobbleOffsetsEnd:
	IF GoldIronTailWobbleOffsetsEnd - GoldIronTailWobbleOffsets != 16
		fail "Gold Iron Tail wobble table must contain exactly 16 frames"
	ENDC
