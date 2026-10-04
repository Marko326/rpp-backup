; Lightweight Earth Power eruption built from existing Gen I battle-animation
; assets. Reuse Ember's two 16x16 flame frames, Rock Throw's 16x16 rock, the
; existing small rock fragment, Gold's Egg Bomb SFX and the proven VBlank WX
; horizontal-shake helper. Polished Crystal remains the composition/timing
; reference; no dedicated Earth Power graphics or audio are added.

EARTH_POWER_ROCK_BIG_TILE_BASE EQU $60 ; four tiles: $60..$63
EARTH_POWER_ROCK_SMALL_TILE    EQU $64
EARTH_POWER_BURST_FRAMES       EQU 40
EARTH_POWER_FINAL_FRAMES       EQU 48
EARTH_POWER_GAP_FRAMES         EQU 8
EARTH_POWER_ROCK_FRAMES        EQU 17 ; exact Rock Smash lifetime: VAR1 $40 through $30

; AnimationTileset2 (legacy tileset 1) Ember source tiles after the normal +$31
; VRAM offset used by DrawFrameBlock.
EARTH_POWER_FIRE_TOP_A    EQU $36 ; source tile $05, FrameBlock0b
EARTH_POWER_FIRE_BOTTOM_A EQU $46 ; source tile $15, FrameBlock0b
EARTH_POWER_FIRE_TOP_B    EQU $35 ; source tile $04, FrameBlock0c
EARTH_POWER_FIRE_BOTTOM_B EQU $45 ; source tile $14, FrameBlock0c

PlayGoldEarthPowerAnimation::
	; Load Gen I Ember's normal tileset, then copy only the existing rock tiles
	; Earth Power needs into private OBJ slots. FrameBlock23 supplies a complete
	; 16x16 Rock Throw rock; $4d is the exact 8x8 small Rock Smash shape used by PC.
	ld a, 1
	ld [wWhichBattleAnimTileset], a
	callba LoadAnimationTileset

	ld hl, vSprites + EARTH_POWER_ROCK_BIG_TILE_BASE * 16
	ld de, AnimationTileset1 + $0a * 16
	ld b, BANK(AnimationTileset1)
	ld c, 2
	call CopyVideoData
	ld hl, vSprites + (EARTH_POWER_ROCK_BIG_TILE_BASE + 2) * 16
	ld de, AnimationTileset1 + $1a * 16
	ld b, BANK(AnimationTileset1)
	ld c, 2
	call CopyVideoData
	ld hl, vSprites + EARTH_POWER_ROCK_SMALL_TILE * 16
	ld de, AnimationTileset1 + $4d * 16
	ld b, BANK(AnimationTileset1)
	ld c, 1
	call CopyVideoData

	; Keep Ember red and both reused rock sizes brown.
	ld a, 2
	ld [rSVBK], a
	ld a, ATK_PAL_RED
	ld [W2_SpritePaletteMap + EARTH_POWER_FIRE_TOP_A], a
	ld [W2_SpritePaletteMap + EARTH_POWER_FIRE_BOTTOM_A], a
	ld [W2_SpritePaletteMap + EARTH_POWER_FIRE_TOP_B], a
	ld [W2_SpritePaletteMap + EARTH_POWER_FIRE_BOTTOM_B], a
	ld a, ATK_PAL_BROWN
	ld [W2_SpritePaletteMap + EARTH_POWER_ROCK_BIG_TILE_BASE], a
	ld [W2_SpritePaletteMap + EARTH_POWER_ROCK_BIG_TILE_BASE + 1], a
	ld [W2_SpritePaletteMap + EARTH_POWER_ROCK_BIG_TILE_BASE + 2], a
	ld [W2_SpritePaletteMap + EARTH_POWER_ROCK_BIG_TILE_BASE + 3], a
	ld [W2_SpritePaletteMap + EARTH_POWER_ROCK_SMALL_TILE], a
	; RPP's stock ATK_PAL_BROWN is substantially darker than Polished Crystal's
	; Rock Smash brown. Give Earth Power the reference palette in the existing
	; brown slot, then restore the ordinary attack palettes when the move ends.
	ld hl, GoldEarthPowerBrownPalette
	ld de, W2_SprPaletteData + ATK_PAL_BROWN * 8
	ld bc, 8
	call CopyData
	ld a, 1
	ld [W2_ForceOBPUpdate], a
	xor a
	ld [rSVBK], a

	; Gold/Crystal clears the acting side HUD before running an ordinary move
	; animation. RPP normally leaves both HUDs visible, so reproduce that system
	; behavior locally for Earth Power. The battle text rows are simultaneously
	; moved to private BG palette 7 so BGP=$1b can invert the battlefield without
	; turning the message box into a high-contrast black rectangle.
	call .PrepareBattleUI

	; Preserve the caller BGP. On CGB, build the $1b-converted palettes manually
	; for slots 0..6 while leaving text palette 7 untouched, matching the Gen II
	; battle-animation palette path. DMG still receives the real $1b BGP value.
	ld a, [rBGP]
	push af
	call GoldBattleHorizontalShakeBegin
	call .SetInvertedBattleBGPProtectText

	; Polished Crystal object centers are 120 -> 144 -> 132 at Y=68. Its Ember
	; flame is centered by OAMData_04 (-8,-8), so the equivalent Gen I flame
	; top-left anchors are 112 -> 136 -> 124 at Y=60.
	ld b, $70 ; 112
	ld c, 0
	call .PlayBurst
	ld b, $88 ; 136
	ld c, 1
	call .PlayBurst
	ld b, $7c ; 124, exact midpoint of 112 and 136
	ld c, 2
	call .PlayFinalBurst

	call GoldBattleHorizontalShakeEnd
	pop af
	ld [rBGP], a
	; Force the normal palette pipeline to rebuild all eight BG palettes from the
	; restored BGP, then put the text rows and acting HUD back exactly where RPP
	; expects them before generic hit feedback runs.
	ld a, 2
	ld [rSVBK], a
	ld a, 1
	ld [W2_ForceBGPUpdate], a
	xor a
	ld [rSVBK], a
	call .RestoreBattleUI

	; Undo the private Earth Power rock brown so later animations keep RPP's
	; normal attack palettes.
	callba LoadAttackSpritePalettes
	ret

