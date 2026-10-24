; ANM-5.62.10: Polished Crystal Gunk Shot renderer for GUNK_SHOT.
;
; Adapt PC's two-stage sequence in RPP's existing animation framework:
;   1) a poison mass beside the user grows as Toxic bubbles converge inward,
;      ending with Gen II Absorb-style short blinks of the full-size mass;
;      RPP intentionally omits BattleAnimSub_AgilityMinor;
;   2) only the barrage stage switches to the dark screen palette, while repeated
;      Mud Shot-style poison projectiles cross the field and Ink Splash particles
;      burst at the target during a VBlank-latched horizontal shake.
;
; Poison object art and the two custom palettes come from Polished Crystal. The
; already-verified Energy Ball Bubble Splash offset table is reused for the
; identical BATTLEANIMFUNC_BUBBLE_SPLASH motion used by Gunk Shot.

GUNK_SHOT_POISON_TILE_BASE EQU $74 ; PC poison.png source tile 7
GUNK_SHOT_TILE_COUNT       EQU 12  ; $74-$7f
GUNK_SHOT_OBJ_PAL          EQU ATK_PAL_PURPLE
GUNK_SHOT_CHARGE_FRAMES    EQU 100
GUNK_SHOT_BARRAGE_FRAMES   EQU 100
GUNK_SHOT_SHAKE_FRAMES     EQU 96
; ANIM-5.62.80: 3 original motion steps per 4 VBlanks (no dropped VBlanks).
GUNK_SHOT_SLOW_CHARGE      EQU 134 ; ceil(100 * 4 / 3)
GUNK_SHOT_SLOW_BARRAGE     EQU 134 ; ceil(100 * 4 / 3)
; ANIM-5.62.81: the final four-bubble group brings the total to 28.
GUNK_SHOT_CHARGE_BUBBLES  EQU 28
; Small dot -> medium 2x2 -> large 3x3, then three full-size blinks.
GUNK_SHOT_CHARGE_SMALL_END  EQU 26
GUNK_SHOT_CHARGE_MEDIUM_END EQU 50
GUNK_SHOT_CHARGE_GROW_END   EQU 76
; ANIM-5.62.87: the full-size blinks hand off directly to the barrage.

PlayPolishedCrystalGunkShotAnimation::
	call .LoadTiles
	call .InstallPurplePalette
	call .PlayCharge

	; After the final blink, transition without replaying Toxic or
	; adding any extra DelayFrames pause.

	; PC changes BGP to $1b only after the charge objects are cleared. Keep the
	; charge on the normal battlefield, then darken the screen for the barrage.
	callba AnimationDarkScreenPalette
	call .InstallImpactPalette
	call .PlayBarrage

	; Restore stock OBJ palettes and tile->palette mappings before returning to
	; the ordinary battle-animation engine.
	callba _LoadAnimationTilesetPalettes
	ld a,$e4
	ld [rOBP0],a
	ld [rOBP1],a
	ret

.LoadTiles
	ld hl,vSprites + GUNK_SHOT_POISON_TILE_BASE * 16
	ld de,GunkShotPoisonTiles
	ld b,BANK(GunkShotPoisonTiles)
	ld c,GUNK_SHOT_TILE_COUNT
	call CopyVideoData
	ret

.InstallPurplePalette
	ld hl,GunkShotPurplePalette
	jr .installPalette

.InstallImpactPalette
	ld hl,GunkShotPsychoBoost2Palette
.installPalette
	; Never carry stack data across an SVBK switch. The stack lives in banked
	; WRAM in this project, so install the palette with direct bank changes only.
	ld a,2
	ld [rSVBK],a
	ld de,W2_SprPaletteData + GUNK_SHOT_OBJ_PAL * 8
	ld bc,8
	call CopyData

	; ColorNonOverworldSprites rewrites OAM palette bits from this map each frame.
	; Map all private Gunk Shot tiles to the same custom slot.
	ld hl,W2_SpritePaletteMap + GUNK_SHOT_POISON_TILE_BASE
	ld b,GUNK_SHOT_TILE_COUNT
	ld a,GUNK_SHOT_OBJ_PAL
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
	ld a,[wSubAnimCounter] ; physical VBlank count
	push af
	call .GetStretchedFrame
	; Toxic accents accompany buildup, not the final blinks.
	; Nine repeats at logical ticks 4,12,...,68, ending before blinks.
	; Ignore the repeated logical tick to avoid replaying the same SFX.
	ld a,[wBaseCoordY]
	cp 1
	jr z,.chargeSoundDone
	ld a,[wSubAnimCounter]
	cp 4
	jr c,.chargeSoundDone
	cp 76
	jr nc,.chargeSoundDone
	sub 4
	and 7
	jr nz,.chargeSoundDone
	ld a,GSSFX_TOXIC
	call PlaySound
