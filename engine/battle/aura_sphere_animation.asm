; AUR-5.62.36: Polished Crystal Aura Sphere renderer for AURA_SPHERE.
;
; The move keeps PC's AgilityMinor streaks, four swirl charges, vortex,
; shrinking glow, 6px/3px projectile step, impact glow, +/-2px 8-frame
; horizontal shake, Bubble palette, and original SFX timeline.
;
; Charge graphics share the stock $31-$7f battle-animation VRAM range, so the
; final SwirlShort can overlap a fully animated Vortex without mid-charge tile
; reloads. PC's gray/yellow OBJ pulse stays active through the entire animation.

AURA_SPHERE_RAY_TILE_BASE       EQU $31
AURA_SPHERE_RAY_TILE_COUNT      EQU 2
AURA_SPHERE_GLOW_TILE_BASE      EQU $33
AURA_SPHERE_GLOW_TILE_COUNT     EQU 10
AURA_SPHERE_VORTEX_TILE_BASE    EQU $40
AURA_SPHERE_VORTEX_TILE_COUNT   EQU 32
AURA_SPHERE_TILE_BASE           EQU $60
AURA_SPHERE_BIG_GLOW_BASE       EQU $70
AURA_SPHERE_OBJ_PAL             EQU ATK_PAL_BLUE
AURA_SPHERE_BRIGHT_PAL          EQU ATK_PAL_RED
AURA_SPHERE_RAY_PAL             EQU ATK_PAL_YELLOW
AURA_SPHERE_RAY_BRIGHT_PAL      EQU ATK_PAL_BROWN
AURA_SPHERE_AGILITY_LEAD_FRAMES EQU 5
AURA_SPHERE_VORTEX_START        EQU 41
AURA_SPHERE_CHARGE_FRAMES       EQU 106
AURA_SPHERE_SHRINK_FRAMES       EQU 11
AURA_SPHERE_PROJECTILE_FRAMES   EQU 12
AURA_SPHERE_PROJECTILE_WAIT     EQU 13
AURA_SPHERE_IMPACT_FRAMES       EQU 9
AURA_SPHERE_SHAKE_FRAMES        EQU 8
AURA_SPHERE_POST_WAIT_FRAMES    EQU 33
AURA_SPHERE_SHRINK_START        EQU AURA_SPHERE_CHARGE_FRAMES
AURA_SPHERE_PROJECTILE_START    EQU AURA_SPHERE_SHRINK_START + AURA_SPHERE_SHRINK_FRAMES
AURA_SPHERE_IMPACT_START        EQU AURA_SPHERE_PROJECTILE_START + AURA_SPHERE_PROJECTILE_WAIT
AURA_SPHERE_POST_WAIT_START     EQU AURA_SPHERE_IMPACT_START + AURA_SPHERE_IMPACT_FRAMES

PlayPolishedCrystalAuraSphereAnimation::
	call .InstallPalette
	call .PlayCharge
	call .PlayShrink
	call .PlayProjectileAndImpact

	; Restore stock OBJ palettes and private tile palette mappings.
	callba _LoadAnimationTilesetPalettes
	ld a,$e4
	ld [rOBP0],a
	ld [rOBP1],a
	ret

.InstallPalette
	ld a,2
	ld [rSVBK],a
	ld hl,AuraSphereBubblePalette
	ld de,W2_SprPaletteData + AURA_SPHERE_OBJ_PAL * 8
	ld bc,8
	call CopyData
	ld hl,AuraSphereBubbleBrightPalette
	ld de,W2_SprPaletteData + AURA_SPHERE_BRIGHT_PAL * 8
	ld bc,8
	call CopyData

	; Charge art uses the stock battle-animation VRAM range $33-$7f.
	; Keep every non-ray Aura Sphere tile on PC's Bubble custom palette.
	ld hl,W2_SpritePaletteMap + AURA_SPHERE_GLOW_TILE_BASE
	ld b,$80 - AURA_SPHERE_GLOW_TILE_BASE
	ld a,AURA_SPHERE_OBJ_PAL
.paletteMapLoop
	ld [hli],a
	dec b
	jr nz,.paletteMapLoop

	; BattleAnimSub_AgilityMinor uses PC's Yellow palette.
	ld hl,AuraSphereYellowPalette
	ld de,W2_SprPaletteData + AURA_SPHERE_RAY_PAL * 8
	ld bc,8
	call CopyData
	ld hl,AuraSphereYellowBrightPalette
	ld de,W2_SprPaletteData + AURA_SPHERE_RAY_BRIGHT_PAL * 8
	ld bc,8
	call CopyData
	ld hl,W2_SpritePaletteMap + AURA_SPHERE_RAY_TILE_BASE
	ld b,AURA_SPHERE_RAY_TILE_COUNT
	ld a,AURA_SPHERE_RAY_PAL
.rayPaletteMapLoop
	ld [hli],a
	dec b
	jr nz,.rayPaletteMapLoop

	ld a,1
	ld [W2_ForceOBPUpdate],a
	xor a
	ld [rSVBK],a
	ret

.LoadChargeTiles
	; PC loads Vortex + Glow + Wind BG + Swirl before the charge begins. RPP's
	; stock animation VRAM is $31-$7f, so all four fit simultaneously without a
	; mid-charge CopyVideoData stall: rays $31-$32, Glow $33-$3c, Vortex
	; $40-$5f, and Swirl $60-$77.
	ld hl,vSprites + AURA_SPHERE_RAY_TILE_BASE * 16
	ld de,AuraSphereAgilityRayTiles
	ld b,BANK(AuraSphereAgilityRayTiles)
	ld c,AURA_SPHERE_RAY_TILE_COUNT
	call CopyVideoData
	ld hl,vSprites + AURA_SPHERE_GLOW_TILE_BASE * 16
	ld de,AuraSphereGlowTiles
	ld b,BANK(AuraSphereGlowTiles)
	ld c,AURA_SPHERE_GLOW_TILE_COUNT
	call CopyVideoData
	ld hl,vSprites + AURA_SPHERE_VORTEX_TILE_BASE * 16
	ld de,AuraSphereVortexTiles
	ld b,BANK(AuraSphereVortexTiles)
	ld c,AURA_SPHERE_VORTEX_TILE_COUNT
	call CopyVideoData
	ld hl,vSprites + AURA_SPHERE_TILE_BASE * 16
	ld de,AuraSphereSwirlTiles
	ld b,BANK(AuraSphereSwirlTiles)
	ld c,24
	call CopyVideoData
	ret