.PlayBurst
	call .SetupBurst
	xor a
	ld [wSubAnimCounter], a
.frameLoop
	ld de, wOAMBuffer
	call .DrawFlame
	call .DrawRockFragments
	call .SetHorizontalShake
	call DelayFrame
	call ClearSprites

	ld hl, wSubAnimCounter
	inc [hl]
	ld a, [hl]
	cp EARTH_POWER_BURST_FRAMES
	jr c, .frameLoop

	call .SetHorizontalShake
	ld c, EARTH_POWER_GAP_FRAMES
	call DelayFrames
	ret

.PlayFinalBurst
	call .SetupBurst
	xor a
	ld [wSubAnimCounter], a
.finalFrameLoop
	ld de, wOAMBuffer
	call .DrawFlame
	call .DrawRockFragments
	call .SetHorizontalShake
	call DelayFrame
	call ClearSprites

	ld hl, wSubAnimCounter
	inc [hl]
	ld a, [hl]
	cp EARTH_POWER_FINAL_FRAMES
	jr c, .finalFrameLoop

	; The reference keeps the final Ember object for 48 frames, while its shake
	; lasts 40 frames, leaving the same eight-frame unshaken tail here.
	call .SetHorizontalShake
	ret

.SetupBurst
	; C identifies which of Polished Crystal's three Rock Smash parameter sets
	; belongs to this burst. Keep it in animation scratch for the manual renderer.
	ld a, c
	ld [wSubAnimFrameDelay], a

	; Store the Gen I flame's top-left OAM anchor. For enemy use, reproduce the
	; reference's RELATIVE_X transform around X=180, accounting for the flame's
	; -8 OAM centering: topLeft' = 164 - topLeft. Gold's raw fixY=$aa result puts
	; the Ember center at Y=102, but Gen I's player battler sits lower on screen;
	; shift the reused 16x16 flame down 8 px so the eruption begins at its feet.
	ld a, [H_WHOSETURN]
	and a
	jr nz, .enemyAnchor
	ld a, b
	ld [wBaseCoordX], a
	ld a, $3c ; 60
	jr .anchorYReady
