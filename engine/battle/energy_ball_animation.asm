; ANM-5.62.05: Polished Crystal Energy Ball renderer for ENERGY_BALL.
;
; Keep Polished Crystal's charge, object art, Gastro Acid palette, SFX timeline,
; Tiny Glow projectile and Bubble Splash impact. Two deliberate RPP adaptations:
;   1) the projectile uses the current Shadow Ball selected 34-frame
;      WAVE_TO_TARGET coordinates on both sides;
;   2) the first impact is anchored exactly at the current RPP Shadow Ball poof
;      center: (128,64) / (48,104); PC's later bubble/hit offsets stay relative.
;
; The renderer lives in roomy bank $3D and does not modify Shadow Ball itself.

ENERGY_BALL_TILE_BASE       EQU $60
ENERGY_BALL_GLOW_TILE_A     EQU $6a
ENERGY_BALL_GLOW_TILE_B     EQU $6b
ENERGY_BALL_HIT_TILE_BASE   EQU $6c
ENERGY_BALL_BUBBLE_TILE_BASE EQU $70
ENERGY_BALL_TILE_COUNT      EQU 17
ENERGY_BALL_OBJ_PAL         EQU ATK_PAL_GREEN
ENERGY_BALL_CHARGE_FRAMES   EQU 128
ENERGY_BALL_PROJECTILE_FRAMES EQU 34
ENERGY_BALL_IMPACT_FRAMES   EQU 24

PlayPolishedCrystalEnergyBallAnimation::
	call .LoadTiles
	call .InstallPalette
	call .PlayCharge

	; Polished Crystal launches Energy Ball with SFX_SWEET_SCENT.
	ld a,GSSFX_SWEET_SCENT
	call PlaySound
	call .PlayProjectile
	call .PlayImpact

	; Restore both stock OBJ palettes and the stock tile->palette map.
	callba _LoadAnimationTilesetPalettes
	ld a,$e4
	ld [rOBP0],a
	ld [rOBP1],a
	ret

.LoadTiles
	ld hl,vSprites + ENERGY_BALL_TILE_BASE * 16
	ld de,EnergyBallObjectTiles
	ld b,BANK(EnergyBallObjectTiles)
	ld c,ENERGY_BALL_TILE_COUNT
	call CopyVideoData
	ret

.InstallPalette
	; Do not carry saved stack data across an SVBK change; switch banks directly,
	; matching the proven Sacred Fire / Icy Wind palette installers.
	ld a,2
	ld [rSVBK],a
	ld hl,EnergyBallGastroAcidPalette
	ld de,W2_SprPaletteData + ENERGY_BALL_OBJ_PAL * 8
	ld bc,8
	call CopyData

	; ColorNonOverworldSprites rewrites OAM palettes from this map every frame.
	; Map the private $60-$70 tile range to the Gastro Acid slot as well.
	ld hl,W2_SpritePaletteMap + ENERGY_BALL_TILE_BASE
	ld b,ENERGY_BALL_TILE_COUNT
	ld a,ENERGY_BALL_OBJ_PAL
.paletteMapLoop
	ld [hli],a
	dec b
	jr nz,.paletteMapLoop
	ld a,1
	ld [W2_ForceOBPUpdate],a
	xor a
	ld [rSVBK],a
	ret

.PlayCharge
	xor a
	ld [wSubAnimCounter],a
.chargeLoop
	ld a,[wSubAnimCounter]
	; PC: WARP_TO at charge frames 0,16,32,48.
	cp 64
	jr nc,.checkPresent
	and $0f
	jr nz,.checkPresent
	ld a,GSSFX_WARP_TO
	call PlaySound
.checkPresent
	ld a,[wSubAnimCounter]
	cp 80
	jr nz,.drawCharge
	ld a,GSSFX_PRESENT
	call PlaySound
.drawCharge
	call .DrawChargeFrame
	call DelayFrame
	call ClearSprites
	ld hl,wSubAnimCounter
	inc [hl]
	ld a,[hl]
	cp ENERGY_BALL_CHARGE_FRAMES
	jp c,.chargeLoop
	ret

.DrawChargeFrame
	ld de,wOAMBuffer
	ld a,[H_WHOSETURN]
	and a
	jr nz,.enemyChargeCenter
	ld b,44
	ld c,88
	jr .chargeCenterReady
.enemyChargeCenter
	ld b,136
	ld c,48
.chargeCenterReady
	ld a,b
	ld [wBaseCoordX],a
	ld a,c
	ld [wBaseCoordY],a

	; PC's ABSORB_CENTER frameset: blank20, tile5x40, tile4x40,
	; large20, blank4, large4. The parent script clears at frame 128.
	ld a,[wSubAnimCounter]
	cp 20
	jr c,.chargeParticles
	cp 60
	jr nc,.centerTile4
	ld h,ENERGY_BALL_TILE_BASE + 5
	call .DrawSmallSquare
	jr .chargeParticles
