; ANM-5.61.62: Gold/Crystal-style Flame Wheel for expanded move FLAME_WHEEL.
;
; Reuse the exact Gold fire tiles, red OBJ palette, Ember SFX and the existing
; Sacred Fire lunge/render helpers. Only Flame Wheel's own timeline and orbit
; behavior live here, so this adds no duplicate graphics/audio payload.
;
; Gold/Crystal visible timeline reproduced here from the Gen II scheduler:
;   - 8 Ember flames spawn at frames 0,7,14,...,49 around the user at (48,96).
;   - each flame uses SmokeFlameWheel's radius-24 circle, 5+5-frame Ember loop,
;     rises 1 px every 4 frames, and remains visible for 100 frames.
;   - the 96-count tail wait finishes at frame 153; TargetObj_1Row then occupies
;     frames 153..159 before Tackle begins at frame 160.
;   - Gen I cannot reproduce Gold's scanline 2-px Tackle motion exactly, so the
;     existing one-tile RPP lunge is shown over the matching nonzero-motion window.
;   - FLASH_INVERTED + Ember + three Fire Blast flames begin at frame 165.
;   - Gold's one-row target conversion consumes animation-object index 9, so the
;     later anim_incobj 9 does not redirect the upper Fire Blast flame; it rises straight.
;   - FLASH_INVERTED ($4,$3) produces one five-frame inverted pulse after five
;     initial normal impact frames, then returns to the normal palette.
;   - the final visible impact frame is age 23 (global frame 188).
; Enemy-side RELATIVE_X transforms use Flame Wheel fixY $98 and Fire Blast fixY $90.

FLAME_WHEEL_TILE_BASE       EQU $60
FLAME_WHEEL_TILE_COUNT      EQU 6
FLAME_WHEEL_ORBIT_LIFE      EQU 100
FLAME_WHEEL_ORBIT_STEP      EQU 7
FLAME_WHEEL_ORBIT_SPAWN_END EQU 56
FLAME_WHEEL_ORBIT_END       EQU 153
FLAME_WHEEL_TARGETOBJ_END   EQU 160
FLAME_WHEEL_USER_SHIFT      EQU 162
FLAME_WHEEL_IMPACT_START    EQU 165
FLAME_WHEEL_USER_RESTORE    EQU 171
FLAME_WHEEL_TOTAL_FRAMES    EQU 189

PlayGoldFlameWheelAnimation::
	; Reuse Sacred Fire's exact six Gold fire tiles in the same private VRAM slots.
	xor a
	ld [wWhichBattleAnimTileset], a
	callba LoadAnimationTileset
	ld hl, vSprites + FLAME_WHEEL_TILE_BASE * 16
	ld de, GoldSacredFireTiles
	ld b, BANK(GoldSacredFireTiles)
	ld c, FLAME_WHEEL_TILE_COUNT
	call CopyVideoData
	call PlayGoldSacredFireAnimation.InstallGoldRedPalette

	xor a
	ld [wSubAnimCounter], a

.orbitLoop
	; Gen II anim_wait 6 leaves six intervening playframes, so the visible spawn
	; cadence is 7 frames: 0,7,14,21,28,35,42,49.
	ld a, [wSubAnimCounter]
	cp FLAME_WHEEL_ORBIT_SPAWN_END
	jr nc, .noOrbitSound
.mod7
	cp FLAME_WHEEL_ORBIT_STEP
	jr c, .gotOrbitRemainder
	sub FLAME_WHEEL_ORBIT_STEP
	jr .mod7
.gotOrbitRemainder
	and a
	jr nz, .noOrbitSound
	ld a, GSSFX_EMBER
	call PlaySound
.noOrbitSound

	ld de, wOAMBuffer
	ld c, 0
.orbitObjectLoop
	ld a, [wSubAnimCounter]
	sub c
	jr c, .nextOrbitObject
	cp FLAME_WHEEL_ORBIT_LIFE
	jr nc, .nextOrbitObject
	push bc
	call .DrawOrbitFlame
	pop bc
