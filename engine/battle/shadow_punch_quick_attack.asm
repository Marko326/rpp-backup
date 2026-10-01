; ANM-5.61.59: Gold Quick Attack approach/return for expanded SHADOW_PUNCH.
;
; Reproduce only the parts that belong before/after the hit:
;   SFX_MENU -> hide USER -> six Gold SPEED_LINE objects -> wait 12 -> ...
;   ... Shadow Punch keeps its own hit animation ... -> show USER -> wait 16.
; Gold's SFX_COMET_PUNCH + HIT_YFIX object are deliberately omitted.
;
; The SPEED_LINE renderer uses the exact Gold speed.png tile/OAM geometry and
; RELATIVE_X enemy transform.  Only the single tile actually referenced by
; OAM sets A0-A2 is imported, so the move does not carry unused Gen II gfx.

SHADOW_PUNCH_SPEED_TILE_BASE EQU $60

PlayGoldQuickAttackPhase::
	ld a,e
	cp GOLD_QUICK_ATTACK_PREPARE
	jr z,.prepare
	cp GOLD_QUICK_ATTACK_APPROACH
	jr z,.approach

.returnUser
	; AnimationShowMonPic contains the stock 3-frame redraw delay.  Add 13 to
	; reproduce Gold's 16-frame post-show wait before the animation returns.
	callba AnimationShowMonPic
	ld c,13
	jp DelayFrames

.prepare
	; Prepare the exact tileset used by the following $46 fist while the user is
	; still visible.  With the recipe's Ghost palette + $7A override already set,
	; this also loads PunchBattleTiles into $77-$7f before Quick Attack begins.
	ld a,1
	ld [wWhichBattleAnimTileset],a
	callba LoadAnimationTileset

	; SPEED_LINE only needs one Gold tile.  It lives away from the fist override,
	; so both the approach and the hit can coexist in VRAM.
	ld hl,vSprites + SHADOW_PUNCH_SPEED_TILE_BASE * 16
	ld de,GoldQuickAttackSpeedTile
	ld b,BANK(GoldQuickAttackSpeedTile)
	ld c,1
	call CopyVideoData

	; Gold SPEED_LINE uses PAL_BATTLE_OB_GRAY.  Keep only this private tile gray;
	; the preloaded fist remains on Shadow Punch's dynamic Ghost palette.
	ld a,2
	ld [rSVBK],a
	ld hl,W2_SpritePaletteMap + SHADOW_PUNCH_SPEED_TILE_BASE
	xor a ; ATK_PAL_GREY
	ld [hl],a
	ld a,1
	ld [W2_ForceOBPUpdate],a
	xor a
	ld [rSVBK],a
	ret

.approach
	ld a,GSSFX_MENU
	call PlaySound
	callba AnimationHideMonPic

	; Gold Quick Attack creates all six lines together, then anim_wait 12.
	; Their framesets naturally collapse 7 -> 5 -> 3 sprites over 3 VBlanks;
	; the remaining 9 VBlanks have no speed-line OAM.
	xor a
	ld [wSubAnimCounter],a
.speedLoop
	ld a,[wSubAnimCounter]
	cp 3
	jr nc,.noSpeedLines
	ld de,wOAMBuffer
	call .DrawSpeedFrame
.noSpeedLines
	call DelayFrame
	call ClearSprites
	ld hl,wSubAnimCounter
	inc [hl]
	ld a,[hl]
	cp 12
	jr c,.speedLoop

	; Feed the existing seamless-stage matcher a reserved pseudo-source token.
	; The SHADOW_PUNCH $FD -> $05 entry turns this into a one-shot "same tiles
	; already prepared" marker, so the fist begins immediately instead of
	; spending another ~12 VBlanks reloading tileset + PunchBattleTiles.
	ld a,$FE
	ld [wBattleAnimSeamlessStage],a
	ret

.DrawSpeedFrame
	; A = age 0..2, DE = next OAM entry.
	and a
	jr z,.frame0
	dec a
	jr z,.frame1

.frame2
	ld b,40
	ld c,3
	ld a,3 ; + direction, age+1
	call .DrawSpeedLine
	ld b,48
	ld c,3
	ld a,$83 ; - direction, age+1
	jp .DrawSpeedLine

.frame1
	ld b,32
	ld c,3
	ld a,2
	call .DrawSpeedLine
	ld b,40
	ld c,5
	ld a,2
	call .DrawSpeedLine
	ld b,48
	ld c,5
	ld a,$82
	call .DrawSpeedLine
	ld b,56
	ld c,3
	ld a,$82
	jp .DrawSpeedLine

.frame0
	ld b,24
	ld c,3
	ld a,1
	call .DrawSpeedLine
	ld b,32
	ld c,5
	ld a,1
	call .DrawSpeedLine
	ld b,40
	ld c,7
	ld a,1
	call .DrawSpeedLine
	ld b,48
	ld c,7
	ld a,$81
	call .DrawSpeedLine
	ld b,56
	ld c,5
	ld a,$81
	call .DrawSpeedLine
	ld b,64
	ld c,3
	ld a,$81
	jp .DrawSpeedLine

.DrawSpeedLine
	; B = Gold logical X, C = OAM sprite count (3/5/7).
	; A low 7 bits = age+1 X offset; bit 7 selects Gold's inverted movement.
	push bc
	bit 7,a
	jr nz,.moveLeft
	add b
	jr .logicalXReady
.moveLeft
	and $7f
	ld h,a
	ld a,b
	sub h
.logicalXReady
	ld b,a

	; SPEED_LINE is RELATIVE_X with fixY $88.  Gen II's enemy transform is
	; x = 180 - logicalX, y = $88 - 88 = 48; player y stays 88.
	ld a,[H_WHOSETURN]
	and a
	ld a,b
	jr z,.xReady
	ld h,a
	ld a,180
	sub h
.xReady
	sub 4 ; OAMData_a0 x offset: -1 tile + 4 px
	ld [wBaseCoordX],a
	ld a,[H_WHOSETURN]
	and a
	ld a,88
	jr z,.yReady
	ld a,48
.yReady
	ld [wBaseCoordY],a
	pop bc

	ld hl,GoldQuickAttackSpeedLineYOffsets
.drawSprite
	ld a,[wBaseCoordY]
	add [hl]
	inc hl
	ld [de],a
	inc de
	ld a,[wBaseCoordX]
	ld [de],a
	inc de
	ld a,SHADOW_PUNCH_SPEED_TILE_BASE
	ld [de],a
	inc de
	xor a
	ld [de],a
	inc de
	dec c
	jr nz,.drawSprite
	ret

; Gold OAMData_a0, converted from dbsprite coordinates.  A0/A1/A2 use the
; first 7/5/3 entries respectively, preserving Gold's unusual draw order.
GoldQuickAttackSpeedLineYOffsets:
	db -12,-4,4,-20,12,-28,20

; Exact gfx/battle_anims/speed.png tile $08 after RGBDS 2bpp conversion.
; This is the only tile referenced by Gold SPEED_LINE OAM sets A0-A2.
GoldQuickAttackSpeedTile:
	db $00,$24,$00,$24,$00,$24,$00,$24
	db $00,$24,$00,$24,$00,$24,$00,$24
GoldQuickAttackSpeedTileEnd:
	IF GoldQuickAttackSpeedTileEnd - GoldQuickAttackSpeedTile != 16
		fail "Gold Quick Attack speed-line tile must be exactly one 8x8 tile"
	ENDC
