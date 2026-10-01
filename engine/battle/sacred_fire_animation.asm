; MOV-5.61.53: near-original Gold/Crystal Sacred Fire for expanded move SACRED_FIRE.
;
; Gold/Crystal sequence reproduced here:
;   - 8 Sacred Fire objects spawn every 8 VBlanks at (48,104).
;   - each object circles with radius 24, rises to -48 px, and lives 49 frames.
;   - after the 96-frame tail wait, preserve Gold's 6-frame TargetObj setup timing.
;   - the USER then lunges one tile toward the target; the target remains visible.
;   - 3 Fire Blast flames split up / down-left / down-right from (136,48).
;   - Ember SFX, Alternate Hues, and Gold's exact red OBJ palette are retained.
; Enemy-side RELATIVE_X transforms use the same Gen II fixY values ($a8/$90).

SACRED_FIRE_TILE_BASE       EQU $60
SACRED_FIRE_TILE_COUNT      EQU 6
SACRED_FIRE_ORBIT_LIFE      EQU 49
SACRED_FIRE_SPIRAL_END      EQU 160
SACRED_FIRE_TARGETOBJ_END   EQU 166
SACRED_FIRE_IMPACT_START    EQU 170
SACRED_FIRE_USER_RESTORE    EQU 174
SACRED_FIRE_TOTAL_FRAMES    EQU 190

PlayGoldSacredFireAnimation::
	xor a
	ld [wWhichBattleAnimTileset], a
	callba LoadAnimationTileset

	ld hl, vSprites + SACRED_FIRE_TILE_BASE * 16
	ld de, GoldSacredFireTiles
	ld b, BANK(GoldSacredFireTiles)
	ld c, SACRED_FIRE_TILE_COUNT
	call CopyVideoData

	; Gold's Sacred Fire objects use PAL_BATTLE_OB_RED continuously. Install the
	; exact Gen II red palette in this move's private animation slot instead of
	; alternating RPP's legacy red/yellow palettes.
	call .InstallGoldRedPalette

	xor a
	ld [wSubAnimCounter], a

.spiralLoop
	call .UpdatePaletteEffects

	; Gold plays Ember as each of the eight orbiting flames is spawned.
	ld a, [wSubAnimCounter]
	cp 64
	jr nc, .noSpiralSound
	and 7
	jr nz, .noSpiralSound
	ld a, GSSFX_EMBER
	call PlaySound
.noSpiralSound

	ld de, wOAMBuffer
	ld c, 0
.orbitObjectLoop
	ld a, [wSubAnimCounter]
	sub c
	jr c, .nextOrbitObject
	cp SACRED_FIRE_ORBIT_LIFE
	jr nc, .nextOrbitObject
	push bc
	call .DrawOrbitFlame
	pop bc
.nextOrbitObject
	ld a, c
	add 8
	ld c, a
	cp 64
	jr c, .orbitObjectLoop

	call DelayFrame
	call ClearSprites
	ld hl, wSubAnimCounter
	inc [hl]
	ld a, [hl]
	cp SACRED_FIRE_SPIRAL_END
	jr c, .spiralLoop

	; Gold spends 6 VBlanks setting TargetObj_1Row up before Tackle starts.
	; RPP does not need to convert the target BG row to an OBJ because the Gen I
	; lunge below moves only the user's tilemap; keep the target visibly unchanged
	; while retaining the original six-frame timing.
.targetObjWait
	call .UpdatePaletteEffects
	call DelayFrame
	call ClearSprites
	ld hl, wSubAnimCounter
	inc [hl]
	ld a, [hl]
	cp SACRED_FIRE_TARGETOBJ_END
	jr c, .targetObjWait

	; Gold BATTLE_BG_EFFECT_TACKLE acts on BG_EFFECT_USER, not the target. Gen I
	; cannot reproduce the 2-pixel scanline scroll directly here, so use the same
	; one-tile forward position as its stock Tackle animation and hold it through
	; the four-frame approach to impact.
	call .ShiftUserForward
