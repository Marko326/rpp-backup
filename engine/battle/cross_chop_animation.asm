; ANM-5.61.67: Gold/Crystal-style Cross Chop for expanded move CROSS_CHOP.
;
; Restore the original Gen II presentation without importing the full battle-
; animation engine. Cross Chop only references cut.png tiles 1 and 2, so keep
; just those two exact RGBGFX tiles here and rebuild the original OAM geometry.
;
; Gold/Crystal visible timeline reproduced here:
;   - frame 0: SFX_CUT and both crossing cut objects spawn at (152,40)/(120,72).
;   - frames 9..96: SHAKE_SCREEN_X $58,$2,$0 => 88 frames of +/-2 px shake,
;     changing direction every VBlank exactly like Gold/Crystal.
;   - ANM-5.61.67: horizontal shake reuses Aeroblast's shared VBlank WX latch;
;     the normal battle Window stays intact and the whole frame moves before scanline 0.
;   - object OAM grows 5,6,7 sprites, holds the 7-sprite pose through frame 104,
;     then expands 8,9,10 sprites and retracts to a 6-sprite diagonal at 111..113.
;   - frames 114..116 are the first OAM wait; the 6-sprite diagonal returns at 117..119.
;   - frame 102: SFX_VICEGRIP and FLASH_INVERTED $0,$8,$10 begin; the visible
;     script window is inverted for frames 102..110 and normal again at 111.
;   - the parent Gold script returns after its 16-count wait, on frame 119.
; RELATIVE_X + fixY $ff maps enemy centers to x=180-x, y=40+y and adds the
; object's X flip. CrossChop2 adds a frameset X+Y flip on top of that.

CROSS_CHOP_TILE_BASE     EQU $60
CROSS_CHOP_TILE_COUNT    EQU 2
CROSS_CHOP_SHAKE_START   EQU 9
CROSS_CHOP_SHAKE_END     EQU 97
CROSS_CHOP_IMPACT_START  EQU 102
CROSS_CHOP_FLASH_NORMAL  EQU 111
CROSS_CHOP_FIRST_WAIT    EQU 114
CROSS_CHOP_SECOND_SLASH  EQU 117
CROSS_CHOP_TOTAL_FRAMES  EQU 120

PlayGoldCrossChopAnimation::
	; Initialize the normal battle-animation palette state, then overwrite two
	; private tile slots with the exact Gold cut tiles used by Cross Chop.
	xor a
	ld [wWhichBattleAnimTileset], a
	callba LoadAnimationTileset
	ld hl, vSprites + CROSS_CHOP_TILE_BASE * 16
	ld de, GoldCrossChopCutTiles
	ld b, BANK(GoldCrossChopCutTiles)
	ld c, CROSS_CHOP_TILE_COUNT
	call CopyVideoData

	; Gold uses PAL_BATTLE_OB_GRAY for both objects.
	ld a, 2
	ld [rSVBK], a
	ld hl, W2_SpritePaletteMap + CROSS_CHOP_TILE_BASE
	ld b, CROSS_CHOP_TILE_COUNT
	ld a, ATK_PAL_GREY
.paletteMapLoop
	ld [hli], a
	dec b
	jr nz, .paletteMapLoop
	ld a, 1
	ld [W2_ForceOBPUpdate], a
	xor a
	ld [rSVBK], a

	; ANM-5.61.67: share Aeroblast's VBlank-latched WX path without moving the
	; battle Window or changing BG-map/auto-transfer ownership.
	call GoldBattleHorizontalShakeBegin

	ld a, GSSFX_CUT
	call PlaySound
	xor a
	ld [wSubAnimCounter], a

