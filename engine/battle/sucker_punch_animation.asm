; Polished Crystal-inspired Sucker Punch animation-only renderer.
;
; Battle logic is intentionally not implemented here.  The successful-use
; presentation keeps Polished Crystal's hide/speed-line/two-crescent/impact
; identity, but the two crescent strikes borrow Night Slash's strongest visual
; idea: grow into the hit instead of translating a rigid 3x2 block at constant
; speed.  Each strike reveals 1 -> 2 -> 3 columns, carries a short trailing
; smear, then preserves Polished Crystal's broad cross-screen follow-through.
; The final 4x4 hit gets the heaviest VBlank-latched shake.  No full-screen
; palette flash is used.

SUCKER_PUNCH_PUNCH_TILE_BASE  EQU $60
SUCKER_PUNCH_PUNCH_TILE_COUNT EQU 6
SUCKER_PUNCH_SPEED_TILE       EQU $66
SUCKER_PUNCH_HIT_TILE_BASE    EQU $67
SUCKER_PUNCH_HIT_TILE_COUNT   EQU 4
SUCKER_PUNCH_PUNCH_PAL        EQU ATK_PAL_PURPLE
SUCKER_PUNCH_HIT_PAL          EQU BATTLE_TYPE_PAL_TILESET1
SUCKER_PUNCH_DRAW_FRAMES      EQU 75

SUCKER_PUNCH_SLICE_RIGHT_1    EQU 0
SUCKER_PUNCH_SLICE_RIGHT_2    EQU 1
SUCKER_PUNCH_SLICE_FULL       EQU 2
SUCKER_PUNCH_SLICE_NONE       EQU $ff

PlayPolishedCrystalSuckerPunchAnimation::
	call SuckerPunchAnim_LoadTiles
	call SuckerPunchAnim_InstallPalettes
	call SuckerPunchAnim_BeginShake

	ld a,GSSFX_MENU
	call PlaySound
	callba AnimationHideMonPic

	xor a
	ld [wSubAnimCounter],a
SuckerPunchAnim_FrameLoop:
	call SuckerPunchAnim_PlayScheduledSound
	call SuckerPunchAnim_UpdateShake

	ld de,wOAMBuffer
	call SuckerPunchAnim_DrawObjects
	call DelayFrame
	call ClearSprites

	ld hl,wSubAnimCounter
	inc [hl]
	ld a,[hl]
	cp SUCKER_PUNCH_DRAW_FRAMES
	jr c,SuckerPunchAnim_FrameLoop

	; The last shake interval ends well before this point, so the base WX has
	; already been VBlank-latched for multiple frames before the hook is disabled.
	call SuckerPunchAnim_EndShake

	; PC starts SHOW_MON on frame 75 and then waits four ticks. RPP's stock show
	; helper consumes three redraw VBlanks, so two more retain the same five-
	; VBlank command-to-command spacing.
	callba AnimationShowMonPic
	ld c,2
	call DelayFrames

	; Restore the ordinary animation tile->palette map after the private Payback
	; palette.  No BGP flash is used, so there is no background palette state to
	; repair here.
	callba _LoadAnimationTilesetPalettes
	ret

SuckerPunchAnim_LoadTiles:
	ld hl,vSprites + SUCKER_PUNCH_PUNCH_TILE_BASE * 16
	ld de,SuckerPunchCrescentTiles
	ld b,BANK(SuckerPunchCrescentTiles)
	ld c,SUCKER_PUNCH_PUNCH_TILE_COUNT
	call CopyVideoData

	ld hl,vSprites + SUCKER_PUNCH_SPEED_TILE * 16
	ld de,SuckerPunchSpeedTile
	ld b,BANK(SuckerPunchSpeedTile)
	ld c,1
	call CopyVideoData

	ld hl,vSprites + SUCKER_PUNCH_HIT_TILE_BASE * 16
	ld de,SuckerPunchHitTiles
	ld b,BANK(SuckerPunchHitTiles)
	ld c,SUCKER_PUNCH_HIT_TILE_COUNT
	call CopyVideoData
	ret

