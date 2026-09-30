; ANM-5.61.47: near-original Gold/Crystal Aeroblast for expanded move AEROBLAST.
; Keep one local 84-VBlank timeline so the horizontal shake can remain active while
; the three Beam objects and Beam Tip appear, matching the Gen 2 overlap instead of
; serialising the fan and beam stages through the Gen 1 command stream.
;
; Gold/Crystal sequence reproduced here:
;   BGP $1b; SHAKE_SCREEN_X($50,$4,$10); gray/yellow OBJ palette cycle;
;   Aeroblast fan at (72,88), 4 poses * 4 VBlanks; wait through VBlank 31;
;   Beam at (80,84) on 32, Beam at (96,76) on 34,
;   Beam at (112,68) + Beam Tip at (126,62) on 36; finish at VBlank 84.
; Gold's RELATIVE_X | OAM_XFLIP | OAM_YFLIP fixing is reproduced for enemy users.

AEROBLAST_FAN_TILE_BASE   EQU $60
AEROBLAST_FAN_TILE_COUNT  EQU 24
AEROBLAST_BEAM_TILE_BASE  EQU $52
AEROBLAST_BEAM_TILE_COUNT EQU 11 ; exact processed Gold Beam gfx set; Aeroblast uses $00-$09.
AEROBLAST_TOTAL_FRAMES    EQU 84
AEROBLAST_SHAKE_FRAMES    EQU 80

PlayGoldAeroblastAnimation::
	; Load the ordinary battle-animation palette infrastructure first, then replace
	; only private tile slots with the exact Gen 2 Aeroblast/Beam graphics below.
	xor a
	ld [wWhichBattleAnimTileset], a
	callba LoadAnimationTileset

	ld hl, vSprites + AEROBLAST_FAN_TILE_BASE * 16
	ld de, GoldAeroblastTiles
	ld b, BANK(GoldAeroblastTiles)
	ld c, AEROBLAST_FAN_TILE_COUNT
	call CopyVideoData

	ld hl, vSprites + AEROBLAST_BEAM_TILE_BASE * 16
	ld de, GoldAeroblastBeamTiles
	ld b, BANK(GoldAeroblastBeamTiles)
	ld c, AEROBLAST_BEAM_TILE_COUNT
	call CopyVideoData

	; Gold/Crystal use anim_bgp $1b. This is much closer to their dark/inverted
	; stage than the generic Gen 1 $6f blackout and remains active for the move.
	ld a, $1b
	ld [rBGP], a

	ld a, GSSFX_AEROBLAST
	call PlaySound

	xor a
	ld [wSubAnimCounter], a
.frameLoop
	call .UpdateObjPalette

	; The dedicated fan exists only for the first 16 VBlanks: four 4-frame poses.
	ld a, [wSubAnimCounter]
	cp 16
	jr nc, .fanDone
	srl a
	srl a
	call .DrawFanFrame
.fanDone

	; Gold retriggers Hyper Beam SFX as each beam section is added.
	ld a, [wSubAnimCounter]
	cp 32
	call z, .PlayHyperBeamSfx
	ld a, [wSubAnimCounter]
	cp 34
	call z, .PlayHyperBeamSfx
	ld a, [wSubAnimCounter]
	cp 36
	call z, .PlayHyperBeamSfx

	; Draw every live Beam object into the same OAM buffer. Their 44-frame
	; lifetimes naturally overlap while the background shake continues.
	ld de, wOAMBuffer
	ld a, [wSubAnimCounter]
	cp 32
	jr c, .beam1Done
	sub 32
	cp 44
	jr nc, .beam1Done
	ld b, 80
	ld c, 84
	call .DrawBeam
.beam1Done
	ld a, [wSubAnimCounter]
	cp 34
	jr c, .beam2Done
	sub 34
	cp 44
	jr nc, .beam2Done
	ld b, 96
	ld c, 76
	call .DrawBeam
.beam2Done
	ld a, [wSubAnimCounter]
	cp 36
	jr c, .beam3Done
	sub 36
	cp 44
	jr nc, .beam3Done
	ld b, 112
	ld c, 68
	call .DrawBeam
.beam3Done

	; Beam Tip starts with the third section and remains through the final wait.
	ld a, [wSubAnimCounter]
	cp 36
	jr c, .tipDone
	ld b, 126
	ld c, 62
	call .DrawBeamTip