.frameLoop
	call .UpdateImpact
	ld de, wOAMBuffer
	call .DrawObject1
	call .DrawObject2

	; Same core as Aeroblast, with Cross Chop's Gold tuple: frames 9..96,
	; 2 pixels, sign changes every VBlank.
	call .SetHorizontalShake
	call DelayFrame
	call ClearSprites

	ld hl, wSubAnimCounter
	inc [hl]
	ld a, [hl]
	cp CROSS_CHOP_TOTAL_FRAMES
	jr c, .frameLoop

	xor a
	ld [wSubAnimCounter], a
	callba AnimationResetScreenPalette
	jp GoldBattleHorizontalShakeEnd

.UpdateImpact
	ld a, [wSubAnimCounter]
	cp CROSS_CHOP_IMPACT_START
	jr nz, .checkFlashNormal
	ld a, GSSFX_VICEGRIP
	call PlaySound
	ld a, $1b
	ld [rBGP], a
	ret
.checkFlashNormal
	cp CROSS_CHOP_FLASH_NORMAL
	ret nz
	ld a, $e4
	ld [rBGP], a
	ret

.SetHorizontalShake
	ld b, CROSS_CHOP_SHAKE_START
	ld c, CROSS_CHOP_SHAKE_END
	ld d, 1 ; Gold $0 phase: flip sign every VBlank.
	ld e, 2
	jp GoldBattleHorizontalShakeSet

.DrawObject1
	ld b, 152
	ld c, 40
	xor a ; CrossChop1 has no frameset-level flip.
	jr .DrawObject

.DrawObject2
	ld b, 120
	ld c, 72
	ld a, OAM_HFLIP | OAM_VFLIP ; CrossChop2 frameset adds X+Y flip.

.DrawObject
	; wDropletTile is generic battle-animation scratch. Here it carries the
	; effective whole-object flip flags while the tile base stays constant.
	ld [wDropletTile], a
	ld a, [H_WHOSETURN]
	and a
	jr z, .playerCenter

	; RELATIVE_X + fixY $ff: x=180-x, y=40+y. Enemy objects additionally XOR
	; OAM_XFLIP into the frameset flags.
	ld a, 180
	sub b
	ld [wBaseCoordX], a
	ld a, c
	add 40
	ld [wBaseCoordY], a
	ld a, [wDropletTile]
	xor OAM_HFLIP
	ld [wDropletTile], a
	jr .centerReady

.playerCenter
	ld a, b
	ld [wBaseCoordX], a
	ld a, c
	ld [wBaseCoordY], a
.centerReady
	call .SelectFrameLayout
	ret nc
	jp .DrawOAMLayout

.SelectFrameLayout
	; Gen II oamframe duration N stays visible for N+1 playframes. The three
	; consecutive OAMSET_4D entries therefore form one 99-frame held pose.
	ld a, [wSubAnimCounter]
	cp 3
	jr c, .frame4B
	cp 6
	jr c, .frame4C
	cp 105
	jr c, .frame4D
	cp 107
	jr c, .frame4F
	cp 109
	jr c, .frame50
	cp 111
	jr c, .frame51
	cp CROSS_CHOP_FIRST_WAIT
	jr c, .frame52
	cp CROSS_CHOP_SECOND_SLASH
	jr c, .blankFrame
	cp CROSS_CHOP_TOTAL_FRAMES
	jr c, .frame52
.blankFrame
	and a
	ret
.frame4B
	ld hl, CrossChopOAM4B
	ld b, 5
	scf
	ret
.frame4C
	ld hl, CrossChopOAM4C
	ld b, 6
	scf
	ret
.frame4D
	ld hl, CrossChopOAM4D
	ld b, 7
	scf
	ret
.frame4F
	ld hl, CrossChopOAM4F
	ld b, 8
	scf
	ret
.frame50
	ld hl, CrossChopOAM50
	ld b, 9
	scf
	ret
.frame51
	ld hl, CrossChopOAM51
	ld b, 10
	scf
	ret
.frame52
	ld hl, CrossChopOAM51 ; Gold OAMSET_52 uses the first six entries of OAMData_51.
	ld b, 6
	scf
	ret

