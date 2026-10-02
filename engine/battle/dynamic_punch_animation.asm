; ANM-5.61.48: Gold/Crystal-style DynamicPunch impact for expanded move DYNAMICPUNCH.
; The existing RPP Fighting fist remains the launch stage. Its final pose is carried
; across this helper while the exact Gen 2 Explosion graphics are loaded, then overlaps
; the first explosion for four VBlanks through the reusable Acid/Shadow Punch bridge.
;
; Gold/Crystal impact sequence reproduced here:
;   FLASH_INVERTED starts with the impact;
;   explosions spawn at (148,32), (116,72), (148,72), (116,32), (132,52);
;   each spawn is 5 VBlanks apart and each Explosion object lives 12 VBlanks
;   as three 4-VBlank OAM poses. The parent script then waits to VBlank 36.

DYNAMIC_PUNCH_EXPLOSION_TILE_BASE  EQU $60
DYNAMIC_PUNCH_EXPLOSION_TILE_COUNT EQU 9
DYNAMIC_PUNCH_IMPACT_FRAMES        EQU 36

PlayGoldDynamicPunchAnimation::
	call LoadGoldDynamicPunchExplosionAssets

	; Unlike Aeroblast, this is a true command-boundary overlap: the legacy $05
	; fist has already finished, so promote its saved OAM high-water to a four-frame
	; custom carry before the new explosion timeline starts.
	ld c, SEAMLESS_CUSTOM_TARGET
	callba ActivateCustomBattleAnimBridge
	jp PlayGoldDynamicPunchExplosionTimeline

; EGG-A4-5.61.75: Egg Bomb enters here after its egg projectile disappears.
; The exact DynamicPunch explosion assets/timeline are shared byte-for-byte.
PlayGoldDynamicPunchExplosionOnly::
	xor a
	ld [wBattleAnimSeamlessStage], a
	ld [wBattleAnimStageCarryTimer], a
	call ClearSprites
	call LoadGoldDynamicPunchExplosionAssets
	jp PlayGoldDynamicPunchExplosionTimeline

LoadGoldDynamicPunchExplosionAssets:
	; Gold's processed explosion.png contains nine nonblank tiles. Loading those
	; private slots costs two VBlanks; DynamicPunch's source fist remains visible
	; because its bridge pose was captured before this helper was entered.
	ld hl, vSprites + DYNAMIC_PUNCH_EXPLOSION_TILE_BASE * 16
	ld de, GoldDynamicPunchExplosionTiles
	ld b, BANK(GoldDynamicPunchExplosionTiles)
	ld c, DYNAMIC_PUNCH_EXPLOSION_TILE_COUNT
	call CopyVideoData

	; Only the private explosion vocabulary is mapped to RPP's already-loaded
	; red attack palette. Egg Bomb may reuse the same VRAM slots for its egg first.
	ld a, 2
	ld [rSVBK], a
	ld hl, W2_SpritePaletteMap + DYNAMIC_PUNCH_EXPLOSION_TILE_BASE
	ld b, DYNAMIC_PUNCH_EXPLOSION_TILE_COUNT
	ld a, ATK_PAL_RED
.setExplosionPalette
	ld [hli], a
	dec b
	jr nz, .setExplosionPalette
	ld a, 1
	ld [W2_ForceOBPUpdate], a
	xor a
	ld [rSVBK], a
	ret

PlayGoldDynamicPunchExplosionTimeline:
	xor a
	ld [wSubAnimCounter], a
.frameLoop
	call .UpdateInvertedFlash
	call .MaybePlayExplosionSfx

	; Draw all currently live Gold Explosion objects into the target OAM lane.
	; During the first four frames BattleAnimGetFrameDest places them after the
	; carried fist; after carry expiry they automatically move back to OAM slot 0.
	callba BattleAnimGetFrameDest
	ld d, h
	ld e, l
	ld hl, GoldDynamicPunchExplosionSpawns
	ld b, 5
.explosionLoop
	ld a, [hli] ; spawn frame
	ld c, a
	ld a, [wSubAnimCounter]
	sub c       ; object age
	jr c, .inactiveExplosion
	cp 12
	jr nc, .inactiveExplosion
	push bc     ; preserve outer object count
	ld c, a     ; C = age 0..11
	ld a, [hli] ; logical Gold X
	ld b, a
	ld a, [hli] ; logical Gold Y
	push hl
	ld h, a     ; B/H = logical center X/Y
	call .DrawExplosion
	pop hl
	pop bc
	jr .nextExplosion
.inactiveExplosion
	inc hl      ; skip logical X
	inc hl      ; skip logical Y
.nextExplosion
	dec b
	jr nz, .explosionLoop

	; This one delay owns both animation time and the four-frame fist carry.
	; Cleanup clears only the explosion lane while the fist is alive, then clears
	; the full OAM buffer once the carry expires.
	callba BattleAnimCarryDelayFrame
	callba ClearBattleAnimTargetOAMKeepingCarry

	ld hl, wSubAnimCounter
	inc [hl]
	ld a, [hl]
	cp DYNAMIC_PUNCH_IMPACT_FRAMES
	jp c, .frameLoop

	xor a
	ld [wSubAnimCounter], a
	callba AnimationResetScreenPalette
	ret

.UpdateInvertedFlash
	; Gold's FLASH_INVERTED alternates normal/inverted BGP on an 8-count timer.
	; RPP runs the impact locally, so reproduce the visible 36-frame portion as
	; four nine-VBlank phases without importing the Gen 2 BG-effect scheduler.
	ld a, [wSubAnimCounter]
	and a
	jr z, .flashInverted
	cp 9
	jr z, .flashNormal
	cp 18
	jr z, .flashInverted
	cp 27
	ret nz