SuckerPunchAnim_InstallPalettes:
	ld a,2
	ld [rSVBK],a
	ld hl,SuckerPunchPaybackPalette
	ld de,W2_SprPaletteData + SUCKER_PUNCH_PUNCH_PAL * 8
	ld bc,8
	call CopyData

	ld hl,W2_SpritePaletteMap + SUCKER_PUNCH_PUNCH_TILE_BASE
	ld b,SUCKER_PUNCH_PUNCH_TILE_COUNT
	ld a,SUCKER_PUNCH_PUNCH_PAL
SuckerPunchAnim_PunchPaletteMapLoop:
	ld [hli],a
	dec b
	jr nz,SuckerPunchAnim_PunchPaletteMapLoop

	; Keep the speed-line tile on the stock gray palette, but give HIT_BIG its
	; own newer Dark move-type palette.  This deliberately leaves the two
	; Payback-purple crescent strikes on their private palette above.
	ld hl,W2_SpritePaletteMap + SUCKER_PUNCH_SPEED_TILE
	xor a ; PAL_BATTLE_OB_GRAY
	ld [hli],a

	ld d,DARK
	ld e,SUCKER_PUNCH_HIT_PAL
	callba LoadBattleAnimTypePalette_Sprite
	ld a,2
	ld [rSVBK],a
	ld hl,W2_SpritePaletteMap + SUCKER_PUNCH_HIT_TILE_BASE
	ld b,SUCKER_PUNCH_HIT_TILE_COUNT
	ld a,SUCKER_PUNCH_HIT_PAL
SuckerPunchAnim_HitPaletteMapLoop:
	ld [hli],a
	dec b
	jr nz,SuckerPunchAnim_HitPaletteMapLoop

	ld a,1
	ld [W2_ForceOBPUpdate],a
	xor a
	ld [rSVBK],a
	ret

SuckerPunchAnim_BeginShake:
	ld a,7
	ld [wBattleAnimWX],a
	ld a,1
	ld [wBattleAnimWXEnabled],a
	ret

SuckerPunchAnim_EndShake:
	ld a,7
	ld [wBattleAnimWX],a
	xor a
	ld [wBattleAnimWXEnabled],a
	ret

SuckerPunchAnim_UpdateShake:
	; First crescent: a restrained +/-1 px snap while it grows through the target.
	; Second crescent: +/-2 px.  The 4x4 impact overrides both with +/-3 px.
	ld a,[wSubAnimCounter]
	cp 53
	jr c,SuckerPunchAnim_ShakeCheckSecond
	cp 60
	jr c,SuckerPunchAnim_ShakeImpact
SuckerPunchAnim_ShakeCheckSecond:
	ld a,[wSubAnimCounter]
	cp 46
	jr c,SuckerPunchAnim_ShakeCheckFirst
	cp 53
	jr c,SuckerPunchAnim_ShakeSecond
SuckerPunchAnim_ShakeCheckFirst:
	ld a,[wSubAnimCounter]
	cp 13
	jr c,SuckerPunchAnim_ShakeBase
	cp 21
	jr c,SuckerPunchAnim_ShakeFirst
	jr SuckerPunchAnim_ShakeBase

SuckerPunchAnim_ShakeFirst:
	ld b,1
	jr SuckerPunchAnim_ApplyShake
SuckerPunchAnim_ShakeSecond:
	ld b,2
	jr SuckerPunchAnim_ApplyShake
SuckerPunchAnim_ShakeImpact:
	ld b,3
	jr SuckerPunchAnim_ApplyShake
SuckerPunchAnim_ShakeBase:
	ld a,7
	ld [wBattleAnimWX],a
	ret
SuckerPunchAnim_ApplyShake:
	ld a,[wSubAnimCounter]
	and 1
	jr nz,SuckerPunchAnim_ShakeRight
	ld a,7
	sub b
	ld [wBattleAnimWX],a
	ret
SuckerPunchAnim_ShakeRight:
	ld a,7
	add b
	ld [wBattleAnimWX],a
	ret

SuckerPunchAnim_PlayScheduledSound:
	ld a,[wSubAnimCounter]
	cp 13
	jr z,SuckerPunchAnim_PlayCometPunch
	cp 46
	jr z,SuckerPunchAnim_PlayCometPunch
	cp 53
	ret nz
	ld a,GSSFX_KARATE_CHOP
	jp PlaySound