.enemyAnchor
	ld a, 164
	sub b
	ld [wBaseCoordX], a
	ld a, $66 ; 102, RPP player-side adaptation (+8 px from raw Gen II top-left)
.anchorYReady
	ld [wBaseCoordY], a

	ld a, GSSFX_EGG_BOMB
	call PlaySound
	ret

.SetHorizontalShake
	ld b, 0
	ld c, EARTH_POWER_BURST_FRAMES
	ld d, 1 ; alternate sign every VBlank
	ld e, 2 ; +/-2 px, same source amplitude as Polished Crystal
	jp GoldBattleHorizontalShakeSet

.DrawFlame
	; Alternate the exact FrameBlock0b/0c Ember composition every four frames.
	ld a, [wSubAnimCounter]
	and 4
	jr nz, .frameB
	ld h, EARTH_POWER_FIRE_TOP_A
	ld l, EARTH_POWER_FIRE_BOTTOM_A
	jr .tilesReady
.frameB
	ld h, EARTH_POWER_FIRE_TOP_B
	ld l, EARTH_POWER_FIRE_BOTTOM_B
.tilesReady
	; top-left
	ld a, [wBaseCoordY]
	ld [de], a
	inc de
	ld a, [wBaseCoordX]
	ld [de], a
	inc de
	ld a, h
	ld [de], a
	inc de
	xor a
	ld [de], a
	inc de

	; top-right
	ld a, [wBaseCoordY]
	ld [de], a
	inc de
	ld a, [wBaseCoordX]
	add 8
	ld [de], a
	inc de
	ld a, h
	ld [de], a
	inc de
	ld a, OAM_HFLIP
	ld [de], a
	inc de

	; bottom-left
	ld a, [wBaseCoordY]
	add 8
	ld [de], a
	inc de
	ld a, [wBaseCoordX]
	ld [de], a
	inc de
	ld a, l
	ld [de], a
	inc de
	xor a
	ld [de], a
	inc de

	; bottom-right
	ld a, [wBaseCoordY]
	add 8
	ld [de], a
	inc de
	ld a, [wBaseCoordX]
	add 8
	ld [de], a
	inc de
	ld a, l
	ld [de], a
	inc de
	ld a, OAM_HFLIP
	ld [de], a
	inc de
	ret

.DrawRockFragments
	; Rock Smash draws 17 positions: VAR1 starts at $40 and the object survives
	; through the $30 sample. Use the reference's actual four parameters for each
	; burst: bit 7 controls left/right scatter, bit 6 chooses small vs big rock,
	; and the low six bits select the vertical amplitude.
	ld a, [wSubAnimCounter]
	cp EARTH_POWER_ROCK_FRAMES
	ret nc

	ld a, [wSubAnimFrameDelay]
	add a
	add a
	ld l, a
	ld h, 0
	ld bc, EarthPowerRockBurstParams
	add hl, bc
	ld b, 4
.rockLoop
	ld a, [hli]
	push hl
	push bc
	call .DrawOneRock
	pop bc
	pop hl
	dec b
	jr nz, .rockLoop
	ret

.DrawOneRock
	; B = original Rock Smash parameter.
	ld b, a

	; Reproduce BattleAnim_ScatterHorizontal exactly. Gen II accumulates an 8.8
	; fixed-point X coordinate once before each visible sample. Positive params are
	; compared *without* masking bit 6; negative params mask to low6 first. That
	; distinction matters for Earth Power's small-rock params $5c and $50.
	; wSubAnimCounter is 0..16, so n = age + 1 matches the accumulated X step.
	bit 7, b
	jr nz, .negativeScatter
	ld a, b
	cp $20
	jr nc, .plusOne
	cp $18
	jr nc, .plusOneHalf
	jr .plusTwo