.centerTile4
	cp 100
	jr nc,.centerLargeOrWait
	ld h,ENERGY_BALL_TILE_BASE + 4
	call .DrawSmallSquare
	jr .chargeParticles
.centerLargeOrWait
	cp 120
	jr c,.centerLarge
	cp 124
	jr c,.chargeParticles
.centerLarge
	ld h,ENERGY_BALL_TILE_BASE
	call .DrawNineSpriteObject

.chargeParticles
	; PC CHARGE uses frameset 43 -> OAM sets $20/$1f/$1e.  Each set is one
	; centered 8x8 sprite (Energy Ball tiles 8/7/6), not OAMData_0f's
	; five-sprite composite.  All eight charge particles therefore fit easily.
	ld a,[wSubAnimCounter]
	cp 96
	ret nc
	ld c,a
	ld b,8
	push bc
	ld a,c
	ld l,a
	ld h,0
	add hl,hl
	add hl,hl
	add hl,hl
	add hl,hl ; HL = frame * 16
	push de
	ld de,EnergyBallChargeOffsets
	add hl,de
	pop de
	pop bc
	ld a,b
.particleLoop
	push af
	push de ; preserve next OAM entry while D/E hold the signed particle offset
	ld a,[hli]
	ld d,a
	ld a,[hli]
	ld e,a
	push hl
	ld a,[H_WHOSETURN]
	and a
	jr nz,.enemyParticle
	ld a,[wBaseCoordX]
	add d
	ld b,a
	ld a,[wBaseCoordY]
	add e
	ld c,a
	jr .particleCoordReady
.enemyParticle
	ld a,[wBaseCoordX]
	sub d
	ld b,a
	ld a,[wBaseCoordY]
	add e
	ld c,a
.particleCoordReady
	pop hl ; restore the offset-table pointer
	pop de ; restore the next OAM entry
	push hl
	ld a,[wSubAnimCounter]
	cp 16
	jr nc,.particleMid
	ld h,ENERGY_BALL_TILE_BASE + 8
	jr .drawParticle
.particleMid
	cp 32
	jr nc,.particleLate
	ld h,ENERGY_BALL_TILE_BASE + 7
	jr .drawParticle
.particleLate
	ld h,ENERGY_BALL_TILE_BASE + 6
.drawParticle
	call .DrawSingleTile
	pop hl
	pop af
	dec a
	jp nz,.particleLoop
	ret

.PlayProjectile
	; RPP adaptation: use the current Shadow Ball trajectory exactly, including
	; its $98 enemy Y mapping and 34 visible frames; only the object art is
	; Polished Crystal's alternating Tiny Glow.
	ld b,$40
	ld c,$5c
	ld hl,EnergyBallShadowPathOffsets
	xor a
	ld [wSubAnimCounter],a
.projectileLoop
	inc b
	inc b
	dec c
	push bc
	ld a,[hli]
	ld d,a
	ld a,[hli]
	ld e,a
	ld a,[H_WHOSETURN]
	and a
	jr nz,.projectileEnemy
	ld a,b
	add d
	ld b,a
	ld a,c
	add e
	ld c,a
	jr .projectileReady
.projectileEnemy
	ld a,$b4
	sub b
	sub d
	ld b,a
	ld a,$98
	sub c
	add e
	ld c,a
.projectileReady
	push hl
	ld de,wOAMBuffer
	ld a,[wSubAnimCounter]
	and 1
	ld h,ENERGY_BALL_GLOW_TILE_A
	jr z,.projectileTileReady
	ld h,ENERGY_BALL_GLOW_TILE_B
.projectileTileReady
	call .DrawSmallSquare
	call DelayFrame
	call ClearSprites
	pop hl
	pop bc
	ld a,[wSubAnimCounter]
	inc a
	ld [wSubAnimCounter],a
	cp ENERGY_BALL_PROJECTILE_FRAMES
	jp c,.projectileLoop
	ret

.PlayImpact
	; PC impact timing: Toxic+Hit, four frames later start the six-frame horizontal
	; shake + four Bubble Splash objects + Toxic+Hit, four frames later Toxic+Hit,
	; then a 16-frame tail. The first hit is exactly Shadow Ball's poof center.
	xor a
	ld [wSubAnimCounter],a
.impactLoop
	ld a,[wSubAnimCounter]
	and a
	jr z,.impactSound
	cp 4
	jr z,.impactSound
	cp 8
	jr nz,.impactSoundDone
.impactSound
	ld a,GSSFX_TOXIC
	call PlaySound