.lungeWait
	call .UpdatePaletteEffects
	call DelayFrame
	call ClearSprites
	ld hl, wSubAnimCounter
	inc [hl]
	ld a, [hl]
	cp SACRED_FIRE_IMPACT_START
	jr c, .lungeWait

	ld a, GSSFX_EMBER
	call PlaySound

.impactLoop
	call .UpdatePaletteEffects
	ld a, [wSubAnimCounter]
	cp SACRED_FIRE_USER_RESTORE
	call z, .RestoreUserPosition

	ld a, [wSubAnimCounter]
	sub SACRED_FIRE_IMPACT_START
	ld de, wOAMBuffer
	push af
	call .DrawImpactCenter
	pop af
	push af
	call .DrawImpactLeft
	pop af
	call .DrawImpactRight

	call DelayFrame
	call ClearSprites
	ld hl, wSubAnimCounter
	inc [hl]
	ld a, [hl]
	cp SACRED_FIRE_TOTAL_FRAMES
	jr c, .impactLoop

	; Restore the ordinary RPP attack palettes after the private Gold red slot.
	callba LoadAttackSpritePalettes
	ld a, $e4
	ld [rOBP0], a
	ld [rOBP1], a
	callba AnimationResetScreenPalette
	ret

.InstallGoldRedPalette
	ld a, 2
	ld [rSVBK], a
	ld hl, GoldSacredFireRedPalette
	ld de, W2_SprPaletteData + ATK_PAL_RED * 8
	ld bc, 8
	call CopyData

	ld hl, W2_SpritePaletteMap + SACRED_FIRE_TILE_BASE
	ld b, SACRED_FIRE_TILE_COUNT
	ld a, ATK_PAL_RED
.paletteMapLoop
	ld [hli], a
	dec b
	jr nz, .paletteMapLoop
	ld a, 1
	ld [W2_ForceOBPUpdate], a
	xor a
	ld [rSVBK], a
	ret

.UpdatePaletteEffects
	; Gold runs ALTERNATE_HUES and CYCLE_OBPALS_GRAY_AND_YELLOW with argument 2,
	; so each DMG palette state lasts three VBlanks. On CGB the Sacred Fire
	; objects themselves keep PAL_BATTLE_OB_RED; only the background hue changes.
	ld a, [wSubAnimCounter]
	ld c, 0
.mod3
	cp 3
	jr c, .gotRemainder
	sub 3
	inc c
	jr .mod3
.gotRemainder
	and a
	ret nz

	ld a, c
	and 7
	ld e, a
	ld d, 0
	ld hl, SacredFireHueCycle
	add hl, de
	ld a, [hl]
	ld [rBGP], a
	ld [rOBP1], a

	; Gen II CYCLE_OBPALS_GRAY_AND_YELLOW CGB sequence: $e4, $90. This is
	; relevant to DMG/SGB rendering only; CGB fire color stays on the fixed red
	; palette installed above.
	ld a, c
	and 1
	ld a, $e4
	jr z, .gotOBP0
	ld a, $90
.gotOBP0
	ld [rOBP0], a
	ret

.DrawOrbitFlame
	; A = object age 0..48, DE = next OAM lane. The offset table is precomputed
	; from Gen II SacredFire's sine/cosine orbit and two-pixel rise cadence.
	push af
	ld l, a
	ld h, 0
	add hl, hl
	ld bc, SacredFireOrbitOffsets
	add hl, bc
	ld b, [hl]
	inc hl
	ld c, [hl]

	ld a, [H_WHOSETURN]
	and a
	jr nz, .orbitEnemy
	ld a, 48
	add b
	ld [wBaseCoordX], a
	ld a, 104
	add c
	ld [wBaseCoordY], a
	jr .orbitCenterDone
