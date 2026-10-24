; ANM-5.61.69: Gold/Crystal-style Crunch on the shared full-frame VBlank WX shake path.
;
; Reproduce Gold's dedicated Crunch instead of composing the Gen 1 Bite recipe:
;   - exact paired BITE jaw geometry across Gold's 36 rendered playframes;
;   - exact 32-frame BATTLE_BG_EFFECT_SHAKE_SCREEN_X through the shared VBlank WX latch,
;     followed by four unshaken tail frames;
;   - SFX_BITE at rendered playframes 9 and 26;
;   - exact HIT_BIG_YFIX geometry at (144,48) and (128,64), seven frames each;
;   - Gold RELATIVE_X/fixY conversion for enemy use;
;   - ten neutral post-animation playframes before generic damage feedback.
; Only the one Cut tile used by BITE and the four HitBig tiles are imported.
; Gold's gray OBJ palette is byte-for-byte RPP's existing ATK_PAL_GREY.

CRUNCH_JAW_TILE_BASE EQU $60
CRUNCH_HIT_TILE_BASE EQU CRUNCH_JAW_TILE_BASE + 1
CRUNCH_TILE_COUNT     EQU 5
CRUNCH_TOTAL_FRAMES   EQU 36
CRUNCH_SHAKE_FRAMES   EQU 32
CRUNCH_POST_HIT_HOLD  EQU 10

PlayGoldCrunchAnimation::
	; Gold's anim_2gfx loads graphics and the ordinary battle OBJ palettes before
	; the visible script starts. Initialize RPP's palette map the same way, then
	; overwrite only the five private tile slots used by Crunch.
	xor a
	ld [wWhichBattleAnimTileset], a
	callba LoadAnimationTileset

	ld hl, vSprites + CRUNCH_JAW_TILE_BASE * 16
	ld de, GoldCrunchTiles
	ld b, BANK(GoldCrunchTiles)
	ld c, CRUNCH_TILE_COUNT
	call CopyVideoData

	; Preserve the caller's DMG/SGB palettes. Gold itself sets BGP=$1b and
	; OBP0=$c0 for this move; CGB sprites use gray palette slot 0. Horizontal
	; movement is owned by the ANM-5.61.67 VBlank-latched WX helper.
	ld a, [rBGP]
	push af
	ld a, [rOBP0]
	push af
	call GoldBattleHorizontalShakeBegin
	ld a, $1b
	ld [rBGP], a
	ld a, $c0
	ld [rOBP0], a

	xor a
	ld [wSubAnimCounter], a
.frameLoop
	ld de, wOAMBuffer
	call .DrawJaws
	call .DrawActiveHit
	call .MaybePlayBiteSfx

	; Gold SHAKE_SCREEN_X($20,$2,$0): +/-2 every VBlank for frames 0..31.
	; The shared setter only stages wBattleAnimWX; GbcVBlankHook commits rWX
	; before scanline 0, so jaws/HitBig can overlap without top-line tearing.
	call .SetHorizontalShake
	call DelayFrame
	call ClearSprites
	ld hl, wSubAnimCounter
	inc [hl]
	ld a, [hl]
	cp CRUNCH_TOTAL_FRAMES
	jr c, .frameLoop

	; Frames 32..35 already presented the base WX, so it is safe to disarm the
	; VBlank latch immediately after the final frame.
	call GoldBattleHorizontalShakeEnd
	pop af
	ld [rOBP0], a
	pop af
	ld [rBGP], a
	xor a
	ld [wSubAnimCounter], a

	; ANM-5.61.69: the Gold reference stays on the neutral battle field for
	; about ten visible frames after the jaw/HitBig timeline before the first
	; damage blink. Keep this outside CRUNCH_TOTAL_FRAMES so the 36-frame body stays exact.
	ld c, CRUNCH_POST_HIT_HOLD
.postHitHold
	call DelayFrame
	dec c
	jr nz, .postHitHold

	ret

.SetHorizontalShake
	ld b, 0
	ld c, CRUNCH_SHAKE_FRAMES
	ld d, 1 ; Gold param $0: flip sign every VBlank.
	ld e, 2
	jp GoldBattleHorizontalShakeSet

.MaybePlayBiteSfx
	ld a, [wSubAnimCounter]
	cp 9
	jr z, .playBite
	cp 26
	ret nz
.playBite
	ld a, GSSFX_BITE
	jp PlaySound

.DrawJaws
	; Both BITE objects share the same center and distance 40, with phases half a
	; turn apart. One signed offset therefore describes both objects exactly.
	ld a, [wSubAnimCounter]
	ld l, a
	ld h, 0
	ld bc, GoldCrunchJawOffsets
	add hl, bc
	ld a, [hl]
	ld b, a

	; Gold creates param $a8 first (phase +32, i.e. the negative offset),
	; then param $28. Preserve that OAM ordering for overlap priority.
	ld a, b
	cpl
	inc a
	push bc
	call .DrawJawAtOffset
	pop bc
	ld a, b
	jp .DrawJawAtOffset

.DrawJawAtOffset
	; A = signed Y offset from Gold logical center (136,56), fixY $90.
	ld c, a
	ld a, [H_WHOSETURN]
	and a
	jr nz, .jawEnemy
	ld a, 136
	ld [wBaseCoordX], a
	ld a, 56
	jr .jawCenterReady
.jawEnemy
	ld a, 44 ; 180 - 136
	ld [wBaseCoordX], a
	ld a, 88 ; $90 - 56