.impactSoundDone
	; Polished Crystal starts horizontal shake with the Bubble Splash phase.
	; Keep the VBlank latch armed after the six active frames so neutral WX=7 is
	; presented before shutdown.
	ld a,[wSubAnimCounter]
	cp 4
	jr nz,.setImpactShake
	call GoldBattleHorizontalShakeBegin
.setImpactShake
	ld a,[wSubAnimCounter]
	cp 4
	jr c,.impactShakeDone
	ld b,4
	ld c,10
	ld d,1
	ld e,1
	call GoldBattleHorizontalShakeSet
.impactShakeDone

	ld de,wOAMBuffer
	ld a,[wSubAnimCounter]
	cp 6
	jr nc,.maybeBubbles
	call .GetImpactHit1
	ld h,ENERGY_BALL_HIT_TILE_BASE
	call .DrawNineSpriteObject

.maybeBubbles
	ld a,[wSubAnimCounter]
	cp 4
	jr c,.maybeHit2
	cp 21
	jr nc,.maybeHit2
	sub 4
	call .DrawBubblesForFrame

.maybeHit2
	ld a,[wSubAnimCounter]
	cp 4
	jr c,.maybeHit3
	cp 10
	jr nc,.maybeHit3
	call .GetImpactHit2
	ld h,ENERGY_BALL_HIT_TILE_BASE
	call .DrawNineSpriteObject

.maybeHit3
	ld a,[wSubAnimCounter]
	cp 8
	jr c,.impactFrameReady
	cp 14
	jr nc,.impactFrameReady
	call .GetImpactHit3
	ld h,ENERGY_BALL_HIT_TILE_BASE
	call .DrawNineSpriteObject

.impactFrameReady
	call DelayFrame
	call ClearSprites
	ld hl,wSubAnimCounter
	inc [hl]
	ld a,[hl]
	cp ENERGY_BALL_IMPACT_FRAMES
	jp c,.impactLoop
	; Neutral WX has already reached VBlank. Disarm the latch, then clear the
	; shared $CD3D scratch so battle state cannot leak into overworld temporaries.
	call GoldBattleHorizontalShakeEnd
	xor a
	ld [wBattleAnimWX],a
	ret

.GetImpactOrigin
	; RPP adaptation: anchor the first Hit at the current Shadow Ball poof center
	; on both sides; later Polished Crystal coordinates remain relative to it.
	ld a,[H_WHOSETURN]
	and a
	jr nz,.impactOriginEnemy
	ld b,128
	ld c,64
	ret
.impactOriginEnemy
	ld b,48
	ld c,104
	ret

.GetImpactHit1
	jp .GetImpactOrigin

.GetImpactHit2
	call .GetImpactOrigin
	ld a,[H_WHOSETURN]
	and a
	jr nz,.hit2Enemy
	ld a,b
	add 8
	ld b,a
	jr .hit2Y
.hit2Enemy
	ld a,b
	sub 8
	ld b,a
.hit2Y
	ld a,c
	sub 8
	ld c,a
	ret

.GetImpactHit3
	call .GetImpactOrigin
	ld a,[H_WHOSETURN]
	and a
	jr nz,.hit3Enemy
	ld a,b
	sub 8
	ld b,a
	jr .hit3Y
.hit3Enemy
	ld a,b
	add 8
	ld b,a
.hit3Y
	ld a,c
	sub 16
	ld c,a
	ret

.DrawBubblesForFrame
	; A = bubble frame 0..16. Four signed dx/dy pairs per row.
	add a
	add a
	add a
	ld l,a
	ld h,0
	ld bc,EnergyBallBurstOffsets
	add hl,bc
	ld a,4
.bubbleLoop
	push af
	ld a,[hli]
	ld b,a
	ld a,[hli]
	ld c,a
	push hl
	push bc
	call .GetImpactOrigin
	; PC Bubble Splash starts at (+4,+8) from its first Hit. Mirror only X.
	ld a,[H_WHOSETURN]
	and a
	jr nz,.bubbleBaseEnemy
	ld a,b
	add 4
	ld b,a
	jr .bubbleBaseY
.bubbleBaseEnemy
	ld a,b
	sub 4
	ld b,a
.bubbleBaseY
	ld a,c
	add 8
	ld c,a
	pop hl ; H=dx, L=dy from pushed BC
	ld a,[H_WHOSETURN]
	and a
	jr nz,.bubbleEnemyX
	ld a,b
	add h
	ld b,a
	jr .bubbleY
.bubbleEnemyX
	ld a,b
	sub h
	ld b,a
.bubbleY
	ld a,c
	add l
	ld c,a
	ld h,ENERGY_BALL_BUBBLE_TILE_BASE
	call .DrawBubbleTile
	pop hl
	pop af
	dec a
	jp nz,.bubbleLoop
	ret

