; ANIM-5.62.194: Polished Crystal Play Rough on existing Red++ systems.
; PC stars/hearts/HIT are unchanged. PC Rock Smash's 16-frame scattering
; is approximated with sampled position data (no new object engine). Stock DrawFrameBlock
; handles art/OAM; Cross Chop's shared VBlank shake handles horizontal motion.
; Keep PC's simultaneous impact timing: draw newly spawned star/heart art
; first, then the short HIT, then surviving older particles. This uses the
; stock FrameBlock OAM lane instead of rebuilding a second renderer.

PLAY_ROUGH_TILE_BASE EQU $60
PLAY_ROUGH_STAR_TILES EQU 4
PLAY_ROUGH_HEART_TILES EQU 4
PLAY_ROUGH_HIT_TILES EQU 4
PLAY_ROUGH_TILE_COUNT EQU 12
PLAY_ROUGH_EVENT_COUNT EQU 20
PLAY_ROUGH_EVENT_SIZE EQU 5
PLAY_ROUGH_PARTICLE_LIFE EQU 16 ; PC Rock Smash 0x40 -> 0x30
PLAY_ROUGH_FRESH_FRAMES EQU 3 ; one PC birth every three frames
PLAY_ROUGH_HIT_LIFE EQU 6 ; PC Frameset_01: six displayed frames
PLAY_ROUGH_TOTAL_FRAMES EQU 73 ; last object at f57, 16-frame life

PlayPolishedCrystalPlayRoughAnimation::
	xor a
	ld [wBattleAnimSeamlessStage], a
	ld [wBattleAnimStageCarryTimer], a
	ld [wExtendedAnimFrameEffect], a
	ld [wSubAnimTransform], a
	ld [wWhichBattleAnimTileset], a
	callba LoadAnimationTileset
	ld hl, vSprites + PLAY_ROUGH_TILE_BASE * 16
	ld de, PlayRoughPCObjectTiles
	ld b, BANK(PlayRoughPCObjectTiles)
	ld c, PLAY_ROUGH_TILE_COUNT
	call CopyVideoData

	; The existing CGB object palette mapper works for these private slots.
	ld a, 2
	ld [rSVBK], a
	ld hl, W2_SpritePaletteMap + PLAY_ROUGH_TILE_BASE
	ld a, ATK_PAL_YELLOW
	ld b, PLAY_ROUGH_STAR_TILES
.starPal
	ld [hli], a
	dec b
	jr nz, .starPal
	ld a, ATK_PAL_RED
	ld b, PLAY_ROUGH_HEART_TILES
.heartPal
	ld [hli], a
	dec b
	jr nz, .heartPal
	ld a, ATK_PAL_GREY
	ld b, PLAY_ROUGH_HIT_TILES
.hitPal
	ld [hli], a
	dec b
	jr nz, .hitPal
	ld a, 1
	ld [W2_ForceOBPUpdate], a
	xor a
	ld [rSVBK], a

	; Reuse Cross Chop's stable VBlank-latched whole-screen shake.
	callba GoldBattleHorizontalShakeBegin
	xor a
	ld [wSubAnimCounter], a
.frameLoop
	call .PlayScheduledSound
	call .SetShake

	callba BattleAnimGetFrameDest
	ld a, l
	ld [wFBDestAddr + 1], a
	ld a, h
	ld [wFBDestAddr], a
	ld a, 2
	ld [wFBMode], a
	; PC spawns the colored burst before the concurrent HIT. Preserve
	; the short contact flash without letting its nine gray sprites
	; monopolize scanline priority ahead of the current burst.
	call .DrawFreshParticles
	call .DrawHits
	call .DrawOlderParticles

	call DelayFrame
	call ClearSprites
	ld hl, wSubAnimCounter
	inc [hl]
	ld a, [hl]
	cp PLAY_ROUGH_TOTAL_FRAMES
	jp c, .frameLoop

	callba GoldBattleHorizontalShakeEnd
	xor a
	ld [wFBMode], a
	callba _LoadAnimationTilesetPalettes
	ret

.SetShake
	; Cross Chop / Aeroblast VBlank-latched Window shake already enabled.
	ld a, [wSubAnimCounter]
	; PC's horizontal-shake effect continues beyond the 60-frame
	; spawn loop. Keep it active through the late flying particles,
	; then stage a neutral WX for two VBlanks before disarming.
	cp PLAY_ROUGH_TOTAL_FRAMES - 2
	jr nc, .neutralShake
	and 1
	jr nz, .rightShake
	ld a, 5
	jr .writeShake