.jawCenterReady
	add c
	ld [wBaseCoordY], a
	ld a, CRUNCH_JAW_TILE_BASE
	ld [wDropletTile], a

	bit 7, c
	jr z, .jawLower
	; Gold BATTLE_ANIM_FRAMESET_BITE_1 / OAMSET_49.
	ld hl, GoldCrunchBiteUpperOAM
	ld b, 4
	jp .DrawOAMLayout
.jawLower
	; Gold BATTLE_ANIM_FRAMESET_BITE_2 / OAMSET_4A.
	ld hl, GoldCrunchBiteLowerOAM
	ld b, 2
	jp .DrawOAMLayout

.DrawActiveHit
	; Gold oamframe duration 6 renders for seven playframes: first 9..15,
	; second 26..32. The script itself continues through playframe 35.
	ld a, [wSubAnimCounter]
	cp 9
	ret c
	cp 16
	jr c, .firstHit
	cp 26
	ret c
	cp 33
	ret nc

	; Gold HIT_BIG_YFIX at logical (128,64), RELATIVE_X + fixY $ff.
	ld a, [H_WHOSETURN]
	and a
	jr nz, .secondHitEnemy
	ld a, 128
	ld [wBaseCoordX], a
	ld a, 64
	jr .drawHit
.secondHitEnemy
	ld a, 52 ; 180 - 128
	ld [wBaseCoordX], a
	ld a, 104 ; 64 + 5 tiles for fixY $ff
	jr .drawHit

.firstHit
	; Gold HIT_BIG_YFIX at logical (144,48), RELATIVE_X + fixY $ff.
	ld a, [H_WHOSETURN]
	and a
	jr nz, .firstHitEnemy
	ld a, 144
	ld [wBaseCoordX], a
	ld a, 48
	jr .drawHit
.firstHitEnemy
	ld a, 36 ; 180 - 144
	ld [wBaseCoordX], a
	ld a, 88 ; 48 + 5 tiles for fixY $ff

.drawHit
	ld [wBaseCoordY], a
	ld a, CRUNCH_HIT_TILE_BASE
	ld [wDropletTile], a
	ld hl, GoldCrunchHitBigOAM
	ld b, 16
	jp .DrawOAMLayout

.DrawOAMLayout
	; HL = y/x/tile/attr entries, B = sprite count, DE = next OAM lane.
.layoutLoop
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
	jr nz, .layoutLoop
	ret

; BattleAnimFunction_Bite with distance $28, sampled across Gold's full 36
; rendered playframes. The five-frame holds at +/-7 are the object's anon-jumptable delay.
GoldCrunchJawOffsets:
	db 40,39,37,33,28,22,15,7
	db 7,7,7,7,7,0,-7,-15
	db -22,-28,-33,-37,-39,-40,-39,-37
	db -33,-28,-22,-15,-7,-7,-7,-7
	db -7,-7,0,7
GoldCrunchJawOffsetsEnd:
	IF GoldCrunchJawOffsetsEnd - GoldCrunchJawOffsets != CRUNCH_TOTAL_FRAMES
		fail "Gold Crunch jaw offset table must contain exactly 36 frames"
	ENDC

; Exact Gold OAMData_49 geometry. All entries use Cut tile #3, imported below as
; the dedicated Crunch jaw tile at CRUNCH_JAW_TILE_BASE.
GoldCrunchBiteUpperOAM:
	db -4,-16,0,OAM_HFLIP
	db -6, -8,0,OAM_HFLIP
	db -6,  0,0,0
	db -4,  8,0,0

; Exact Gold OAMData_4a geometry.
GoldCrunchBiteLowerOAM:
	db -4,-8,0,OAM_HFLIP | OAM_VFLIP
	db -4, 0,0,OAM_VFLIP

; Exact Gold OAMData_00 geometry used by BATTLE_ANIM_FRAMESET_HIT_BIG.
GoldCrunchHitBigOAM:
	db -16,-16,0,0
	db -16, -8,1,0
	db  -8,-16,2,0
	db  -8, -8,3,0
	db -16,  0,1,OAM_HFLIP
	db -16,  8,0,OAM_HFLIP
	db  -8,  0,3,OAM_HFLIP
	db  -8,  8,2,OAM_HFLIP
	db   0,-16,2,OAM_VFLIP
	db   0, -8,3,OAM_VFLIP
	db   8,-16,0,OAM_VFLIP
	db   8, -8,1,OAM_VFLIP
	db   0,  0,3,OAM_HFLIP | OAM_VFLIP
	db   0,  8,2,OAM_HFLIP | OAM_VFLIP
	db   8,  0,1,OAM_HFLIP | OAM_VFLIP
	db   8,  8,0,OAM_HFLIP | OAM_VFLIP

; Exact RGBGFX 2bpp conversion from pokegold's assets:
;   cut.png tile #3 (the only Cut tile used by BITE), then
;   hit.png tiles #0-#3 after Gold's --remove-whitespace processing.
GoldCrunchTiles:
	db $dd,$b3,$dd,$b3,$dd,$b3,$25,$6b,$4e,$4a,$0a,$0e,$0c,$0c,$08,$08
	db $00,$00,$00,$00,$00,$00,$00,$18,$08,$16,$06,$09,$07,$08,$03,$04
	db $00,$01,$00,$01,$01,$02,$01,$02,$03,$04,$07,$88,$8f,$70,$ff,$00
	db $03,$04,$01,$02,$01,$02,$01,$02,$03,$04,$07,$08,$0f,$30,$3f,$c0
	db $ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00
GoldCrunchTilesEnd:
	IF GoldCrunchTilesEnd - GoldCrunchTiles != CRUNCH_TILE_COUNT * 16
		fail "Gold Crunch tile data must contain exactly 5 tiles"
	ENDC