; H = tile base, B/C = center, DE = next OAM entry.
.DrawSmallSquare
	ld a,c
	sub 8
	ld [de],a
	inc de
	ld a,b
	sub 8
	ld [de],a
	inc de
	ld a,h
	ld [de],a
	inc de
	ld a,ENERGY_BALL_OBJ_PAL
	ld [de],a
	inc de
	ld a,c
	sub 8
	ld [de],a
	inc de
	ld a,b
	ld [de],a
	inc de
	ld a,h
	ld [de],a
	inc de
	ld a,ENERGY_BALL_OBJ_PAL | OAM_HFLIP
	ld [de],a
	inc de
	ld a,c
	ld [de],a
	inc de
	ld a,b
	sub 8
	ld [de],a
	inc de
	ld a,h
	ld [de],a
	inc de
	ld a,ENERGY_BALL_OBJ_PAL | OAM_VFLIP
	ld [de],a
	inc de
	ld a,c
	ld [de],a
	inc de
	ld a,b
	ld [de],a
	inc de
	ld a,h
	ld [de],a
	inc de
	ld a,ENERGY_BALL_OBJ_PAL | OAM_HFLIP | OAM_VFLIP
	ld [de],a
	inc de
	ret

; PC OAMData_0f is one centered 8x8 sprite.  Frameset 43 (Charge) and
; Bubble Splash both reference this one-sprite layout.
.DrawSingleTile
	ld a,c
	sub 4
	ld [de],a
	inc de
	ld a,b
	sub 4
	ld [de],a
	inc de
	ld a,h
	ld [de],a
	inc de
	ld a,ENERGY_BALL_OBJ_PAL
	ld [de],a
	inc de
	ret

.DrawBubbleTile
	ld a,c
	sub 4
	ld [de],a
	inc de
	ld a,b
	sub 4
	ld [de],a
	inc de
	ld a,h
	ld [de],a
	inc de
	ld a,[H_WHOSETURN]
	and a
	ld a,ENERGY_BALL_OBJ_PAL
	jr z,.bubbleAttrReady
	or OAM_HFLIP ; PC ANIM_OBJ_BUBBLE_SPLASH carries OAM_XFLIP for enemy use
.bubbleAttrReady
	ld [de],a
	inc de
	ret

; PC OAMData_01: 3x3 impact/large-energy arrangement using four unique tiles.
.DrawNineSpriteObject
	; row -12
	ld a,c
	sub 12
	ld [de],a
	inc de
	ld a,b
	sub 12
	ld [de],a
	inc de
	ld a,h
	ld [de],a
	inc de
	ld a,ENERGY_BALL_OBJ_PAL
	ld [de],a
	inc de
	ld a,c
	sub 12
	ld [de],a
	inc de
	ld a,b
	sub 4
	ld [de],a
	inc de
	ld a,h
	inc a
	ld [de],a
	inc de
	ld a,ENERGY_BALL_OBJ_PAL
	ld [de],a
	inc de
	ld a,c
	sub 12
	ld [de],a
	inc de
	ld a,b
	add 4
	ld [de],a
	inc de
	ld a,h
	ld [de],a
	inc de
	ld a,ENERGY_BALL_OBJ_PAL | OAM_HFLIP
	ld [de],a
	inc de
	; row -4
	ld a,c
	sub 4
	ld [de],a
	inc de
	ld a,b
	sub 12
	ld [de],a
	inc de
	ld a,h
	add 2
	ld [de],a
	inc de
	ld a,ENERGY_BALL_OBJ_PAL
	ld [de],a
	inc de
	ld a,c
	sub 4
	ld [de],a
	inc de
	ld a,b
	sub 4
	ld [de],a
	inc de
	ld a,h
	add 3
	ld [de],a
	inc de
	ld a,ENERGY_BALL_OBJ_PAL
	ld [de],a
	inc de
	ld a,c
	sub 4
	ld [de],a
	inc de
	ld a,b
	add 4
	ld [de],a
	inc de
	ld a,h
	add 2
	ld [de],a
	inc de
	ld a,ENERGY_BALL_OBJ_PAL | OAM_HFLIP | OAM_VFLIP
	ld [de],a
	inc de
	; row +4
	ld a,c
	add 4
	ld [de],a
	inc de
	ld a,b
	sub 12
	ld [de],a
	inc de
	ld a,h
	ld [de],a
	inc de
	ld a,ENERGY_BALL_OBJ_PAL | OAM_VFLIP
	ld [de],a
	inc de
	ld a,c
	add 4
	ld [de],a
	inc de
	ld a,b
	sub 4
	ld [de],a
	inc de
	ld a,h
	inc a
	ld [de],a
	inc de
	ld a,ENERGY_BALL_OBJ_PAL | OAM_HFLIP | OAM_VFLIP
	ld [de],a
	inc de
	ld a,c
	add 4
	ld [de],a
	inc de
	ld a,b
	add 4
	ld [de],a
	inc de
	ld a,h
	ld [de],a
	inc de
	ld a,ENERGY_BALL_OBJ_PAL | OAM_HFLIP | OAM_VFLIP
	ld [de],a
	inc de
	ret

