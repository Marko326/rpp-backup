; ANIM-5.62.74: selected double-ring art with softened impact/echo shake.
; Two cry-led volleys each carry a leading wave and a delayed echo. The
; largest ring uses 36 OBJs, so it briefly suppresses the echo to leave four
; OBJ slots for the impact rays (max 40 OBJs; no new WRAM or damage calls).
; Keep original v45 mirrored OBJ layouts, all 2bpp pixels and golden palette.
; Keep the renderer and data outside ROM0 and the tight battle code banks.

HYPER_VOICE_TILE_BASE      EQU $60
HYPER_VOICE_TILE_COUNT     EQU 22
HYPER_VOICE_RAY_TILE       EQU HYPER_VOICE_TILE_BASE + HYPER_VOICE_TILE_COUNT - 2
HYPER_VOICE_SPARK_TILE     EQU HYPER_VOICE_TILE_BASE + HYPER_VOICE_TILE_COUNT - 1
HYPER_VOICE_RING_PAL       EQU ATK_PAL_YELLOW
HYPER_VOICE_CHARGE_FRAMES  EQU 6
HYPER_VOICE_PULSE_FRAMES   EQU 39
HYPER_VOICE_ECHO_DELAY     EQU 11
HYPER_VOICE_GAP_FRAMES     EQU 6

IF HYPER_VOICE_TILE_BASE + HYPER_VOICE_TILE_COUNT > $80
	fail "Hyper Voice v2 tiles exceed battle OBJ VRAM"
ENDC

PlayRubyHyperVoiceAnimation::
	call .LoadTiles
	call .InstallPalette
	ld a,7
	ld [wBattleAnimWX],a
	ld a,1
	ld [wBattleAnimWXEnabled],a

	call .Charge
	call .PlayPulse
	ld c,HYPER_VOICE_GAP_FRAMES
	call DelayFrames
	call .Charge
	call .PlayPulse

	; Flush a neutral WX on VBlank before disarming the window shake hook.
	ld a,7
	ld [wBattleAnimWX],a
	ld a,$e4
	ld [rBGP],a
	call DelayFrame
	xor a
	ld [wBattleAnimWXEnabled],a
	call ClearSprites
	callba _LoadAnimationTilesetPalettes
	ld a,$e4
	ld [rBGP],a
	ld [rOBP0],a
	ld [rOBP1],a
	ret

.LoadTiles
	ld hl,vSprites + HYPER_VOICE_TILE_BASE * 16
	ld de,HyperVoiceWaveTiles
	ld b,BANK(HyperVoiceWaveTiles)
	ld c,HYPER_VOICE_TILE_COUNT
	call CopyVideoData
	ret

.InstallPalette
	ld a,2
	ld [rSVBK],a
	ld hl,HyperVoiceGoldPalette
	ld de,W2_SprPaletteData + HYPER_VOICE_RING_PAL * 8
	ld bc,8
	call CopyData
	ld hl,W2_SpritePaletteMap + HYPER_VOICE_TILE_BASE
	ld b,HYPER_VOICE_TILE_COUNT
	ld a,HYPER_VOICE_RING_PAL
.paletteMapLoop
	ld [hli],a
	dec b
	jr nz,.paletteMapLoop
	ld a,1
	ld [W2_ForceOBPUpdate],a
	xor a
	ld [rSVBK],a
	ret

.Charge
	; Give the user's cry a visible wind-up instead of launching a
	; weightless ring on the very first frame.
	xor a
	ld [wSubAnimCounter],a
.chargeLoop
	ld a,[wSubAnimCounter]
	and 1
	ld a,5
	jr z,.chargeWX
	ld a,9
.chargeWX
	ld [wBattleAnimWX],a
	ld a,[wSubAnimCounter]
	and 2
	ld a,$e4
	jr z,.chargeBG
	ld a,$90
