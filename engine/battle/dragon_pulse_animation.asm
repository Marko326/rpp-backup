; ANM-5.61.97: Gold/Crystal Dragon Rage renderer used by Dragon Pulse.
;
; The Gold script launches 16 identical 16x16 fire objects four frames apart.
; RPP keeps the same art/path and Dragon palette, but deliberately runs the
; projectile stream at 80% of Gold's speed: launches are five frames apart and
; every projectile takes 45 moving frames instead of 36 to reach the target.
;
; This is a time-resample, not frame skipping. Each display frame has its own
; precomputed Gold-path position, so horizontal motion stays monotonic and the
; sine wave keeps advancing continuously without a stop/start cadence.
; Enemy use keeps Gold's RELATIVE_X / fixY $90 coordinate transform.

DRAGON_PULSE_TILE_BASE    EQU $60
DRAGON_PULSE_TILE_COUNT   EQU 2
DRAGON_PULSE_SPAWN_STEP   EQU 5
DRAGON_PULSE_OBJECTS      EQU 16
DRAGON_PULSE_MOVING_FRAMES EQU 45
DRAGON_PULSE_OBJECT_LIFE  EQU 46 ; 45 moving frames + Gold's deinit-frame hold
; Gold's 16-launch loop becomes 80 frames instead of 64; its final anim_wait 64
; is unchanged, matching the original script structure while slowing the stream.
DRAGON_PULSE_TOTAL_FRAMES EQU 146

PlayGoldDragonPulseAnimation::
	xor a
	ld [wWhichBattleAnimTileset], a
	callba LoadAnimationTileset

	; Gold BATTLE_ANIM_GFX_FIRE OAM set $0A uses processed fire tiles #0/#1.
	; Sacred Fire already stores the exact six-tile Gold fire sheet in this bank.
	ld hl, vSprites + DRAGON_PULSE_TILE_BASE * 16
	ld de, GoldSacredFireTiles
	ld b, BANK(GoldSacredFireTiles)
	ld c, DRAGON_PULSE_TILE_COUNT
	call CopyVideoData

	; Keep Gold's sprite art but use RPP's newer Dragon blue-violet palette.
	ld d, DRAGON
	ld e, BATTLE_TYPE_PAL_TILESET1
	callba LoadBattleAnimTypePalette_Sprite
	ld a, 2
	ld [rSVBK], a
	ld hl, W2_SpritePaletteMap + DRAGON_PULSE_TILE_BASE
	ld b, DRAGON_PULSE_TILE_COUNT
	ld a, BATTLE_TYPE_PAL_TILESET1
.paletteLoop
	ld [hli], a
	dec b
	jr nz, .paletteLoop
	ld a, 1
	ld [W2_ForceOBPUpdate], a
	xor a
	ld [rSVBK], a

	xor a
	ld [wSubAnimCounter], a
.frameLoop
	ld de, wOAMBuffer
	ld c, 0 ; spawn frame
	ld b, DRAGON_PULSE_OBJECTS
.projectileLoop
	ld a, [wSubAnimCounter]
	sub c ; age = current frame - spawn frame
	jr c, .nextProjectile
	cp DRAGON_PULSE_OBJECT_LIFE
	jr nc, .nextProjectile

	; Play Ember exactly when this projectile is born. Keeping the sound tied to
	; age 0 also makes the five-frame launch cadence exact without modulo tricks.
	push bc
	push af
	and a
	jr nz, .noSpawnSound
	push de
	ld a, GSSFX_EMBER
	call PlaySound
	pop de
.noSpawnSound
	pop af
	call .DrawProjectileAge
	pop bc
.nextProjectile
	ld a, c
	add DRAGON_PULSE_SPAWN_STEP
	ld c, a
	dec b
	jr nz, .projectileLoop

	call DelayFrame
	call ClearSprites
	ld hl, wSubAnimCounter
	inc [hl]
	ld a, [hl]
	cp DRAGON_PULSE_TOTAL_FRAMES
	jr c, .frameLoop

	xor a
	ld [wSubAnimCounter], a
	ret

.DrawProjectileAge
	; A = projectile age 0..45, DE = next OAM entry.
	; Ages 0..44 are a smooth 5:4 time-resample of Gold's 0..35 moving frames.
	; Age 45 repeats the final position, preserving Gold's deinit-frame hold.
	cp DRAGON_PULSE_MOVING_FRAMES
	jr c, .movingAge
	ld a, DRAGON_PULSE_MOVING_FRAMES - 1
.movingAge
	; Four bytes per age: player X,Y then enemy X,Y. The table bakes in Gold's
	; sine/cosine offsets plus RELATIVE_X/fixY, sampled at 80% timeline speed.
	add a
	add a
	ld l, a
	ld h, 0
	ld bc, DragonPulseSlowPositions
	add hl, bc
	ld a, [H_WHOSETURN]
	and a
	jr nz, .enemyCoords
	ld a, [hli]
	ld [wBaseCoordX], a
	ld a, [hl]
	ld [wBaseCoordY], a
	jr .draw
.enemyCoords
	inc hl
	inc hl
	ld a, [hli]
	ld [wBaseCoordX], a
	ld a, [hl]
	ld [wBaseCoordY], a
.draw
	ld a, DRAGON_PULSE_TILE_BASE
	ld [wDropletTile], a
	jp PlayGoldSacredFireAnimation.DrawLargeFlame

; Smooth 80%-speed resample of BATTLE_ANIM_FUNC_WAVE_TO_TARGET.
; For display age t=0..44:
;   logical X = 66 + round(8*t/5), logical Y = 91 - round(4*t/5)
;   wave phase = floor(16*t/5), with Gold's d=16 Q8 sine/cosine behavior.
; Rounding the base coordinates keeps horizontal motion advancing every frame;
; the final sample lands on the same Gold endpoint used by original age 35.
DragonPulseSlowPositions:
	; ages 00-04
	db 67,91,115,53,68,94,112,58,69,97,111,63,71,101,109,67,72,102,108,70
	; ages 05-09
	db 74,103,106,73,75,101,103,73,76,98,102,72,78,95,100,69,79,90,99,66
	; ages 10-14
	db 81,83,97,61,83,78,95,58,84,73,94,55,86,69,92,51,87,66,91,50
	; ages 15-19
	db 90,63,90,49,92,63,88,51,93,64,87,54,95,67,85,57,96,70,84,62
	; ages 20-24
	db 99,75,83,69,100,78,80,74,101,81,79,79,103,85,77,83,104,86,76,86
	; ages 25-29
	db 106,87,74,89,107,85,71,89,108,82,70,88,110,79,68,85,111,74,67,82
	; ages 30-34
	db 113,67,65,77,115,62,63,74,116,57,62,71,118,53,60,67,119,50,59,66
	; ages 35-39
	db 122,47,58,65,124,47,56,67,125,48,55,70,127,51,53,73,128,54,52,78
	; ages 40-44
	db 131,59,51,85,132,62,48,90,133,65,47,95,135,69,45,99,136,70,44,102
DragonPulseSlowPositionsEnd:
	IF DragonPulseSlowPositionsEnd - DragonPulseSlowPositions != DRAGON_PULSE_MOVING_FRAMES * 4
		fail "Dragon Pulse slow position table must contain 45 four-byte samples"
	ENDC