.LoadProjectileAndImpact
	ld hl,vSprites + AURA_SPHERE_TILE_BASE * 16
	ld de,AuraSphereProjectileTiles
	ld b,BANK(AuraSphereProjectileTiles)
	ld c,16
	call CopyVideoData
	ld hl,vSprites + AURA_SPHERE_BIG_GLOW_BASE * 16
	ld de,AuraSphereBigGlowTiles
	ld b,BANK(AuraSphereBigGlowTiles)
	ld c,15
	call CopyVideoData
	ret

.PlayCharge
	call .LoadChargeTiles
	xor a
	ld [wSubAnimCounter],a
.chargeLoop
	; PC anim_wait 4 resumes on the fifth following playframe: the first two
	; Agility streaks start at frame 0, then the remaining three, Outrage SFX,
	; and first SwirlShort all begin together at frame 5.
	ld a,[wSubAnimCounter]
	cp AURA_SPHERE_AGILITY_LEAD_FRAMES
	jr nz,.chargeSoundDone
	ld a,GSSFX_OUTRAGE
	call PlaySound
.chargeSoundDone
	ld a,[wSubAnimCounter]
	call .UpdateAuraPalette
	ld de,wOAMBuffer
	call .DrawAgilityRays
	call .DrawActiveSwirls
	call .DrawVortex
	call DelayFrame
	call ClearSprites
	ld hl,wSubAnimCounter
	inc [hl]
	ld a,[hl]
	cp AURA_SPHERE_CHARGE_FRAMES
	jr c,.chargeLoop
	ret

.UpdateAuraPalette
	; PC ANIM_BG_CYCLE_OBPALS_GRAY_AND_YELLOW starts on the same playframe as
	; AgilityMinor. With parameter $2 its exact repeating phase is:
	; normal at frame 0, bright at 1-3, normal at 4-6, bright at 7-9, ...
	; A = absolute Aura Sphere script playframe. Only remap on phase boundaries.
.mod6
	cp 6
	jr c,.paletteRemainder
	sub 6
	jr .mod6
.paletteRemainder
	cp 1
	jr z,.setBrightPalette
	cp 4
	ret nz
	ld d,AURA_SPHERE_OBJ_PAL
	ld e,AURA_SPHERE_RAY_PAL
	jr .setPaletteMap
.setBrightPalette
	ld d,AURA_SPHERE_BRIGHT_PAL
	ld e,AURA_SPHERE_RAY_BRIGHT_PAL
.setPaletteMap
	ld a,2
	ld [rSVBK],a
	ld hl,W2_SpritePaletteMap + AURA_SPHERE_GLOW_TILE_BASE
	ld b,$80 - AURA_SPHERE_GLOW_TILE_BASE
	ld a,d
.palettePulseLoop
	ld [hli],a
	dec b
	jr nz,.palettePulseLoop
	ld hl,W2_SpritePaletteMap + AURA_SPHERE_RAY_TILE_BASE
	ld b,AURA_SPHERE_RAY_TILE_COUNT
	ld a,e
.rayPalettePulseLoop
	ld [hli],a
	dec b
	jr nz,.rayPalettePulseLoop
	ld a,1
	ld [W2_ForceOBPUpdate],a
	xor a
	ld [rSVBK],a
	ret

.DrawAgilityRays
	; BattleAnimSub_AgilityMinor object list:
	; (8,24,$10), (8,48,$02), anim_wait 4, then on playframe 5:
	; (8,56,$0c), (8,80,$04), (8,104,$0e).
	ld a,0
	ld b,24
	ld c,$10
	call .DrawOneAgilityRay
	ld a,0
	ld b,48
	ld c,$02
	call .DrawOneAgilityRay
	ld a,5
	ld b,56
	ld c,$0c
	call .DrawOneAgilityRay
	ld a,5
	ld b,80
	ld c,$04
	call .DrawOneAgilityRay
	ld a,5
	ld b,104
	ld c,$0e
	jp .DrawOneAgilityRay

.DrawOneAgilityRay
	; A = spawn frame, B = logical Y, C = +X pixels/frame, DE = next OAM.
	ld h,a
	ld a,[wSubAnimCounter]
	sub h
	ret c
	; PC Frameset_Agility ends on the same OAM frame; it does not delete the
	; object. BattleAnimFunction_Agility keeps advancing X until anim_clearobjs.
	inc a ; BattleAnimFunction_Agility updates X before drawing.
	ld h,a
	ld a,8
.rayAdvanceLoop
	add c ; 8-bit wrap is intentional and matches BATTLEANIMSTRUCT_XCOORD.
	dec h
	jr nz,.rayAdvanceLoop
	ld h,a
	ld a,[H_WHOSETURN]
	and a
	jr nz,.enemyRay
	ld a,h
	ld [wBaseCoordX],a
	ld a,b
	ld [wBaseCoordY],a
	ld a, (1 << OAM_PRIORITY)
	ld [wDropletTile],a
	jr .drawRay
.enemyRay
	ld a,180
	sub h
	ld [wBaseCoordX],a
	ld a,136 ; ANIM_OBJ_AGILITY fixY $88.
	sub b
	ld [wBaseCoordY],a
	ld a, (1 << OAM_PRIORITY) | OAM_HFLIP
	ld [wDropletTile],a
.drawRay
	ld hl,AuraSphereAgilityRayOAM
	ld b,4
	jp .DrawOAMLayout

.DrawActiveSwirls
	; PC anim_wait 8 resumes 9 playframes later, so SwirlShort objects spawn
	; at charge-relative frames 0,9,18,27 after AgilityMinor's five-frame lead.
	; The frameset itself remains visible for 16 playframes.
	ld a,0
	call .DrawOneSwirlIfActive
	ld a,9
	call .DrawOneSwirlIfActive
	ld a,18
	call .DrawOneSwirlIfActive
	ld a,27
	jp .DrawOneSwirlIfActive

