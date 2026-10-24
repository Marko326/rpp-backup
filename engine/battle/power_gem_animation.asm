; ANIM-5.62.198: Power Gem's eight-object Polished Crystal arrangement,
; using ONLY Red++'s existing Rock Throw / Earth Power 16x16 stone pixels.
; The rocks rise, hover, then use PC's +8/-4 flight step in launch order.
; No new graphics, generic OAM engine, or move-effect behavior is introduced.

POWER_GEM_ROCK_TILE      EQU $60 ; four consecutive Rock Throw object tiles
POWER_GEM_ROCK_COUNT     EQU 8
POWER_GEM_RISE_FRAMES    EQU 12
POWER_GEM_FLIGHT_FRAMES  EQU 23
POWER_GEM_TOTAL_FRAMES   EQU 138 ; 8 births + 80 hover + launches + 32 tail

PlayPolishedCrystalPowerGemAnimation::
	; Reuse the exact Gen I rock already loaded by Earth Power: source
	; AnimationTileset1 tiles $0a/$0b/$1a/$1b form FrameBlock23.
	xor a
	ld [wWhichBattleAnimTileset], a
	callba LoadAnimationTileset
	ld hl, vSprites + POWER_GEM_ROCK_TILE * 16
	ld de, AnimationTileset1 + $0a * 16
	ld b, BANK(AnimationTileset1)
	ld c, 2
	call CopyVideoData
	ld hl, vSprites + (POWER_GEM_ROCK_TILE + 2) * 16
	ld de, AnimationTileset1 + $1a * 16
	ld b, BANK(AnimationTileset1)
	ld c, 2
	call CopyVideoData

	; Retain the project's normal Rock Throw brown; do not import PC gem art.
	ld a, 2
	ld [rSVBK], a
	ld hl, W2_SpritePaletteMap + POWER_GEM_ROCK_TILE
	ld a, ATK_PAL_BROWN
	ld b, 4
.setRockPalette
	ld [hli], a
	dec b
	jr nz, .setRockPalette
	ld a, 1
	ld [W2_ForceOBPUpdate], a
	xor a
	ld [rSVBK], a

	ld [wSubAnimCounter], a
.frameLoop
	call .PlayScheduledSound
	call .DrawAllRocks
	call DelayFrame
	call ClearSprites
	ld hl, wSubAnimCounter
	inc [hl]
	ld a, [hl]
	cp POWER_GEM_TOTAL_FRAMES
	jp c, .frameLoop

	; Restore the normal tile/palette pipeline for the next battle animation.
	callba _LoadAnimationTilesetPalettes
	ld a, $e4
	ld [rOBP0], a
	ld [rOBP1], a
	ret

.PlayScheduledSound
	; PC starts with Metronome, then sounds Shine during the 8 launches.
	ld a, [wSubAnimCounter]
	and a
	jr z, .metronome
	cp 88
	jr z, .shine
	cp 92
	jr z, .shine
	cp 98
	jr z, .shine
	cp 100
	jr z, .shine
	cp 104
	ret nz
.shine
	ld a, GSSFX_SHINE
	jp PlaySound
.metronome
	ld a, GSSFX_METRONOME
	jp PlaySound

.DrawAllRocks
	ld de, wOAMBuffer
	xor a
	ld [wSubAnimFrameDelay], a ; rock index, 0..7
.rockLoop
	; The position routine uses DE to index the data table. Preserve
	; the OAM write cursor; each visible rock consumes exactly 4 sprites.
	push de
	call .GetRockCenter
	pop de
	jr nc, .skipRock
	call .DrawRock
.skipRock
	ld hl, wSubAnimFrameDelay
	inc [hl]
	ld a, [hl]
	cp POWER_GEM_ROCK_COUNT
	jr c, .rockLoop
	ret

