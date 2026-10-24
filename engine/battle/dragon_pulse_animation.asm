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
	; The 80%-speed resample repeats its exact wave phase every 20 display
	; frames. Each repeat is only a base translation: player +32 X/-16 Y,
	; enemy -32 X/+16 Y. Keep one 20-frame cycle instead of all 45 XY pairs.
	ld b, 0 ; cycle X translation magnitude
	ld c, 0 ; cycle Y translation magnitude
	cp 20
	jr c, .ageInCycle
	sub 20
	ld b, 32
	ld c, 16
	cp 20
	jr c, .ageInCycle
	sub 20
	ld b, 64
	ld c, 32
.ageInCycle
	push bc
	add a
	add a
	ld l, a
	ld h, 0
	ld bc, DragonPulseSlowCyclePositions
	add hl, bc
	pop bc
	ld a, [H_WHOSETURN]
	and a
	jr nz, .enemyCoords
	ld a, [hli]
	add b
	ld [wBaseCoordX], a
	ld a, [hl]
	sub c
	ld [wBaseCoordY], a
	jr .draw
.enemyCoords
	inc hl
	inc hl
	ld a, [hli]
	sub b
	ld [wBaseCoordX], a
	ld a, [hl]
	add c
	ld [wBaseCoordY], a
.draw
	ld a, DRAGON_PULSE_TILE_BASE
	ld [wDropletTile], a
	jp PlayGoldSacredFireAnimation.DrawLargeFlame

; One exact 20-frame period of the smooth 80%-speed Gold WAVE_TO_TARGET
; resample. For display age t, phase=floor(16*t/5); after 20 frames phase has
; advanced by 64 (one full turn), while the base path has translated exactly
; 32 px horizontally and 16 px vertically. Runtime applies that translation to
; cycles 1 and 2, preserving every coordinate from the former 45-entry table.
DragonPulseSlowCyclePositions:
	; ages 00-04
	db 67,91,115,53,68,94,112,58,69,97,111,63,71,101,109,67,72,102,108,70
	; ages 05-09
	db 74,103,106,73,75,101,103,73,76,98,102,72,78,95,100,69,79,90,99,66
	; ages 10-14
	db 81,83,97,61,83,78,95,58,84,73,94,55,86,69,92,51,87,66,91,50
	; ages 15-19
	db 90,63,90,49,92,63,88,51,93,64,87,54,95,67,85,57,96,70,84,62
DragonPulseSlowCyclePositionsEnd:
	IF DragonPulseSlowCyclePositionsEnd - DragonPulseSlowCyclePositions != 20 * 4
		fail "Dragon Pulse slow cycle table must contain 20 four-byte samples"
	ENDC