.chargeBG
	ld [rBGP],a
	call DelayFrame
	ld hl,wSubAnimCounter
	inc [hl]
	ld a,[hl]
	cp HYPER_VOICE_CHARGE_FRAMES
	jr c,.chargeLoop
	ld a,7
	ld [wBattleAnimWX],a
	ld a,$e4
	ld [rBGP],a
	ret

.PlayPulse
	call .PlayUserCry
	xor a
	ld [wSubAnimCounter],a
.frameLoop
	call .UpdateFeedback
	ld de,wOAMBuffer
	ld a,[wSubAnimCounter]
	call .DrawWave
	ld a,[wSubAnimCounter]
	cp HYPER_VOICE_ECHO_DELAY
	jr c,.noEcho
	; A 64px ring uses 36 objects. During its eight frames, the
	; echo waits; the other four OAM entries belong to the hit rays.
	cp 20
	jr c,.drawEcho
	cp 28
	jr c,.noEcho
.drawEcho
	sub HYPER_VOICE_ECHO_DELAY
	call .DrawWave
.noEcho
	call .DrawImpact
	call DelayFrame
	call ClearSprites
	ld hl,wSubAnimCounter
	inc [hl]
	ld a,[hl]
	cp HYPER_VOICE_PULSE_FRAMES
	jr c,.frameLoop
	ld a,7
	ld [wBattleAnimWX],a
	ld a,$e4
	ld [rBGP],a
	ret

.PlayUserCry
	; Brighten the native user's cry without stealing the sound
	; channel from the next move. The two volleys remain one damage hit.
	ld a,$18
	ld [wFrequencyModifier],a
	ld a,$40
	ld [wTempoModifier],a
	ld a,[H_WHOSETURN]
	and a
	jr nz,.enemyCry
	ld a,[wBattleMonSpecies]
	jr .startCry
.enemyCry
	ld a,[wEnemyMonSpecies]
.startCry
	push af
	ld a,1
	ld [wSFXDontWait],a
	pop af
	call PlayCry
	xor a
	ld [wSFXDontWait],a
	ret

.UpdateFeedback
	; Preserve v45 pulse/echo timings but smooth the shake.
	; First impact +/-4px; final delayed echo +/-2px (v45 +/-6px).
	ld a,[wSubAnimCounter]
	cp 23
	jr c,.neutral
	cp 30
	jr c,.firstImpact
	cp 33
	jr c,.neutral
	cp 39
	jr nc,.neutral
	; Soften the last aftershock to avoid an excessive ending wobble.
	and 2
	ld a,5
	jr z,.writeWX
	ld a,9
	jr .writeWX
.firstImpact
	and 2
	ld a,3
	jr z,.writeWX
	ld a,11
	jr .writeWX
.neutral
	ld a,7
.writeWX
	ld [wBattleAnimWX],a
	ld a,[wSubAnimCounter]
	cp 24
	jr c,.normalBG
	cp 26
	jr c,.flashBG
	cp 34
	jr c,.normalBG
	cp 36
	jr nc,.normalBG
.flashBG
	ld a,$90
	jr .writeBG
.normalBG
	ld a,$e4
.writeBG
	ld [rBGP],a
	ret

.DrawWave
	; Input A = wave age (0..27), DE = free OAM cursor. The center
	; accelerates across the screen to the opposite battler in 28 frames.
	cp 28
	ret nc
	push af
	call .SetWaveCenter
	pop af
	cp 5
	jr nc,.medium
	ld hl,HyperVoiceRing16Layout
	jr .drawWaveLayout
.medium
	cp 15
	jr nc,.large
	ld hl,HyperVoiceRing32Layout
	jr .drawWaveLayout
.large
	cp 20
	jr nc,.huge
	ld hl,HyperVoiceRing48Layout
	jr .drawWaveLayout
.huge
	ld hl,HyperVoiceRing64Layout
.drawWaveLayout
	jp .DrawLayout