.DrawOneSwirlIfActive
	ld b,a ; spawn frame relative to the first swirl
	ld a,[wSubAnimCounter]
	sub AURA_SPHERE_AGILITY_LEAD_FRAMES
	sub b
	ret c
	cp 16
	ret nc
	ld c,a ; age 0..15
	push bc
	call .SetChargeCenter
	pop bc
	; Object base OAM_XFLIP applies only to enemy-user rendering.
	xor a
	ld [wDropletTile],a
	ld a,[H_WHOSETURN]
	and a
	jr z,.swirlObjectFlagsReady
	ld a,OAM_HFLIP
	ld [wDropletTile],a
.swirlObjectFlagsReady
	ld a,c
	srl a ; duration 1 => each OAM frame lasts two playframes
	ld c,a ; frame 0..7
	cp 4
	jr c,.swirlFrameFlagsReady
	ld a,[wDropletTile]
	xor OAM_HFLIP | OAM_VFLIP
	ld [wDropletTile],a
.swirlFrameFlagsReady
	ld a,c
	and 3
	cp 0
	jr z,.swirl0
	cp 1
	jr z,.swirl1
	cp 2
	jr z,.swirl2
	ld hl,AuraSphereSwirlOAM3
	jr .drawSwirl
.swirl0
	ld hl,AuraSphereSwirlOAM0
	jr .drawSwirl
.swirl1
	ld hl,AuraSphereSwirlOAM1
	jr .drawSwirl
.swirl2
	ld hl,AuraSphereSwirlOAM2
.drawSwirl
	ld b,9
	jp .DrawOAMLayout

.DrawVortex
	ld a,[wSubAnimCounter]
	cp AURA_SPHERE_VORTEX_START
	ret c
	sub AURA_SPHERE_VORTEX_START
	push af
	call .SetChargeCenter
	xor a
	ld [wDropletTile],a
	ld a,[H_WHOSETURN]
	and a
	jr z,.vortexFlagsReady
	ld a,OAM_HFLIP
	ld [wDropletTile],a
.vortexFlagsReady
	pop af
	; PC Frameset_Vortex starts D8/D9/DA/DB immediately, two playframes each.
	srl a
	and 3
	cp 0
	jr z,.vortex0
	cp 1
	jr z,.vortex1
	cp 2
	jr z,.vortex2
	ld hl,AuraSphereVortexOAM3
	jr .drawVortex
.vortex0
	ld hl,AuraSphereVortexOAM0
	jr .drawVortex
.vortex1
	ld hl,AuraSphereVortexOAM1
	jr .drawVortex
.vortex2
	ld hl,AuraSphereVortexOAM2
.drawVortex
	ld b,16
	jp .DrawOAMLayout

.SetChargeCenter
	; RELATIVE_X + fixY $94 for SwirlShort/Vortex/ShrinkingGlow.
	ld a,[H_WHOSETURN]
	and a
	jr nz,.enemyChargeCenter
	ld a,44
	ld [wBaseCoordX],a
	ld a,96
	ld [wBaseCoordY],a
	ret
.enemyChargeCenter
	ld a,136 ; 180 - 44
	ld [wBaseCoordX],a
	ld a,52  ; $94 - 96
	ld [wBaseCoordY],a
	ret

.PlayShrink
	; PC clears the charge objects, but its gray/yellow BG effect keeps running.
	; Do not reset Bubble here: Shrinking Glow stays on the same global pulse.
	ld a,GSSFX_SLUDGE_BOMB
	call PlaySound
	xor a
	ld [wSubAnimCounter],a
.shrinkLoop
	ld a,[wSubAnimCounter]
	add AURA_SPHERE_SHRINK_START
	call .UpdateAuraPalette
	ld de,wOAMBuffer
	call .SetChargeCenter
	xor a
	ld [wDropletTile],a ; Shrinking Glow has no object-level flip.
	ld a,[wSubAnimCounter]
	cp 3
	jr c,.shrink54
	cp 6
	jr c,.shrink53
	cp 9
	jr c,.shrink55
	jr .shrinkDrawDone ; frames 9-10 are blank after the frameset deletes
.shrink54
	ld hl,AuraSphereShrink54OAM
	ld b,4
	call .DrawOAMLayout
	jr .shrinkDrawDone
.shrink53
	ld hl,AuraSphereShrink53OAM
	ld b,9
	call .DrawOAMLayout
	jr .shrinkDrawDone
.shrink55
	ld hl,AuraSphereShrink55OAM
	ld b,4
	call .DrawOAMLayout
.shrinkDrawDone
	call DelayFrame
	call ClearSprites
	ld hl,wSubAnimCounter
	inc [hl]
	ld a,[hl]
	cp AURA_SPHERE_SHRINK_FRAMES
	jr c,.shrinkLoop
	ret

.PlayProjectileAndImpact
	call .LoadProjectileAndImpact
	ld a,GSSFX_MEGA_PUNCH
	call PlaySound
	xor a
	ld [wSubAnimCounter],a
.projectileLoop
	ld a,[wSubAnimCounter]
	add AURA_SPHERE_PROJECTILE_START
	call .UpdateAuraPalette
	ld de,wOAMBuffer
	call .SetProjectileCenter
	; ANIM_OBJ_AURA_SPHERE applies X+Y object flip only for enemy users.
	xor a
	ld [wDropletTile],a
	ld a,[H_WHOSETURN]
	and a
	jr z,.projectileFlagsReady
	ld a,OAM_HFLIP | OAM_VFLIP
	ld [wDropletTile],a