.orbitEnemy
	ld a, 132 ; 180 - 48
	sub b
	ld [wBaseCoordX], a
	ld a, 64 ; $a8 - 104
	add c
	ld [wBaseCoordY], a
.orbitCenterDone
	pop af
	and 4
	ld a, SACRED_FIRE_TILE_BASE
	jr z, .orbitTileDone
	add 2
.orbitTileDone
	ld [wDropletTile], a
	jp .DrawLargeFlame

.DrawImpactCenter
	; MOV-5.61.53: keep the upper Sacred Fire flame on the vertical centerline
	; for its whole lifetime. Age 0 is the spawn frame, matching Gen II object
	; initialization; movement therefore starts at age 1 instead of one pixel early.
	push af
	ld b, 0
	cpl
	inc a
	ld c, a
	call .SetImpactCenter
	pop af
	jp .DrawImpactFrame

.DrawImpactLeft
	; Param $4 equivalent: keep travelling down-left for the full object life.
	; Age 0 stays at the common spawn point, then each axis advances 1 px/frame.
	push af
	ld c, a
	cpl
	inc a
	ld b, a
	call .SetImpactCenter
	pop af
	jp .DrawImpactFrame

.DrawImpactRight
	; Param $5 equivalent: keep travelling down-right for the full object life.
	; Age 0 stays at the common spawn point, then each axis advances 1 px/frame.
	push af
	ld b, a
	ld c, a
	call .SetImpactCenter
	pop af
	jp .DrawImpactFrame

.SetImpactCenter
	; B/C = signed X/Y offsets from Gold logical (136,48), fixY $90.
	ld a, [H_WHOSETURN]
	and a
	jr nz, .impactEnemy
	ld a, 136
	add b
	ld [wBaseCoordX], a
	ld a, 48
	add c
	ld [wBaseCoordY], a
	ret
.impactEnemy
	ld a, 44 ; 180 - 136
	sub b
	ld [wBaseCoordX], a
	ld a, 96 ; $90 - 48
	add c
	ld [wBaseCoordY], a
	ret

.DrawImpactFrame
	; Burned frameset: tile 5, tile 4, then alternate big 2/3 and 0/1.
	cp 4
	jr nc, .impactNotTile5
	ld a, SACRED_FIRE_TILE_BASE + 5
	jp .DrawSmallFlame
.impactNotTile5
	cp 8
	jr nc, .impactLarge
	ld a, SACRED_FIRE_TILE_BASE + 4
	jp .DrawSmallFlame
.impactLarge
	and 4
	ld a, SACRED_FIRE_TILE_BASE
	jr nz, .impactLargeReady
	add 2
.impactLargeReady
	ld [wDropletTile], a
	jp .DrawLargeFlame

.DrawSmallFlame
	; A = absolute tile ID; one centered 8x8 sprite.
	ld b, a
	ld a, [wBaseCoordY]
	sub 4
	ld [de], a
	inc de
	ld a, [wBaseCoordX]
	sub 4
	ld [de], a
	inc de
	ld a, b
	ld [de], a
	inc de
	xor a
	ld [de], a
	inc de
	ret

.DrawLargeFlame
	; Gold OAM set 0A/0E: 16x16 flame made from two unique tiles and H-flips.
	ld a, [wBaseCoordY]
	sub 8
	ld [de], a
	inc de
	ld a, [wBaseCoordX]
	sub 8
	ld [de], a
	inc de
	ld a, [wDropletTile]
	ld [de], a
	inc de
	xor a
	ld [de], a
	inc de

	ld a, [wBaseCoordY]
	sub 8
	ld [de], a
	inc de
	ld a, [wBaseCoordX]
	ld [de], a
	inc de
	ld a, [wDropletTile]
	ld [de], a
	inc de
	ld a, OAM_HFLIP
	ld [de], a
	inc de

	ld a, [wBaseCoordY]
	ld [de], a
	inc de
	ld a, [wBaseCoordX]
	sub 8
	ld [de], a
	inc de
	ld a, [wDropletTile]
	inc a
	ld [de], a
	inc de
	xor a
	ld [de], a
	inc de

	ld a, [wBaseCoordY]
	ld [de], a
	inc de
	ld a, [wBaseCoordX]
	ld [de], a
	inc de
	ld a, [wDropletTile]
	inc a
	ld [de], a
	inc de
	ld a, OAM_HFLIP
	ld [de], a
	inc de
	ret

