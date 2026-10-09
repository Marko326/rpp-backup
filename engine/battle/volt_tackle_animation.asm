; VTA-5.62.43: Ruby-inspired Volt Tackle renderer, pacing/impact pass.
;
; The GBA script's identity is kept, but expressed with the project's already-
; verified Gen II animation vocabulary:
;   1) Gold Spark's Thunder Wave charge, then Gold Quick Attack speed-line vanish;
;   2) five alternating horizontal electric sweeps, matching Ruby's task 0..4;
;   3) a hard target electrocution with VBlank-latched +/-2 px shake;
;   4) user redraw. Ruby's final attacker-side electricity is intentionally omitted.
;
; VTC-5.62.51 restores the original alternating screen-wide sweeps while
; fixing the first release and last arrival to the size-aware body centers.
;
; VTA-5.62.43 keeps the stock post-move damage feedback alive. Phase 1 cleared
; wAnimationType at the end, which accidentally removed the project's normal
; hit reaction after Volt Tackle.
;
; Ruby's alpha blending / affine circle-of-light cannot be reproduced literally on
; this renderer. Gold Spark's real opening charge graphics are reused before the
; SPEED_LINE disappearance, but without its inverted BG flash. All lightning
; tiles/palettes are preloaded before hiding the attacker to avoid dead air.

VOLT_TACKLE_SWEEP_COUNT        EQU 5
VOLT_TACKLE_SWEEP_FRAMES       EQU 8
VOLT_TACKLE_SWEEP_TOTAL        EQU VOLT_TACKLE_SWEEP_COUNT * VOLT_TACKLE_SWEEP_FRAMES
VOLT_TACKLE_SWEEP_SPRITES      EQU 6
; VTA-5.62.43: Retain timing knobs for future changes; final values are 2/0.
; One sweep has eight poses; changing the hold time changes pacing, not the path.
VOLT_TACKLE_SWEEP_STEP_FRAMES  EQU 2 ; 1..8 VBlanks per electric pose
; Additional blank frames AFTER Quick Attack hides and BEFORE sweep #1.
; 0 = immediate, 2 = slight beat, 4 = audible pause, 8 = pronounced pause.
VOLT_TACKLE_VANISH_DELAY      EQU 0 ; 0..60 frames; zero is handled explicitly

IF VOLT_TACKLE_SWEEP_STEP_FRAMES < 1 || VOLT_TACKLE_SWEEP_STEP_FRAMES > 8
	fail "Volt Tackle sweep step must be 1..8 frames"
ENDC
IF VOLT_TACKLE_VANISH_DELAY < 0 || VOLT_TACKLE_VANISH_DELAY > 60
	fail "Volt Tackle vanish delay must be 0..60 frames"
ENDC

VOLT_TACKLE_IMPACT_FRAMES      EQU 24
VOLT_TACKLE_IMPACT_SHAKE_END   EQU 18
VOLT_TACKLE_ELECTRIC_TILE_0    EQU SPARK_LIGHTNING_TILE_BASE + 14
VOLT_TACKLE_ELECTRIC_TILE_1    EQU SPARK_LIGHTNING_TILE_BASE + 15
VOLT_TACKLE_ELECTRIC_TILE_2    EQU SPARK_LIGHTNING_TILE_BASE + 16

PlayRubyVoltTackleAnimation::
	; Preload the complete Gold Spark electric set while the attacker is still
	; visible. Phase 2 loaded this only after the mon disappeared, producing the
	; ~0.4 s empty beat visible in capture. Quick Attack needs just tile $60, so
	; load Spark first and temporarily replace that one tile for SPEED_LINE.
	callba LoadGoldSparkElectricAssets
	; VTA-5.62.43: this is the *actual first stage of Gold Spark*:
	; Thunder Wave expands around the visible attacker for 24 frames with the
	; Zap Cannon charge SFX. Do not use Spark's inverted BGP screen flash.
	callba PlayGoldSparkVoltTackleCharge
	callba LoadGoldQuickAttackSpeedLine

	ld e,GOLD_QUICK_ATTACK_VOLT_APPROACH
	callba PlayGoldQuickAttackPhase

	; Optional beat between disappearance and first sweep; no 0-frame call,
	; since DelayFrames with C=0 could underflow into a 256-frame wait.