.rightShake
	ld a, 9
	jr .writeShake
.neutralShake
	ld a, 7
.writeShake
	ld [wBattleAnimWX], a
	ret

.DrawHits
	ld hl, PlayRoughEvents
	ld b, PLAY_ROUGH_EVENT_COUNT
.hitLoop
	ld a, [hli]
	ld c, a
	ld a, [wSubAnimCounter]
	sub c
	jr c, .skipHit
	cp PLAY_ROUGH_HIT_LIFE
	jr nc, .skipHit
	push bc
	push hl
	; HL = x,y,kind,trajectory. Bit1 marks PC HIT_YFIX.
	inc hl
	inc hl
	bit 1, [hl]
	pop hl
	jr z, .noHit
	push hl
	call .DrawHitEvent
	pop hl
.noHit
	pop bc
.skipHit
	ld de, PLAY_ROUGH_EVENT_SIZE - 1
	add hl, de
	dec b
	jr nz, .hitLoop
	ret

.DrawHitEvent
	ld a, [hli]
	ld b, a
	ld a, [hl]
	ld c, a
	call .TransformCenter
	; TransformCenter returns the current PC hit center in B/C.
	; Do not use wBaseCoordX/Y left by the previous particle: that
	; draws this nine-sprite contact flash at the wrong impact point.
	ld a, b
	sub 12
	ld [wBaseCoordX], a
	ld a, c
	sub 12
	ld [wBaseCoordY], a
	ld bc, PlayRoughPCHitFrame
	jp PlayRoughNativeDrawFrame

.DrawFreshParticles
	xor a ; mode 0: births from the current three-frame event
	jr .DrawParticlesByAge

.DrawOlderParticles
	ld a, 1 ; mode 1: still-flying particles after the initial birth
.DrawParticlesByAge
	; Keep the age-group mode on the stack: native FrameBlock drawing
	; changes BC/DE/HL, so no volatile register may hold it across calls.
	push af
	ld hl, PlayRoughEventsEnd - PLAY_ROUGH_EVENT_SIZE
	ld b, PLAY_ROUGH_EVENT_COUNT
.particleLoop
	ld a, [hli]
	ld c, a
	ld a, [wSubAnimCounter]
	sub c
	jr c, .skipParticle
	cp PLAY_ROUGH_PARTICLE_LIFE
	jr nc, .skipParticle
	ld e, a ; age 0..15
	pop af
	push af
	and a
	jr nz, .olderOnly
	; The most recent birth gets first OAM priority. On the two
	; frames between births this is still the same PC object.
	ld a, e
	cp PLAY_ROUGH_FRESH_FRAMES
	jr nc, .skipParticle
	jr .slotReady
.olderOnly
	ld a, e
	cp PLAY_ROUGH_FRESH_FRAMES
	jr c, .skipParticle
.slotReady
	; Never emit only part of a 4-sprite star/heart FrameBlock.
	ld a, [wFBDestAddr + 1]
	cp 37 * 4
	jr nc, .skipParticle
	ld a, e ; restore this object's age for the PC motion table
	push bc
	push hl
	call .DrawParticleEvent
	pop hl
	pop bc
.skipParticle
	; HL is at the current event's X byte (birth + 1). -6
	; reaches the previous event's birth (5-byte entries).
	ld de, -(PLAY_ROUGH_EVENT_SIZE + 1)
	add hl, de
	dec b
	jr nz, .particleLoop
	pop af
	ret

.DrawParticleEvent
	; A = age 0..15, HL = original X,Y,kind,trajectory index.
	; The sampled offsets follow PC's Rock Smash parameter-dependent
	; horizontal 8.8 speed and 6-bit sine rise (integer-rounded).
	ld e, a
	ld a, [hli]
	ld [wBaseCoordX], a
	ld a, [hli]
	ld [wBaseCoordY], a
	ld a, [hli]
	push af ; kind: even=star, odd=heart
	ld a, [hl] ; PC trajectory 0..9
	ld l, a
	ld h, 0
	add hl, hl ; 2
	add hl, hl ; 4
	add hl, hl ; 8
	add hl, hl ; 16
	add hl, hl ; 32 bytes per trajectory
	ld a, e
	add a ; two bytes per sample
	ld e, a
	ld d, 0
	add hl, de
	ld de, PlayRoughPCMotionSamples
	add hl, de
	ld a, [hli] ; signed X delta
	ld b, a
	ld c, [hl] ; signed Y delta
	ld a, [wBaseCoordX]
	ld d, a
	ld a, [wBaseCoordY]
	ld e, a
	ld a, [H_WHOSETURN]
	and a
	jr nz, .enemy
	ld a, d
	add b
	ld b, a
	ld a, e
	add c
	ld c, a
	jr .center