.DrawOAMLayout
	; HL = y/x/tile/attr tuples, B = sprite count, DE = next OAM slot.
	; Apply the same whole-frame/object transform as Gen II BattleAnimOAMUpdate:
	; flipped 8x8 offsets become -(offset+8), and flip flags XOR sprite attrs.
.spriteLoop
	ld a, [hli]
	ld c, a
	ld a, [wDropletTile]
	and OAM_VFLIP
	ld a, c
	jr z, .gotYOffset
	add 8
	cpl
	inc a
.gotYOffset
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
	jr z, .gotXOffset
	add 8
	cpl
	inc a
.gotXOffset
	ld c, a
	ld a, [wBaseCoordX]
	add c
	ld [de], a
	inc de

	ld a, [hli]
	add CROSS_CHOP_TILE_BASE
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

; Exact Gold OAM sets used by BATTLE_ANIM_FRAMESET_CROSS_CHOP_1/_2 after the
; OAM-set vtile offset +1 is folded into the two private tiles below.
CrossChopOAM4B:
	db  -4, -4,0,0
	db  -4,-12,1,0
	db  -4, -4,1,OAM_HFLIP
	db   4,-12,1,OAM_VFLIP
	db   4, -4,1,OAM_HFLIP | OAM_VFLIP

CrossChopOAM4C:
	db  -4, -4,0,0
	db   2,-10,0,0
	db   2,-18,1,0
	db   2,-10,1,OAM_HFLIP
	db  10,-18,1,OAM_VFLIP
	db  10,-10,1,OAM_HFLIP | OAM_VFLIP

CrossChopOAM4D:
	db  -4, -4,0,0
	db   2,-10,0,0
	db   8,-16,0,0
	db   8,-24,1,0
	db   8,-16,1,OAM_HFLIP
	db  16,-24,1,OAM_VFLIP
	db  16,-16,1,OAM_HFLIP | OAM_VFLIP

CrossChopOAM4F:
	db  -4, -4,0,0
	db   2,-10,0,0
	db   8,-16,0,0
	db  14,-22,0,0
	db  14,-30,1,0
	db  14,-22,1,OAM_HFLIP
	db  22,-30,1,OAM_VFLIP
	db  22,-22,1,OAM_HFLIP | OAM_VFLIP

CrossChopOAM50:
	db  -4, -4,0,0
	db   2,-10,0,0
	db   8,-16,0,0
	db  14,-22,0,0
	db  20,-28,0,0
	db  20,-36,1,0
	db  20,-28,1,OAM_HFLIP
	db  28,-36,1,OAM_VFLIP
	db  28,-28,1,OAM_HFLIP | OAM_VFLIP

CrossChopOAM51:
	db  -4, -4,0,0
	db   2,-10,0,0
	db   8,-16,0,0
	db  14,-22,0,0
	db  20,-28,0,0
	db  26,-34,0,0
	db  26,-42,1,0
	db  26,-34,1,OAM_HFLIP
	db  34,-42,1,OAM_VFLIP
	db  34,-34,1,OAM_HFLIP | OAM_VFLIP

; Exact RGBGFX 2bpp conversion of Gold/Crystal cut.png tiles 1 and 2. Cross Chop
; never references the other four tiles from that sheet.
GoldCrossChopCutTiles:
	db $03,$04,$07,$08,$0e,$11,$1c,$22,$38,$44,$70,$88,$e0,$10,$c0,$20
	db $00,$01,$00,$41,$01,$32,$13,$2c,$0f,$10,$0f,$10,$1f,$20,$3f,$c0
GoldCrossChopCutTilesEnd:
	IF GoldCrossChopCutTilesEnd - GoldCrossChopCutTiles != CROSS_CHOP_TILE_COUNT * 16
		fail "Gold Cross Chop cut tile data must contain exactly 2 tiles"
	ENDC