IF VOLT_TACKLE_VANISH_DELAY > 0
	ld c,VOLT_TACKLE_VANISH_DELAY
	call DelayFrames
ENDC

	; SPEED_LINE overwrote Spark tile $60 only. Volt Tackle deliberately draws
	; its sweep/burst from lightning tiles $6e-$70 (base+14..16), so no post-vanish
	; VRAM reload is needed at all: the first electric pass can begin immediately.

	; VTC-5.62.49: one size index drives release, five lanes and final impact.
	; Cache after the prelude, before the animation's own sweep frames.
	call .CacheEnemyFrontSize
	xor a
	ld [wSubAnimCounter],a
.sweepLoop
	call .MaybePlaySweepSfx
	ld de,wOAMBuffer
	call .DrawSweepFrame
	; The configured pose hold controls sweep speed, independently of post-vanish
	; wait. Ruby's original separately-lingering sparks are still approximated.
	ld c,VOLT_TACKLE_SWEEP_STEP_FRAMES
	call DelayFrames
	call ClearSprites
	ld hl,wSubAnimCounter
	inc [hl]
	ld a,[hl]
	cp VOLT_TACKLE_SWEEP_TOTAL
	jr c,.sweepLoop

	; Ruby hits hard on the fifth pass, shakes the target, and overlays animated
	; electricity. The target is BG-backed in this engine, so use the existing
	; full-frame WX latch for a short +/-2 px impact while the electric OBJ stays
	; centered on the victim. Only player use keeps this horizontal impact shake:
	; enemy use gets the standard vertical hit feedback after the move.
	ld a,GSSFX_THUNDERSHOCK
	call PlaySound
	ld a,7
	ld [wBattleAnimWX],a
	xor a
	ld [wBattleAnimWXEnabled],a
	ld a,[H_WHOSETURN]
	and a
	jr nz,.impactReady
	ld a,1
	ld [wBattleAnimWXEnabled],a
.impactReady
	xor a
	ld [wSubAnimCounter],a
.impactLoop
	call .SetImpactShake
	ld de,wOAMBuffer
	call .DrawTargetElectric
	call DelayFrame
	call ClearSprites
	ld hl,wSubAnimCounter
	inc [hl]
	ld a,[hl]
	cp VOLT_TACKLE_IMPACT_FRAMES
	jr c,.impactLoop
	; The final impact frames were already presented at base WX, so the latch
	; can now be disabled without leaking the final +/-2 position into battle UI.
	ld a,7
	ld [wBattleAnimWX],a
	xor a
	ld [wBattleAnimWXEnabled],a

	; Ruby brings the attacker back by blinking it in from off-screen. Keep the
	; established Gold Quick Attack redraw for now. Ruby then shocks the attacker
	; itself; VTA-5.62.43 deliberately drops that beat per project direction, so
	; only the target keeps the electrocution overlay.
	ld e,GOLD_QUICK_ATTACK_RETURN
	callba PlayGoldQuickAttackPhase

	; Restore the ordinary battle animation palette mapping after Spark's private
	; Electric slots, and leave all temporary counters/latches neutral.
	callba _LoadAnimationTilesetPalettes
	ld a,$e4
	ld [rBGP],a
	xor a
	ld [wSubAnimCounter],a
	ld [wBattleAnimSeamlessStage],a
	ld [wBattleAnimStageCarryTimer],a
	; Do NOT clear wAnimationType here. PlayApplyingAttackAnimation consumes it
	; immediately after the authored move and supplies the project's normal damage
	; reaction. Phase 1 cleared it and accidentally made Volt Tackle look like the
	; target had not taken a hit.
	ret
; VTC-5.62.49: read the displayed enemy's normal/regional 5x5,6x6,7x7
; dimensions without leaving the shared 28-byte wMonHeader changed.
; Each saved AF contributes only the byte in A; flags are immaterial.
.CacheEnemyFrontSize
	ld a,[wd0b5]
	push af
	ld hl,wMonHeader
	ld b,wMonHPicBank + 1 - wMonHeader