.SetWaveCenter
	; X = start +/- 3*age; Y = start -/+ floor(3*age/2).
	; Mirror both axes for an enemy attack; DE is preserved for OAM.
	ld b,a
	add a
	add b
	ld c,a
	srl a
	ld b,a
	ld a,[H_WHOSETURN]
	and a
	jr nz,.enemyCenter
	ld a,48
	add c
	ld [wBaseCoordX],a
	ld a,96
	sub b
	ld [wBaseCoordY],a
	ret
.enemyCenter
	ld a,132
	sub c
	ld [wBaseCoordX],a
	ld a,56
	add b
	ld [wBaseCoordY],a
	ret

.DrawImpact
	; Four spark/ray OBJ slots remain available even on 36-OBJ
	; 64px frames; hit windows are 24..27 and 34..37.
	ld a,[wSubAnimCounter]
	cp 24
	ret c
	cp 28
	jr c,.impact
	cp 34
	ret c
	cp 38
	ret nc
.impact
	ld a,[H_WHOSETURN]
	and a
	jr nz,.enemyTarget
	ld a,132
	ld [wBaseCoordX],a
	ld a,56
	ld [wBaseCoordY],a
	jr .drawImpactLayout
.enemyTarget
	ld a,48
	ld [wBaseCoordX],a
	ld a,96
	ld [wBaseCoordY],a
.drawImpactLayout
	ld hl,HyperVoiceImpactLayout
	jp .DrawLayout

.DrawLayout
	; Packed layout: count, then (signed dy, signed dx, tile, OBJ
	; flip flags). Skip transparent 8x8 cells in large wave outlines.
	; DE advances by precisely four bytes per drawn OBJ, maximum 40.
	ld b,[hl]
	inc hl
.layoutLoop
	ld a,[hli]
	ld c,a
	ld a,[wBaseCoordY]
	add c
	ld [de],a
	inc de
	ld a,[hli]
	ld c,a
	ld a,[wBaseCoordX]
	add c
	ld [de],a
	inc de
	ld a,[hli]
	ld [de],a
	inc de
	ld a,[hli]
	or HYPER_VOICE_RING_PAL
	ld [de],a
	inc de
	dec b
	jr nz,.layoutLoop
	ret

HyperVoiceGoldPalette:
	RGB 31,31,31
	RGB 27,10,0
	RGB 31,23,2
	RGB 31,31,27

; Generated 2bpp circular wave stages, mirror-reused OBJ tiles.
HyperVoiceRing16Layout:
	db 4
	db -8,-8,$60,0
	db -8,0,$60,OAM_HFLIP
	db 0,-8,$60,OAM_VFLIP
	db 0,0,$60,OAM_HFLIP | OAM_VFLIP
HyperVoiceRing32Layout:
	db 16
	db -16,-16,$61,0
	db -16,-8,$62,0
	db -16,0,$62,OAM_HFLIP
	db -16,8,$61,OAM_HFLIP
	db -8,-16,$63,OAM_HFLIP | OAM_VFLIP
	db -8,-8,$64,OAM_HFLIP | OAM_VFLIP
	db -8,0,$64,OAM_VFLIP
	db -8,8,$63,OAM_VFLIP
	db 0,-16,$63,OAM_HFLIP
	db 0,-8,$64,OAM_HFLIP
	db 0,0,$64,0
	db 0,8,$63,0
	db 8,-16,$61,OAM_VFLIP
	db 8,-8,$62,OAM_VFLIP
	db 8,0,$62,OAM_HFLIP | OAM_VFLIP
	db 8,8,$61,OAM_HFLIP | OAM_VFLIP
