; ANM-5.61.45: Gold-style Sludge Bomb for expanded move #$DF.
; The projectile uses Gold's BARRAGE_BALL tiles already stored as
; GoldOrbAnimationTileset. The impact tiles below are exact poison.png tiles 4-8
; used by Frameset_SludgeBubble / Frameset_SludgeBubbleBurst.
;
; Gold coordinate fixing is reproduced for enemy users:
;   projectile (fixY $90): x = 180-x, y = 144-y + sineOffset
;   sludge bubble (fixY $b4): x = 180-x, y = 180-y + yOffset

SLUDGE_BOMB_PROJECTILE_TILE_1 EQU $3f ; stock palette map = ATK_PAL_GREY
SLUDGE_BOMB_PROJECTILE_TILE_2 EQU $40 ; stock palette map = ATK_PAL_GREY
SLUDGE_BOMB_BUBBLE_TILE_1     EQU $4d ; $4d-$51 all map to ATK_PAL_GREY
SLUDGE_BOMB_BUBBLE_TILE_2     EQU $4e
SLUDGE_BOMB_BUBBLE_TILE_3     EQU $4f
SLUDGE_BOMB_BURST_TILE_1      EQU $50
SLUDGE_BOMB_BURST_TILE_2      EQU $51

PlayGoldSludgeBombAnimation::
	; Initialize the ordinary battle-animation palette map, then overwrite only
	; gray-mapped tile slots. No dynamic type palette or HOME hook is needed.
	xor a
	ld [wWhichBattleAnimTileset], a
	callba LoadAnimationTileset

	ld hl, vSprites + SLUDGE_BOMB_PROJECTILE_TILE_1 * 16
	ld de, GoldOrbAnimationTileset
	ld b, BANK(GoldOrbAnimationTileset)
	ld c, 2
	call CopyVideoData

	ld hl, vSprites + SLUDGE_BOMB_BUBBLE_TILE_1 * 16
	ld de, GoldSludgeBubbleTiles
	ld b, BANK(GoldSludgeBubbleTiles)
	ld c, 5
	call CopyVideoData

	; ANM-5.61.45: reuse Red's existing gentle mon-palette darkening instead of
	; the harsh full-screen $6f blackout. Keep it through the complete move.
	callba AnimationDarkenMonPalette

	; Gold: anim_sound 6, 2, SFX_SLUDGE_BOMB.
	ld a, GSSFX_SLUDGE_BOMB
	call PlaySound

	; Gold BATTLE_ANIM_FUNC_THROW_TO_TARGET_DISAPPEAR starts at (64,92),
	; advances +2 X / -1 Y each frame and uses param $10 for its sine arc.
	ld b, 64
	ld c, 92
	ld hl, GoldSludgeBombThrowOffsets
	ld a, 36
.projectileLoop
	push af
	ld a, b
	add $2
	ld b, a
	dec c
	ld a, [hli]
	ld d, a
	; ANM-5.61.45: DelayFrame/ClearSprites do not preserve BC. B/C are the
	; Gold projectile's live X/Y coordinates, so keep them across the frame.
	; Without this, the first frame is valid but later frames jump off-path.
	push hl
	push bc
	call .DrawProjectile
	call DelayFrame
	call ClearSprites
	pop bc
	pop hl
	pop af
	dec a
	jr nz, .projectileLoop

	; Gold's BattleAnimSub_Sludge creates center/left/right bubbles every 8
	; frames, repeats that triplet five times, then the parent animation waits 64.
	; Simulate the same overlapping object lifetimes without allocating new WRAM.
	ld c, 0 ; impact timeline, 0..183
.impactFrame
	; SFX_TOXIC accompanies every spawned bubble at t=0,8,...112.
	ld a, c
	cp 113
	jr nc, .skipToxicSfx
	and 7
	jr nz, .skipToxicSfx
	push bc
	ld a, GSSFX_TOXIC
	call PlaySound
	pop bc
.skipToxicSfx

	ld hl, GoldSludgeBubbleSpawns
	ld de, wOAMBuffer
	ld b, 15
.bubbleLoop
	ld a, [hli] ; spawn frame
	push bc      ; B=count, C=global frame
	ld b, a
	ld a, c
	sub b        ; age = frame - spawn
	jr c, .inactiveBubble
	cp 34        ; burst frameset is gone after age 33
	jr nc, .inactiveBubble
	ld b, a      ; B=age
	ld a, [hli]  ; logical Gold X
	ld c, a      ; C=logical X
	push hl
	call .DrawBubble
	pop hl
	jr .bubbleDone
.inactiveBubble
	inc hl       ; skip logical X
.bubbleDone
	pop bc
	dec b
	jr nz, .bubbleLoop

	push bc
	call DelayFrame
	call ClearSprites
	pop bc
	inc c
	ld a, c
	cp 184       ; 15*8 frame subroutine + Gold's final anim_wait 64
	jr c, .impactFrame

	; ANM-5.61.45: match the Shadow Ball dark-background lifetime: keep the
	; gentle darkening until the complete impact/tail sequence has finished.
	callba AnimationResetScreenPalette
	ret

.DrawProjectile:
	; B/C = Gold logical center after this frame's movement, D = sine Y offset.
	; Build the same four-sprite 16x16 BARRAGE_BALL OAM set used by Sludge Bomb.
	ld a, [H_WHOSETURN]
	and a
	jr nz, .enemyProjectile
	ld h, b
	ld a, c
	add d
	ld l, a
	jr .gotProjectileCenter