.projectileFlagsReady
	ld hl,AuraSphereProjectileOAM
	ld b,16
	call .DrawOAMLayout
	call DelayFrame
	call ClearSprites
	ld hl,wSubAnimCounter
	inc [hl]
	ld a,[hl]
	cp AURA_SPHERE_PROJECTILE_FRAMES
	jr c,.projectileLoop

	; anim_wait 12 resumes on the 13th following playframe. The projectile has
	; already deinitialized, leaving one blank transition frame before impact.
	ld a,AURA_SPHERE_PROJECTILE_START + AURA_SPHERE_PROJECTILE_FRAMES
	call .UpdateAuraPalette
	call DelayFrame
	call ClearSprites

	; PC: ANIM_BG_SHAKE_SCREEN_X, $08, $2, $0 => +/-2 px for 8 frames.
	call .HorizontalShakeBegin
	ld a,GSSFX_AEROBLAST
	call PlaySound
	xor a
	ld [wSubAnimCounter],a
.impactLoop
	ld a,[wSubAnimCounter]
	add AURA_SPHERE_IMPACT_START
	call .UpdateAuraPalette
	ld b,0
	ld c,AURA_SPHERE_SHAKE_FRAMES
	ld d,1
	ld e,2
	call .HorizontalShakeSet
	ld de,wOAMBuffer
	call .SetImpactCenter
	xor a
	ld [wDropletTile],a
	ld a,[wSubAnimCounter]
	and 3
	cp 2
	jr c,.impactDD
	ld hl,AuraSphereImpactDCOAM
	ld b,16
	jr .drawImpact
.impactDD
	ld hl,AuraSphereImpactDDOAM
	ld b,29
.drawImpact
	call .DrawOAMLayout
	call DelayFrame
	call ClearSprites
	ld hl,wSubAnimCounter
	inc [hl]
	ld a,[hl]
	cp AURA_SPHERE_IMPACT_FRAMES
	jr c,.impactLoop

	; anim_wait 32 occupies 33 playframes before anim_ret. Keep the palette
	; cycle running through the blank tail and neutral WX latched until cleanup.
	ld a,7
	ld [wBattleAnimWX],a
	xor a
	ld [wSubAnimCounter],a
.postWaitLoop
	ld a,[wSubAnimCounter]
	add AURA_SPHERE_POST_WAIT_START
	call .UpdateAuraPalette
	call DelayFrame
	call ClearSprites
	ld hl,wSubAnimCounter
	inc [hl]
	ld a,[hl]
	cp AURA_SPHERE_POST_WAIT_FRAMES
	jr c,.postWaitLoop
	call .HorizontalShakeEnd
	ret

; AUR-5.62.36: keep the WX-latch shake helpers local to bank $3E; the shared
; Gold helpers are in bank $3D and cannot be reached with a plain call.
.HorizontalShakeBegin
	ld a,7
	ld [wBattleAnimWX],a
	ld a,1
	ld [wBattleAnimWXEnabled],a
	ret

; B = first active frame, C = first inactive frame, D = phase mask, E = pixels.
.HorizontalShakeSet
	ld a,[wSubAnimCounter]
	cp b
	jr c,.horizontalShakeBase
	cp c
	jr nc,.horizontalShakeBase
	sub b
	and d
	jr nz,.horizontalShakeRight
	ld a,7
	sub e
	ld [wBattleAnimWX],a
	ret
.horizontalShakeRight
	ld a,7
	add e
	ld [wBattleAnimWX],a
	ret
.horizontalShakeBase
	ld a,7
	ld [wBattleAnimWX],a
	ret

.HorizontalShakeEnd
	ld a,7
	ld [wBattleAnimWX],a
	xor a
	ld [wBattleAnimWXEnabled],a
	ret

.SetProjectileCenter
	; MoveFromUserToTargetAndDisappear updates before OAM: logical X += 6,
	; logical Y -= 3. First visible frame is (70,85), twelfth is (136,52).
	ld a,[wSubAnimCounter]
	ld b,a
	add a
	add b ; 3 * t
	ld c,a
	add a ; 6 * t
	add 70
	ld b,a ; logical X
	ld a,85
	sub c
	ld c,a ; logical Y
	ld a,[H_WHOSETURN]
	and a
	jr nz,.enemyProjectileCenter
	ld a,b
	ld [wBaseCoordX],a
	ld a,c
	ld [wBaseCoordY],a
	ret
.enemyProjectileCenter
	ld a,180
	sub b
	ld [wBaseCoordX],a
	ld a,144 ; fixY $90
	sub c
	ld [wBaseCoordY],a
	ret

.SetImpactCenter
	; PC BIG_GLOW_CLEAR at logical (136,48), RELATIVE_X + fixY $90.
	ld a,[H_WHOSETURN]
	and a
	jr nz,.enemyImpactCenter
	ld a,136
	ld [wBaseCoordX],a
	ld a,48
	ld [wBaseCoordY],a
	ret
.enemyImpactCenter
	ld a,44
	ld [wBaseCoordX],a
	ld a,96
	ld [wBaseCoordY],a
	ret

.DrawOAMLayout
	; HL = exact PC emitted y/x/tile/attr tuples, B = sprite count, DE = next OAM.
	; Whole-object/frame flips match BattleAnimOAMUpdate: offset -> -(offset+8),
	; and sprite flip attrs XOR the whole-object flags.
.spriteLoop
	; Match PC BattleAnimOAMUpdate's 40-sprite hard stop so persistent
	; Agility streaks can never write past wOAMBuffer into wTileMap.
	ld a,e
	cp 40 * 4
	ret nc
	ld a,[hli]
	ld c,a
	ld a,[wDropletTile]
	and OAM_VFLIP
	ld a,c
	jr z,.gotYOffset
	add 8
	cpl
	inc a
.gotYOffset
	ld c,a
	ld a,[wBaseCoordY]
	add c
	ld [de],a
	inc de

	ld a,[hli]
	ld c,a
	ld a,[wDropletTile]
	and OAM_HFLIP
	ld a,c
	jr z,.gotXOffset
	add 8
	cpl
	inc a
.gotXOffset
	ld c,a
	ld a,[wBaseCoordX]
	add c
	ld [de],a
	inc de

	ld a,[hli]
	ld [de],a
	inc de
	ld a,[hli]
	ld c,a
	ld a,[wDropletTile]
	xor c
	ld [de],a
	inc de
	dec b
	jr nz,.spriteLoop
	ret