.tipDone

	; Gold's shake is +/-4 px, flips direction every two VBlanks, and lasts 80.
	call .ApplyHorizontalShake
	call DelayFrame
	call .UndoHorizontalShake
	call ClearSprites

	ld hl, wSubAnimCounter
	inc [hl]
	ld a, [hl]
	cp AEROBLAST_TOTAL_FRAMES
	jp c, .frameLoop

	; Gen 2's animation cleanup restores the battle palette after the command ends.
	callba AnimationResetScreenPalette
	ret

.PlayHyperBeamSfx
	; RPP's Hyper Beam MoveSoundTable entry is SFX_BATTLE_36 with $00/$80
	; pitch/tempo. Reuse those exact Gen 1 sound parameters three times.
	xor a
	ld [wFrequencyModifier], a
	ld a, $80
	ld [wTempoModifier], a
	ld a, SFX_BATTLE_36
	jp PlaySound

.UpdateObjPalette
	; Gen 2 CYCLE_OBPALS_GRAY_AND_YELLOW with argument $2 changes state every
	; three VBlanks. RPP already has both OBJ palettes, so only remap these private
	; tile ranges instead of importing the Gen 2 background-effect scheduler.
	ld a, [wSubAnimCounter]
	ld c, 0
.mod3
	cp 3
	jr c, .remainder
	sub 3
	inc c
	jr .mod3
.remainder
	and a
	ret nz
	ld a, c
	and 1
	ld d, ATK_PAL_GREY
	jr z, .gotPalette
	ld d, ATK_PAL_YELLOW
.gotPalette
	ld a, 2
	ld [rSVBK], a
	ld hl, W2_SpritePaletteMap + AEROBLAST_BEAM_TILE_BASE
	ld b, AEROBLAST_BEAM_TILE_COUNT
	ld a, d
.beamMapLoop
	ld [hli], a
	dec b
	jr nz, .beamMapLoop
	ld hl, W2_SpritePaletteMap + AEROBLAST_FAN_TILE_BASE
	ld b, AEROBLAST_FAN_TILE_COUNT
	ld a, d
.fanMapLoop
	ld [hli], a
	dec b
	jr nz, .fanMapLoop
	ld a, 1
	ld [W2_ForceOBPUpdate], a
	xor a
	ld [rSVBK], a
	ret

.ApplyHorizontalShake
	ld a, [wSubAnimCounter]
	cp AEROBLAST_SHAKE_FRAMES
	ret nc
	and 2
	ld a, [rWX]
	jr nz, .shakeRight
	sub 4 ; Gold's first two shake frames use -4.
	ld [rWX], a
	ret
.shakeRight
	add 4
	ld [rWX], a
	ret

.UndoHorizontalShake
	ld a, [wSubAnimCounter]
	cp AEROBLAST_SHAKE_FRAMES
	ret nc
	and 2
	ld a, [rWX]
	jr nz, .undoRight
	add 4
	ld [rWX], a
	ret
.undoRight
	sub 4
	ld [rWX], a
	ret

.DrawFanFrame
	; A = pose 0..3. Gold OAM sets CF-D2 use six new tiles per pose.
	ld c, a
	add a
	add c
	add a
	add AEROBLAST_FAN_TILE_BASE
	ld [wDropletTile], a
	ld b, 72
	ld c, 88
	call .SetRelativeCenter
	ld hl, AeroblastFanOAMLayout
	ld b, 12
	jp .DrawOAMLayout

.DrawBeam
	; A = object age 0..43, B/C = Gold logical center, DE = next OAM lane.
	push af
	call .SetRelativeCenter
	pop af
	cp 4
	jr nc, .beamHold
	ld a, AEROBLAST_BEAM_TILE_BASE
	ld [wDropletTile], a
	ld hl, AeroblastBeamEarlyOAMLayout
	ld b, 4
	jp .DrawOAMLayout
.beamHold
	ld a, AEROBLAST_BEAM_TILE_BASE + 2
	ld [wDropletTile], a
	ld hl, AeroblastBeamHoldOAMLayout
	ld b, 4
	jp .DrawOAMLayout