HyperVoiceRing48Layout:
	db 24
	db -24,-24,$65,0
	db -24,-16,$66,0
	db -24,-8,$67,OAM_HFLIP | OAM_VFLIP
	db -24,0,$67,OAM_VFLIP
	db -24,8,$66,OAM_HFLIP
	db -24,16,$65,OAM_HFLIP
	db -16,-24,$68,0
	db -16,-16,$69,OAM_HFLIP | OAM_VFLIP
	db -16,8,$69,OAM_VFLIP
	db -16,16,$68,OAM_HFLIP
	db -8,-24,$6a,OAM_HFLIP | OAM_VFLIP
	db -8,16,$6a,OAM_VFLIP
	db 0,-24,$6a,OAM_HFLIP
	db 0,16,$6a,0
	db 8,-24,$68,OAM_VFLIP
	db 8,-16,$69,OAM_HFLIP
	db 8,8,$69,0
	db 8,16,$68,OAM_HFLIP | OAM_VFLIP
	db 16,-24,$65,OAM_VFLIP
	db 16,-16,$66,OAM_VFLIP
	db 16,-8,$67,OAM_HFLIP
	db 16,0,$67,0
	db 16,8,$66,OAM_HFLIP | OAM_VFLIP
	db 16,16,$65,OAM_HFLIP | OAM_VFLIP
HyperVoiceRing64Layout:
	db 36
	db -32,-24,$6b,0
	db -32,-16,$6c,0
	db -32,-8,$6d,OAM_HFLIP | OAM_VFLIP
	db -32,0,$6d,OAM_VFLIP
	db -32,8,$6c,OAM_HFLIP
	db -32,16,$6b,OAM_HFLIP
	db -24,-32,$6e,0
	db -24,-24,$6f,OAM_HFLIP | OAM_VFLIP
	db -24,-16,$70,OAM_HFLIP | OAM_VFLIP
	db -24,8,$70,OAM_VFLIP
	db -24,16,$6f,OAM_VFLIP
	db -24,24,$6e,OAM_HFLIP
	db -16,-32,$71,0
	db -16,-24,$72,OAM_HFLIP | OAM_VFLIP
	db -16,16,$72,OAM_VFLIP
	db -16,24,$71,OAM_HFLIP
	db -8,-32,$73,OAM_HFLIP | OAM_VFLIP
	db -8,24,$73,OAM_VFLIP
	db 0,-32,$73,OAM_HFLIP
	db 0,24,$73,0
	db 8,-32,$71,OAM_VFLIP
	db 8,-24,$72,OAM_HFLIP
	db 8,16,$72,0
	db 8,24,$71,OAM_HFLIP | OAM_VFLIP
	db 16,-32,$6e,OAM_VFLIP
	db 16,-24,$6f,OAM_HFLIP
	db 16,-16,$70,OAM_HFLIP
	db 16,8,$70,0
	db 16,16,$6f,0
	db 16,24,$6e,OAM_HFLIP | OAM_VFLIP
	db 24,-24,$6b,OAM_VFLIP
	db 24,-16,$6c,OAM_VFLIP
	db 24,-8,$6d,OAM_HFLIP
	db 24,0,$6d,0
	db 24,8,$6c,OAM_HFLIP | OAM_VFLIP
	db 24,16,$6b,OAM_HFLIP | OAM_VFLIP
HyperVoiceImpactLayout:
	db 4
	db -4,-28,HYPER_VOICE_SPARK_TILE,0
	db -4,20,HYPER_VOICE_SPARK_TILE,0
	db -28,-4,HYPER_VOICE_RAY_TILE,OAM_VFLIP
	db 20,-4,HYPER_VOICE_RAY_TILE,0

