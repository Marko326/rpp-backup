; HUR-5.62.32: Polished Crystal Hurricane renderer for HURRICANE.
;
; The main column is PC's 18-sprite HURRICANE object using HIDDEN_POWER_FAST
; (radius 24, vertical component quartered), while BattleAnimSub_AgilityMinor
; contributes five persistent Bubble-palette wind streaks. The background keeps
; PC's alternating hues, gray/yellow OBJ cycle and +/-4px two-frame shake.
;
; This renderer is intentionally isolated in bank $38: bank $3D is already
; crowded by the recent Gold/Crystal and Polished Crystal animation ports.

HURRICANE_TILE_BASE       EQU $60
HURRICANE_TILE_COUNT      EQU 18
HURRICANE_WIND_TILE_BASE  EQU $72
HURRICANE_WIND_TILE_COUNT EQU 2
HURRICANE_MAIN_PAL        EQU ATK_PAL_GREY
HURRICANE_WIND_PAL        EQU ATK_PAL_YELLOW
HURRICANE_WIND_ATTR       EQU (1 << OAM_PRIORITY) | HURRICANE_WIND_PAL
HURRICANE_ORBIT_FRAMES         EQU 32
HURRICANE_PC_TOTAL_FRAMES      EQU 121
HURRICANE_EXTRA_ACTIVE_FRAMES  EQU 15 ; HUR-5.62.32: 3 extra Thunder beats before the silent tail
HURRICANE_EXTRA_TAIL_FRAMES    EQU HURRICANE_ORBIT_FRAMES / 2 ; finish the tuned storm on the left side
HURRICANE_TAIL_START_FRAME     EQU 95 + HURRICANE_EXTRA_ACTIVE_FRAMES
HURRICANE_TOTAL_FRAMES         EQU HURRICANE_PC_TOTAL_FRAMES + HURRICANE_EXTRA_ACTIVE_FRAMES + HURRICANE_EXTRA_TAIL_FRAMES

IF HURRICANE_TOTAL_FRAMES > $ff
	fail "Hurricane duration must fit in wSubAnimCounter"
ENDC

PlayPolishedCrystalHurricaneAnimation::
	call .LoadTiles
	call .InstallPalettes
	call .ShakeBegin

	xor a
	ld [wSubAnimCounter],a
.frameLoop
	call .UpdatePalettes
	call .PlayThunder
	call .SetHorizontalShake

	ld de,wOAMBuffer
	call .DrawHurricane
	call .DrawAgilityMinor
	call DelayFrame
	call ClearSprites

	ld hl,wSubAnimCounter
	inc [hl]
	ld a,[hl]
	cp HURRICANE_TOTAL_FRAMES
	jp c,.frameLoop

	; RPP keeps the WX shake active through the tuned Hurricane timeline. Give
	; the base WX one VBlank to latch before disarming it, otherwise the last
	; +/-4 position could leak into the next UI.
	ld a,7
	ld [wBattleAnimWX],a
	ld a,$e4
	ld [rBGP],a
	ld [rOBP0],a
	ld [rOBP1],a
	call DelayFrame
	call .ShakeEnd

	callba _LoadAnimationTilesetPalettes
	ld a,$e4
	ld [rBGP],a
	ld [rOBP0],a
	ld [rOBP1],a
	ret

.LoadTiles
	ld hl,vSprites + HURRICANE_TILE_BASE * 16
	ld de,HurricaneTiles
	ld b,BANK(HurricaneTiles)
	ld c,HURRICANE_TILE_COUNT
	call CopyVideoData

	ld hl,vSprites + HURRICANE_WIND_TILE_BASE * 16
	ld de,HurricaneWindTiles
	ld b,BANK(HurricaneWindTiles)
	ld c,HURRICANE_WIND_TILE_COUNT
	call CopyVideoData
	ret

.InstallPalettes
	; Slot 0 follows OBP0 (PC gray -> Bright); slot 4 follows OBP1 (PC blue ->
	; Bubble). This preserves the two independent DMG palette effects on CGB.
	ld a,2
	ld [rSVBK],a
	ld hl,HurricaneBrightPalette
	ld de,W2_SprPaletteData + HURRICANE_MAIN_PAL * 8
	ld bc,8
	call CopyData
	ld hl,HurricaneBubblePalette
	ld de,W2_SprPaletteData + HURRICANE_WIND_PAL * 8
	ld bc,8
	call CopyData

	ld hl,W2_SpritePaletteMap + HURRICANE_TILE_BASE
	ld b,HURRICANE_TILE_COUNT
	ld a,HURRICANE_MAIN_PAL