EnergyBallGastroAcidPalette:
	RGB 31,31,31
	RGB 27,31,5
	RGB 15,31,1
	RGB 9,25,0

; Exact PC source tiles needed by Energy Ball:
; energyball.png all 10 tiles, glow.png tiles 4-5, hit.png tiles 4-7,
; bubble.png tile 8.
EnergyBallObjectTiles:
	db $00,$00,$00,$00,$18,$18,$26,$3e,$21,$3f,$16,$19,$17,$18,$0b,$0c
	db $18,$18,$24,$3c,$24,$3c,$5a,$66,$bd,$c3,$7e,$81,$c3,$00,$00,$00
	db $0a,$0c,$16,$18,$6c,$70,$9c,$e0,$9c,$e0,$6c,$70,$16,$18,$0a,$0c
	db $00,$00,$00,$00,$18,$00,$3c,$00,$3c,$00,$18,$00,$00,$00,$00,$00
	db $01,$01,$02,$03,$1a,$1b,$25,$3e,$2f,$30,$1c,$10,$68,$70,$98,$e0
	db $00,$00,$00,$00,$03,$03,$0c,$0f,$11,$1e,$17,$18,$24,$38,$2c,$30
	db $3c,$3c,$42,$7e,$99,$e7,$a5,$c3,$a5,$c3,$99,$e7,$42,$7e,$3c,$3c
	db $00,$00,$18,$18,$24,$3c,$5a,$66,$5a,$66,$24,$3c,$18,$18,$00,$00
	db $00,$00,$00,$00,$18,$18,$24,$3c,$24,$3c,$18,$18,$00,$00,$00,$00
	db $00,$00,$00,$00,$03,$03,$0f,$0f,$1c,$1f,$19,$1e,$33,$3c,$36,$39
	db $07,$07,$1f,$1f,$3c,$3f,$70,$7f,$60,$7f,$e3,$fc,$c7,$f8,$c7,$f8
	db $00,$00,$00,$00,$03,$03,$0f,$0f,$1f,$1f,$1c,$1f,$38,$3f,$39,$3e
	db $00,$00,$00,$00,$00,$00,$00,$18,$08,$16,$06,$09,$07,$08,$03,$04
	db $00,$18,$18,$24,$18,$24,$3c,$42,$3c,$42,$7e,$81,$ff,$00,$ff,$00
	db $03,$04,$07,$18,$1f,$60,$7f,$80,$7f,$80,$1f,$60,$07,$18,$03,$04
	db $ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00
	db $3c,$3c,$4a,$46,$85,$83,$85,$83,$cd,$83,$b9,$c7,$42,$7e,$3c,$3c

EnergyBallShadowPathOffsets:
	db $01,$00,$00,$06,$00,$0b,$00,$0e
	db $00,$10,$ff,$0e,$ff,$0b,$ff,$06
	db $ff,$00,$ff,$fa,$ff,$f5,$ff,$f2
	db $00,$f0,$00,$f2,$00,$f5,$00,$fa
	db $01,$00,$00,$06,$00,$0b,$00,$0e
	db $00,$10,$ff,$0e,$ff,$0b,$ff,$06
	db $ff,$00,$ff,$fa,$ff,$f5,$ff,$f2
	db $00,$f0,$00,$f2,$00,$f5,$00,$fa
	db $01,$00,$00,$06