SuckerPunchAnim_PlayCometPunch:
	ld a,GSSFX_COMET_PUNCH
	jp PlaySound

SuckerPunchAnim_DrawObjects:
	ld a,[wSubAnimCounter]
	cp 3
	call c,SuckerPunchAnim_DrawSpeedFrame

	ld a,[wSubAnimCounter]
	cp 13
	jr c,SuckerPunchAnim_SkipRightPunch
	cp 26
	jr nc,SuckerPunchAnim_SkipRightPunch
	call SuckerPunchAnim_DrawRightPunch
SuckerPunchAnim_SkipRightPunch:

	ld a,[wSubAnimCounter]
	cp 46
	jr c,SuckerPunchAnim_SkipLeftPunch
	cp 61
	jr nc,SuckerPunchAnim_SkipLeftPunch
	call SuckerPunchAnim_DrawLeftPunch
SuckerPunchAnim_SkipLeftPunch:

	ld a,[wSubAnimCounter]
	cp 53
	jr c,SuckerPunchAnim_SkipBigHit
	cp 59
	jr nc,SuckerPunchAnim_SkipBigHit
	call SuckerPunchAnim_DrawBigHit
SuckerPunchAnim_SkipBigHit:

	ld a,[wSubAnimCounter]
	cp 66
	ret c
	cp 69
	ret nc
	sub 66
	jp SuckerPunchAnim_DrawSpeedFrameWithAge

SuckerPunchAnim_DrawSpeedFrame:
	ld a,[wSubAnimCounter]
SuckerPunchAnim_DrawSpeedFrameWithAge:
	and a
	jr z,SuckerPunchAnim_SpeedFrame0
	dec a
	jr z,SuckerPunchAnim_SpeedFrame1

SuckerPunchAnim_SpeedFrame2:
	ld b,40
	ld c,3
	ld a,3
	call SuckerPunchAnim_DrawSpeedLine
	ld b,48
	ld c,3
	ld a,$83
	jp SuckerPunchAnim_DrawSpeedLine

SuckerPunchAnim_SpeedFrame1:
	ld b,32
	ld c,3
	ld a,2
	call SuckerPunchAnim_DrawSpeedLine
	ld b,40
	ld c,5
	ld a,2
	call SuckerPunchAnim_DrawSpeedLine
	ld b,48
	ld c,5
	ld a,$82
	call SuckerPunchAnim_DrawSpeedLine
	ld b,56
	ld c,3
	ld a,$82
	jp SuckerPunchAnim_DrawSpeedLine

SuckerPunchAnim_SpeedFrame0:
	ld b,24
	ld c,3
	ld a,1
	call SuckerPunchAnim_DrawSpeedLine
	ld b,32
	ld c,5
	ld a,1
	call SuckerPunchAnim_DrawSpeedLine
	ld b,40
	ld c,7
	ld a,1
	call SuckerPunchAnim_DrawSpeedLine
	ld b,48
	ld c,7
	ld a,$81
	call SuckerPunchAnim_DrawSpeedLine
	ld b,56
	ld c,5
	ld a,$81
	call SuckerPunchAnim_DrawSpeedLine
	ld b,64
	ld c,3
	ld a,$81
	jp SuckerPunchAnim_DrawSpeedLine

SuckerPunchAnim_DrawSpeedLine:
	; B = PC logical X, C = 3/5/7 OAM entries. Low 7 bits of A are the
	; age+1 X displacement; bit 7 selects the opposite direction.
	push bc
	bit 7,a
	jr nz,SuckerPunchAnim_SpeedLineLeft
	add b
	jr SuckerPunchAnim_SpeedLineLogicalXReady
SuckerPunchAnim_SpeedLineLeft:
	and $7f
	ld h,a
	ld a,b
	sub h
SuckerPunchAnim_SpeedLineLogicalXReady:
	ld b,a

	ld a,[H_WHOSETURN]
	and a
	ld a,b
	jr z,SuckerPunchAnim_SpeedLineXReady
	ld h,a
	ld a,180
	sub h
SuckerPunchAnim_SpeedLineXReady:
	sub 4
	ld [wBaseCoordX],a
	ld a,[H_WHOSETURN]
	and a
	ld a,88
	jr z,SuckerPunchAnim_SpeedLineYReady
	ld a,48