; Polished Crystal's PAL_BTLCUSTOM_BUBBLE.
AuraSphereBubblePalette:
	RGB 31,31,31
	RGB 19,28,28
	RGB 0,23,28
	RGB 3,10,30

AuraSphereBubbleBrightPalette:
	RGB 31,31,31
	RGB 31,31,31
	RGB 19,28,28
	RGB 0,23,28

AuraSphereYellowPalette:
	RGB 31,31,31
	RGB 31,31,7
	RGB 31,16,1
	RGB 0,0,0

AuraSphereYellowBrightPalette:
	RGB 31,31,31
	RGB 31,31,31
	RGB 31,31,7
	RGB 31,16,1

AuraSphereAgilityRayOAM:
	db  -4,-16,$31,0
	db  -4, -8,$32,0
	db  -4,  0,$32,OAM_HFLIP
	db  -4,  8,$31,OAM_HFLIP

AuraSphereSwirlOAM0:
	db  -12, -12,$60,0
	db  -12,  -4,$61,0
	db  -12,   4,$62,0
	db   -4, -12,$63,0
	db   -4,  -4,$64,0
	db   -4,   4,$65,0
	db    4, -12,$62,OAM_HFLIP | OAM_VFLIP
	db    4,  -4,$61,OAM_HFLIP | OAM_VFLIP
	db    4,   4,$60,OAM_HFLIP | OAM_VFLIP

AuraSphereSwirlOAM1:
	db  -12, -12,$6c,0
	db  -12,  -4,$6d,0
	db  -12,   4,$6e,0
	db   -4, -12,$6f,0
	db   -4,  -4,$70,0
	db   -4,   4,$71,0
	db    4, -12,$6e,OAM_HFLIP | OAM_VFLIP
	db    4,  -4,$6d,OAM_HFLIP | OAM_VFLIP
	db    4,   4,$6c,OAM_HFLIP | OAM_VFLIP

AuraSphereSwirlOAM2:
	db  -12, -12,$66,0
	db  -12,  -4,$67,0
	db  -12,   4,$68,0
	db   -4, -12,$69,0
	db   -4,  -4,$6a,0
	db   -4,   4,$6b,0
	db    4, -12,$68,OAM_HFLIP | OAM_VFLIP
	db    4,  -4,$67,OAM_HFLIP | OAM_VFLIP
	db    4,   4,$66,OAM_HFLIP | OAM_VFLIP

AuraSphereSwirlOAM3:
	db  -12, -12,$72,0
	db  -12,  -4,$73,0
	db  -12,   4,$74,0
	db   -4, -12,$75,0
	db   -4,  -4,$76,0
	db   -4,   4,$77,0
	db    4, -12,$74,OAM_HFLIP | OAM_VFLIP
	db    4,  -4,$73,OAM_HFLIP | OAM_VFLIP
	db    4,   4,$72,OAM_HFLIP | OAM_VFLIP

AuraSphereVortexOAM0:
	db  -16, -16,$40,0
	db  -16,  -8,$41,0
	db  -16,   0,$42,0
	db  -16,   8,$43,0
	db   -8, -16,$44,0
	db   -8,  -8,$45,0
	db   -8,   0,$46,0
	db   -8,   8,$47,0
	db    0, -16,$47,OAM_HFLIP | OAM_VFLIP
	db    0,  -8,$46,OAM_HFLIP | OAM_VFLIP
	db    0,   0,$45,OAM_HFLIP | OAM_VFLIP
	db    0,   8,$44,OAM_HFLIP | OAM_VFLIP
	db    8, -16,$43,OAM_HFLIP | OAM_VFLIP
	db    8,  -8,$42,OAM_HFLIP | OAM_VFLIP
	db    8,   0,$41,OAM_HFLIP | OAM_VFLIP
	db    8,   8,$40,OAM_HFLIP | OAM_VFLIP

AuraSphereVortexOAM1:
	db  -16, -16,$48,0
	db  -16,  -8,$49,0
	db  -16,   0,$4a,0
	db  -16,   8,$4b,0
	db   -8, -16,$4c,0
	db   -8,  -8,$4d,0
	db   -8,   0,$4e,0
	db   -8,   8,$4f,0
	db    0, -16,$4f,OAM_HFLIP | OAM_VFLIP
	db    0,  -8,$4e,OAM_HFLIP | OAM_VFLIP
	db    0,   0,$4d,OAM_HFLIP | OAM_VFLIP
	db    0,   8,$4c,OAM_HFLIP | OAM_VFLIP
	db    8, -16,$4b,OAM_HFLIP | OAM_VFLIP
	db    8,  -8,$4a,OAM_HFLIP | OAM_VFLIP
	db    8,   0,$49,OAM_HFLIP | OAM_VFLIP
	db    8,   8,$48,OAM_HFLIP | OAM_VFLIP

AuraSphereVortexOAM2:
	db  -16, -16,$50,0
	db  -16,  -8,$51,0
	db  -16,   0,$52,0
	db  -16,   8,$53,0
	db   -8, -16,$54,0
	db   -8,  -8,$55,0
	db   -8,   0,$56,0
	db   -8,   8,$57,0
	db    0, -16,$57,OAM_HFLIP | OAM_VFLIP
	db    0,  -8,$56,OAM_HFLIP | OAM_VFLIP
	db    0,   0,$55,OAM_HFLIP | OAM_VFLIP
	db    0,   8,$54,OAM_HFLIP | OAM_VFLIP
	db    8, -16,$53,OAM_HFLIP | OAM_VFLIP
	db    8,  -8,$52,OAM_HFLIP | OAM_VFLIP
	db    8,   0,$51,OAM_HFLIP | OAM_VFLIP
	db    8,   8,$50,OAM_HFLIP | OAM_VFLIP