.nextOrbitObject
	ld a, c
	add FLAME_WHEEL_ORBIT_STEP
	ld c, a
	cp FLAME_WHEEL_ORBIT_SPAWN_END
	jr c, .orbitObjectLoop

	call DelayFrame
	call ClearSprites
	ld hl, wSubAnimCounter
	inc [hl]
	ld a, [hl]
	cp FLAME_WHEEL_ORBIT_END
	jr c, .orbitLoop

	; Gold converts the target BG row to an OBJ for these seven visible frames.
	; RPP keeps the target BG visible, matching the existing Sacred Fire compromise,
	; but preserves the real scheduler timing before Tackle starts.
.targetObjWait
	call DelayFrame
	call ClearSprites
	ld hl, wSubAnimCounter
	inc [hl]
	ld a, [hl]
	cp FLAME_WHEEL_TARGETOBJ_END
	jr c, .targetObjWait

	; Gold Tackle initializes at frame 160 and its visible displacement first becomes
	; nonzero at frame 162. Gen I cannot scanline-scroll the battler by 2 px/frame,
	; so shift one tile only for that same active-motion window.
.lungeWait
	ld a, [wSubAnimCounter]
	cp FLAME_WHEEL_USER_SHIFT
	call z, .ShiftUserForward
	call DelayFrame
	call ClearSprites
	ld hl, wSubAnimCounter
	inc [hl]
	ld a, [hl]
	cp FLAME_WHEEL_IMPACT_START
	jr c, .lungeWait

	ld a, GSSFX_EMBER
	call PlaySound

.impactLoop
	ld a, [wSubAnimCounter]
	sub FLAME_WHEEL_IMPACT_START
	call .UpdateImpactFlash

	; Gold's Tackle BG effect is visibly back at zero by frame 171.
	ld a, [wSubAnimCounter]
	cp FLAME_WHEEL_USER_RESTORE
	call z, .RestoreUserPosition

	ld a, [wSubAnimCounter]
	sub FLAME_WHEEL_IMPACT_START
	ld de, wOAMBuffer
	push af
	call .DrawImpactCenter
	pop af
	push af
	call .DrawImpactLeft
	pop af
	call .DrawImpactRight

	call DelayFrame
	call ClearSprites
	ld hl, wSubAnimCounter
	inc [hl]
	ld a, [hl]
	cp FLAME_WHEEL_TOTAL_FRAMES
	jr c, .impactLoop

	; Return normal RPP battle palettes and clear the helper's scratch counter.
	xor a
	ld [wSubAnimCounter], a
	callba LoadAttackSpritePalettes
	ld a, $e4
	ld [rOBP0], a
	ld [rOBP1], a
	callba AnimationResetScreenPalette
	ret

.DrawOrbitFlame
	; A = object age 0..99, DE = next OAM lane.
	; SmokeFlameWheel advances phase by 2 each frame. The circular component has
	; a 32-frame period; VAR2 contributes the separate -1 px rise every 4 frames.
	push af
	ld l, a
	and 31
	add a
	ld l, a
	ld h, 0
	ld bc, FlameWheelOrbitOffsets
	add hl, bc
	ld b, [hl]
	inc hl
	ld c, [hl]
	pop af
	push af
	srl a
	srl a
	ld h, a
	ld a, c
	sub h
	ld c, a

	ld a, [H_WHOSETURN]
	and a
	jr nz, .orbitEnemy
	ld a, 48
	add b
	ld [wBaseCoordX], a
	ld a, 96
	add c
	ld [wBaseCoordY], a
	jr .orbitCenterReady
.orbitEnemy
	ld a, 132 ; 180 - 48
	sub b
	ld [wBaseCoordX], a
	ld a, 56 ; $98 - 96
	add c
	ld [wBaseCoordY], a
.orbitCenterReady
	pop af
	; Frameset_Ember uses duration 4, which is five visible frames in Gen II:
	; OAM $0F for ages 0..4, $10 for 5..9, then restart every ten frames.
.mod10
	cp 10
	jr c, .gotEmberRemainder
	sub 10
	jr .mod10
.gotEmberRemainder
	cp 5
	ld a, FLAME_WHEEL_TILE_BASE + 4 ; Gold OAM set $0F
	jr c, .orbitTileReady
	inc a                              ; Gold OAM set $10
.orbitTileReady
	jp PlayGoldSacredFireAnimation.DrawSmallFlame