SuckerPunchAnim_SpeedLineYReady:
	ld [wBaseCoordY],a
	pop bc

	ld hl,SuckerPunchSpeedYOffsets
SuckerPunchAnim_SpeedLineSpriteLoop:
	ld a,[wBaseCoordY]
	add [hl]
	inc hl
	ld [de],a
	inc de
	ld a,[wBaseCoordX]
	ld [de],a
	inc de
	ld a,SUCKER_PUNCH_SPEED_TILE
	ld [de],a
	inc de
	xor a
	ld [de],a
	inc de
	dec c
	jr nz,SuckerPunchAnim_SpeedLineSpriteLoop
	ret

SuckerPunchAnim_DrawRightPunch:
	; The first strike still enters from PC's upper-right side, but instead of
	; carrying a rigid 3x2 block at six pixels per frame, it grows 1->2->3
	; columns as it bites into the target, then leaves a short two-column smear.
	ld a,[wSubAnimCounter]
	sub 13
	ld hl,SuckerPunchRightMotionTable
	call SuckerPunchAnim_GetMotionRecord
	call SuckerPunchAnim_SetRightPunchYAndAttr
	jp SuckerPunchAnim_DrawMotionRecord

SuckerPunchAnim_DrawLeftPunch:
	; The counter-strike mirrors the reveal direction and accelerates into the
	; large hit.  Its last partial crescent overlaps the impact for one frame.
	ld a,[wSubAnimCounter]
	sub 46
	ld hl,SuckerPunchLeftMotionTable
	call SuckerPunchAnim_GetMotionRecord
	call SuckerPunchAnim_SetLeftPunchYAndAttr
	jp SuckerPunchAnim_DrawMotionRecord

SuckerPunchAnim_GetMotionRecord:
	; A = record index. Each record is x, primary slice, trail x, trail slice.
	; The dedicated renderer owns these ordinary animation scratch bytes while
	; the stock frame-block interpreter is not running.
	add a
	add a
	ld c,a
	ld b,0
	add hl,bc
	ld a,[hli]
	ld [wBaseCoordX],a
	ld a,[hli]
	ld [wSubAnimTransform],a
	ld a,[hli]
	ld [wNumFBTiles],a
	ld a,[hl]
	ld [wUnusedD08A],a
	ret

SuckerPunchAnim_SetRightPunchYAndAttr:
	; First crescent points into its leftward sweep for the player; mirror both
	; position and facing for an enemy user.
	ld a,[H_WHOSETURN]
	and a
	jr nz,SuckerPunchAnim_SetRightPunchEnemy
	ld a,32
	ld [wBaseCoordY],a
	ld a,OAM_HFLIP
	ld [wSubAnimFrameDelay],a
	ret
SuckerPunchAnim_SetRightPunchEnemy:
	ld a,72
	ld [wBaseCoordY],a
	xor a
	ld [wSubAnimFrameDelay],a
	ret

SuckerPunchAnim_SetLeftPunchYAndAttr:
	; Unlike PC's rigid object, turn the counter-strike around so its crescent
	; faces the new travel direction. This is the Night Slash-inspired force cue:
	; two opposed strokes rather than the same sprite sliding both ways.
	ld a,[H_WHOSETURN]
	and a
	jr nz,SuckerPunchAnim_SetLeftPunchEnemy
	ld a,48
	ld [wBaseCoordY],a
	xor a
	ld [wSubAnimFrameDelay],a
	ret
SuckerPunchAnim_SetLeftPunchEnemy:
	ld a,88
	ld [wBaseCoordY],a
	ld a,OAM_HFLIP
	ld [wSubAnimFrameDelay],a
	ret

SuckerPunchAnim_DrawMotionRecord:
	; Draw the growing primary crescent, then (when present) a shorter copy at
	; the previous position.  The trail is geometric, not translucent, so it
	; stays compatible with the project's existing OBJ palette path.
	ld a,[wBaseCoordX]
	call SuckerPunchAnim_SetMirroredBaseX
	ld a,[wSubAnimTransform]
	call SuckerPunchAnim_DrawCrescentSlice

	ld a,[wUnusedD08A]
	cp SUCKER_PUNCH_SLICE_NONE
	ret z
	push af
	ld a,[wNumFBTiles]
	call SuckerPunchAnim_SetMirroredBaseX
	pop af
	jp SuckerPunchAnim_DrawCrescentSlice