.GetRockCenter
	; Invisible before this object's staggered birth time.
	ld a, [wSubAnimCounter]
	ld hl, wSubAnimFrameDelay
	cp [hl]
	jp c, .hidden

	; Record: native PC animation/OAM X/Y, launch frame (from frame 0).
	ld a, [wSubAnimFrameDelay]
	ld b, a
	add a
	add b
	ld e, a
	ld d, 0
	ld hl, PowerGemRockPositions
	add hl, de
	ld a, [hli]
	ld b, a
	ld a, [hli]
	ld c, a
	ld e, [hl]

	; Player attacks: native +8/-4 motion.
	; Enemy attacks: raised spawn X'=180-X, Y'=Y-40; launch from the
	; same hovering position, moving left/down by 8/4 with no jump.
	ld a, [wSubAnimCounter]
	cp e
	jr nc, .flying

	; Birth -> rise -> hover. Keep the staggered timing, but transform
	; the resulting center like PC rather than altering a raw OAM position.
	ld hl, wSubAnimFrameDelay
	sub [hl]
	cp POWER_GEM_RISE_FRAMES
	jr c, .rising
	ld a, POWER_GEM_RISE_FRAMES
.rising
	ld d, a
	ld a, c
	sub d
	ld c, a
	ld a, [wSubAnimCounter]
	and 7
	cp 4
	jr c, .transformCenter
	inc c
	jr .transformCenter

.flying
	; PC PowerGemFunction3 calls BattleAnim_StepToTarget with A=8:
	; EACH flight frame advances X by +8 and Y by -4. The old 198A
	; separately clamped Y to 64/104, making a false horizontal tail.
	sub e                       ; elapsed frames since this rock launched
	cp POWER_GEM_FLIGHT_FRAMES
	jp nc, .hidden
	ld h, a                     ; age
	ld a, c
	sub POWER_GEM_RISE_FRAMES
	ld c, a                     ; final hovering Y (PC reference space)
	ld a, h
	add a
	add a
	ld d, a                     ; age * 4, vertical travel
	ld a, [H_WHOSETURN]
	and a
	ld a, c
	jr z, .playerFlightY
	add d                       ; enemy flies downward toward player
	jr .setFlightY
.playerFlightY
	sub d                       ; original 198B player path: Y-4/frame
.setFlightY
	ld c, a
	ld a, h
	add a
	add a
	add a                         ; age * 8, horizontal travel
	add b
	ld b, a
	cp 192                       ; PC exits visible flight at X >= $c0
	jr nc, .hidden

.transformCenter
	ld a, [H_WHOSETURN]
	and a
	jr z, .visible
	ld a, 180
	sub b
	ld b, a
	ld a, c
	sub 40                      ; identical to 198A enemy spawn/hover Y
	ld c, a
.visible
	scf
	ret
.hidden
	and a                       ; clear carry: this rock is not visible
	ret

.DrawRock
	; BC = center X/Y, DE = OAM cursor; same four-tile order as
	; Earth Power's complete existing Rock Throw 16x16 FrameBlock23.
	ld a, b
	sub 8
	ld l, a
	ld a, c
	sub 8
	ld h, a
	; top-left
	ld a, h
	ld [de], a
	inc de
	ld a, l
	ld [de], a
	inc de
	ld a, POWER_GEM_ROCK_TILE
	ld [de], a
	inc de
	xor a
	ld [de], a
	inc de
	; top-right
	ld a, h
	ld [de], a
	inc de
	ld a, l
	add 8
	ld [de], a
	inc de
	ld a, POWER_GEM_ROCK_TILE + 1
	ld [de], a
	inc de
	xor a
	ld [de], a
	inc de
	; bottom-left
	ld a, h
	add 8
	ld [de], a
	inc de
	ld a, l
	ld [de], a
	inc de
	ld a, POWER_GEM_ROCK_TILE + 2
	ld [de], a
	inc de
	xor a
	ld [de], a
	inc de
	; bottom-right
	ld a, h
	add 8
	ld [de], a
	inc de
	ld a, l
	add 8
	ld [de], a
	inc de
	ld a, POWER_GEM_ROCK_TILE + 3
	ld [de], a
	inc de
	xor a
	ld [de], a
	inc de
	ret

; Source PC birth centers and launch order: 8,7,6,4,1,3,5,2.
; (X, Y, launch frame). No foreign gem/stone graphic bytes are imported.
PowerGemRockPositions:
	db 46,  88,  98 ; #1
	db 24,  90, 104 ; #2
	db 36,  72, 100 ; #3
	db 44, 112,  96 ; #4
	db 30, 106, 102 ; #5
	db 64, 104,  92 ; #6
	db 54,  68,  90 ; #7
	db 72,  82,  88 ; #8