.DrawImpactCenter
	; Fire Blast param $1 is the upward flame. In Gold, TargetObj_1Row first queues
	; a temporary battler-row animation object as index 9 after the eight orbit flames,
	; so Flame Wheel's later anim_incobj 9 targets that row object, not this flame.
	; The visible upper flame therefore keeps X fixed and rises one pixel per frame.
	push af
	ld b, 0
	cpl
	inc a
	ld c, a
	call PlayGoldSacredFireAnimation.SetImpactCenter
	pop af
	jp .DrawImpactFrame

.DrawImpactLeft
	; Param $4: age 0 stays at spawn; later frames move down-left 1 px/frame.
	push af
	ld c, a
	cpl
	inc a
	ld b, a
	call PlayGoldSacredFireAnimation.SetImpactCenter
	pop af
	jp .DrawImpactFrame

.DrawImpactRight
	; Param $5: age 0 stays at spawn; later frames move down-right 1 px/frame.
	push af
	ld b, a
	ld c, a
	call PlayGoldSacredFireAnimation.SetImpactCenter
	pop af
	jp .DrawImpactFrame

.DrawImpactFrame
	; Frameset_Burned also uses duration 4 = five visible frames per OAM pose.
	; The Flame Wheel script ends at age 23, during the third large-flame pose.
	cp 5
	jr nc, .impactNotTile5
	ld a, FLAME_WHEEL_TILE_BASE + 5
	jp PlayGoldSacredFireAnimation.DrawSmallFlame
.impactNotTile5
	cp 10
	jr nc, .impactLarge2
	ld a, FLAME_WHEEL_TILE_BASE + 4
	jp PlayGoldSacredFireAnimation.DrawSmallFlame
.impactLarge2
	cp 15
	jr nc, .impactLarge0
	ld a, FLAME_WHEEL_TILE_BASE + 2
	jr .drawImpactLarge
.impactLarge0
	cp 20
	jr nc, .impactLarge2Again
	ld a, FLAME_WHEEL_TILE_BASE
	jr .drawImpactLarge
.impactLarge2Again
	ld a, FLAME_WHEEL_TILE_BASE + 2
.drawImpactLarge
	ld [wDropletTile], a
	jp PlayGoldSacredFireAnimation.DrawLargeFlame

.UpdateImpactFlash
	; Gold FLASH_INVERTED ($4,$3) begins on the normal palette, then applies one
	; five-playframe inverted pulse and returns to normal. This intentionally does
	; not use RPP's legacy short flash: that routine adds a white-out frame which
	; Gold Flame Wheel never displays.
	cp 5
	jr z, .flashInverted
	cp 10
	ret nz
	ld a, $e4
	ld [rBGP], a
	ret
.flashInverted
	ld a, $1b
	ld [rBGP], a
	ret

.ShiftUserForward
	call .CurrentUserInvulnerable
	ret nz
	callba SacredFireShiftUserForwardNoDelay
	ret

.RestoreUserPosition
	call .CurrentUserInvulnerable
	ret nz
	callba SacredFireRestoreUserPositionNoDelay
	ret

.CurrentUserInvulnerable
	ld a, [H_WHOSETURN]
	and a
	ld a, [wPlayerBattleStatus1]
	jr z, .gotUserStatus
	ld a, [wEnemyBattleStatus1]
.gotUserStatus
	and 1 << Invulnerable
	ret

FlameWheelOrbitOffsets:
	; Exact Gold SmokeFlameWheel radius-24 sine/cosine component for phases 0..31.
	; The independent upward drift is applied at runtime from object age / 4.
	db 24,0, 23,0, 22,1, 19,1, 16,2, 13,2, 9,2, 4,2
	db 0,3, -4,2, -9,2, -13,2, -16,2, -19,1, -22,1, -23,0
	db -24,0, -23,-1, -22,-2, -19,-2, -16,-2, -13,-3, -9,-3, -4,-3
	db 0,-3, 4,-3, 9,-3, 13,-3, 16,-2, 19,-2, 22,-2, 23,-1
FlameWheelOrbitOffsetsEnd:
	IF FlameWheelOrbitOffsetsEnd - FlameWheelOrbitOffsets != 32 * 2
		fail "Flame Wheel orbit table must contain exactly 32 xy pairs"
	ENDC