SuckerPunchAnim_SetMirroredBaseX:
	ld b,a
	ld a,[H_WHOSETURN]
	and a
	ld a,b
	jr z,SuckerPunchAnim_MirroredBaseXReady
	ld h,a
	ld a,180
	sub h
SuckerPunchAnim_MirroredBaseXReady:
	ld [wBaseCoordX],a
	ret

SuckerPunchAnim_DrawCrescentSlice:
	cp SUCKER_PUNCH_SLICE_RIGHT_1
	jr z,SuckerPunchAnim_DrawSliceRight1
	cp SUCKER_PUNCH_SLICE_RIGHT_2
	jr z,SuckerPunchAnim_DrawSliceRight2
	cp SUCKER_PUNCH_SLICE_FULL
	jr z,SuckerPunchAnim_DrawSliceFull
	ret
SuckerPunchAnim_DrawSliceRight1:
	ld hl,SuckerPunchCrescentRight1Layout
	ld b,2
	jr SuckerPunchAnim_DrawCrescentLayout
SuckerPunchAnim_DrawSliceRight2:
	ld hl,SuckerPunchCrescentRight2Layout
	ld b,4
	jr SuckerPunchAnim_DrawCrescentLayout
SuckerPunchAnim_DrawSliceFull:
	ld hl,SuckerPunchCrescentFullLayout
	ld b,6
	jr SuckerPunchAnim_DrawCrescentLayout
SuckerPunchAnim_DrawCrescentLayout:
SuckerPunchAnim_CrescentLoop:
	push bc
	ld a,[hli]
	ld b,a
	; Apply the direction-specific whole-object flip chosen for this stroke.
	ld a,[wSubAnimFrameDelay]
	and OAM_HFLIP
	jr z,SuckerPunchAnim_CrescentXReady
	ld a,b
	cpl
	sub 7 ; whole-object X flip: -(dx + 8)
	ld b,a
SuckerPunchAnim_CrescentXReady:
	ld a,[hli]
	ld c,a
	ld a,[wBaseCoordY]
	add c
	ld [de],a
	inc de
	ld a,[wBaseCoordX]
	add b
	ld [de],a
	inc de
	ld a,[hli]
	add SUCKER_PUNCH_PUNCH_TILE_BASE
	ld [de],a
	inc de
	ld a,[wSubAnimFrameDelay]
	or SUCKER_PUNCH_PUNCH_PAL
SuckerPunchAnim_CrescentAttrReady:
	ld [de],a
	inc de
	pop bc
	dec b
	jr nz,SuckerPunchAnim_CrescentLoop
	ret

SuckerPunchAnim_DrawBigHit:
	ld a,[H_WHOSETURN]
	and a
	ld a,136
	ld b,48
	jr z,SuckerPunchAnim_BigHitCenterReady
	ld a,44
	ld b,88
SuckerPunchAnim_BigHitCenterReady:
	ld [wBaseCoordX],a
	ld a,b
	ld [wBaseCoordY],a

	ld hl,SuckerPunchHitLayout
	ld b,16
SuckerPunchAnim_BigHitLoop:
	push bc
	ld a,[hli]
	ld b,a
	ld a,[hli]
	ld c,a
	ld a,[wBaseCoordY]
	add c
	ld [de],a
	inc de
	ld a,[wBaseCoordX]
	add b
	ld [de],a
	inc de
	ld a,[hli]
	add SUCKER_PUNCH_HIT_TILE_BASE
	ld [de],a
	inc de
	ld a,[hli]
	ld [de],a
	inc de
	pop bc
	dec b
	jr nz,SuckerPunchAnim_BigHitLoop
	ret

SuckerPunchSpeedYOffsets:
	db -12,-4,4,-20,12,-28,20