.saveHeader
	ld a,[hli]
	push af
	dec b
	jr nz,.saveHeader
	ld a,[wEnemyMonSpecies]
	ld d,a
	ld a,[wEnemyMonForm]
	ld e,a
	callba RegionalFormLoadPokedexHeader
	ld a,[wMonHSpriteDim]
	and $f
	sub 5
	cp 3
	jr c,.sizeReady
	ld a,2                         ; conservative 7x7 fallback
.sizeReady
	ld [wBattleAnimStageCarryTimer],a
	ld hl,wMonHPicBank + 1
	ld b,wMonHPicBank + 1 - wMonHeader
.restoreHeader
	dec hl
	pop af
	ld [hl],a
	dec b
	jr nz,.restoreHeader
	pop af
	ld [wd0b5],a
	ret


.MaybePlaySweepSfx
	; Ruby plays one Thunderbolt SFX per electric task (five total). Trigger at
	; frames 0/8/16/24/32 so audio and sweep direction changes stay locked.
	ld a,[wSubAnimCounter]
	and VOLT_TACKLE_SWEEP_FRAMES - 1
	ret nz
	ld a,GSSFX_SPARK
	jp PlaySound

.DrawSweepFrame
	; VTC-5.62.51: match the original five horizontal sweeps.
	; Sweep 1 starts at the current user's picture center, sweeps 2-4 cross
	; the full screen, and sweep 5 finishes at the victim's picture center.
	; Enemy use reverses the five heights (not the internal sweep order).
	; Leave the size-aware center lookup and final electric burst unchanged.
	ld a,[wSubAnimCounter]
	ld c,a
	and VOLT_TACKLE_SWEEP_FRAMES - 1
	ld h,a                         ; H = age 0..7
	ld a,c
	srl a
	srl a
	srl a
	ld l,a                         ; L = pass 0..4

	; VTC-5.62.49: all five Y lanes use one evenly spaced 5x5/6x6/7x7
	; table. The other side reads the same five values in reverse order.
	ld a,[wBattleAnimStageCarryTimer]
	ld c,a
	add a
	add a
	add c                         ; size index * 5
	ld c,a
	ld a,[wSubAnimCounter]
	srl a
	srl a
	srl a                         ; pass 0..4
	ld b,a
	ld a,[H_WHOSETURN]
	and a
	ld a,b
	jr z,.laneIndexReady
	ld b,a
	ld a,4
	sub b                         ; enemy use: pass 4..0
.laneIndexReady
	add c
	ld c,a
	ld b,0
	ld hl,VoltTackleSweepYTable
	add hl,bc
	ld a,[hl]
	ld [wBaseCoordY],a

	; Alternate five full-width horizontal directions: player first pass
	; starts at X=48, the three middle passes sweep edge-to-edge, and the
	; fifth ends at target X=132 (136 for 6x6). Enemy X is mirrored 180-X.
	ld a,[wSubAnimCounter]
	ld c,a
	ld b,0
	ld hl,VoltTackleSweepXTable
	add hl,bc
	ld a,[hl]
	ld [wBaseCoordX],a

	; Odd Ruby tasks travel backward. The H flip also reverses trail offsets so
	; the six fragments stay behind the moving head rather than ahead of it.
	ld a,[wSubAnimCounter]
	srl a
	srl a
	srl a
	and 1
	jr nz,.sweepReverse
	xor a
	ld [wDropletTile],a
	jr .sweepDirectionReady
.sweepReverse
	ld a,OAM_HFLIP
	ld [wDropletTile],a
.sweepDirectionReady

	; Enemy RELATIVE_X mirrors the travel direction and sprite flip together.
	ld a,[H_WHOSETURN]
	and a
	jr z,.drawSweepSprites
	ld a,[wBaseCoordX]
	ld c,a
	ld a,180
	sub c
	ld [wBaseCoordX],a
	ld a,[wDropletTile]
	xor OAM_HFLIP
	ld [wDropletTile],a

