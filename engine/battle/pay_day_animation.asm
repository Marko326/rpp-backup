; ANIM-5.62.85: RPP coin tumbles on the 18-frame Ruby-style throw.
; Three stages: flight with planar rotation -> centred hit -> legacy $52 bounce.
; Egg Bomb-style per-frame OAM pose cycling. Reuse the RPP $4b/$4c-derived
; coin rotation tiles come from RPP $4b/$4c; no extra SFX or WRAM.
;
; Both battlers traverse the *same* size-aware diagonal in opposite directions.
; Enemy front centre is the same 5x5/6x6/7x7 lookup as Volt Tackle;
; player back centre is (48,88). There is no arbitrary X mirror constant.

PAY_DAY_COIN_TILE_LEFT  EQU $31 + $4b
PAY_DAY_COIN_TILE_RIGHT EQU $31 + $4c
PAY_DAY_HIT_TILE_TOP    EQU $31 + $2c
PAY_DAY_HIT_TILE_MID    EQU $31 + $3c
PAY_DAY_FLIGHT_POINTS   EQU 18
PAY_DAY_HIT_FRAMES      EQU 6
PAY_DAY_SPIN_TILE_BASE  EQU $60
PAY_DAY_SPIN_TILE_COUNT EQU 4 * 4
PAY_DAY_FLIGHT_SPIN_FRAMES_PER_POSE EQU 2
ASSERT PAY_DAY_FLIGHT_SPIN_FRAMES_PER_POSE == 2 ; .DrawCoin uses SRL

ASSERT PAY_DAY_COIN_TILE_RIGHT < $80
ASSERT PAY_DAY_SPIN_TILE_BASE + PAY_DAY_SPIN_TILE_COUNT <= $80

PlayPayDayCoinTossAnimation::
	xor a
	ld [wWhichBattleAnimTileset],a
	callba LoadAnimationTileset

	; Egg Bomb's tested technique: preload temporary projectile graphics once,
	; then select poses through OAM each flight frame. The rotated tiles are
	; synthesized solely from RPP's existing coin ($4b/$4c); four raster poses
	; plus 180-degree OAM flips make eight 45-degree steps.
	ld hl,vSprites + PAY_DAY_SPIN_TILE_BASE * 16
	ld de,PayDaySpinTiles
	ld b,BANK(PayDaySpinTiles)
	ld c,PAY_DAY_SPIN_TILE_COUNT
	call CopyVideoData

	; Use the RPP yellow palette for coin and temporary rotated tiles.
	ld a,2
	ld [rSVBK],a
	ld a,ATK_PAL_YELLOW
	ld [W2_SpritePaletteMap + PAY_DAY_COIN_TILE_LEFT],a
	ld [W2_SpritePaletteMap + PAY_DAY_COIN_TILE_RIGHT],a
	ld hl,W2_SpritePaletteMap + PAY_DAY_SPIN_TILE_BASE
	ld b,PAY_DAY_SPIN_TILE_COUNT
.setFlightSpinPalette
	ld [hli],a
	dec b
	jr nz,.setFlightSpinPalette
	ld a,1
	ld [W2_ForceOBPUpdate],a
	xor a
	ld [rSVBK],a

	; Volt Tackle's form-aware enemy front-body centre, for all three sizes.
	call .CacheEnemyFrontSize
	call .SetVictimCenter

	; Final Ruby-style launch/contact sound split. On the 18-frame throw use
	; Gold's short Razor Wind rush instead of the legacy Silph Scope chirp.
	; Gold's own Pay Day sequence plays Pound before the coin, whereas
	; Ruby plays its wind effect on launch and Pay Day jingle at contact.
	xor a
	ld [wFrequencyModifier],a
	ld a,$ff
	ld [wTempoModifier],a
	ld a,GSSFX_PAY_DAY_RAZOR_WIND
	call PlaySound

	xor a
	ld [wSubAnimCounter],a
.frameLoop
	; Get one of the three size-aware paths (36 bytes each).
	ld a,[wBattleAnimStageCarryTimer]
	add a
	ld e,a
	ld d,0
	ld hl,.flightTablePtrs
	add hl,de
	ld a,[hli]
	ld h,[hl]
	ld l,a
	; Enemy uses the exact same coordinates in reverse order.
	ld a,[wSubAnimCounter]
	ld b,a
	ld a,[H_WHOSETURN]
	and a
	jr z,.playerFrame
	ld a,PAY_DAY_FLIGHT_POINTS - 1
	sub b
	jr .indexFrame