; Motion records: primary X, primary slice, trail X, trail slice.
; The first strike keeps the Night Slash-inspired 1->2->3 column reveal, then
; restores PC's broad right-to-left sweep instead of collapsing around X=136.
SuckerPunchRightMotionTable:
	db 176,SUCKER_PUNCH_SLICE_RIGHT_1,   0,SUCKER_PUNCH_SLICE_NONE
	db 168,SUCKER_PUNCH_SLICE_RIGHT_2,   0,SUCKER_PUNCH_SLICE_NONE
	db 158,SUCKER_PUNCH_SLICE_FULL,      0,SUCKER_PUNCH_SLICE_NONE
	db 150,SUCKER_PUNCH_SLICE_FULL,    168,SUCKER_PUNCH_SLICE_RIGHT_1
	db 142,SUCKER_PUNCH_SLICE_FULL,    158,SUCKER_PUNCH_SLICE_RIGHT_2
	db 136,SUCKER_PUNCH_SLICE_FULL,    150,SUCKER_PUNCH_SLICE_RIGHT_2
	db 130,SUCKER_PUNCH_SLICE_FULL,    142,SUCKER_PUNCH_SLICE_RIGHT_2
	db 124,SUCKER_PUNCH_SLICE_FULL,    136,SUCKER_PUNCH_SLICE_RIGHT_2
	db 118,SUCKER_PUNCH_SLICE_FULL,    130,SUCKER_PUNCH_SLICE_RIGHT_1
	db 114,SUCKER_PUNCH_SLICE_FULL,    124,SUCKER_PUNCH_SLICE_RIGHT_1
	db 110,SUCKER_PUNCH_SLICE_FULL,    118,SUCKER_PUNCH_SLICE_RIGHT_1
	db 106,SUCKER_PUNCH_SLICE_RIGHT_2, 114,SUCKER_PUNCH_SLICE_RIGHT_1
	db 104,SUCKER_PUNCH_SLICE_RIGHT_1,   0,SUCKER_PUNCH_SLICE_NONE

; The counter-strike still expands into the target and overlaps HIT_BIG near the
; standard center, but now keeps accelerating afterward until it exits the far
; side of the screen.  This preserves the forceful hit while recovering PC's
; much wider RADIAL_MOVE_OUT_FAST follow-through.
SuckerPunchLeftMotionTable:
	db  94,SUCKER_PUNCH_SLICE_RIGHT_1,   0,SUCKER_PUNCH_SLICE_NONE
	db 104,SUCKER_PUNCH_SLICE_RIGHT_2,   0,SUCKER_PUNCH_SLICE_NONE
	db 116,SUCKER_PUNCH_SLICE_FULL,      0,SUCKER_PUNCH_SLICE_NONE
	db 126,SUCKER_PUNCH_SLICE_FULL,    108,SUCKER_PUNCH_SLICE_RIGHT_1
	db 134,SUCKER_PUNCH_SLICE_FULL,    116,SUCKER_PUNCH_SLICE_RIGHT_2
	db 138,SUCKER_PUNCH_SLICE_FULL,    126,SUCKER_PUNCH_SLICE_RIGHT_2
	db 140,SUCKER_PUNCH_SLICE_FULL,    134,SUCKER_PUNCH_SLICE_RIGHT_1
	db 140,SUCKER_PUNCH_SLICE_FULL,    136,SUCKER_PUNCH_SLICE_RIGHT_1
	db 150,SUCKER_PUNCH_SLICE_FULL,    140,SUCKER_PUNCH_SLICE_RIGHT_2
	db 164,SUCKER_PUNCH_SLICE_FULL,    150,SUCKER_PUNCH_SLICE_RIGHT_2
	db 180,SUCKER_PUNCH_SLICE_FULL,    164,SUCKER_PUNCH_SLICE_RIGHT_1
	db 198,SUCKER_PUNCH_SLICE_FULL,    180,SUCKER_PUNCH_SLICE_RIGHT_1
	db 216,SUCKER_PUNCH_SLICE_RIGHT_2, 198,SUCKER_PUNCH_SLICE_RIGHT_1
	db 232,SUCKER_PUNCH_SLICE_RIGHT_1, 216,SUCKER_PUNCH_SLICE_RIGHT_1
	db 244,SUCKER_PUNCH_SLICE_RIGHT_1,   0,SUCKER_PUNCH_SLICE_NONE