.chargeSoundDone

	ld de,wOAMBuffer
	call .DrawChargeMass
	; The 3x3 charge sprite uses wBaseCoordY; restore the subframe phase.
	pop af
	push af
	and 3
	ld [wBaseCoordY],a
	call .DrawChargeBubbles
	call DelayFrame
	call ClearSprites
	pop af
	inc a
	ld [wSubAnimCounter],a
	cp GUNK_SHOT_SLOW_CHARGE
	jp c,.chargeLoop
	ret

.GetStretchedFrame
	; A = actual VBlank, wSubAnimCounter = floor(A * 3 / 4).
	; Phase 0,1,2,3 corresponds to 0,3/4,1/2,1/4 logical ticks.
	ld b,a
	add 3
	srl a
	srl a
	ld c,a
	ld a,b
	sub c
	ld [wSubAnimCounter],a
	ld a,b
	and 3
	ld [wBaseCoordY],a
	ret

.DrawChargeMass
	; Inward droplets build a small dot into a full-size 3x3 poison mass.
	ld a,[wSubAnimCounter]
	cp GUNK_SHOT_CHARGE_GROW_END
	jr nc,.chargeFlashTail
	call .GetChargeMassCenter
	ld a,[wSubAnimCounter]
	cp GUNK_SHOT_CHARGE_SMALL_END
	jr c,.smallMass
	cp GUNK_SHOT_CHARGE_MEDIUM_END
	jr c,.mediumMass
	jr .largeMass
.chargeFlashTail
	; Gold/Silver Absorb rhythm: 4 blank + 4 large-mass frames, three times.
	sub GUNK_SHOT_CHARGE_GROW_END
	and 7
	cp 4
	ret c
	call .GetChargeMassCenter
	jr .largeMass
.smallMass
	ld h,GUNK_SHOT_POISON_TILE_BASE ; source tile 7
	jp .DrawDot
.mediumMass
	ld h,GUNK_SHOT_POISON_TILE_BASE + 2 ; source tile 9
	jp .DrawMirroredSquare
.largeMass
	jp .DrawNineUnique ; source tiles 10-18

.GetChargeMassCenter
	ld a,[H_WHOSETURN]
	and a
	jr nz,.chargeMassEnemy
	ld b,48
	ld c,96
	ret
.chargeMassEnemy
	ld b,132
	ld c,48
	ret

.DrawChargeBubbles
	; Use the 28 spawn times introduced in 81; reverse each Bubble Splash path.
	; The last droplets feed the enlarged mass before its Absorb blinks.
	xor a ; particle index 0..27
.chargeBubbleLoop
	push af
	add a
	add 4 ; spawn frame = 4 + 2 * index
	ld b,a
	ld a,[wSubAnimCounter]
	sub b
	jr c,.chargeBubbleSkip
	cp 17
	jr nc,.chargeBubbleSkip
	ld b,a ; age
	pop af
	push af
	and 3
	ld c,a ; param family 0..3
	call .GetInwardBubbleOffset
	push bc ; signed dx/dy
	call .GetChargeBubbleOrigin
	pop hl ; H=dx, L=dy
	ld a,[H_WHOSETURN]
	and a
	jr nz,.chargeBubbleEnemyX
	ld a,b
	add h
	ld b,a
	jr .chargeBubbleY
.chargeBubbleEnemyX
	ld a,b
	sub h
	ld b,a
.chargeBubbleY
	ld a,c
	add l
	ld c,a
	ld h,GUNK_SHOT_POISON_TILE_BASE
	call .DrawDot