.playerFrame
	ld a,b
.indexFrame
	add a
	ld e,a
	ld d,0
	add hl,de
	ld a,[hli]
	ld b,a                            ; coin centre X
	ld c,[hl]                         ; coin centre Y
	call .DrawCoin
	call DelayFrame
	call ClearSprites
	ld hl,wSubAnimCounter
	inc [hl]
	ld a,[hl]
	cp PAY_DAY_FLIGHT_POINTS
	jr c,.frameLoop

	; The temporary spin graphics occupy OBJ $60-$6f. Two of those slots
	; ($6d/$6e) are used by FrameBlock01's hit burst. Restore *only* these
	; two tiles from the original RPP animation sheet before the hit, as Egg
	; Bomb similarly replaces projectile graphics before its explosion.
	; $52 subsequently reloads its normal animation graphics itself.
	ld hl,vSprites + PAY_DAY_HIT_TILE_MID * 16
	ld de,AnimationTileset1 + $3c * 16
	ld b,BANK(AnimationTileset1)
	ld c,2
	call CopyVideoData

	; Part 2: keep the same 6-frame centred hit pose, but start Gold's
	; real two-pulse Pay Day coin jingle at contact (as Ruby's timing does).
	; Do not also start Pound here: a second PlaySound can cut the jingle.
	callba _LoadAnimationTilesetPalettes
	xor a
	ld [wFrequencyModifier],a
	ld a,$ff
	ld [wTempoModifier],a
	ld a,GSSFX_PAY_DAY_COIN
	call PlaySound
	ld a,PAY_DAY_HIT_FRAMES
	ld [wSubAnimCounter],a
.impactLoop
	call .DrawCenteredHit
	call DelayFrame
	call ClearSprites
	ld hl,wSubAnimCounter
	dec [hl]
	jr nz,.impactLoop

	; The extended recipe continues with the original $52 bounce, but no
	; SFX for that third stage. Do not leak size/cache state into interpreter.
	xor a
	ld [wBattleAnimStageCarryTimer],a
	ld [wSubAnimCounter],a
	ret

.CacheEnemyFrontSize
	; Mirror the verified Volt Tackle header save/restore. The display size
	; can vary by form; don't overwrite the persistent battle header.
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
	ld a,2                         ; 7x7 fallback
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

.SetVictimCenter
	ld a,[H_WHOSETURN]
	and a
	jr nz,.victimPlayer
	ld a,[wBattleAnimStageCarryTimer]
	ld c,a
	ld b,0
	ld hl,.enemyCenterX
	add hl,bc
	ld a,[hl]
	ld [wBaseCoordX],a
	ld hl,.enemyCenterY
	add hl,bc
	ld a,[hl]
	ld [wBaseCoordY],a
	ret
.victimPlayer
	ld a,48
	ld [wBaseCoordX],a
	ld a,88
	ld [wBaseCoordY],a
	ret

.DrawCoin
	; As in Egg Bomb's .DrawEgg: rewrite the same four OAM quadrants on each
	; VBlank without changing the position/timing tables. The original RPP
	; coin is 16x16; all poses keep its centre fixed at (B,C).
	ld a,c
	sub 8
	ld [wOAMBuffer + 0],a
	ld [wOAMBuffer + 4],a
	add 8
	ld [wOAMBuffer + 8],a
	ld [wOAMBuffer + 12],a
	ld a,b
	sub 8
	ld [wOAMBuffer + 1],a
	ld [wOAMBuffer + 9],a
	add 8
	ld [wOAMBuffer + 5],a
	ld [wOAMBuffer + 13],a

	; One pose every two position updates: 0/45/90/135 degrees from
	; gfx/pay_day_spin.2bpp, then 180/225/270/315 via H+V OAM flips.
	; Eight phases take 16 frames, so the 18-frame throw makes one turn.
	ld a,[wSubAnimCounter]
	srl a
	and 7
	bit 2,a
	jr z,.forward
	and 3
	add a
	add a
	add PAY_DAY_SPIN_TILE_BASE + 3
	ld h,OAM_HFLIP | OAM_VFLIP
	ld l,$ff                     ; tile order 3,2,1,0
	jr .paint
.forward
	add a
	add a
	add PAY_DAY_SPIN_TILE_BASE
	ld h,0
	ld l,1                       ; tile order 0,1,2,3
.paint
	ld b,a
	ld de,wOAMBuffer + 2
	ld c,4
.paintLoop
	ld a,b
	ld [de],a
	inc de
	ld a,h
	ld [de],a
	inc de
	inc de
	inc de
	ld a,b
	add l
	ld b,a
	dec c
	jr nz,.paintLoop
	ret

.DrawCenteredHit
	; Nine pieces match FrameBlock01; each offset is measured relative
	; to the *centre* rather than the old generic $01 two-hit anchors.
	ld hl,.hitOffsets
	ld de,wOAMBuffer
	ld b,9
.hitLoop
	ld a,[wBaseCoordY]
	add [hl]
	inc hl
	ld [de],a
	inc de
	ld a,[wBaseCoordX]
	add [hl]
	inc hl
	ld [de],a
	inc de
	ld a,[hli]
	add $31
	ld [de],a
	inc de
	ld a,[hli]
	ld [de],a
	inc de
	dec b
	jr nz,.hitLoop
	ret

.hitOffsets
	; y relative to centre, x relative to centre, tile, OAM flips.
	db -12,-12,$2c,0
	db -12, -4,$2d,0
	db -12,  4,$2c,OAM_HFLIP
	db  -4,-12,$3c,0
	db  -4, -4,$3d,0
	db  -4,  4,$3c,OAM_HFLIP
	db   4,-12,$2c,OAM_VFLIP
	db   4, -4,$2d,OAM_VFLIP
	db   4,  4,$2c,OAM_HFLIP | OAM_VFLIP
.hitOffsetsEnd
	ASSERT .hitOffsetsEnd - .hitOffsets == 9 * 4

.enemyCenterX
	db 132,136,132
.enemyCenterY
	db 52,48,44
.flightTablePtrs
	dw .flight5x5,.flight6x6,.flight7x7

.flight5x5
	db  48,88,  53,86,  58,84,  63,82
	db  68,80,  73,77,  78,75,  83,73
	db  88,71,  92,69,  97,67, 102,65
	db 107,63, 112,60, 117,58, 122,56
	db 127,54, 132,52

.flight6x6
	db  48,88,  53,86,  58,83,  64,81
	db  69,79,  74,76,  79,74,  84,72
	db  89,69,  95,67, 100,64, 105,62
	db 110,60, 115,57, 120,55, 126,53
	db 131,50, 136,48

.flight7x7
	db  48,88,  53,85,  58,83,  63,80
	db  68,78,  73,75,  78,72,  83,70
	db  88,67,  92,65,  97,62, 102,60
	db 107,57, 112,54, 117,52, 122,49
	db 127,47, 132,44
.flightEnd
	ASSERT .flight6x6 - .flight5x5 == PAY_DAY_FLIGHT_POINTS * 2
	ASSERT .flight7x7 - .flight6x6 == PAY_DAY_FLIGHT_POINTS * 2
	ASSERT .flightEnd - .flight7x7 == PAY_DAY_FLIGHT_POINTS * 2


; ANIM-5.62.85: Ruby uses AFFINEANIMCMD_FRAME(0,0,10,1) and rotates
; the coin *within the screen plane* during sub_80CFF68's bouncing phase.
; RPP's $52 still owns its seven legacy bounce coordinates and durations;
; smooth interpolation still owns movement. The first frame installs 16
; spun tiles *after* $52's normal animation-tileset reload. OBJ $60-$6f
; avoids overwriting stock coin tiles $7c/$7d or battle OBJ $80+ slots.
; Only the coin's OAM tiles, flips and bottom-quadrant X are modified.
;
; Four 45-degree sprite rasters plus their hardware 180-degree H/V flips
; create eight 45-degree poses. Each lasts three frames: a 24-frame turn,
; close to Ruby's ~25.6-frame affine revolution. The 16 new tiles need only
; two VBlanks to install, not four, without touching stock coin tiles.
; FrameBlock77 has exactly four sprites; no new OAM entries or WRAM are used.
UpdatePayDayBounceCoinSpin::
	ld a,[wNumFBTiles]
	cp 4
	ret nz
	ld a,[wSubAnimCounter]
	cp 1
	ret c
	cp 8
	ret nc
	; Load after $52 has reloaded the normal 79-tile animation sheet.
	; Only this first $52 frame installs the rotated sprites in OBJ $60-$6f.
	; Those 16 slots are overwritten by normal loading for later effects.
	cp 7
	jr nz,.poseReady
	ld a,[wFBTileCounter]
	cp 4
	jr nz,.poseReady
	ld hl,vSprites + PAY_DAY_SPIN_TILE_BASE * 16
	ld de,PayDaySpinTiles
	ld b,BANK(PayDaySpinTiles)
	ld c,PAY_DAY_SPIN_TILE_COUNT
	call CopyVideoData
	ld a,2
	ld [rSVBK],a
	ld hl,W2_SpritePaletteMap + PAY_DAY_SPIN_TILE_BASE
	ld b,PAY_DAY_SPIN_TILE_COUNT
	ld a,ATK_PAL_YELLOW
.paletteLoop
	ld [hli],a
	dec b
	jr nz,.paletteLoop
	ld a,1
	ld [W2_ForceOBPUpdate],a
	xor a
	ld [rSVBK],a
.poseReady
	ld a,[wSubAnimCounter]
	ld e,a
	ld a,7
	sub e
	ld e,a
	ld d,0
	ld hl,.anchorFrameOffsets
	add hl,de
	ld a,[wFBTileCounter]
	sub 4
	add [hl]
	ld e,a
	ld hl,.phaseByDisplayedFrame
	add hl,de
	ld a,[hl]                    ; phase 0..7
	bit 2,a                       ; phases 4..7 are 180-degree rotated 0..3
	jr z,.forwardPose
	and 3
	add a
	add a
	add PAY_DAY_SPIN_TILE_BASE + 3
	ld b,a                       ; first drawn tile is bottom-right raster
	ld h,OAM_HFLIP | OAM_VFLIP
	ld l,$ff                     ; tile order 3,2,1,0
	jr .paintPose
.forwardPose
	add a
	add a
	add PAY_DAY_SPIN_TILE_BASE
	ld b,a
	ld h,0
	ld l,1                       ; tile order 0,1,2,3
.paintPose

	; Preserve current smooth X/Y motion: read sprite 0's drawn X as the
	; anchor. All four pieces occupy a centered, upright 16x16 OAM grid.
	ld a,[wFBDestAddr + 1]
	ld e,a
	ld a,[wFBDestAddr]
	ld d,a
	inc de                       ; sprite 0 X
	ld a,[de]
	ld c,a
	inc de                       ; sprite 0 tile
	ld a,b
	ld [de],a
	inc de
	ld a,h
	ld [de],a                 ; sprite 0 flip flags
	inc de                       ; sprite 1 Y
	inc de                       ; sprite 1 X
	ld a,c
	add 8
	ld [de],a
	inc de                       ; sprite 1 tile
	ld a,b
	add l
	ld b,a
	ld [de],a
	inc de
	ld a,h
	ld [de],a                 ; sprite 1 flags
	inc de                       ; sprite 2 Y
	inc de                       ; sprite 2 X
	ld a,c
	ld [de],a
	inc de                       ; sprite 2 tile
	ld a,b
	add l
	ld b,a
	ld [de],a
	inc de
	ld a,h
	ld [de],a                 ; sprite 2 flags
	inc de                       ; sprite 3 Y
	inc de                       ; sprite 3 X
	ld a,c
	add 8
	ld [de],a
	inc de                       ; sprite 3 tile
	ld a,b
	add l
	ld [de],a
	inc de
	ld a,h
	ld [de],a                 ; sprite 3 flags

	; DrawFrameBlock resets this count to 4 at every fresh keyframe. It is
	; safe to use as a local display-frame counter after its drawing loop.
	ld hl,wFBTileCounter
	inc [hl]
	ret

.anchorFrameOffsets
	; Each of the 7 legacy $52 anchors lasts 4 waits + 1 cleanup VBlank.
	db 0,5,10,15,20,25,30

.phaseByDisplayedFrame
	db 0,0,0,1,1,1,2,2,2,3
	db 3,3,4,4,4,5,5,5,6,6
	db 6,7,7,7,0,0,0,1,1,1
	db 2,2,2,3,3
.phaseByDisplayedFrameEnd
	ASSERT .phaseByDisplayedFrameEnd - .phaseByDisplayedFrame == 35

PayDaySpinTiles:
	INCBIN "gfx/pay_day_spin.2bpp"
PayDaySpinTilesEnd:
	ASSERT PayDaySpinTilesEnd - PayDaySpinTiles == PAY_DAY_SPIN_TILE_COUNT * 16