.mainPalMap
	ld [hli],a
	dec b
	jr nz,.mainPalMap
	ld hl,W2_SpritePaletteMap + HURRICANE_WIND_TILE_BASE
	ld b,HURRICANE_WIND_TILE_COUNT
	ld a,HURRICANE_WIND_PAL
.windPalMap
	ld [hli],a
	dec b
	jr nz,.windPalMap
	ld a,1
	ld [W2_UseOBP1],a
	ld [W2_ForceOBPUpdate],a
	xor a
	ld [rSVBK],a
	ret

.UpdatePalettes
	; BattleBGEffect_GetNthDMGPal holds each entry for battle_turn+1 frames.
	; Hurricane passes $4, so both repeating effects advance every five VBlanks.
	; GetNthDMGPal shows entry 0 on the queue frame, then holds each next
	; entry for five frames: 0, 1x5, 2x5, ... before repeating.
	ld a,[wSubAnimCounter]
	ld c,0
	and a
	jr z,.hueQuotientReady
	dec a
	inc c
.hueDiv5
	cp 5
	jr c,.hueQuotientReady
	sub 5
	inc c
	jr .hueDiv5
.hueQuotientReady
	ld a,c
	and 7
	ld e,a
	ld d,0
	ld hl,HurricaneHueCycle
	add hl,de
	ld a,[hl]
	ld [rBGP],a
	ld [rOBP1],a

	ld a,c
	and 1
	ld a,$e4
	jr z,.grayCycleReady
	ld a,$90
.grayCycleReady
	ld [rOBP0],a
	ret

.PlayThunder
	; PC anim_wait 4 consumes the command frame plus four delayed VBlanks.
	; AgilityMinor therefore returns on frame 5, then Thunder plays every five
	; frames: 5,10,...,90 in the stock 18-iteration Hurricane loop. RPP keeps
	; the same five-frame cadence through the 15-frame tuned extension (to 105).
	ld a,[wSubAnimCounter]
	cp 5
	ret c
	cp HURRICANE_TAIL_START_FRAME
	ret nc
.mod5
	sub 5
	jr z,.play
	jr nc,.mod5
	ret
.play
	ld a,GSSFX_THUNDER
	jp PlaySound

.ShakeBegin
	ld a,7
	ld [wBattleAnimWX],a
	ld a,1
	ld [wBattleAnimWXEnabled],a
	ret

.SetHorizontalShake
	; PC ANIM_BG_SHAKE_SCREEN_X $90,$4,$10 starts at -4 and flips every two
	; VBlanks. RPP preserves that cadence through the tuned 152-frame timeline.
	ld a,[wSubAnimCounter]
	and 2
	ld a,7 - 4
	jr z,.shakeReady
	ld a,7 + 4
.shakeReady
	ld [wBattleAnimWX],a
	ret

.ShakeEnd
	ld a,7
	ld [wBattleAnimWX],a
	xor a
	ld [wBattleAnimWXEnabled],a
	ret

.DrawHurricane
	; HIDDEN_POWER_FAST begins at param $38, advances by two each frame, uses
	; radius 24, and arithmetic-shifts the sine Y component right twice.
	ld a,[wSubAnimCounter]
	and 31
	add a
	ld c,a
	ld b,0
	ld hl,HurricaneOrbitOffsets
	add hl,bc
	ld a,[hli]
	ld b,a ; orbit X
	ld a,[hl]
	ld c,a ; orbit Y

	ld a,[H_WHOSETURN]
	and a
	jr nz,.enemyCenter
	ld a,132
	add b
	ld [wBaseCoordX],a
	ld a,56
	add c
	ld [wBaseCoordY],a
	jr .centerReady
.enemyCenter
	; RELATIVE_X with fixY=$ff maps (132,56) -> (48,96) and negates the
	; function-produced XOFFSET while leaving YOFFSET unchanged.
	ld a,48
	sub b
	ld [wBaseCoordX],a
	ld a,96
	add c
	ld [wBaseCoordY],a
.centerReady

	ld hl,HurricaneOAMLayout
	ld b,18