; 96 frames × 8 PC Recover/Charge offsets (dx,dy), radius 48->1.
EnergyBallChargeOffsets:
	db $30,$00,$21,$21,$00,$30,$df,$21,$d0,$00,$df,$df,$00,$d0,$21,$df
	db $2f,$04,$1e,$25,$fc,$2f,$db,$1e,$d1,$fc,$e2,$db,$04,$d1,$25,$e2
	db $2e,$09,$1a,$27,$f7,$2e,$d9,$1a,$d2,$f7,$e6,$d9,$09,$d2,$27,$e6
	db $2c,$0d,$16,$29,$f3,$2c,$d7,$16,$d4,$f3,$ea,$d7,$0d,$d4,$29,$ea
	db $2a,$11,$11,$2a,$ef,$2a,$d6,$11,$d6,$ef,$ef,$d6,$11,$d6,$2a,$ef
	db $28,$15,$0d,$2c,$eb,$28,$d4,$0d,$d8,$eb,$f3,$d4,$15,$d8,$2c,$f3
	db $25,$19,$08,$2c,$e7,$25,$d4,$08,$db,$e7,$f8,$d4,$19,$db,$2c,$f8
	db $22,$1c,$04,$2c,$e4,$22,$d4,$04,$de,$e4,$fc,$d4,$1c,$de,$2c,$fc
	db $1f,$1f,$00,$2c,$e1,$1f,$d4,$00,$e1,$e1,$00,$d4,$1f,$e1,$2c,$00
	db $1b,$22,$fc,$2b,$de,$1b,$d5,$fc,$e5,$de,$04,$d5,$22,$e5,$2b,$04
	db $17,$23,$f8,$2a,$dd,$17,$d6,$f8,$e9,$dd,$08,$d6,$23,$e9,$2a,$08
	db $14,$25,$f4,$29,$db,$14,$d7,$f4,$ec,$db,$0c,$d7,$25,$ec,$29,$0c
	db $10,$26,$f0,$26,$da,$10,$da,$f0,$f0,$da,$10,$da,$26,$f0,$26,$10
	db $0c,$28,$ed,$25,$d8,$0c,$db,$ed,$f4,$d8,$13,$db,$28,$f4,$25,$13
	db $07,$28,$ea,$22,$d8,$07,$de,$ea,$f9,$d8,$16,$de,$28,$f9,$22,$16
	db $04,$28,$e6,$1f,$d8,$04,$e1,$e6,$fc,$d8,$1a,$e1,$28,$fc,$1f,$1a
	db $00,$28,$e4,$1c,$d8,$00,$e4,$e4,$00,$d8,$1c,$e4,$28,$00,$1c,$1c
	db $fd,$27,$e2,$19,$d9,$fd,$e7,$e2,$03,$d9,$1e,$e7,$27,$03,$19,$1e
	db $f9,$26,$e0,$15,$da,$f9,$eb,$e0,$07,$da,$20,$eb,$26,$07,$15,$20
	db $f5,$25,$de,$12,$db,$f5,$ee,$de,$0b,$db,$22,$ee,$25,$0b,$12,$22
	db $f2,$23,$dd,$0e,$dd,$f2,$f2,$dd,$0e,$dd,$23,$f2,$23,$0e,$0e,$23
	db $ef,$21,$dc,$0b,$df,$ef,$f5,$dc,$11,$df,$24,$f5,$21,$11,$0b,$24
	db $ec,$1e,$dc,$07,$e2,$ec,$f9,$dc,$14,$e2,$24,$f9,$1e,$14,$07,$24
	db $e9,$1c,$dc,$03,$e4,$e9,$fd,$dc,$17,$e4,$24,$fd,$1c,$17,$03,$24
	db $e7,$19,$dc,$00,$e7,$e7,$00,$dc,$19,$e7,$24,$00,$19,$19,$00,$24
	db $e5,$16,$dd,$fd,$ea,$e5,$03,$dd,$1b,$ea,$23,$03,$16,$1b,$fd,$23
	db $e3,$13,$de,$fa,$ed,$e3,$06,$de,$1d,$ed,$22,$06,$13,$1d,$fa,$22
	db $e2,$10,$df,$f6,$f0,$e2,$0a,$df,$1e,$f0,$21,$0a,$10,$1e,$f6,$21
	db $e1,$0d,$e1,$f3,$f3,$e1,$0d,$e1,$1f,$f3,$1f,$0d,$0d,$1f,$f3,$1f
	db $e0,$09,$e3,$f0,$f7,$e0,$10,$e3,$20,$f7,$1d,$10,$09,$20,$f0,$1d
	db $e0,$06,$e5,$ee,$fa,$e0,$12,$e5,$20,$fa,$1b,$12,$06,$20,$ee,$1b
	db $e0,$03,$e7,$ec,$fd,$e0,$14,$e7,$20,$fd,$19,$14,$03,$20,$ec,$19
	db $e0,$00,$ea,$ea,$00,$e0,$16,$ea,$20,$00,$16,$16,$00,$20,$ea,$16
	db $e1,$fd,$ec,$e8,$03,$e1,$18,$ec,$1f,$03,$14,$18,$fd,$1f,$e8,$14
	db $e2,$fa,$ef,$e7,$06,$e2,$19,$ef,$1e,$06,$11,$19,$fa,$1e,$e7,$11
	db $e3,$f8,$f2,$e5,$08,$e3,$1b,$f2,$1d,$08,$0e,$1b,$f8,$1d,$e5,$0e
	db $e5,$f5,$f5,$e5,$0b,$e5,$1b,$f5,$1b,$0b,$0b,$1b,$f5,$1b,$e5,$0b
	db $e6,$f2,$f8,$e4,$0e,$e6,$1c,$f8,$1a,$0e,$08,$1c,$f2,$1a,$e4,$08
	db $e8,$f0,$fb,$e4,$10,$e8,$1c,$fb,$18,$10,$05,$1c,$f0,$18,$e4,$05
	db $ea,$ee,$fe,$e4,$12,$ea,$1c,$fe,$16,$12,$02,$1c,$ee,$16,$e4,$02
	db $ed,$ed,$00,$e4,$13,$ed,$1c,$00,$13,$13,$00,$1c,$ed,$13,$e4,$00
	db $ef,$eb,$02,$e5,$15,$ef,$1b,$02,$11,$15,$fe,$1b,$eb,$11,$e5,$fe
	db $f1,$ea,$05,$e6,$16,$f1,$1a,$05,$0f,$16,$fb,$1a,$ea,$0f,$e6,$fb
	db $f4,$e9,$07,$e7,$17,$f4,$19,$07,$0c,$17,$f9,$19,$e9,$0c,$e7,$f9
	db $f7,$e8,$09,$e8,$18,$f7,$18,$09,$09,$18,$f7,$18,$e8,$09,$e8,$f7
	db $f9,$e8,$0c,$ea,$18,$f9,$16,$0c,$07,$18,$f4,$16,$e8,$07,$ea,$f4
	db $fc,$e8,$0d,$ec,$18,$fc,$14,$0d,$04,$18,$f3,$14,$e8,$04,$ec,$f3
	db $fe,$e8,$0f,$ed,$18,$fe,$13,$0f,$02,$18,$f1,$13,$e8,$02,$ed,$f1
	db $00,$e8,$10,$f0,$18,$00,$10,$10,$00,$18,$f0,$10,$e8,$00,$f0,$f0
	db $02,$e9,$12,$f1,$17,$02,$0f,$12,$fe,$17,$ee,$0f,$e9,$fe,$f1,$ee
	db $04,$ea,$13,$f4,$16,$04,$0c,$13,$fc,$16,$ed,$0c,$ea,$fc,$f4,$ed
	db $06,$ea,$14,$f6,$16,$06,$0a,$14,$fa,$16,$ec,$0a,$ea,$fa,$f6,$ec
	db $08,$ec,$14,$f8,$14,$08,$08,$14,$f8,$14,$ec,$08,$ec,$f8,$f8,$ec
	db $0a,$ed,$15,$fa,$13,$0a,$06,$15,$f6,$13,$eb,$06,$ed,$f6,$fa,$eb
	db $0b,$ef,$14,$fc,$11,$0b,$04,$14,$f5,$11,$ec,$04,$ef,$f5,$fc,$ec
	db $0d,$f0,$14,$fe,$10,$0d,$02,$14,$f3,$10,$ec,$02,$f0,$f3,$fe,$ec
	db $0e,$f2,$14,$00,$0e,$0e,$00,$14,$f2,$0e,$ec,$00,$f2,$f2,$00,$ec
	db $0f,$f4,$13,$01,$0c,$0f,$ff,$13,$f1,$0c,$ed,$ff,$f4,$f1,$01,$ed
	db $0f,$f6,$12,$03,$0a,$0f,$fd,$12,$f1,$0a,$ee,$fd,$f6,$f1,$03,$ee
	db $10,$f8,$12,$05,$08,$10,$fb,$12,$f0,$08,$ee,$fb,$f8,$f0,$05,$ee
	db $10,$fa,$10,$06,$06,$10,$fa,$10,$f0,$06,$f0,$fa,$fa,$f0,$06,$f0
	db $11,$fb,$0f,$08,$05,$11,$f8,$0f,$ef,$05,$f1,$f8,$fb,$ef,$08,$f1
	db $10,$fd,$0e,$09,$03,$10,$f7,$0e,$f0,$03,$f2,$f7,$fd,$f0,$09,$f2
	db $10,$ff,$0d,$0a,$01,$10,$f6,$0d,$f0,$01,$f3,$f6,$ff,$f0,$0a,$f3
	db $10,$00,$0b,$0b,$00,$10,$f5,$0b,$f0,$00,$f5,$f5,$00,$f0,$0b,$f5
	db $0f,$01,$0a,$0c,$ff,$0f,$f4,$0a,$f1,$ff,$f6,$f4,$01,$f1,$0c,$f6
	db $0e,$02,$08,$0c,$fe,$0e,$f4,$08,$f2,$fe,$f8,$f4,$02,$f2,$0c,$f8
	db $0e,$04,$07,$0d,$fc,$0e,$f3,$07,$f2,$fc,$f9,$f3,$04,$f2,$0d,$f9
	db $0c,$05,$05,$0c,$fb,$0c,$f4,$05,$f4,$fb,$fb,$f4,$05,$f4,$0c,$fb
	db $0c,$06,$04,$0d,$fa,$0c,$f3,$04,$f4,$fa,$fc,$f3,$06,$f4,$0d,$fc
	db $0a,$07,$02,$0c,$f9,$0a,$f4,$02,$f6,$f9,$fe,$f4,$07,$f6,$0c,$fe
	db $0a,$08,$01,$0c,$f8,$0a,$f4,$01,$f6,$f8,$ff,$f4,$08,$f6,$0c,$ff
	db $08,$08,$00,$0c,$f8,$08,$f4,$00,$f8,$f8,$00,$f4,$08,$f8,$0c,$00
	db $07,$09,$ff,$0b,$f7,$07,$f5,$ff,$f9,$f7,$01,$f5,$09,$f9,$0b,$01
	db $06,$09,$fe,$0a,$f7,$06,$f6,$fe,$fa,$f7,$02,$f6,$09,$fa,$0a,$02
	db $05,$09,$fd,$0a,$f7,$05,$f6,$fd,$fb,$f7,$03,$f6,$09,$fb,$0a,$03
	db $03,$09,$fd,$09,$f7,$03,$f7,$fd,$fd,$f7,$03,$f7,$09,$fd,$09,$03
	db $02,$09,$fc,$08,$f7,$02,$f8,$fc,$fe,$f7,$04,$f8,$09,$fe,$08,$04
	db $01,$08,$fb,$07,$f8,$01,$f9,$fb,$ff,$f8,$05,$f9,$08,$ff,$07,$05
	db $00,$08,$fb,$06,$f8,$00,$fa,$fb,$00,$f8,$05,$fa,$08,$00,$06,$05
	db $00,$08,$fb,$05,$f8,$00,$fb,$fb,$00,$f8,$05,$fb,$08,$00,$05,$05
	db $00,$07,$fa,$05,$f9,$00,$fb,$fa,$00,$f9,$06,$fb,$07,$00,$05,$06
	db $ff,$06,$fb,$03,$fa,$ff,$fd,$fb,$01,$fa,$05,$fd,$06,$01,$03,$05
	db $fe,$06,$fa,$03,$fa,$fe,$fd,$fa,$02,$fa,$06,$fd,$06,$02,$03,$06
	db $fe,$05,$fb,$02,$fb,$fe,$fe,$fb,$02,$fb,$05,$fe,$05,$02,$02,$05
	db $fe,$05,$fb,$01,$fb,$fe,$ff,$fb,$02,$fb,$05,$ff,$05,$02,$01,$05
	db $fe,$04,$fc,$00,$fc,$fe,$00,$fc,$02,$fc,$04,$00,$04,$02,$00,$04
	db $fd,$03,$fc,$00,$fd,$fd,$00,$fc,$03,$fd,$04,$00,$03,$03,$00,$04
	db $fe,$02,$fc,$00,$fe,$fe,$00,$fc,$02,$fe,$04,$00,$02,$02,$00,$04
	db $fd,$02,$fd,$00,$fe,$fd,$00,$fd,$03,$fe,$03,$00,$02,$03,$00,$03
	db $fe,$01,$fe,$00,$ff,$fe,$00,$fe,$02,$ff,$02,$00,$01,$02,$00,$02
	db $fe,$01,$fe,$00,$ff,$fe,$00,$fe,$02,$ff,$02,$00,$01,$02,$00,$02
	db $ff,$00,$ff,$00,$00,$ff,$00,$ff,$01,$00,$01,$00,$00,$01,$00,$01
	db $ff,$00,$ff,$00,$00,$ff,$00,$ff,$01,$00,$01,$00,$00,$01,$00,$01
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; 17 visible frames × four PC Bubble Splash offsets (dx,dy).
EnergyBallBurstOffsets:
	db $01,$00,$ff,$00,$fe,$00,$01,$00
	db $02,$fe,$fe,$fd,$fc,$ff,$02,$ff
	db $03,$fb,$fd,$f9,$fa,$fd,$03,$fd
	db $04,$f8,$fc,$f5,$f8,$fc,$04,$fc
	db $05,$f6,$fb,$f1,$f6,$fa,$05,$fa
	db $06,$f3,$fa,$ee,$f4,$f9,$06,$f9
	db $07,$f1,$f9,$ea,$f2,$f8,$07,$f8
	db $08,$ef,$f8,$e7,$f0,$f6,$08,$f6
	db $09,$ed,$f7,$e4,$ee,$f5,$09,$f5
	db $0a,$eb,$f6,$e2,$ec,$f4,$0a,$f4
	db $0b,$e9,$f5,$df,$ea,$f3,$0b,$f3
	db $0c,$e8,$f4,$dd,$e8,$f2,$0c,$f2
	db $0d,$e7,$f3,$dc,$e6,$f2,$0d,$f2
	db $0e,$e6,$f2,$da,$e4,$f1,$0e,$f1
	db $0f,$e5,$f1,$d9,$e2,$f1,$0f,$f1
	db $10,$e5,$f0,$d9,$e0,$f1,$10,$f1
	db $11,$e4,$ef,$d8,$de,$f0,$11,$f0