HyperVoiceWaveTiles:
	; Tile $60
	db $03,$00
	db $0c,$03
	db $33,$0f
	db $2f,$1f
	db $5c,$3f
	db $59,$3e
	db $b2,$7c
	db $b4,$78
	; Tile $61
	db $00,$00
	db $00,$00
	db $00,$00
	db $03,$00
	db $06,$01
	db $09,$07
	db $1b,$07
	db $17,$0f
	; Tile $62
	db $07,$00
	db $38,$07
	db $c7,$3f
	db $3f,$ff
	db $f8,$ff
	db $e3,$fc
	db $9c,$e0
	db $20,$c0
	; Tile $63
	db $2d,$1e
	db $2d,$1e
	db $4d,$3e
	db $5a,$3c
	db $5a,$3c
	db $ba,$7c
	db $34,$f8
	db $74,$f8
	; Tile $64
	db $00,$00
	db $00,$00
	db $00,$00
	db $00,$00
	db $00,$00
	db $00,$00
	db $01,$00
	db $03,$00
	; Tile $65
	db $00,$00
	db $00,$00
	db $00,$00
	db $00,$00
	db $00,$00
	db $00,$00
	db $00,$00
	db $01,$00
	; Tile $66
	db $00,$00
	db $00,$00
	db $03,$00
	db $0c,$03
	db $33,$0f
	db $67,$1f
	db $9e,$7f
	db $39,$fe
	; Tile $67
	db $01,$00
	db $1e,$01
	db $e1,$1f
	db $0f,$ff
	db $fe,$ff
	db $e0,$ff
	db $0f,$f0
	db $f0,$00
	; Tile $68
	db $02,$01
	db $04,$03
	db $0d,$03
	db $0b,$07
	db $13,$0f
	db $16,$0f
	db $2e,$1f
	db $2d,$1e
	; Tile $69
	db $00,$00
	db $01,$00
	db $02,$01
	db $02,$01
	db $05,$03
	db $09,$07
	db $33,$0f
	db $4e,$3f
	; Tile $6a
	db $2d,$1e
	db $2d,$1e
	db $2d,$1e
	db $49,$3e
	db $5a,$3c
	db $5a,$3c
	db $5a,$3c
	db $b2,$7c
	; Tile $6b
	db $00,$00
	db $00,$00
	db $00,$00
	db $00,$00
	db $00,$00
	db $03,$00
	db $06,$01
	db $09,$07
	; Tile $6c
	db $00,$00
	db $01,$00
	db $0e,$01
	db $31,$0f
	db $c7,$3f
	db $3e,$ff
	db $78,$ff
	db $e7,$f8
	; Tile $6d
	db $00,$00
	db $0f,$00
	db $e0,$1f
	db $0f,$ff
	db $ff,$ff
	db $f0,$ff
	db $07,$f8
	db $f0,$00
	; Tile $6e
	db $00,$00
	db $00,$00
	db $00,$00
	db $00,$00
	db $01,$00
	db $02,$01
	db $06,$01
	db $05,$03
	; Tile $6f
	db $0b,$07
	db $13,$0f
	db $26,$1f
	db $4c,$3f
	db $9d,$7e
	db $3a,$fc
	db $e4,$f8
	db $c8,$f0
	; Tile $70
	db $00,$00
	db $00,$00
	db $00,$00
	db $00,$00
	db $00,$00
	db $03,$00
	db $04,$03
	db $19,$07
	; Tile $71
	db $09,$07
	db $0b,$07
	db $17,$0f
	db $16,$0f
	db $26,$1f
	db $2d,$1e
	db $2d,$1e
	db $59,$3e
	; Tile $72
	db $00,$00
	db $00,$00
	db $00,$00
	db $01,$00
	db $01,$00
	db $02,$01
	db $04,$03
	db $05,$03
	; Tile $73
	db $2d,$1e
	db $2d,$1e
	db $2d,$1e
	db $0d,$3e
	db $58,$3e
	db $5a,$3c
	db $5a,$3c
	db $5a,$3c
	; Tile $74
	db $00,$00
	db $00,$00
	db $00,$07
	db $7f,$1f
	db $7f,$1f
	db $00,$07
	db $00,$00
	db $00,$00
	; Tile $75
	db $00,$18
	db $00,$18
	db $20,$18
	db $18,$ff
	db $18,$ff
	db $04,$18
	db $00,$18
	db $00,$18
HyperVoiceWaveTilesEnd:
	IF HyperVoiceWaveTilesEnd - HyperVoiceWaveTiles != HYPER_VOICE_TILE_COUNT * 16
		fail "Hyper Voice v2 tile data length mismatch"
	ENDC