.chargeBubbleSkip
	pop af
	inc a
	cp GUNK_SHOT_CHARGE_BUBBLES
	jr c,.chargeBubbleLoop
	ret

.GetChargeBubbleOrigin
	; Converge on the exact charge-mass center, on either attacker's side.
	jp .GetChargeMassCenter

.GetBubbleOffset
	; B=age 0..16, C=param family 0..3. Return signed dx/dy in B/C.
	ld a,b
	add a
	add a
	add a ; age * 8
	ld b,a
	ld a,c
	add a ; family * 2
	add b
	ld c,a
	ld b,0
	ld hl,EnergyBallBurstOffsets
	add hl,bc
	ld a,[hli]
	ld b,a
	ld a,[hl]
	ld c,a
	ret

.GetSmoothBubbleOffset
	; Interpolate between adjacent PC samples instead of repeating a frame.
	; B=age 0..16, C=family 0..3; preserve the next OAM pointer DE.
	ld a,[wBaseCoordY]
	and a
	jp z,.GetBubbleOffset
	ld a,b
	cp 16 ; last defined sample has no successor
	jp z,.GetBubbleOffset
	push de
	push bc ; original age/family
	call .GetBubbleOffset
	pop hl ; original age/family (H/L)
	push bc ; preserve current dx/dy across the second lookup
	ld b,h
	ld c,l
	inc b
	call .GetBubbleOffset ; B/C = next signed dx/dy
	pop hl ; H/L = current signed dx/dy
	ld a,h
	add b
	sra a
	ld d,a ; halfway dx
	ld a,l
	add c
	sra a
	ld e,a ; halfway dy
	ld a,[wBaseCoordY]
	cp 2
	jr z,.smoothHalf
	cp 1
	jr nz,.smoothQuarter
	; Phase 1 is three quarters of the way to the next PC sample.
	ld a,d
	add b
	sra a
	ld b,a
	ld a,e
	add c
	sra a
	ld c,a
	pop de
	ret
.smoothQuarter
	; Phase 3 is one quarter of the way to the next PC sample.
	ld a,d
	add h
	sra a
	ld b,a
	ld a,e
	add l
	sra a
	ld c,a
	pop de
	ret
.smoothHalf
	ld b,d
	ld c,e
	pop de
	ret

.GetInwardBubbleOffset
	; B=age 0..16; play the 17 Bubble Splash positions in reverse order.
	; Fractional interpolation must reverse too, or droplets jitter outward.
	ld a,[wBaseCoordY]
	and a
	jr nz,.inwardFraction
	ld a,16
	sub b
	ld b,a
	jp .GetBubbleOffset
.inwardFraction
	ld a,b
	cp 16
	jr z,.inwardFinal
	ld a,15
	sub b
	ld b,a
	ld a,[wBaseCoordY]
	push af
	cpl
	add 5 ; reverse subframe phase: 1->3, 2->2, 3->1
	ld [wBaseCoordY],a
	call .GetSmoothBubbleOffset
	pop af
	ld [wBaseCoordY],a
	ret
.inwardFinal
	ld b,0
	jp .GetBubbleOffset

.PlayBarrage
	; PC starts a 96-frame, 4-pixel horizontal shake here. Its shake phase flips
	; every two frames; d=2 in the shared RPP helper reproduces that cadence.
	call GoldBattleHorizontalShakeBegin
	xor a
	ld [wSubAnimCounter],a
.barrageLoop
	ld a,[wSubAnimCounter] ; physical VBlank count
	push af
	call .GetStretchedFrame
	ld a,[wSubAnimCounter]
	cp GUNK_SHOT_SHAKE_FRAMES
	jr nc,.shakeBase
	ld b,0
	ld c,GUNK_SHOT_SHAKE_FRAMES
	ld d,2
	ld e,4
	call GoldBattleHorizontalShakeSet
	jr .shakeDone
.shakeBase
	ld a,7
	ld [wBattleAnimWX],a