.negativeScatter
	ld a, b
	and $3f
	cp $20
	jr nc, .minusOne
	cp $18
	jr nc, .minusOneHalf
	jr .minusTwo

.plusOne
	call .GetRockStep
	jr .xMagnitudeReady
.plusOneHalf
	call .GetRockStep
	ld c, a
	add a
	add c
	srl a ; floor(3*n/2), exact high byte of +$180 accumulation
	jr .xMagnitudeReady
.plusTwo
	call .GetRockStep
	add a
	jr .xMagnitudeReady
.minusOne
	call .GetRockStep
	cpl
	inc a
	jr .xMagnitudeReady
.minusOneHalf
	call .GetRockStep
	ld c, a
	add a
	add c
	inc a
	srl a ; ceil(3*n/2), then negate: exact high byte of -$180 accumulation
	cpl
	inc a
	jr .xMagnitudeReady
.minusTwo
	call .GetRockStep
	add a
	cpl
	inc a
.xMagnitudeReady
	ld c, a

	; RELATIVE_X mirrors the object coordinate after Rock Smash updates it, so
	; enemy-side horizontal motion must reverse on screen as well.
	ld a, [H_WHOSETURN]
	and a
	jr z, .xRelativeReady
	ld a, c
	cpl
	inc a
	ld c, a
.xRelativeReady

	; Rock Smash's vertical movement is a single rising sine quarter-wave. The
	; only amplitudes Earth Power uses are 16, 28 and 40 pixels.
	ld a, b
	and $3f
	cp $28
	jr z, .amp40
	cp $1c
	jr z, .amp28
	ld hl, EarthPowerRockYOffset16
	jr .yTableReady
.amp28
	ld hl, EarthPowerRockYOffset28
	jr .yTableReady
.amp40
	ld hl, EarthPowerRockYOffset40
.yTableReady
	ld a, [wSubAnimCounter]
	add l
	ld l, a
	jr nc, .noYCarry
	inc h
.noYCarry
	ld a, [hl]
	ld h, a ; signed Y offset

	; Convert our flame top-left back to the reference object's logical center.
	; Rock Smash uses fixY=$ff, so enemy rocks sit 6 px lower than enemy Ember.
	ld a, [wBaseCoordX]
	add 8
	add c
	ld l, a ; logical object X
	ld a, [wBaseCoordY]
	add 8
	ld c, a
	ld a, [H_WHOSETURN]
	and a
	jr z, .rockCenterYReady
	ld a, c
	add 6
	ld c, a
.rockCenterYReady
	ld a, c
	add h
	ld h, a ; logical object Y

	; In the reference bit 6 selects the small one-sprite frameset. Otherwise the
	; four-sprite big rock is centered at (-8,-8) around the logical coordinate.
	bit 6, b
	jr nz, .drawSmallRock
	ld a, l
	sub 8
	ld l, a
	ld a, h
	sub 8
	ld h, a
	jr .DrawBigRock

.drawSmallRock
	; Y, X, tile, flags. The Gen II object applies OAM_XFLIP on the enemy side.
	ld a, h
	ld [de], a
	inc de
	ld a, l
	ld [de], a
	inc de
	ld a, EARTH_POWER_ROCK_SMALL_TILE
	ld [de], a
	inc de
	xor a
	ld c, a
	ld a, [H_WHOSETURN]
	and a
	ld a, c
	jr z, .smallFlagsReady
	ld a, OAM_HFLIP
.smallFlagsReady
	ld [de], a
	inc de
	ret