; VTC-5.62.49: the 6x6 enemy picture is centered four pixels right
	; of the odd-width pictures. Keep the release and impact X identical.
.drawSweepSprites
	ld a,[wBattleAnimStageCarryTimer]
	cp 1
	jr nz,.sweepXReady
	ld a,[H_WHOSETURN]
	and a
	jr z,.playerLastX
	ld a,[wSubAnimCounter]
	and a
	jr nz,.sweepXReady
	jr .setEvenX
.playerLastX
	ld a,[wSubAnimCounter]
	cp VOLT_TACKLE_SWEEP_TOTAL - 1
	jr nz,.sweepXReady
.setEvenX
	ld a,136
	ld [wBaseCoordX],a
.sweepXReady
	; VTC-5.62.51: unfold only the FIRST beam from its user's center,
	; and retract only the LAST beam into the target center. The three
	; middle full-screen sweeps retain all six electric fragments per pose.
	ld b,VOLT_TACKLE_SWEEP_SPRITES
	ld a,[wSubAnimCounter]
	and VOLT_TACKLE_SWEEP_FRAMES - 1
	ld c,a                         ; age 0..7
	ld a,[wSubAnimCounter]
	cp VOLT_TACKLE_SWEEP_FRAMES
	jr nc,.checkLastSweep
	ld a,c
	and a
	jr z,.oneSpark
	cp 1
	jr z,.threeSparks
	jr .sweepCountReady
.checkLastSweep
	cp VOLT_TACKLE_SWEEP_FRAMES * (VOLT_TACKLE_SWEEP_COUNT - 1)
	jr c,.sweepCountReady
	ld a,c
	cp VOLT_TACKLE_SWEEP_FRAMES - 1
	jr z,.oneSpark
	cp VOLT_TACKLE_SWEEP_FRAMES - 2
	jr z,.threeSparks
	jr .sweepCountReady
.oneSpark
	ld b,1
	jr .sweepCountReady
.threeSparks
	ld b,3
.sweepCountReady
	ld hl,VoltTackleSweepOffsets
.sweepSpriteLoop
	; Y zig-zag.
	ld a,[wBaseCoordY]
	add [hl]
	inc hl
	ld [de],a
	inc de

	; X trail is authored for a forward pass. Reverse (or enemy-mirrored reverse)
	; flips the signed offset so the six fragments stay behind the moving head.
	ld a,[hli]
	ld c,a
	ld a,[wDropletTile]
	and OAM_HFLIP
	ld a,c
	jr z,.sweepXOffsetReady
	cpl
	inc a
.sweepXOffsetReady
	ld c,a
	ld a,[wBaseCoordX]
	add c
	ld [de],a
	inc de

	ld a,[hli]                     ; tile 0/1/2 selector
	add VOLT_TACKLE_ELECTRIC_TILE_0
	ld [de],a
	inc de
	ld a,[wDropletTile]
	ld c,a
	ld a,[hli]                     ; authored per-piece flip
	xor c
	ld [de],a
	inc de
	dec b
	jr nz,.sweepSpriteLoop
	ret

.SetImpactShake
	; The enemy's horizontal impact latch stays disabled. Its damage feedback
	; later uses the stock vertical shake, with no second horizontal wobble.
	ld a,[H_WHOSETURN]
	and a
	ret nz
	ld a,[wSubAnimCounter]
	cp VOLT_TACKLE_IMPACT_SHAKE_END
	jr nc,.impactBase
	and 1
	jr nz,.impactRight
	ld a,5                         ; base 7 - 2
	ld [wBattleAnimWX],a
	ret
.impactRight
	ld a,9                         ; base 7 + 2
	ld [wBattleAnimWX],a
	ret
.impactBase
	ld a,7
	ld [wBattleAnimWX],a
	ret

.DrawTargetElectric
	call .SetTargetCenter
	jp .DrawElectricBurst