.mainSpriteLoop
	push bc
	ld a,[hli]
	ld b,a ; dx
	ld a,[hli]
	ld c,a ; dy
	ld a,[wBaseCoordY]
	add c
	ld [de],a
	inc de

	ld a,[wSubAnimCounter]
	and 2 ; Frameset_Hurricane alternates normal/X-flipped every two frames.
	jr z,.mainNoFlipX
	ld a,b
	cpl
	sub 7 ; -(dx + 8)
	ld b,a
.mainNoFlipX
	ld a,[wBaseCoordX]
	add b
	ld [de],a
	inc de
	ld a,[hli]
	add HURRICANE_TILE_BASE
	ld [de],a
	inc de
	ld a,[wSubAnimCounter]
	and 2
	ld a,HURRICANE_MAIN_PAL
	jr z,.mainAttrReady
	or OAM_HFLIP
.mainAttrReady
	ld [de],a
	inc de
	pop bc
	dec b
	jr nz,.mainSpriteLoop
	ret

.DrawAgilityMinor
	ld hl,HurricaneAgilityObjects
	ld a,5
.agilityObjectLoop
	push af
	ld a,[hli]
	ld b,a ; spawn frame
	ld a,[wSubAnimCounter]
	sub b
	jr c,.agilitySkip
	; Frameset_Agility ends with battleoamend, which holds its last OAM frame.
	; The object therefore keeps moving until the parent Hurricane animation ends.
	inc a ; function updates before OAM draw: elapsed updates = age + 1
	ld b,a
	ld a,[hli]
	ld c,a ; logical Y
	ld a,[hli] ; logical X step
	push hl
	call .DrawAgilityObject
	pop hl
	jr .agilityNext
.agilitySkip
	inc hl
	inc hl
.agilityNext
	pop af
	dec a
	jr nz,.agilityObjectLoop
	ret

.DrawAgilityObject
	; A = step, B = elapsed updates, C = logical Y; initial logical X is 8.
	ld h,a
	ld a,8
.agilityXLoop
	add h
	dec b
	jr nz,.agilityXLoop
	ld b,a
	ld a,[H_WHOSETURN]
	and a
	jr z,.agilityCoordsReady
	ld a,180
	sub b
	ld b,a
	ld a,136
	sub c
	ld c,a
.agilityCoordsReady
	ld a,b
	ld [wBaseCoordX],a
	ld a,c
	sub 4
	ld [wBaseCoordY],a

	ld hl,HurricaneAgilityPlayerLayout
	ld a,[H_WHOSETURN]
	and a
	jr z,.agilityLayoutReady
	ld hl,HurricaneAgilityEnemyLayout
.agilityLayoutReady
	ld b,4
.agilitySpriteLoop
	ld a,[wBaseCoordY]
	ld [de],a
	inc de
	ld a,[hli]
	ld c,a
	ld a,[wBaseCoordX]
	add c
	ld [de],a
	inc de
	ld a,[hli]
	add HURRICANE_WIND_TILE_BASE
	ld [de],a
	inc de
	ld a,[hli]
	or HURRICANE_WIND_ATTR
	ld [de],a
	inc de
	dec b
	jr nz,.agilitySpriteLoop
	ret

; spawn frame, logical Y, X step from BattleAnimSub_AgilityMinor.
HurricaneAgilityObjects:
	db 0,24,$10
	db 0,48,$02
	db 5,56,$0c
	db 5,80,$04
	db 5,104,$0e

; OAMData_59 direct geometry. Enemy entries include the descriptor X flip.
HurricaneAgilityPlayerLayout:
	db -16,0,0,  -8,1,0,   0,1,OAM_HFLIP,   8,0,OAM_HFLIP
HurricaneAgilityEnemyLayout:
	db   8,0,OAM_HFLIP,   0,1,OAM_HFLIP,  -8,1,0,  -16,0,0

; OAMData_Hurricane: 3 columns x 6 rows, source tiles 0..17 row-major.
HurricaneOAMLayout:
	db -12,-32,0,  -4,-32,1,  4,-32,2
	db -12,-24,3,  -4,-24,4,  4,-24,5
	db -12,-16,6,  -4,-16,7,  4,-16,8
	db -12,-8,9,  -4,-8,10,  4,-8,11
	db -12,0,12,  -4,0,13,  4,0,14
	db -12,8,15,  -4,8,16,  4,8,17