AuraSphereVortexOAM3:
	db  -16, -16,$58,0
	db  -16,  -8,$59,0
	db  -16,   0,$5a,0
	db  -16,   8,$5b,0
	db   -8, -16,$5c,0
	db   -8,  -8,$5d,0
	db   -8,   0,$5e,0
	db   -8,   8,$5f,0
	db    0, -16,$5f,OAM_HFLIP | OAM_VFLIP
	db    0,  -8,$5e,OAM_HFLIP | OAM_VFLIP
	db    0,   0,$5d,OAM_HFLIP | OAM_VFLIP
	db    0,   8,$5c,OAM_HFLIP | OAM_VFLIP
	db    8, -16,$5b,OAM_HFLIP | OAM_VFLIP
	db    8,  -8,$5a,OAM_HFLIP | OAM_VFLIP
	db    8,   0,$59,OAM_HFLIP | OAM_VFLIP
	db    8,   8,$58,OAM_HFLIP | OAM_VFLIP

AuraSphereShrink54OAM:
	db   -8,  -8,$37,0
	db   -8,   0,$37,OAM_HFLIP
	db    0,  -8,$37,OAM_VFLIP
	db    0,   0,$37,OAM_HFLIP | OAM_VFLIP

AuraSphereShrink53OAM:
	; PC OAMData_01 row-major y/x layout.
	db  -12, -12,$33,0
	db  -12,  -4,$34,0
	db  -12,   4,$33,OAM_HFLIP
	db   -4, -12,$35,0
	db   -4,  -4,$36,0
	db   -4,   4,$35,OAM_HFLIP | OAM_VFLIP
	db    4, -12,$33,OAM_VFLIP
	db    4,  -4,$34,OAM_HFLIP | OAM_VFLIP
	db    4,   4,$33,OAM_HFLIP | OAM_VFLIP

AuraSphereShrink55OAM:
	db   -8,  -8,$38,0
	db   -8,   0,$38,OAM_HFLIP
	db    0,  -8,$38,OAM_VFLIP
	db    0,   0,$38,OAM_HFLIP | OAM_VFLIP

AuraSphereProjectileOAM:
	db  -16, -16,$60,0
	db  -16,  -8,$61,0
	db  -16,   0,$62,0
	db  -16,   8,$63,0
	db   -8, -16,$64,0
	db   -8,  -8,$65,0
	db   -8,   0,$66,0
	db   -8,   8,$67,0
	db    0, -16,$68,0
	db    0,  -8,$69,0
	db    0,   0,$6a,0
	db    0,   8,$6b,0
	db    8, -16,$6c,0
	db    8,  -8,$6d,0
	db    8,   0,$6e,0
	db    8,   8,$6f,0

AuraSphereImpactDDOAM:
	db  -25, -16,$71,0
	db  -25,  -8,$72,0
	db  -17, -24,$73,0
	db  -17, -16,$74,0
	db  -17,  -8,$75,0
	db   -9, -24,$76,0
	db   -9, -16,$77,0
	db  -25,   8,$71,OAM_HFLIP
	db  -25,   0,$72,OAM_HFLIP
	db  -17,  16,$73,OAM_HFLIP
	db  -17,   8,$74,OAM_HFLIP
	db  -17,   0,$75,OAM_HFLIP
	db   -9,  16,$76,OAM_HFLIP
	db   -9,   8,$77,OAM_HFLIP
	db   15, -16,$71,OAM_VFLIP
	db   15,  -8,$72,OAM_VFLIP
	db    7, -24,$73,OAM_VFLIP
	db    7, -16,$74,OAM_VFLIP
	db    7,  -8,$75,OAM_VFLIP
	db   -1, -24,$76,OAM_VFLIP
	db   -1, -16,$77,OAM_VFLIP
	db   15,   8,$71,OAM_HFLIP | OAM_VFLIP
	db   15,   0,$72,OAM_HFLIP | OAM_VFLIP
	db    7,  16,$73,OAM_HFLIP | OAM_VFLIP
	db    7,   8,$74,OAM_HFLIP | OAM_VFLIP
	db    7,   0,$75,OAM_HFLIP | OAM_VFLIP
	db   -1,  16,$76,OAM_HFLIP | OAM_VFLIP
	db   -1,   8,$77,OAM_HFLIP | OAM_VFLIP
	db   -1,   0,$78,OAM_HFLIP | OAM_VFLIP

AuraSphereImpactDCOAM:
	db  -16, -16,$79,0
	db  -16,  -8,$7a,0
	db   -8, -16,$7b,0
	db   -8,  -8,$7c,0
	db  -16,   0,$7a,OAM_HFLIP
	db  -16,   8,$79,OAM_HFLIP
	db   -8,   0,$7c,OAM_HFLIP
	db   -8,   8,$7b,OAM_HFLIP
	db    0, -16,$7b,OAM_VFLIP
	db    0,  -8,$7c,OAM_VFLIP
	db    8, -16,$79,OAM_VFLIP
	db    8,  -8,$7a,OAM_VFLIP
	db    0,   0,$7c,OAM_HFLIP | OAM_VFLIP
	db    0,   8,$7b,OAM_HFLIP | OAM_VFLIP
	db    8,   0,$7a,OAM_HFLIP | OAM_VFLIP
	db    8,   8,$79,OAM_HFLIP | OAM_VFLIP