.DrawBigRock
	; FrameBlock23: a complete existing Gen I 16x16 rock, no new art.
	; top-left
	ld a, h
	ld [de], a
	inc de
	ld a, l
	ld [de], a
	inc de
	ld a, EARTH_POWER_ROCK_BIG_TILE_BASE
	ld [de], a
	inc de
	xor a
	ld [de], a
	inc de

	; top-right
	ld a, h
	ld [de], a
	inc de
	ld a, l
	add 8
	ld [de], a
	inc de
	ld a, EARTH_POWER_ROCK_BIG_TILE_BASE + 1
	ld [de], a
	inc de
	xor a
	ld [de], a
	inc de

	; bottom-left
	ld a, h
	add 8
	ld [de], a
	inc de
	ld a, l
	ld [de], a
	inc de
	ld a, EARTH_POWER_ROCK_BIG_TILE_BASE + 2
	ld [de], a
	inc de
	xor a
	ld [de], a
	inc de

	; bottom-right
	ld a, h
	add 8
	ld [de], a
	inc de
	ld a, l
	add 8
	ld [de], a
	inc de
	ld a, EARTH_POWER_ROCK_BIG_TILE_BASE + 3
	ld [de], a
	inc de
	xor a
	ld [de], a
	inc de
	ret

; Exact Polished Crystal PAL_BATTLE_OB_BROWN used by Rock Smash. RPP's stock
; ATK_PAL_BROWN is darker (20,14,0 / 10,6,0), so Earth Power installs this
; private copy only for the duration of the move.

; Gen II updates the 8.8 X position before each visible Rock Smash sample,
; therefore the accumulated horizontal step number is age + 1 (1..17).
.GetRockStep
	ld a, [wSubAnimCounter]
	inc a
	ret

.PrepareBattleUI
	; Hide the acting side's HUD using RPP's actual HUD rectangles.
	ld a, [H_WHOSETURN]
	and a
	jr nz, .hideEnemyHUD
	coord hl, 9, 7
	lb bc, 5, 11
	jr .clearActorHUD
.hideEnemyHUD
	coord hl, 0, 0
	lb bc, 4, 12
.clearActorHUD
	call ClearScreenArea

	; RPP's message box normally shares BG palette 0 with the player battler.
	; Palette 7 is unused by the normal battle map, but menu teardown can leave a
	; few stale palette-7 cells in rows 0..11. If slot 7 is kept uninverted those
	; cells become bright blocks on the dark battlefield, so normalize only those
	; stale battlefield cells back to palette 0 before reserving slot 7 for text.
	ld a, 2
	ld [rSVBK], a
	call .NormalizeBattlefieldPalette7

	; Copy the normal text palette into slot 7 and route only rows 12..17 there so
	; the Earth Power inversion can exclude text just like Gen II excludes its
	; PAL_BATTLE_BG_TEXT slot.
	ld hl, W2_BgPaletteData
	ld de, W2_BgPaletteData + 7 * 8
	ld bc, 8
	call CopyData
	ld a, 7
	call .FillBattleTextPaletteMap
	ld a, 3
	ld [W2_StaticPaletteMapChanged], a
	; Palette 7 was previously unused in battle, so also request a normal palette
	; rebuild before any message-box cell is displayed with that slot.
	ld a, 1
	ld [W2_ForceBGPUpdate], a
	xor a
	ld [rSVBK], a

	; Auto BG/attribute transfer advances in thirds; three frames commit both the
	; cleared actor HUD and all six message-box palette rows before the script body.
	ld a, 1
	ld [H_AUTOBGTRANSFERENABLED], a
	ld c, 3
	jp DelayFrames

.RestoreBattleUI
	; Route the message box back to RPP's normal battle palette 0.
	ld a, 2
	ld [rSVBK], a
	xor a
	call .FillBattleTextPaletteMap
	ld a, 3
	ld [W2_StaticPaletteMapChanged], a
	xor a
	ld [rSVBK], a

	; Restore only the HUD that belonged to the acting side, mirroring Gen II's
	; BattleAnimRestoreHUDs outcome without disturbing the target HUD.
	ld a, [H_WHOSETURN]
	and a
	jr nz, .restoreEnemyHUD
	callba DrawPlayerHUDAndHPBar
	jr .hudRestored
.restoreEnemyHUD
	callba DrawEnemyHUDAndHPBar
.hudRestored
	ld a, 1
	ld [H_AUTOBGTRANSFERENABLED], a
	ld c, 3
	jp DelayFrames