.enemy
	; PC RELATIVE_X + fixY($ff): enemy mirror X, move target Y +40.
	ld a, 180
	sub d
	sub b
	ld b, a
	ld a, e
	add 40
	add c
	ld c, a
.center
	call .SetBurstBase
	pop af
	and 1
	ld bc, PlayRoughPCStarFrame
	jr z, .draw
	ld bc, PlayRoughPCHeartFrame
.draw
	jp PlayRoughNativeDrawFrame

.TransformCenter
	ld a, [H_WHOSETURN]
	and a
	jr z, .normal
	ld a, 180
	sub b
	ld b, a
	ld a, c
	add 40
	ld c, a
.normal
	ret

.SetBurstBase
	ld a, b
	sub 8
	ld [wBaseCoordX], a
	ld a, c
	sub 8
	ld [wBaseCoordY], a
	ret

.PlayScheduledSound
	; Match PC's two-pass 0/9/18/24 and 30/39/48/54 audio schedule.
	; The underlying Gen II SFX tracks are already in crysaudio/sfx.asm.
	ld a, [wSubAnimCounter]
	cp 0
	jr z, .boneClub
	cp 30
	jr z, .boneClub
	cp 9
	jr z, .doubleSlap
	cp 39
	jr z, .doubleSlap
	cp 18
	jr z, .sludge
	cp 48
	jr z, .sludge
	cp 24
	jr z, .karateChop
	cp 54
	ret nz
.karateChop
	ld a, GSSFX_KARATE_CHOP
	jp PlaySound
.boneClub
	ld a, GSSFX_BONE_CLUB
	jp PlaySound
.doubleSlap
	ld a, GSSFX_DOUBLE_SLAP
	jp PlaySound
.sludge
	ld a, GSSFX_SLUDGE_BOMB
	jp PlaySound

; Original PC spawn centers/modes/parameters, repeated at frames +30.
; entry: birth, center X, center Y, kind (bit0 heart, bit1 HIT), path 0..9.
PlayRoughEvents:
	db  0, 128, 48, 2, 0
	db  3, 144, 64, 1, 1
	db  6, 144, 64, 2, 2
	db  9, 120, 52, 1, 3
	db 12, 120, 52, 2, 4
	db 15, 152, 48, 0, 5
	db 18, 152, 48, 3, 6
	db 21, 136, 56, 0, 7
	db 24, 136, 56, 3, 8
	db 27, 128, 48, 0, 9
	db 30, 128, 48, 2, 0
	db 33, 144, 64, 1, 1
	db 36, 144, 64, 2, 2
	db 39, 120, 52, 1, 3
	db 42, 120, 52, 2, 4
	db 45, 152, 48, 0, 5
	db 48, 152, 48, 3, 6
	db 51, 136, 56, 0, 7
	db 54, 136, 56, 3, 8
	db 57, 128, 48, 0, 9
PlayRoughEventsEnd:
	ASSERT PlayRoughEventsEnd - PlayRoughEvents == PLAY_ROUGH_EVENT_COUNT * PLAY_ROUGH_EVENT_SIZE