AuraSphereSwirlTiles:
	db $00,$00,$00,$00,$00,$00,$03,$03,$0f,$0f,$1c,$1c,$30,$33,$00,$0f
	db $07,$07,$00,$f8,$00,$07,$f0,$f1,$fc,$fc,$3e,$3e,$0f,$ff,$f3,$ff
	db $c0,$c0,$f0,$f0,$38,$38,$18,$98,$0c,$cc,$0c,$4c,$0c,$6c,$8c,$ec
	db $03,$1f,$03,$33,$07,$67,$0f,$4f,$1e,$df,$1c,$9f,$31,$37,$31,$37
	db $c3,$ff,$81,$c3,$81,$81,$00,$81,$00,$81,$81,$81,$81,$c3,$c3,$ff
	db $8c,$ec,$8c,$ec,$38,$f9,$78,$fb,$f0,$f2,$e0,$e6,$c0,$cc,$c0,$f8
	db $00,$00,$00,$00,$0f,$0f,$3f,$3f,$70,$70,$60,$63,$c0,$cf,$c1,$d9
	db $00,$30,$00,$1c,$c0,$c6,$f0,$f3,$38,$39,$3c,$fd,$1f,$ff,$cf,$ff
	db $00,$00,$00,$00,$40,$40,$60,$60,$30,$b0,$30,$b0,$18,$d8,$18,$d8
	db $83,$b3,$87,$a7,$8e,$af,$0e,$4f,$1d,$5f,$1d,$5f,$19,$5b,$19,$5b
	db $e7,$ff,$81,$c3,$00,$81,$00,$81,$00,$81,$00,$81,$81,$c3,$e7,$ff
	db $98,$da,$98,$da,$b8,$fa,$b8,$fa,$70,$f2,$71,$f5,$e1,$e5,$c1,$cd
	db $00,$00,$00,$00,$00,$0f,$00,$01,$00,$00,$07,$07,$1f,$1f,$39,$39
	db $00,$00,$1e,$1e,$07,$c7,$01,$f1,$00,$3c,$b0,$be,$f9,$ff,$fc,$ff
	db $00,$00,$00,$00,$80,$80,$c0,$c0,$e0,$e8,$60,$68,$60,$6c,$e1,$ed
	db $73,$73,$60,$67,$e0,$ef,$c1,$dd,$c3,$db,$87,$b7,$87,$b7,$87,$b7
	db $8e,$ff,$02,$c3,$80,$81,$81,$81,$81,$81,$01,$81,$40,$c3,$71,$ff
	db $e1,$ed,$e1,$ed,$c1,$cd,$83,$9b,$c3,$fb,$07,$f7,$06,$e6,$ce,$ce
	db $01,$01,$00,$00,$00,$03,$00,$0f,$00,$00,$0f,$0f,$1f,$1f,$39,$39
	db $fc,$fc,$1f,$1f,$07,$e7,$01,$f9,$00,$1c,$e0,$ee,$f1,$f7,$f9,$ff
	db $00,$00,$00,$00,$80,$80,$c0,$c0,$c0,$c4,$60,$64,$60,$64,$e0,$ec
	db $32,$33,$60,$67,$61,$6f,$43,$4f,$47,$5f,$07,$1f,$03,$33,$07,$37
	db $1d,$ff,$c0,$c3,$80,$81,$80,$81,$01,$81,$01,$81,$03,$c3,$b8,$ff
	db $e0,$ec,$c0,$cc,$e0,$f8,$e2,$fa,$c2,$f2,$86,$f6,$06,$e6,$4c,$cc

AuraSphereVortexTiles:
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$07,$07,$0f,$0f
	db $03,$03,$00,$00,$00,$3f,$00,$ff,$1f,$00,$ff,$ff,$ff,$ff,$ff,$01
	db $fe,$fe,$3f,$3f,$7f,$87,$0f,$f1,$83,$7c,$f1,$0e,$f8,$c7,$fc,$e3
	db $00,$00,$80,$80,$c0,$c0,$e0,$e0,$f0,$f0,$f0,$70,$f8,$78,$f8,$38
	db $1d,$1c,$30,$33,$00,$0f,$01,$1e,$07,$39,$07,$73,$0f,$67,$0f,$c7
	db $01,$fe,$00,$ff,$7f,$80,$ff,$7c,$ff,$f0,$ff,$c0,$ff,$80,$cf,$30
	db $fc,$33,$7e,$99,$3e,$c9,$fe,$01,$fe,$01,$fc,$03,$fc,$03,$f9,$06
	db $78,$b8,$78,$b8,$78,$b8,$78,$b8,$78,$b8,$f8,$39,$f8,$71,$f8,$73
	db $00,$00,$00,$00,$00,$00,$03,$03,$0f,$0f,$1f,$1f,$3f,$3e,$7f,$78
	db $00,$07,$00,$01,$00,$00,$ff,$fc,$ff,$ff,$ff,$ff,$ff,$03,$07,$f8
	db $00,$80,$00,$e0,$02,$72,$03,$3b,$c1,$1d,$f1,$cd,$f0,$ee,$f9,$f6
	db $00,$00,$00,$00,$00,$00,$00,$00,$80,$80,$c0,$c0,$c0,$c0,$e0,$e0
	db $7c,$73,$f8,$e7,$f1,$ee,$f3,$cc,$e7,$d8,$e7,$d9,$a7,$9b,$8f,$b3
	db $01,$fe,$78,$87,$fe,$01,$ff,$60,$ff,$c0,$ff,$80,$df,$20,$9f,$60
	db $f8,$77,$fc,$3b,$7c,$9b,$7c,$9b,$fc,$0b,$fc,$0b,$fc,$03,$fd,$02
	db $e0,$68,$e0,$68,$e0,$6c,$f0,$6c,$f0,$6c,$f0,$6c,$f1,$6d,$f1,$ed
	db $00,$00,$00,$00,$00,$00,$00,$03,$00,$0f,$00,$1c,$03,$20,$07,$00
	db $00,$00,$3f,$3f,$07,$07,$01,$f1,$01,$fe,$f0,$0f,$fc,$03,$ff,$f8
	db $00,$00,$00,$00,$e0,$ec,$f0,$f3,$fc,$39,$7f,$9c,$3f,$ce,$1f,$e7
	db $00,$00,$00,$00,$00,$00,$40,$40,$30,$b0,$18,$d8,$8c,$6c,$8c,$6c
	db $0f,$03,$1f,$0f,$1f,$1f,$3f,$3e,$7f,$7c,$7e,$79,$fc,$f3,$f8,$f7
	db $ff,$fe,$ff,$ff,$ff,$c1,$ff,$00,$83,$7c,$1f,$e0,$7f,$80,$ff,$30
	db $8f,$73,$cf,$33,$e7,$99,$f7,$49,$f7,$09,$ff,$03,$ff,$03,$ff,$06
	db $c6,$36,$c6,$b6,$cf,$b7,$cf,$b7,$cf,$b7,$cf,$37,$cf,$37,$9f,$67
	db $00,$00,$00,$00,$03,$03,$07,$07,$0c,$0c,$08,$0b,$10,$17,$03,$0c
	db $3f,$3f,$ff,$ff,$ff,$ff,$3f,$00,$01,$fe,$00,$ff,$fe,$01,$ff,$78
	db $c0,$c0,$f0,$f0,$f8,$f8,$fe,$fc,$ff,$3e,$7f,$9e,$3f,$cf,$1f,$e7
	db $00,$00,$00,$00,$00,$40,$00,$20,$00,$30,$80,$30,$c0,$18,$c0,$18
	db $07,$19,$07,$13,$0f,$27,$0f,$2e,$1f,$1c,$3e,$39,$3c,$33,$38,$37
	db $ff,$fe,$ff,$c7,$ff,$01,$c7,$38,$1f,$e0,$3f,$c0,$7f,$90,$ff,$20
	db $9f,$67,$cf,$37,$cf,$b3,$ef,$93,$ef,$13,$ef,$13,$ff,$03,$ff,$06
	db $e0,$98,$e0,$98,$e2,$9a,$e2,$9a,$c2,$b2,$c6,$36,$86,$76,$9e,$6e