.shakeDone

	; Bubble Beam SFX at the start and midpoint of each 16-tick barrage cycle.
	; Do not retrigger sounds on duplicated logical ticks.
	ld a,[wBaseCoordY]
	cp 1
	jr z,.barrageSoundDone
	ld a,[wSubAnimCounter]
	cp 64
	jr nc,.barrageSoundDone
	and 7
	jr nz,.barrageSoundDone
	ld a,GSSFX_BUBBLE_BEAM
	call PlaySound
.barrageSoundDone

	ld de,wOAMBuffer
	call .DrawMudProjectiles
	call .DrawInkBursts
	call DelayFrame
	call ClearSprites
	pop af
	inc a
	ld [wSubAnimCounter],a
	cp GUNK_SHOT_SLOW_BARRAGE
	jp c,.barrageLoop

	; The last six VBlanks presented neutral WX=7. Now disarm the latch and
	; clear the shared $CD3D scratch so nothing leaks into overworld UI.
	call GoldBattleHorizontalShakeEnd
	xor a
	ld [wBattleAnimWX],a
	ret

.DrawMudProjectiles
	; Four projectiles are created per 16-frame loop, every four frames, for four
	; loops (16 total). PC's param $4 advances logical X +4 and Y -2 per frame.
	xor a ; projectile index 0..15
.projectileLoop
	push af
	add a
	add a ; spawn = index * 4
	ld b,a
	ld a,[wSubAnimCounter]
	sub b
	jr c,.projectileSkip
	cp 17
	jr nc,.projectileSkip
	inc a ; visible step 1..17
	ld b,a
	; logical X = 64 + 4*step
	add a
	add a
	add 64
	ld h,a
	; logical Y = 92 - 2*step. Fractional movement fills every VBlank.
	ld a,b
	add a
	ld l,a
	ld a,[wBaseCoordY]
	and a
	jr z,.projectileFractionDone
	cp 1
	jr nz,.projectileNotThreeQuarters
	inc h
	inc h
	inc h
	inc l
	inc l
	jr .projectileFractionDone
.projectileNotThreeQuarters
	cp 2
	jr nz,.projectileQuarter
	inc h
	inc h
	inc l
	jr .projectileFractionDone
.projectileQuarter
	inc h
.projectileFractionDone
	ld a,92
	sub l
	ld c,a
	ld b,h
	ld a,[H_WHOSETURN]
	and a
	jr z,.projectileCoordsReady
	ld a,180
	sub b
	ld b,a
	ld a,154 ; Mud Shot fixY $9a
	sub c
	ld c,a
.projectileCoordsReady
	ld h,GUNK_SHOT_POISON_TILE_BASE + 2 ; source tile 9
	call .DrawMirroredSquare
.projectileSkip
	pop af
	inc a
	cp 16
	jr c,.projectileLoop
	ret

.DrawInkBursts
	ld hl,GunkShotInkBurstFrames
.inkBurstLoop
	ld a,[hli]
	cp $ff
	ret z
	ld b,a
	ld a,[wSubAnimCounter]
	sub b
	jr c,.inkBurstLoop
	cp 17
	jr nc,.inkBurstLoop
	push hl
	ld [wBaseCoordX],a ; preserve age while B/C become particle coordinates
	xor a ; family 0
.inkParticleLoop
	push af
	ld c,a
	ld a,[wBaseCoordX]
	ld b,a
	call .GetSmoothBubbleOffset
	push bc
	call .GetImpactOrigin
	pop hl ; H=dx, L=dy
	ld a,[H_WHOSETURN]
	and a
	jr nz,.inkEnemyX
	ld a,b
	add h
	ld b,a
	jr .inkY
.inkEnemyX
	ld a,b
	sub h
	ld b,a
.inkY
	ld a,c
	add l
	ld c,a
	ld h,GUNK_SHOT_POISON_TILE_BASE
	call .DrawDot
	pop af
	inc a
	cp 4
	jr c,.inkParticleLoop
	pop hl
	jr .inkBurstLoop

.GetImpactOrigin
	; PC INK_SPLASH at (136,56), fixY=$ff: enemy Y becomes 40+56 = 96.
	ld a,[H_WHOSETURN]
	and a
	jr nz,.impactEnemy
	ld b,136
	ld c,56
	ret
.impactEnemy
	ld b,44
	ld c,96
	ret