; PC Rock Smash path samples. Approximated from 6-bit Sine and the
; six horizontal 8.8 fixed-point scatter velocities for the ten params.
; Each pair is signed dx,dy from the original spawn center, ages 0..15.
PlayRoughPCMotionSamples:
	; $28: +1px/frame X, sine amplitude 40
	db 0, 0, 1, -4, 2, -8, 3, -12, 4, -15, 5, -19, 6, -22, 7, -25
	db 8, -28, 9, -31, 10, -33, 11, -35, 12, -37, 13, -38, 14, -39, 15, -40
	; $5c: +1px/frame X, sine amplitude 28
	db 0, 0, 1, -3, 2, -5, 3, -8, 4, -11, 5, -13, 6, -16, 7, -18
	db 8, -20, 9, -22, 10, -23, 11, -25, 12, -26, 13, -27, 14, -27, 15, -28
	; $10: +2px/frame X, sine amplitude 16
	db 0, 0, 2, -2, 4, -3, 6, -5, 8, -6, 10, -8, 12, -9, 14, -10
	db 16, -11, 18, -12, 20, -13, 22, -14, 24, -15, 26, -15, 28, -16, 30, -16
	; $e8: -1px/frame X, sine amplitude 40
	db 0, 0, -1, -4, -2, -8, -3, -12, -4, -15, -5, -19, -6, -22, -7, -25
	db -8, -28, -9, -31, -10, -33, -11, -35, -12, -37, -13, -38, -14, -39, -15, -40
	; $9c: -1.5px/frame X, sine amplitude 28
	db 0, 0, -1, -3, -3, -5, -4, -8, -6, -11, -7, -13, -9, -16, -10, -18
	db -12, -20, -13, -22, -15, -23, -16, -25, -18, -26, -19, -27, -21, -27, -22, -28
	; $d0: -2px/frame X, sine amplitude 16
	db 0, 0, -2, -2, -4, -3, -6, -5, -8, -6, -10, -8, -12, -9, -14, -10
	db -16, -11, -18, -12, -20, -13, -22, -14, -24, -15, -26, -15, -28, -16, -30, -16
	; $1c: +1.5px/frame X, sine amplitude 28
	db 0, 0, 1, -3, 3, -5, 4, -8, 6, -11, 7, -13, 9, -16, 10, -18
	db 12, -20, 13, -22, 15, -23, 16, -25, 18, -26, 19, -27, 21, -27, 22, -28
	; $50: +1px/frame X, sine amplitude 16
	db 0, 0, 1, -2, 2, -3, 3, -5, 4, -6, 5, -8, 6, -9, 7, -10
	db 8, -11, 9, -12, 10, -13, 11, -14, 12, -15, 13, -15, 14, -16, 15, -16
	; $dc: -1.5px/frame X, sine amplitude 28
	db 0, 0, -1, -3, -3, -5, -4, -8, -6, -11, -7, -13, -9, -16, -10, -18
	db -12, -20, -13, -22, -15, -23, -16, -25, -18, -26, -19, -27, -21, -27, -22, -28
	; $90: -2px/frame X, sine amplitude 16
	db 0, 0, -2, -2, -4, -3, -6, -5, -8, -6, -10, -8, -12, -9, -14, -10
	db -16, -11, -18, -12, -20, -13, -22, -14, -24, -15, -26, -15, -28, -16, -30, -16
PlayRoughPCMotionSamplesEnd:
	ASSERT PlayRoughPCMotionSamplesEnd - PlayRoughPCMotionSamples == 10 * 16 * 2

; Polished Crystal source pixels (unmodified 2bpp indices);
PlayRoughPCObjectTiles:
	; STAR tile 0
	db $00, $00, $03, $03, $07, $04, $07, $04
	db $0f, $08, $ff, $f0, $ff, $80, $7f, $40
	; STAR tile 1
	db $00, $00, $00, $00, $80, $80, $80, $80
	db $c0, $40, $fc, $3c, $fc, $04, $f8, $08
	; STAR tile 2
	db $3f, $30, $1f, $10, $1f, $10, $3f, $23
	db $3c, $2c, $30, $30, $00, $00, $00, $00
	; STAR tile 3
	db $f0, $30, $e0, $20, $e0, $20, $f0, $10
	db $f0, $d0, $30, $30, $00, $00, $00, $00
	; HEART tile 0
	db $00, $00, $00, $00, $00, $18, $00, $3c
	db $00, $7f, $00, $7f, $00, $7f, $00, $7f
	; HEART tile 1
	db $00, $00, $00, $00, $00, $60, $00, $f0
	db $00, $f8, $00, $f8, $00, $f8, $00, $f8
	; HEART tile 2
	db $00, $3f, $00, $1f, $00, $0f, $00, $07
	db $00, $03, $00, $00, $00, $00, $00, $00
	; HEART tile 3
	db $00, $f0, $00, $e0, $00, $c0, $00, $80
	db $00, $00, $00, $00, $00, $00, $00, $00
	; HIT_YFIX tile 0
	db $00, $00, $00, $00, $00, $00, $00, $18
	db $08, $16, $06, $09, $07, $08, $03, $04
	; HIT_YFIX tile 1
	db $00, $18, $18, $24, $18, $24, $3c, $42
	db $3c, $42, $7e, $81, $ff, $00, $ff, $00
	; HIT_YFIX tile 2
	db $03, $04, $07, $18, $1f, $60, $7f, $80
	db $7f, $80, $1f, $60, $07, $18, $03, $04
	; HIT_YFIX tile 3
	db $ff, $00, $ff, $00, $ff, $00, $ff, $00
	db $ff, $00, $ff, $00, $ff, $00, $ff, $00
PlayRoughPCObjectTilesEnd:
	ASSERT PlayRoughPCObjectTilesEnd - PlayRoughPCObjectTiles == PLAY_ROUGH_TILE_COUNT * 16