.FillBattleTextPaletteMap
	; A = palette number. Rows 12..17 are the six message-box rows in RPP battle.
	ld hl, W2_TilesetPaletteMap + 12 * SCREEN_WIDTH
	ld b, 6
.textPalRow
	ld c, SCREEN_WIDTH
.textPalCol
	ld [hli], a
	dec c
	jr nz, .textPalCol
	dec b
	jr nz, .textPalRow
	ret

.NormalizeBattlefieldPalette7
	; Battle setup itself uses palettes 0..4 in rows 0..11. Any palette-7 entry
	; there is stale menu state, not live battle art. Clear only those entries so
	; keeping palette 7 normal cannot expose white 8x8/16x16 blocks mid-field.
	ld hl, W2_TilesetPaletteMap
	ld bc, 12 * SCREEN_WIDTH
.normalizeFieldLoop
	ld a, [hl]
	cp 7
	jr nz, .normalizeFieldNext
	xor a
	ld [hl], a
.normalizeFieldNext
	inc hl
	dec bc
	ld a, b
	or c
	jr nz, .normalizeFieldLoop
	ret

.SetInvertedBattleBGPProtectText
	; Keep the actual DMG BGP state faithful to the reference.
	ld a, $1b
	ld [rBGP], a

	; The RPP CGB converter normally applies rBGP to all eight BG palettes. Build
	; the converted buffer ourselves for palettes 0..6 and leave slot 7 raw.
	ld a, 2
	ld [rSVBK], a
	ld b, 0
	ld hl, W2_BgPaletteDataBuffer
.convertNextBGPal
	ld d, $1b
	ld e, 4
.convertNextBGColor
	ld a, d
	call .CopyMappedBGColor
	srl d
	srl d
	dec e
	jr nz, .convertNextBGColor
	inc b
	ld a, b
	cp 7
	jr c, .convertNextBGPal

	; Palette 7 stays in its normal order for the message box.
	ld hl, W2_BgPaletteData + 7 * 8
	ld de, W2_BgPaletteDataBuffer + 7 * 8
	ld bc, 8
	call CopyData
	ld a, 1
	ld [W2_BgPaletteDataModified], a
	ld a, $1b
	ld [W2_LastBGP], a
	xor a
	ld [W2_ForceBGPUpdate], a
	ld [rSVBK], a
	ret

.CopyMappedBGColor
	; Same mapping primitive as color/vblank.asm:SetColor, kept local so this move
	; can protect one palette without changing the global RPP palette converter.
	push de
	and 3
	add a
	ld c, a
	ld a, b
	add a
	add a
	add a
	add c
	ld e, a
	ld d, HIGH(W2_BgPaletteData)
	ld a, [de]
	ld [hli], a
	inc de
	ld a, [de]
	ld [hli], a
	pop de
	ret

GoldEarthPowerBrownPalette:
	RGB 31,31,31
	RGB 24,18,7
	RGB 20,15,3
	RGB 0,0,0

; Exact Earth Power Rock Smash parameters from Polished Crystal. Each row is one
; eruption. Keeping these bytes makes the size/direction/speed mix obvious and
; easy to tune without introducing the full Gen II object engine.
EarthPowerRockBurstParams:
	db $5c, $e8, $9c, $50
	db $5c, $e8, $d0, $10
	db $28, $e8, $d0, $50

; Exact 17 visible Sine samples used by Rock Smash as VAR1 runs $40..$30.
; These are the Gen II Q8.8 sine-table results for amplitudes 16, 28 and 40;
; the last step reaches the apex naturally instead of faking a hold frame.
EarthPowerRockYOffset16:
	db 0,-1,-3,-4,-6,-7,-8,-10,-11,-12,-13,-14,-14,-15,-15,-15,-16
EarthPowerRockYOffset28:
	db 0,-2,-5,-8,-10,-13,-15,-17,-19,-21,-23,-24,-25,-26,-27,-27,-28
EarthPowerRockYOffset40:
	db 0,-3,-7,-11,-15,-18,-22,-25,-28,-30,-33,-35,-37,-38,-39,-39,-40