.flashNormal
	ld a, $e4
	ld [rBGP], a
	ret
.flashInverted
	ld a, $1b
	ld [rBGP], a
	ret

.MaybePlayExplosionSfx
	ld a, [wSubAnimCounter]
	cp 21
	ret nc
	; Spawn/SFX times are exactly 0,5,10,15,20.
	ld c, a
.mod5
	cp 5
	jr c, .gotRemainder
	sub 5
	jr .mod5
.gotRemainder
	and a
	ret nz
	ld a, GSSFX_EGG_BOMB
	jp PlaySound

.DrawExplosion
	; Input: B = Gold logical X, H = Gold logical Y, C = age, DE = next OAM slot.
	; BATTLE_ANIM_OBJ_EXPLOSION1 is RELATIVE_X with fixY $90 and no object-level
	; X/Y flip, so enemy use mirrors only the center: x=180-x, y=144-y.
	ld a, [H_WHOSETURN]
	and a
	jr nz, .enemyCenter
	ld a, b
	ld [wBaseCoordX], a
	ld a, h
	ld [wBaseCoordY], a
	jr .centerReady
.enemyCenter
	ld a, 180
	sub b
	ld [wBaseCoordX], a
	ld a, 144
	sub h
	ld [wBaseCoordY], a
.centerReady

	ld a, c
	cp 4
	jr nc, .notEarly
	ld a, DYNAMIC_PUNCH_EXPLOSION_TILE_BASE
	ld [wDropletTile], a
	ld hl, DynamicPunchExplosionEarlyOAM
	ld b, 4
	jp .DrawOAMLayout
.notEarly
	cp 8
	jr nc, .late
	ld a, DYNAMIC_PUNCH_EXPLOSION_TILE_BASE + 1
	ld [wDropletTile], a
	ld hl, DynamicPunchExplosionLargeOAM
	ld b, 16
	jp .DrawOAMLayout
.late
	ld a, DYNAMIC_PUNCH_EXPLOSION_TILE_BASE + 5
	ld [wDropletTile], a
	ld hl, DynamicPunchExplosionLargeOAM
	ld b, 16
	jp .DrawOAMLayout

.DrawOAMLayout
	; HL = y/x/tile/attr tuples, B = sprite count, DE = next OAM slot.
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

; Gold's BattleAnimSub_Explosion2: spawn frame, logical X, logical Y.
GoldDynamicPunchExplosionSpawns:
	db  0,148,32
	db  5,116,72
	db 10,148,72
	db 15,116,32
	db 20,132,52

; Exact Gold OAMData_02 used by BATTLE_ANIM_OAMSET_18.
DynamicPunchExplosionEarlyOAM:
	db -8,-8,0,0
	db -8, 0,0,OAM_HFLIP
	db  0,-8,0,OAM_VFLIP
	db  0, 0,0,OAM_HFLIP | OAM_VFLIP

; Exact Gold OAMData_00 geometry used by OAM sets $19/$1a. The mid pose uses
; tile base +1 (tiles 1-4); the late pose uses tile base +5 (tiles 5-8).
DynamicPunchExplosionLargeOAM:
	db -16,-16,0,0
	db -16, -8,1,0
	db -16,  0,1,OAM_HFLIP
	db -16,  8,0,OAM_HFLIP
	db  -8,-16,2,0
	db  -8, -8,3,0
	db  -8,  0,3,OAM_HFLIP
	db  -8,  8,2,OAM_HFLIP
	db   0,-16,2,OAM_VFLIP
	db   0, -8,3,OAM_VFLIP
	db   0,  0,3,OAM_HFLIP | OAM_VFLIP
	db   0,  8,2,OAM_HFLIP | OAM_VFLIP
	db   8,-16,0,OAM_VFLIP
	db   8, -8,1,OAM_VFLIP
	db   8,  0,1,OAM_HFLIP | OAM_VFLIP
	db   8,  8,0,OAM_HFLIP | OAM_VFLIP

; Exact RGBGFX 2bpp conversion of Gold/Crystal explosion.png after the original
; --remove-whitespace processing. Gold and Crystal assets are byte-identical.
GoldDynamicPunchExplosionTiles:
	db $07,$07,$1f,$1f,$3f,$3f,$7f,$7f,$7f,$7f,$ff,$ff,$ff,$ff,$ff,$ff
	db $00,$00,$00,$00,$00,$00,$03,$03,$07,$07,$0f,$0f,$1f,$1f,$1f,$1f
	db $0f,$0f,$3f,$3f,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
	db $3f,$3f,$3f,$3f,$7f,$7f,$7f,$7f,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
	db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
	db $00,$00,$00,$00,$00,$00,$01,$01,$03,$03,$07,$07,$0f,$0f,$1e,$1f
	db $07,$07,$3f,$3f,$7f,$7f,$fc,$ff,$e0,$ff,$c3,$fc,$0f,$f0,$3e,$c0
	db $3c,$3f,$3c,$3f,$79,$7e,$71,$7e,$73,$7c,$f3,$fc,$e7,$f8,$e6,$f8
	db $78,$80,$e0,$00,$c0,$00,$80,$00,$80,$00,$00,$00,$00,$00,$00,$00
GoldDynamicPunchExplosionTilesEnd:
	IF GoldDynamicPunchExplosionTilesEnd - GoldDynamicPunchExplosionTiles != DYNAMIC_PUNCH_EXPLOSION_TILE_COUNT * 16
		fail "Gold DynamicPunch Explosion tile data must contain exactly 9 tiles"
	ENDC