.ShiftUserForward
	call .CurrentUserInvulnerable
	ret nz
	; MOV-5.61.53: do the complete tilemap move inside bank $1E. `homecall`
	; cannot be emitted from this bank-$3D routine because switching banks would
	; replace the caller code before its next instruction executes.
	callba SacredFireShiftUserForwardNoDelay
	ret

.RestoreUserPosition
	call .CurrentUserInvulnerable
	ret nz
	callba SacredFireRestoreUserPositionNoDelay
	ret

.CurrentUserInvulnerable
	ld a, [H_WHOSETURN]
	and a
	ld a, [wPlayerBattleStatus1]
	jr z, .gotUserStatus
	ld a, [wEnemyBattleStatus1]
.gotUserStatus
	and 1 << Invulnerable
	ret

GoldSacredFireRedPalette:
	; Gold/Crystal PAL_BATTLE_OB_RED from gfx/battle_anims/battle_anims.pal.
	RGB 31, 31, 31
	RGB 31, 19, 24
	RGB 30, 10, 6
	RGB 0, 0, 0

SacredFireHueCycle:
	; Gold ALTERNATE_HUES DMG palette sequence.
	db $e4,$f8,$fc,$f8,$e4,$90,$40,$90

SacredFireOrbitOffsets:
	db 24,0, 23,0, 22,-1, 19,-1, 16,-2, 13,-2, 9,-4
	db 4,-4, 0,-5, -4,-6, -9,-8, -13,-8, -16,-10, -19,-11
	db -22,-13, -23,-14, -24,-16, -23,-17, -22,-20, -19,-20, -16,-22
	db -13,-23, -9,-25, -4,-25, 0,-27, 4,-27, 9,-29, 13,-29
	db 16,-30, 19,-30, 22,-32, 23,-31, 24,-32, 23,-32, 22,-33
	db 19,-33, 16,-34, 13,-34, 9,-36, 4,-36, 0,-37, -4,-38
	db -9,-40, -13,-40, -16,-42, -19,-43, -22,-45, -23,-46, -24,-48
SacredFireOrbitOffsetsEnd:
	IF SacredFireOrbitOffsetsEnd - SacredFireOrbitOffsets != SACRED_FIRE_ORBIT_LIFE * 2
		fail "Sacred Fire orbit offset table must contain exactly 49 xy pairs"
	ENDC

; Exact gfx/battle_anims/fire.png after RGBDS 2bpp conversion: six 8x8 tiles.
GoldSacredFireTiles::
	db $00,$08,$00,$1d,$00,$5f,$00,$ff,$00,$ff,$00,$7f,$00,$7f,$02,$3d
	db $03,$fc,$03,$fc,$07,$f8,$07,$78,$07,$78,$07,$38,$03,$3c,$03,$1c
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$00,$03
	db $00,$07,$00,$07,$00,$1f,$01,$3e,$03,$3c,$03,$1c,$03,$1c,$01,$0e
	db $00,$28,$00,$2a,$00,$6e,$00,$7e,$18,$e7,$3c,$c3,$3c,$c3,$3c,$42
	db $00,$00,$00,$10,$00,$14,$00,$3c,$00,$7e,$18,$66,$18,$66,$18,$24
GoldSacredFireTilesEnd::
	IF GoldSacredFireTilesEnd - GoldSacredFireTiles != SACRED_FIRE_TILE_COUNT * 16
		fail "Gold Sacred Fire tileset must contain exactly six tiles"
	ENDC