.SetTargetCenter
	ld a,[H_WHOSETURN]
	and a
	jr nz,.targetEnemyUse
	; VTC-5.62.49: use the same enemy-body anchor as the final sweep.
	ld a,[wBattleAnimStageCarryTimer]
	ld c,a
	ld b,0
	ld hl,VoltTackleEnemyTargetX
	add hl,bc
	ld a,[hl]
	ld [wBaseCoordX],a
	ld hl,VoltTackleEnemyTargetY
	add hl,bc
	ld a,[hl]
	ld [wBaseCoordY],a
	ret
.targetEnemyUse
	ld a,48                        ; player back picture center
	ld [wBaseCoordX],a
	ld a,88
	ld [wBaseCoordY],a
	ret

.DrawElectricBurst
	; Eight 8x8 fragments form two animated diagonals around the battler. Ruby
	; uses two larger ELECTRICITY sprites at +/-16; this denser Gen II version
	; reads similarly at GB resolution without importing new GBA art.
	ld a,[wSubAnimCounter]
	and 3
	cp 3
	jr nz,.burstFrameReady
	xor a
.burstFrameReady
	ld c,a                         ; C = tile animation frame 0..2
	ld hl,VoltTackleBurstOffsets
	ld b,8
.burstLoop
	ld a,[wBaseCoordY]
	add [hl]
	inc hl
	ld [de],a
	inc de
	ld a,[wBaseCoordX]
	add [hl]
	inc hl
	ld [de],a
	inc de
	ld a,c
	add VOLT_TACKLE_ELECTRIC_TILE_0
	ld [de],a
	inc de
	ld a,[hli]
	ld c,a                         ; temporarily keep authored attrs
	ld a,[H_WHOSETURN]
	and a
	ld a,c
	jr z,.burstAttrReady
	xor OAM_HFLIP
.burstAttrReady
	ld [de],a
	inc de
	; Advance animation frame independently of authored attr scratch.
	ld a,[wSubAnimCounter]
	and 3
	cp 3
	jr nz,.burstFrameReloaded
	xor a
.burstFrameReloaded
	ld c,a
	dec b
	jr nz,.burstLoop
	ret

; VTC-5.62.51: the five full-width sweeps use size-aware Y lanes,
; for 5x5/6x6/7x7. Player use reads forward; enemy use reverses the lanes.
; Steps are 9, 10 and 11 pixels respectively, no one-off endpoints.
VoltTackleSweepYTable:
	db 88,79,70,61,52            ; 5x5
	db 88,78,68,58,48            ; 6x6
	db 88,77,66,55,44            ; 7x7
VoltTackleEnemyTargetX:
	db 132,136,132
VoltTackleEnemyTargetY:
	db 52,48,44

; Five Ruby-style horizontal passes, eight head samples each.
; Passes 1/5 begin/end on the correct body centers, while 2-4 scan
; screen edge to edge. Enemy use mirrors X and reverses height order.
VoltTackleSweepXTable:
	; 0: user center -> off right
	db 48,64,80,96,112,128,144,160
	; 1: right -> left
	db 168,144,120,96,72,48,24,0
	; 2: left -> right
	db 0,24,48,72,96,120,144,168
	; 3: right -> left
	db 168,144,120,96,72,48,24,0
	; 4: left -> target; enemy mirror finishes at player center X=48
	db 0,19,38,57,75,94,113,132

; y, x-from-head, tile-index(0..2), attr. Six fragments form one moving current.
VoltTackleSweepOffsets:
	db  0,  0,0,0
	db -4, -8,1,OAM_VFLIP
	db  4,-16,2,0
	db -2,-24,1,OAM_HFLIP
	db  3,-32,0,OAM_VFLIP
	db  0,-40,2,OAM_HFLIP | OAM_VFLIP

; y, x, attr around the target center. Two diagonals approximate Ruby's paired
; ELECTRICITY objects while keeping peak OAM comfortably below 40.
VoltTackleBurstOffsets:
	db -16,-16,0
	db  -8, -8,OAM_HFLIP
	db   8,  8,OAM_VFLIP
	db  16, 16,OAM_HFLIP | OAM_VFLIP
	db -16,  8,OAM_HFLIP
	db  -8,  0,0
	db   8, -8,OAM_HFLIP | OAM_VFLIP
	db  16,-16,OAM_VFLIP