AuraSphereAgilityRayTiles:
	; First two tiles of PC ANIM_GFX_WIND_BG, used by BATTLEANIMOAMSET_AC.
	db $00,$00,$00,$00,$00,$1f,$00,$20,$1f,$20,$00,$1f,$00,$00,$00,$00
	db $00,$00,$00,$00,$00,$ff,$00,$00,$ff,$00,$00,$ff,$00,$00,$00,$00

AuraSphereGlowTiles:
	db $00,$00,$01,$01,$07,$07,$0f,$0f,$1f,$1f,$3c,$3f,$38,$3f,$78,$7f
	db $3c,$3c,$ff,$ff,$ff,$ff,$c3,$ff,$00,$ff,$00,$ff,$18,$e7,$7e,$81
	db $70,$7f,$71,$7e,$e1,$fe,$e3,$fc,$e3,$fc,$e1,$fe,$71,$7e,$70,$7f
	db $ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00
	db $07,$07,$1f,$1f,$3c,$3f,$70,$7f,$60,$7f,$e3,$fc,$c7,$f8,$c7,$f8
	db $00,$00,$00,$00,$03,$03,$0f,$0f,$1f,$1f,$1c,$1f,$38,$3f,$39,$3e
	db $00,$3c,$00,$42,$00,$81,$00,$81,$00,$81,$00,$81,$00,$42,$00,$3c
	db $3c,$3c,$42,$7e,$99,$e7,$a5,$c3,$a5,$c3,$99,$e7,$42,$7e,$3c,$3c
	db $00,$00,$18,$18,$24,$3c,$5a,$66,$5a,$66,$24,$3c,$18,$18,$00,$00
	db $00,$00,$00,$00,$03,$03,$0f,$0f,$1c,$1f,$19,$1e,$33,$3c,$36,$39

AuraSphereProjectileTiles:
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$03,$07,$07,$0f
	db $00,$00,$00,$00,$07,$0f,$1f,$3f,$78,$ff,$c0,$ff,$87,$f8,$1f,$e0
	db $00,$00,$7f,$ff,$ff,$ff,$00,$ff,$00,$ff,$fc,$03,$ff,$00,$ff,$00
	db $00,$00,$80,$c0,$f0,$f0,$f8,$fc,$3c,$fc,$1e,$fe,$0e,$fe,$86,$7f
	db $0e,$1f,$1c,$3f,$3c,$7f,$79,$7e,$f9,$fe,$eb,$ec,$93,$9c,$13,$1c
	db $3f,$c0,$7f,$80,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00
	db $ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00
	db $c7,$3f,$c3,$3f,$e3,$1f,$e3,$1f,$e3,$1f,$e2,$1f,$e6,$1e,$e6,$1e
	db $37,$3c,$3b,$7a,$63,$62,$44,$47,$08,$0f,$10,$1f,$21,$3f,$6e,$7e
	db $ff,$00,$ff,$00,$ff,$00,$ff,$00,$7f,$80,$1f,$e0,$a7,$b8,$20,$3f
	db $ff,$00,$ff,$00,$ff,$00,$ff,$00,$fe,$01,$f8,$07,$c1,$3f,$0f,$ff
	db $cc,$3e,$cc,$3c,$98,$7c,$30,$f8,$60,$f0,$c0,$e0,$80,$c0,$00,$80
	db $f0,$f0,$c0,$c0,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	db $46,$7e,$f9,$f9,$83,$c3,$07,$07,$00,$00,$00,$00,$00,$00,$00,$00
	db $fe,$ff,$f8,$fc,$e0,$f0,$80,$80,$00,$00,$00,$00,$00,$00,$00,$00
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

AuraSphereBigGlowTiles:
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	db $00,$00,$00,$00,$00,$00,$01,$01,$07,$07,$1f,$1f,$3c,$3f,$70,$7f
	db $00,$00,$0f,$0f,$7f,$7f,$f8,$ff,$c0,$ff,$03,$fc,$1f,$e0,$7c,$80
	db $00,$00,$01,$01,$03,$03,$07,$07,$06,$07,$0e,$0f,$0c,$0f,$1c,$1f
	db $e1,$fe,$c7,$f8,$8e,$f0,$1c,$e0,$38,$c0,$70,$80,$60,$80,$c0,$00
	db $e0,$00,$80,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	db $18,$1f,$39,$3e,$31,$3e,$33,$3c,$73,$7c,$63,$7c,$66,$78,$66,$78
	db $c0,$00,$80,$00,$80,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	db $00,$00,$00,$00,$00,$00,$01,$01,$03,$03,$07,$07,$0e,$0f,$1c,$1f
	db $07,$07,$3f,$3f,$fc,$ff,$e0,$ff,$81,$fe,$0f,$f0,$3f,$c0,$78,$80
	db $38,$3f,$31,$3e,$73,$7c,$63,$7c,$66,$78,$e6,$f8,$c6,$f8,$cc,$f0
	db $e0,$00,$c0,$00,$80,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