; Exact 32-frame period of PC HIDDEN_POWER_FAST at param $38 / radius $18.
; Pairs are signed X,Y offsets; Y is Sine followed by two arithmetic shifts.
HurricaneOrbitOffsets:
	db 16,-4,  19,-4,  22,-3,  23,-1,  24,0,  23,1,  22,2,  19,3
	db 16,4,  13,4,  9,5,  4,5,  0,6,  -4,5,  -9,5,  -13,4
	db -16,4,  -19,3,  -22,2,  -23,1,  -24,0,  -23,-1,  -22,-3,  -19,-4
	db -16,-4,  -13,-5,  -9,-6,  -4,-6,  0,-6,  4,-6,  9,-6,  13,-5

; PC BattleBGEffect_AlternateHues palette order.
HurricaneHueCycle:
	db $e4,$f8,$fc,$f8,$e4,$90,$40,$90

HurricaneBrightPalette:
	RGB 31,31,31
	RGB 28,28,28
	RGB 16,16,16
	RGB 10,10,10

HurricaneBubblePalette:
	RGB 31,31,31
	RGB 19,28,28
	RGB 0,23,28
	RGB 3,10,30

; Exact RGBGFX-equivalent 2bpp conversion of PC hurricane.png (24x48).
HurricaneTiles:
	db $00,$00,$00,$00,$00,$00,$01,$01,$07,$04,$1e,$11,$38,$26,$70,$48
	db $03,$03,$1f,$18,$7c,$43,$e0,$18,$80,$60,$00,$87,$06,$39,$38,$c6
	db $e0,$e0,$fc,$0c,$0e,$f2,$02,$0c,$01,$03,$01,$b1,$11,$2d,$0e,$12
	db $60,$53,$c3,$a4,$86,$c9,$84,$ca,$48,$54,$38,$34,$3f,$2f,$3f,$20
	db $e0,$18,$80,$61,$01,$8e,$0f,$30,$38,$47,$0e,$ff,$ef,$f0,$fc,$03
	db $02,$0e,$07,$f5,$ec,$1b,$28,$f5,$f0,$ca,$e6,$12,$8f,$45,$1a,$0d
	db $28,$27,$10,$10,$0a,$0c,$0d,$0b,$03,$28,$01,$24,$03,$13,$07,$04
	db $00,$f8,$01,$00,$1d,$03,$fb,$fc,$fe,$01,$00,$fc,$01,$01,$7c,$ff
	db $32,$15,$b6,$62,$64,$8a,$8c,$44,$0a,$9e,$2a,$36,$84,$cc,$04,$84
	db $05,$06,$02,$03,$00,$01,$00,$00,$00,$00,$00,$08,$00,$08,$00,$04
	db $00,$c3,$03,$0c,$88,$b1,$3c,$7f,$70,$48,$c0,$a3,$00,$af,$2f,$70
	db $08,$ea,$f0,$31,$f8,$d9,$04,$84,$02,$f6,$06,$0a,$78,$8c,$72,$fe
	db $00,$03,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01
	db $1f,$3f,$53,$6c,$60,$50,$30,$2f,$7f,$70,$8f,$bf,$a0,$d6,$c0,$a1
	db $72,$86,$02,$1a,$14,$6c,$78,$98,$e4,$7c,$94,$ac,$38,$48,$70,$99
	db $02,$03,$06,$07,$0a,$0e,$09,$0d,$0c,$0b,$07,$04,$03,$03,$00,$00
	db $41,$fe,$1f,$1f,$07,$78,$fc,$83,$7f,$7f,$00,$ff,$ff,$00,$7e,$7e
	db $68,$f9,$c8,$2a,$10,$d0,$70,$70,$90,$90,$20,$a0,$c0,$c0,$00,$00
HurricaneTilesEnd:
	IF HurricaneTilesEnd - HurricaneTiles != HURRICANE_TILE_COUNT * 16
		fail "Hurricane art must contain exactly 18 tiles"
	ENDC

; Exact PC wind_bg.png source tiles 0-1 used by BattleAnimSub_AgilityMinor.
HurricaneWindTiles:
	db $00,$00,$00,$00,$00,$1f,$00,$20,$1f,$20,$00,$1f,$00,$00,$00,$00
	db $00,$00,$00,$00,$00,$ff,$00,$00,$ff,$00,$00,$ff,$00,$00,$00,$00
HurricaneWindTilesEnd:
	IF HurricaneWindTilesEnd - HurricaneWindTiles != HURRICANE_WIND_TILE_COUNT * 16
		fail "Hurricane AgilityMinor wind art must contain exactly two tiles"
	ENDC