.DrawDot
	; H=tile, B/C=center, DE=next OAM entry.
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
	ld a,GUNK_SHOT_OBJ_PAL
	ld [de],a
	inc de
	ret

.DrawMirroredSquare
	; PC OAMData_02: 16x16 from one quarter tile and H/V flips.
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
	ld a,GUNK_SHOT_OBJ_PAL
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
	ld a,GUNK_SHOT_OBJ_PAL | OAM_HFLIP
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
	ld a,GUNK_SHOT_OBJ_PAL | OAM_VFLIP
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
	ld a,GUNK_SHOT_OBJ_PAL | OAM_HFLIP | OAM_VFLIP
	ld [de],a
	inc de
	ret

.DrawNineUnique
	; PC OAMData_f3 is column-major in tile memory: top row uses 0/3/6,
	; middle 1/4/7, bottom 2/5/8. Keep that order exactly.
	ld a,b
	ld [wBaseCoordX],a
	ld a,c
	ld [wBaseCoordY],a
	ld hl,GunkShotNineLayout
	ld a,9
.nineLoop
	push af
	ld a,[hli]
	ld b,a ; dx
	ld a,[wBaseCoordX]
	add b
	ld b,a
	ld a,[hli]
	ld c,a ; dy
	ld a,[wBaseCoordY]
	add c
	ld c,a
	ld a,c
	ld [de],a
	inc de
	ld a,b
	ld [de],a
	inc de
	ld a,[hli]
	add GUNK_SHOT_POISON_TILE_BASE + 3
	ld [de],a
	inc de
	ld a,GUNK_SHOT_OBJ_PAL
	ld [de],a
	inc de
	pop af
	dec a
	jr nz,.nineLoop
	ret

GunkShotNineLayout:
	db -12,-12,0,  -4,-12,3,   4,-12,6
	db -12, -4,1,  -4, -4,4,   4, -4,7
	db -12,  4,2,  -4,  4,5,   4,  4,8

GunkShotInkBurstFrames:
	db 8,24,40,56,68,$ff

; Polished Crystal custom palettes used by Gunk Shot.
GunkShotPurplePalette:
	RGB 31,31,31
	RGB 22,5,24
	RGB 10,2,11
	RGB 0,0,0

GunkShotPsychoBoost2Palette:
	RGB 31,31,31
	RGB 31,18,25
	RGB 31,0,27
	RGB 15,6,31

; Exact PC poison.png source tiles 7-18.
GunkShotPoisonTiles:
	db $3c,$3c,$7e,$6e,$ff,$df,$ff,$df,$ff,$ff,$ff,$ff,$7e,$7e,$3c,$3c
	db $3c,$3c,$7e,$7e,$c3,$c3,$81,$81,$81,$81,$00,$00,$00,$00,$00,$00
	db $01,$01,$03,$03,$1b,$1b,$3f,$3f,$3f,$3f,$1f,$1f,$7f,$7f,$ff,$ff
	db $00,$00,$00,$00,$0c,$0c,$1a,$16,$37,$3f,$3f,$3f,$1f,$1f,$0f,$0f
	db $0f,$0f,$3f,$3e,$6f,$5e,$de,$ff,$ff,$ff,$7f,$7f,$3f,$3f,$0f,$0f
	db $0f,$0f,$13,$1f,$27,$3f,$3f,$3f,$1e,$1e,$0c,$0c,$00,$00,$00,$00
	db $18,$18,$34,$2c,$6e,$5e,$5e,$7e,$ff,$ff,$ff,$ff,$ff,$ff,$cf,$bf
	db $df,$3f,$bf,$7f,$7f,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
	db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7e,$7e,$7e,$7e,$3c,$3c,$18,$18
	db $00,$00,$00,$00,$30,$30,$58,$78,$bc,$fc,$fc,$fc,$f8,$f8,$f0,$f0
	db $f0,$f0,$fc,$fc,$fe,$fe,$ff,$ff,$ff,$ff,$fe,$fe,$fc,$fc,$f0,$f0
	db $f0,$f0,$f8,$f8,$fc,$fc,$fc,$fc,$78,$78,$30,$30,$00,$00,$00,$00