.enemyProjectile
	ld a, 180
	sub b
	ld h, a
	ld a, 144
	sub c
	add d ; Gold flips base coordinates but not the function's Y offset
	ld l, a
.gotProjectileCenter
	ld de, wOAMBuffer

	; top-left
	ld a, l
	sub 8
	ld [de], a
	inc de
	ld a, h
	sub 8
	ld [de], a
	inc de
	ld a, SLUDGE_BOMB_PROJECTILE_TILE_1
	ld [de], a
	inc de
	xor a ; ATK_PAL_GREY
	ld [de], a
	inc de

	; top-right (X flip)
	ld a, l
	sub 8
	ld [de], a
	inc de
	ld a, h
	ld [de], a
	inc de
	ld a, SLUDGE_BOMB_PROJECTILE_TILE_1
	ld [de], a
	inc de
	ld a, OAM_HFLIP | ATK_PAL_GREY
	ld [de], a
	inc de

	; bottom-left
	ld a, l
	ld [de], a
	inc de
	ld a, h
	sub 8
	ld [de], a
	inc de
	ld a, SLUDGE_BOMB_PROJECTILE_TILE_2
	ld [de], a
	inc de
	xor a
	ld [de], a
	inc de

	; bottom-right (X flip)
	ld a, l
	ld [de], a
	inc de
	ld a, h
	ld [de], a
	inc de
	ld a, SLUDGE_BOMB_PROJECTILE_TILE_2
	ld [de], a
	inc de
	ld a, OAM_HFLIP | ATK_PAL_GREY
	ld [de], a
	ret

.DrawBubble:
	; B=age, C=Gold logical X, DE=next OAM entry. Gold's sludge object holds at
	; Y=72 for 13 frames, then switches to the burst frameset while rising 1 px/frame.
	xor a
	ld h, a ; rise amount
	ld a, b
	cp 13
	jr c, .chooseBubbleTile
	sub 12
	ld h, a
.chooseBubbleTile
	ld a, b
	cp 4
	ld l, SLUDGE_BOMB_BUBBLE_TILE_1
	jr c, .gotBubbleTile
	cp 8
	ld l, SLUDGE_BOMB_BUBBLE_TILE_2
	jr c, .gotBubbleTile
	cp 13
	ld l, SLUDGE_BOMB_BUBBLE_TILE_3
	jr c, .gotBubbleTile
	cp 30
	ld l, SLUDGE_BOMB_BURST_TILE_1
	jr c, .gotBubbleTile
	ld l, SLUDGE_BOMB_BURST_TILE_2
.gotBubbleTile

	; Raw OAMData_0f is centered with a -4/-4 offset.
	ld a, [H_WHOSETURN]
	and a
	ld a, 72
	jr z, .gotBubbleBaseY
	ld a, 108 ; 180 - logical Y 72 (Gold fixY $b4)
.gotBubbleBaseY
	sub h
	sub 4
	ld [de], a
	inc de

	ld a, [H_WHOSETURN]
	and a
	ld a, c
	jr z, .gotBubbleX
	ld a, 180
	sub c
.gotBubbleX
	sub 4
	ld [de], a
	inc de

	ld a, l
	ld [de], a
	inc de
	xor a ; ATK_PAL_GREY
	ld [de], a
	inc de
	ret

; Exact Gold BATTLE_ANIM_FUNC_THROW_TO_TARGET_DISAPPEAR sine results for
; amplitude $10 and initial VAR1=0 (phase decrements once per frame).
GoldSludgeBombThrowOffsets:
	db $00,$ff,$fd,$fc,$fa,$f9,$f8,$f6,$f5,$f4,$f3,$f2
	db $f2,$f1,$f1,$f1,$f0,$f1,$f1,$f1,$f2,$f2,$f3,$f4
	db $f5,$f6,$f8,$f9,$fa,$fc,$fd,$ff,$00,$01,$03,$04

; spawn frame, logical X. Gold order is center / left / right, repeated 5x.
GoldSludgeBubbleSpawns:
	db   0,132,   8,116,  16,148
	db  24,132,  32,116,  40,148
	db  48,132,  56,116,  64,148
	db  72,132,  80,116,  88,148
	db  96,132, 104,116, 112,148

; Exact Gold poison.png tiles 4-8 (8x8 2bpp), used by OAM sets $0f/$10/$1e/$1f/$20.
GoldSludgeBubbleTiles:
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$3c,$3c,$7e,$5e,$ff,$ff
	db $00,$00,$00,$00,$00,$00,$3c,$3c,$7e,$6e,$ff,$df,$ff,$ff,$ff,$ff
	db $3c,$3c,$7e,$6e,$ff,$df,$ff,$df,$ff,$ff,$7e,$7e,$3c,$3c,$ff,$ff
	db $3c,$3c,$7e,$6e,$ff,$df,$ff,$df,$ff,$ff,$ff,$ff,$7e,$7e,$3c,$3c
	db $3c,$3c,$7e,$7e,$c3,$c3,$81,$81,$81,$81,$00,$00,$00,$00,$00,$00
GoldSludgeBubbleTilesEnd:
	IF GoldSludgeBubbleTilesEnd - GoldSludgeBubbleTiles != 5 * 16
		fail "Gold Sludge Bomb bubble tiles must contain exactly 5 tiles"
	ENDC