.DrawBeamTip
	; B/C = Gold logical center. Param 0 makes Gen 2's SHAKE object function a
	; no-op, so the tip itself is stationary while the screen shake supplies motion.
	call .SetRelativeCenter
	ld a, AEROBLAST_BEAM_TILE_BASE + 4
	ld [wDropletTile], a
	ld hl, AeroblastBeamTipOAMLayout
	ld b, 6
	jp .DrawOAMLayout

.SetRelativeCenter
	; B/C = Gold logical X/Y. All Aeroblast/Beam objects use RELATIVE_X and fixY
	; $98; enemy use therefore maps center to x=180-x, y=152-y.
	ld a, [H_WHOSETURN]
	and a
	jr nz, .enemyCenter
	ld a, b
	ld [wBaseCoordX], a
	ld a, c
	ld [wBaseCoordY], a
	ret
.enemyCenter
	ld a, 180
	sub b
	ld [wBaseCoordX], a
	ld a, 152
	sub c
	ld [wBaseCoordY], a
	ret

.DrawOAMLayout
	; HL = y/x/tile/attr entries, B = sprite count, DE = destination.
	; Gen 2's object-level X/Y flip transforms an 8x8 OAM coordinate as
	; -(offset+8) and toggles both sprite flip flags for enemy users.
.spriteLoop
	ld a, [hli]
	ld c, a
	ld a, [H_WHOSETURN]
	and a
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
	ld a, [H_WHOSETURN]
	and a
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
	ld c, a
	ld a, [wDropletTile]
	add c
	ld [de], a
	inc de

	ld a, [hli]
	ld c, a
	ld a, [H_WHOSETURN]
	and a
	ld a, c
	jr z, .gotAttributes
	xor OAM_HFLIP | OAM_VFLIP
.gotAttributes
	ld [de], a
	inc de

	dec b
	jr nz, .spriteLoop
	ret

; Exact Gold OAMData_cf geometry used by OAM sets CF-D2.
AeroblastFanOAMLayout:
	db -16,-12,0,0
	db -16, -4,1,0
	db -16,  4,2,0
	db  -8,-12,3,0
	db  -8, -4,4,0
	db  -8,  4,5,0
	db   0,-12,5,OAM_HFLIP | OAM_VFLIP
	db   0, -4,4,OAM_HFLIP | OAM_VFLIP
	db   0,  4,3,OAM_HFLIP | OAM_VFLIP
	db   8,-12,2,OAM_HFLIP | OAM_VFLIP
	db   8, -4,1,OAM_HFLIP | OAM_VFLIP
	db   8,  4,0,OAM_HFLIP | OAM_VFLIP

; Exact Gold OAMData_2f, OAMData_30 and OAMData_31 geometry for Beam/Beam Tip.
AeroblastBeamEarlyOAMLayout:
	db -8,-8,0,0
	db -8, 0,0,OAM_HFLIP
	db  0,-8,1,0
	db  0, 0,0,OAM_HFLIP | OAM_VFLIP

AeroblastBeamHoldOAMLayout:
	db -8,-8,0,0
	db -8, 0,1,0
	db  0,-8,1,OAM_HFLIP | OAM_VFLIP
	db  0, 0,0,OAM_HFLIP | OAM_VFLIP

AeroblastBeamTipOAMLayout:
	db -12,-8,0,0
	db -12, 0,1,0
	db  -4,-8,2,0
	db  -4, 0,3,0
	db   4,-8,4,0
	db   4, 0,5,0