; PC OAMData_93 is a 3x2 crescent.  Partial layouts reveal the leading columns
; like Night Slash's E2->E8 growth frames instead of sliding all six sprites as
; an already-complete rectangle.
SuckerPunchCrescentRight1Layout:
	db  4,-8,2,   4,0,5
SuckerPunchCrescentRight2Layout:
	db -4,-8,1,   4,-8,2,  -4,0,4,   4,0,5
SuckerPunchCrescentFullLayout:
	db -12,-8,0,  -4,-8,1,   4,-8,2
	db -12, 0,3,  -4, 0,4,   4, 0,5

; PC OAMData_00: 4x4 mirrored large-hit object.
SuckerPunchHitLayout:
	db -16,-16,0,0
	db  -8,-16,1,0
	db -16, -8,2,0
	db  -8, -8,3,0
	db   0,-16,1,OAM_HFLIP
	db   8,-16,0,OAM_HFLIP
	db   0, -8,3,OAM_HFLIP
	db   8, -8,2,OAM_HFLIP
	db -16,  0,2,OAM_VFLIP
	db  -8,  0,3,OAM_VFLIP
	db -16,  8,0,OAM_VFLIP
	db  -8,  8,1,OAM_VFLIP
	db   0,  0,3,OAM_HFLIP | OAM_VFLIP
	db   8,  0,2,OAM_HFLIP | OAM_VFLIP
	db   0,  8,1,OAM_HFLIP | OAM_VFLIP
	db   8,  8,0,OAM_HFLIP | OAM_VFLIP

; PC PAL_BTLCUSTOM_PAYBACK, used by Sucker Punch's OBJECTS_2 crescent.
SuckerPunchPaybackPalette:
	RGB 31,31,31
	RGB 31,31,31
	RGB 31,15,28
	RGB 22,0,23

; Exact gfx/battle_anims/objects2.png source tiles 4-9.
SuckerPunchCrescentTiles:
	db $07,$07,$1f,$1f,$03,$03,$00,$00,$03,$03,$1f,$1f,$ff,$ff,$0f,$0f
	db $ff,$ff,$ff,$ff,$fe,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
	db $00,$00,$e0,$e0,$18,$f8,$04,$fc,$82,$fe,$82,$fe,$c1,$ff,$a1,$ff
	db $03,$03,$07,$07,$1f,$1f,$03,$03,$00,$00,$03,$03,$0f,$0f,$01,$01
	db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
	db $d5,$ff,$e9,$ff,$d6,$fe,$fe,$fe,$fc,$fc,$f8,$f8,$e0,$e0,$00,$00
SuckerPunchCrescentTilesEnd:
	IF SuckerPunchCrescentTilesEnd - SuckerPunchCrescentTiles != 16 * SUCKER_PUNCH_PUNCH_TILE_COUNT
		fail "Sucker Punch crescent tiles must be exactly six 8x8 tiles"
	ENDC

; Exact gfx/battle_anims/speed.png source tile 8.
SuckerPunchSpeedTile:
	db $00,$24,$00,$24,$00,$24,$00,$24
	db $00,$24,$00,$24,$00,$24,$00,$24
SuckerPunchSpeedTileEnd:
	IF SuckerPunchSpeedTileEnd - SuckerPunchSpeedTile != 16
		fail "Sucker Punch speed-line tile must be exactly one 8x8 tile"
	ENDC

; Exact gfx/battle_anims/hit.png source tiles 0-3.
SuckerPunchHitTiles:
	db $00,$00,$00,$00,$00,$00,$00,$18,$08,$16,$06,$09,$07,$08,$03,$04
	db $00,$01,$00,$01,$01,$02,$01,$02,$03,$04,$07,$88,$8f,$70,$ff,$00
	db $03,$04,$01,$02,$01,$02,$01,$02,$03,$04,$07,$08,$0f,$30,$3f,$c0
	db $ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00
SuckerPunchHitTilesEnd:
	IF SuckerPunchHitTilesEnd - SuckerPunchHitTiles != 16 * SUCKER_PUNCH_HIT_TILE_COUNT
		fail "Sucker Punch hit tiles must be exactly four 8x8 tiles"
	ENDC