; Exact RGBGFX 2bpp conversion of pokegold/pokecrystal aeroblast.png (24x64).
; Gold and Crystal assets are byte-identical; six tiles are consumed per pose.
GoldAeroblastTiles:
	db $00,$00,$00,$00,$03,$00,$07,$00,$0f,$00,$1f,$00,$1f,$00,$3f,$00
	db $3c,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00
	db $00,$00,$00,$00,$c0,$00,$e0,$00,$f0,$00,$f8,$00,$f8,$00,$fc,$00
	db $3f,$00,$7f,$00,$7f,$00,$7f,$00,$7f,$00,$ff,$00,$ff,$00,$ff,$00
	db $ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00
	db $fc,$00,$fe,$00,$fe,$00,$fe,$00,$fe,$00,$ff,$00,$ff,$00,$ff,$00
	db $00,$00,$00,$00,$03,$00,$07,$00,$0f,$00,$1f,$00,$1f,$00,$3f,$00
	db $30,$00,$f3,$00,$f3,$00,$f3,$00,$f3,$00,$f3,$00,$f3,$00,$f3,$00
	db $00,$00,$00,$00,$c0,$00,$e0,$00,$f0,$00,$f8,$00,$f8,$00,$fc,$00
	db $3f,$00,$7f,$00,$7f,$00,$7f,$00,$7f,$00,$7f,$00,$03,$00,$00,$00
	db $f7,$00,$f7,$00,$f7,$00,$f7,$00,$f7,$00,$f7,$00,$f7,$00,$1f,$00
	db $fc,$00,$fe,$00,$fe,$00,$fe,$00,$fe,$00,$ff,$00,$ff,$00,$ff,$00
	db $00,$00,$00,$00,$03,$00,$07,$00,$0f,$00,$1f,$00,$1f,$00,$3f,$00
	db $30,$00,$f0,$00,$f0,$00,$f0,$00,$f0,$00,$f0,$00,$f0,$00,$f1,$00
	db $00,$00,$00,$00,$00,$00,$60,$00,$70,$00,$f8,$00,$f8,$00,$fc,$00
	db $3f,$00,$7f,$00,$7f,$00,$1f,$00,$07,$00,$01,$00,$00,$00,$00,$00
	db $f1,$00,$f1,$00,$f3,$00,$f3,$00,$f3,$00,$f7,$00,$77,$00,$1f,$00
	db $fc,$00,$fe,$00,$fe,$00,$fe,$00,$fe,$00,$ff,$00,$ff,$00,$ff,$00
	db $00,$00,$00,$00,$03,$00,$03,$00,$03,$00,$01,$00,$01,$00,$00,$00
	db $30,$00,$f0,$00,$f0,$00,$f0,$00,$f0,$00,$f0,$00,$f0,$00,$f0,$00
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	db $f0,$00,$70,$00,$70,$00,$30,$00,$30,$00,$11,$00,$17,$00,$1f,$00
	db $00,$00,$00,$00,$06,$00,$1e,$00,$7e,$00,$ff,$00,$ff,$00,$ff,$00
GoldAeroblastTilesEnd:
	IF GoldAeroblastTilesEnd - GoldAeroblastTiles != AEROBLAST_FAN_TILE_COUNT * 16
		fail "Gold Aeroblast tile data must contain exactly 24 tiles"
	ENDC

; Exact Gold/Crystal beam.png output after the original Makefile processing:
; --remove-xflip --remove-yflip --remove-whitespace. The resulting 11-tile set is
; byte-for-byte the object-gfx vocabulary used by Gen 2; Aeroblast addresses $00-$09.
GoldAeroblastBeamTiles:
	db $07,$07,$18,$1f,$27,$38,$58,$60,$50,$60,$a0,$c0,$a0,$c0,$a0,$c0
	db $20,$c0,$40,$80,$80,$00,$00,$00,$78,$00,$c7,$38,$38,$ff,$c7,$c7
	db $00,$00,$00,$00,$00,$00,$00,$00,$03,$03,$0c,$0f,$33,$3c,$cf,$f0
	db $03,$03,$0c,$0f,$33,$3c,$cf,$f0,$3c,$c0,$f3,$00,$cf,$00,$3c,$03
	db $00,$20,$00,$20,$00,$30,$10,$29,$19,$26,$3f,$40,$1f,$e0,$07,$18
	db $00,$10,$00,$30,$00,$60,$40,$a0,$80,$40,$80,$40,$c0,$20,$e0,$1f
	db $03,$04,$01,$02,$01,$02,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01
	db $f8,$06,$f0,$08,$e0,$10,$c0,$20,$c0,$20,$c0,$20,$e0,$10,$f0,$08
	db $00,$01,$01,$02,$01,$02,$03,$04,$07,$08,$00,$1f,$00,$00,$00,$00
	db $f8,$06,$e0,$1f,$c0,$20,$80,$40,$80,$40,$c0,$20,$00,$e0,$00,$30
	db $00,$00,$00,$00,$00,$03,$03,$0c,$0c,$33,$30,$cc,$c0,$30,$00,$c0
GoldAeroblastBeamTilesEnd:
	IF GoldAeroblastBeamTilesEnd - GoldAeroblastBeamTiles != AEROBLAST_BEAM_TILE_COUNT * 16
		fail "Gold Aeroblast Beam tile data must contain exactly 11 tiles"
	ENDC
