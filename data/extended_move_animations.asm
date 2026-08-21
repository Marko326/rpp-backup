; Dedicated animation recipes for expanded moves.
;
; Expanded move data still keeps a legacy animation byte for compatibility.
; PrepareCurrentMoveAnimation asks this bank for a dedicated recipe by REAL move
; ID. Every expanded move from METAL_CLAW through MIND_BLAST now has a recipe.
;
; Each recipe starts with its byte length (including the $FF terminator). The
; command stream itself is copied into the existing 30-byte wBuffer.

; Gold-style orb projectile prototype.
; RPP already contains the Gen 2 Sludge Bomb SFX in crysaudio/sfx.asm; rbsfx.asm
; exposes it as the next SFX ID after the three existing GSSFX entries.
GSSFX_SLUDGE_BOMB EQU GSSFX_SUPER_EFFECTIVE + 1

; Keep the old public label because bank $1E already far-calls it.  The second
; label is the direction for later reuse by Moonblast / Energy Ball / etc.
PlayExtendedShadowBallProjectile:
PlayExtendedOrbProjectile:
	; Gold-style Shadow Ball projectile; C2 currently has no operand.
	; Initialize animation VRAM and OBJ palettes through the exact legacy path.
	; LoadAnimationTileset calls the normal palette wrapper, then loads tileset 0.
	; The two Gold orb tiles overwrite $31/$32 immediately below.
	xor a
	ld [wWhichBattleAnimTileset],a
	callba LoadAnimationTileset

	; Load the exact two unique tiles used by Gold's BARRAGE_BALL frameset.
	; Use tile slots $35/$36 because AnimationTileset1Palettes maps both to
	; ATK_PAL_BLUE.  ColorNonOverworldSprites therefore keeps the orb blue on
	; every frame instead of forcing $31/$32 to the yellow palette.
	ld hl,vSprites + $350
	ld de,GoldOrbAnimationTileset
	ld b,BANK(GoldOrbAnimationTileset)
	ld c,2
	call CopyVideoData

	; Gold plays one SFX_SLUDGE_BOMB for the whole launch/flight/impact sequence.
	; The impact smoke below is deliberately silent.
	ld a,GSSFX_SLUDGE_BOMB
	call PlaySound

	; Gold's WAVE_TO_TARGET moves X by +2 and base Y by -1 each frame, with a
	; 16-pixel sine wave whose phase advances by 4.  32 frames = two full waves.
	; Mirror the path for an enemy user.
	ld a,[H_WHOSETURN]
	and a
	jr nz,.enemy
	ld b,$40 ; object center X = 64
	ld c,$5C ; object center Y = 92
	ld d,$02 ; X += 2
	ld e,$FF ; base Y -= 1
	jr .start
.enemy
	ld b,$84 ; mirrored target-side center X = 132
	ld c,$38 ; mirrored target-side center Y = 56
	ld d,$FE ; X -= 2
	ld e,$01 ; base Y += 1
.start
	ld hl,GoldShadowBallWaveOffsets
	ld a,32
.loop
	push af
	push bc ; un-waved center
	push de ; base delta

	; Read the signed Gold-like sine offset. Mirror its sign for enemy use so
	; the whole path is the geometric reverse of the player's path.
	ld a,[hli]
	ld d,a
	ld a,[H_WHOSETURN]
	and a
	jr z,.gotWave
	ld a,d
	cpl
	inc a
	ld d,a
.gotWave
	ld a,c
	add d
	ld c,a

	; Keep the wave-table pointer alive across DelayFrame/ClearSprites.
	; ClearSprites clobbers HL, so restore it only after the frame cleanup.
	push hl
	call .drawBall
	call DelayFrame
	call ClearSprites
	pop hl

	pop de
	pop bc
	ld a,b
	add d
	ld b,a
	ld a,c
	add e
	ld c,a
	pop af
	dec a
	jr nz,.loop

	; Gold post-hit feedback is attacker-side based rather than side-effect based:
	; player Shadow Ball -> blink enemy; enemy Shadow Ball -> vertical screen shake.
	ld a,[H_WHOSETURN]
	and a
	ld a,4
	jr z,.setHitFeedback
	ld a,1
.setHitFeedback
	ld [wAnimationType],a
	ret

.drawBall:
	; B,C = 16x16 orb center. Gold's OAM set uses two unique left-half tiles and
	; mirrors them horizontally to form the right half.
	ld hl,wOAMBuffer

	; top-left
	ld a,c
	sub 8
	ld [hli],a
	ld a,b
	sub 8
	ld [hli],a
	ld a,$35
	ld [hli],a
	ld a,ATK_PAL_BLUE
	ld [hli],a

	; top-right = X-flipped copy of top-left tile
	ld a,c
	sub 8
	ld [hli],a
	ld a,b
	ld [hli],a
	ld a,$35
	ld [hli],a
	ld a,ATK_PAL_BLUE | OAM_HFLIP
	ld [hli],a

	; bottom-left
	ld a,c
	ld [hli],a
	ld a,b
	sub 8
	ld [hli],a
	ld a,$36
	ld [hli],a
	ld a,ATK_PAL_BLUE
	ld [hli],a

	; bottom-right = X-flipped copy of bottom-left tile
	ld a,c
	ld [hli],a
	ld a,b
	ld [hli],a
	ld a,$36
	ld [hli],a
	ld a,ATK_PAL_BLUE | OAM_HFLIP
	ld [hl],a
	ret


; d=16, phase += 4 in Gold. Two cycles over 32 frames.
; Values are integer approximations of 16*sin(phase*pi/32).
GoldShadowBallWaveOffsets:
	db $00,$06,$0B,$0F,$10,$0F,$0B,$06
	db $00,$FA,$F5,$F1,$F0,$F1,$F5,$FA
	db $00,$06,$0B,$0F,$10,$0F,$0B,$06
	db $00,$FA,$F5,$F1,$F0,$F1,$F5,$FA

LoadExtendedMoveAnimation:
; input: e = real move ID (range-checked by PrepareCurrentMoveAnimation)
; output: wMoveAnimScriptLoaded = 1 after the dedicated recipe is staged
;
; Expanded move IDs are contiguous, so index a compact pointer table directly.
	ld a, e
	sub METAL_CLAW
	add a
	ld l, a
	ld h, 0
	ld de, ExtendedMoveAnimationPointers
	add hl, de
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld a, [hli] ; recipe byte length, including terminator
	ld b, a
	ld de, wBuffer
.copy
	ld a, [hli]
	ld [de], a
	inc de
	dec b
	jr nz, .copy
	ld a, 1
	ld [wMoveAnimScriptLoaded], a
	ret

; Full contiguous table for expanded move IDs $A6-$FD.
ExtendedMoveAnimationPointers:
	dw MetalClawExtAnim             ; METAL_CLAW
	dw BulletPunchExtAnim           ; BULLET_PUNCH
	dw FlashCannonExtAnim           ; FLASH_CANNON
	dw IronTailExtAnim              ; IRON_TAIL
	dw MeteorMashExtAnim            ; METEOR_MASH
	dw CrunchExtAnim                ; CRUNCH
	dw DarkPulseExtAnim             ; DARK_PULSE
	dw FeintAttackExtAnim           ; FEINT_ATTACK
	dw NightSlashExtAnim            ; NIGHT_SLASH
	dw MoonblastExtAnim             ; MOONBLAST
	dw DrainingKissExtAnim          ; DRAININGKISS
	dw DisarmingVoiceExtAnim        ; DISARM_VOICE
	dw DazzlingGleamExtAnim         ; DAZZLINGLEAM
	dw DracoMeteorExtAnim           ; DRACO_METEOR
	dw DragonbreathExtAnim          ; DRAGONBREATH
	dw DragonClawExtAnim            ; DRAGON_CLAW
	dw DragonPulseExtAnim           ; DRAGON_PULSE
	dw TwisterExtAnim               ; TWISTER
	dw OutrageExtAnim               ; OUTRAGE
	dw ShadowClawExtAnim            ; SHADOW_CLAW
	dw SteelWingExtAnim             ; STEEL_WING
	dw IronDefenseExtAnim           ; IRON_DEFENSE
	dw AirSlashExtAnim              ; AIR_SLASH
	dw FireFangExtAnim              ; FIRE_FANG
	dw FlareBlitzExtAnim            ; FLARE_BLITZ
	dw BlastBurnExtAnim             ; BLAST_BURN
	dw IceFangExtAnim               ; ICE_FANG
	dw ThunderFangExtAnim           ; THUNDER_FANG
	dw WaterPulseExtAnim            ; WATER_PULSE
	dw AquaTailExtAnim              ; AQUA_TAIL
	dw HydroCannonExtAnim           ; HYDRO_CANNON
	dw FrenzyPlantExtAnim           ; FRENZY_PLANT
	dw SuckerPunchExtAnim           ; SUCKER_PUNCH
	dw ShadowBallExtAnim            ; SHADOW_BALL
	dw FlameWheelExtAnim            ; FLAME_WHEEL
	dw MoonlightExtAnim             ; HEALINGLIGHT
	dw HexExtAnim                   ; HEX
	dw ShadowPunchExtAnim           ; SHADOW_PUNCH
	dw AerialAceExtAnim             ; AERIAL_ACE
	dw AcrobaticsExtAnim            ; ACROBATICS
	dw AirCutterExtAnim             ; AIR_CUTTER
	dw IcyWindExtAnim               ; ICY_WIND
	dw IceShardExtAnim              ; ICE_SHARD
	dw SheerColdExtAnim             ; SHEER_COLD
	dw ElectroBallExtAnim           ; ELECTRO_BALL
	dw NuzzleExtAnim                ; NUZZLE
	dw DischargeExtAnim             ; DISCHARGE
	dw VoltTackleExtAnim            ; VOLT_TACKLE
	dw MuddyWaterExtAnim            ; MUDDY_WATER
	dw WhirlpoolExtAnim             ; WHIRLPOOL
	dw GigaDrainExtAnim             ; GIGA_DRAIN
	dw PetalBlizzardExtAnim         ; PETALBLIZARD
	dw LeafBladeExtAnim             ; LEAF_BLADE
	dw WoodHammerExtAnim            ; WOOD_HAMMER
	dw PoisonJabExtAnim             ; POISON_JAB
	dw GunkShotExtAnim              ; GUNK_SHOT
	dw PoisonFangExtAnim            ; POISON_FANG
	dw SludgeWaveExtAnim            ; SLUDGE_WAVE
	dw SilverWindExtAnim            ; SILVER_WIND
	dw BugBuzzExtAnim               ; BUG_BUZZ
	dw MegahornExtAnim              ; MEGAHORN
	dw XScissorExtAnim              ; X_SCISSOR
	dw SignalBeamExtAnim            ; SIGNAL_BEAM
	dw EarthPowerExtAnim            ; EARTH_POWER
	dw MudSlapExtAnim               ; MUD_SLAP
	dw MudBombExtAnim               ; MUD_BOMB
	dw ExtrasensoryExtAnim          ; EXTRASENSORY
	dw ZenHeadbuttExtAnim           ; ZEN_HEADBUTT
	dw PsychoCutExtAnim             ; PSYCHO_CUT
	dw HyperVoiceExtAnim            ; HYPER_VOICE
	dw ExtremespeedExtAnim          ; EXTREMESPEED
	dw GigaImpactExtAnim            ; GIGA_IMPACT
	dw PowerGemExtAnim              ; POWER_GEM
	dw RockBlastExtAnim             ; ROCK_BLAST
	dw RockPolishExtAnim            ; ROCK_POLISH
	dw RockTombExtAnim              ; ROCK_TOMB
	dw DynamicpunchExtAnim          ; DYNAMICPUNCH
	dw StormThrowExtAnim            ; STORM_THROW
	dw CrossChopExtAnim             ; CROSS_CHOP
	dw LowSweepExtAnim              ; LOW_SWEEP
	dw HurricaneExtAnim             ; HURRICANE
	dw BabydolleyesExtAnim          ; BABYDOLLEYES
	dw BoneRushExtAnim              ; BONE_RUSH
	dw AeroblastExtAnim             ; AEROBLAST
	dw AncientpowerExtAnim          ; ANCIENTPOWER
	dw DiveExtAnim                  ; DIVE
	dw LusterPurgeExtAnim           ; LUSTER_PURGE
	dw MindBlastExtAnim             ; MIND_BLAST
ExtendedMoveAnimationPointersEnd:
	IF ExtendedMoveAnimationPointersEnd - ExtendedMoveAnimationPointers != (NUM_ATTACKS - METAL_CLAW) * 2
		fail "extended move animation pointer table size mismatch"
	ENDC

MetalClawExtAnim:
	db MetalClawExtAnimEnd - MetalClawExtAnimData
MetalClawExtAnimData:
	; Metal sheen -> crossing claw cuts -> impact shake.
	db SE_LIGHT_SCREEN_PALETTE,$FF
	db $04,$09,$0F ; Scratch-style claw
	db SE_DARK_SCREEN_FLASH,$FF
	db $04,$FF,$16 ; Cut-style crossing slash
	db SE_SHAKE_SCREEN,$FF
	db SE_RESET_SCREEN_PALETTE,$FF
	db $FF
MetalClawExtAnimEnd:
	IF MetalClawExtAnimEnd - MetalClawExtAnimData > 30
		fail "Metal Claw animation recipe exceeds wBuffer"
	ENDC

BulletPunchExtAnim:
	db BulletPunchExtAnimEnd - BulletPunchExtAnimData
BulletPunchExtAnimData:
	db $04,$03,$02
	db $04,$03,$02
	db $46,$FF,$04
	db $FF
BulletPunchExtAnimEnd:
	IF BulletPunchExtAnimEnd - BulletPunchExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

IronTailExtAnim:
	db IronTailExtAnimEnd - IronTailExtAnimData
IronTailExtAnimData:
	db SE_MOVE_MON_HORIZONTALLY,$84
	db $04,$FF,$16
	db SE_RESET_MON_POSITION,$FF
	db $FF
IronTailExtAnimEnd:
	IF IronTailExtAnimEnd - IronTailExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

MeteorMashExtAnim:
	db MeteorMashExtAnimEnd - MeteorMashExtAnimData
MeteorMashExtAnimData:
	db SE_SPIRAL_BALLS_INWARD,$FF
	db $46,$04,$04
	db SE_SHAKE_SCREEN,$FF
	db $FF
MeteorMashExtAnimEnd:
	IF MeteorMashExtAnimEnd - MeteorMashExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

CrunchExtAnim:
	db CrunchExtAnimEnd - CrunchExtAnimData
CrunchExtAnimData:
	db SE_DARK_SCREEN_PALETTE,$FF
	db $08,$2B,$02
	db SE_DARK_SCREEN_FLASH,$FF
	db SE_RESET_SCREEN_PALETTE,$FF
	db $FF
CrunchExtAnimEnd:
	IF CrunchExtAnimEnd - CrunchExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

DarkPulseExtAnim:
	db DarkPulseExtAnimEnd - DarkPulseExtAnimData
DarkPulseExtAnimData:
	; Darken the field and send three expanding pulse/wave bursts.
	db SE_DARK_SCREEN_PALETTE,$FF
	db $06,$2F,$31 ; Supersonic/Psywave-style pulse
	db $08,$FF,$31
	db $0A,$FF,$31
	db SE_WAVY_SCREEN,$FF
	db SE_DARK_SCREEN_FLASH,$FF
	db SE_RESET_SCREEN_PALETTE,$FF
	db $FF
DarkPulseExtAnimEnd:
	IF DarkPulseExtAnimEnd - DarkPulseExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

FeintAttackExtAnim:
	db FeintAttackExtAnimEnd - FeintAttackExtAnimData
FeintAttackExtAnimData:
	db SE_SLIDE_MON_OFF,$61
	db $46,$FF,$04
	db SE_SHOW_MON_PIC,$FF
	db $FF
FeintAttackExtAnimEnd:
	IF FeintAttackExtAnimEnd - FeintAttackExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

NightSlashExtAnim:
	db NightSlashExtAnimEnd - NightSlashExtAnimData
NightSlashExtAnimData:
	db SE_DARK_SCREEN_FLASH,$0E
	db $06,$A2,$0F
	db $04,$FF,$16
	db $FF
NightSlashExtAnimEnd:
	IF NightSlashExtAnimEnd - NightSlashExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

MoonblastExtAnim:
	db MoonblastExtAnimEnd - MoonblastExtAnimData
MoonblastExtAnimData:
	; Gather light, scatter star-like sparks, then release a bright beam.
	db SE_LIGHT_SCREEN_PALETTE,$FF
	db SE_SPIRAL_BALLS_INWARD,$FF
	db $43,$80,$3F ; Swift-style stars
	db $04,$4B,$2E ; Solar Beam-style ray
	db SE_FLASH_SCREEN_LONG,$FF
	db SE_RESET_SCREEN_PALETTE,$FF
	db $FF
MoonblastExtAnimEnd:
	IF MoonblastExtAnimEnd - MoonblastExtAnimData > 30
		fail "Moonblast animation recipe exceeds wBuffer"
	ENDC

FlashCannonExtAnim:
	db FlashCannonExtAnimEnd - FlashCannonExtAnimData
FlashCannonExtAnimData:
	; Explicitly opt into Hyper Beam's per-frame flash behavior without using
	; HYPER_BEAM as this move's animation identity.
	db SE_LIGHT_SCREEN_PALETTE,$FF
	db SE_SPIRAL_BALLS_INWARD,$FF
	db EXT_ANIM_SET_FRAME_EFFECT,EXT_FRAME_FLASH_4
	db $02,$3E,$2E
	db EXT_ANIM_SET_FRAME_EFFECT,EXT_FRAME_NONE
	db SE_FLASH_SCREEN_LONG,$FF
	db SE_SHAKE_SCREEN,$FF
	db SE_RESET_SCREEN_PALETTE,$FF
	db $FF
FlashCannonExtAnimEnd:
	IF FlashCannonExtAnimEnd - FlashCannonExtAnimData > 30
		fail "Flash Cannon animation recipe exceeds wBuffer"
	ENDC

DrainingKissExtAnim:
	db DrainingKissExtAnimEnd - DrainingKissExtAnimData
DrainingKissExtAnimData:
	db $06,$8D,$12
	db SE_SPIRAL_BALLS_INWARD,$FF
	db $06,$FF,$22
	db $FF
DrainingKissExtAnimEnd:
	IF DrainingKissExtAnimEnd - DrainingKissExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

DisarmingVoiceExtAnim:
	db DisarmingVoiceExtAnimEnd - DisarmingVoiceExtAnimData
DisarmingVoiceExtAnimData:
	; Use the attacker's actual cry with Growl's softer pitch/tempo profile, then
	; layer voice-wave visuals.  No dependency on wAnimationID == GROWL/ROAR.
	db EXT_ANIM_PLAY_USER_CRY,GROWL
	db $46,$FF,$12
	db $50,$FF,$40
	db $06,$2F,$31
	db $FF
DisarmingVoiceExtAnimEnd:
	IF DisarmingVoiceExtAnimEnd - DisarmingVoiceExtAnimData > 30
		fail "Disarming Voice animation recipe exceeds wBuffer"
	ENDC

DazzlingGleamExtAnim:
	db DazzlingGleamExtAnimEnd - DazzlingGleamExtAnimData
DazzlingGleamExtAnimData:
	db SE_LIGHT_SCREEN_PALETTE,$FF
	db SE_DARK_SCREEN_FLASH,$88
	db SE_DARK_SCREEN_FLASH,$FF
	db SE_RESET_SCREEN_PALETTE,$FF
	db $FF
DazzlingGleamExtAnimEnd:
	IF DazzlingGleamExtAnimEnd - DazzlingGleamExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

DracoMeteorExtAnim:
	db DracoMeteorExtAnimEnd - DracoMeteorExtAnimData
DracoMeteorExtAnimData:
	; Prototype: keep Blizzard/IceFall's BaseCoord + mode sequence (Sub38),
	; but force Swift's complete 16x16 star object (FrameBlock68).  Tileset 1
	; is required because FrameBlock68's $03/$13 tiles are Swift's star there.
	db SE_DARK_SCREEN_PALETTE,$FF
	db EXT_ANIM_SET_FRAME_EFFECT,EXT_FRAMEBLOCK_OVERRIDE | $68
	db $43,$9C,$38
	db EXT_ANIM_SET_FRAME_EFFECT,EXT_FRAME_NONE
	db SE_SHAKE_SCREEN,$FF
	db SE_RESET_SCREEN_PALETTE,$FF
	db $FF
DracoMeteorExtAnimEnd:
	IF DracoMeteorExtAnimEnd - DracoMeteorExtAnimData > 30
		fail "Draco Meteor animation recipe exceeds wBuffer"
	ENDC

; V2 anchor correction for the specific Sub38 -> FrameBlock68 prototype.
; Every 66 -> 68 replacement grows from 8 px to 16 px in width, so shift
; the star left 4 px.  Sub38's 67 entries are its mode-3 terminal objects,
; except for the final entry (counter == 1); those also grow from 8 px to
; 16 px in height, so shift them up 4 px as well.
ApplyDracoMeteorStarAnchorCompensation:
	ld a,[wBaseCoordX]
	sub 4
	ld [wBaseCoordX],a

	ld a,[wFBMode]
	cp 3
	jr z,.shiftY
	ld a,[wSubAnimCounter]
	cp 1
	ret nz
.shiftY
	ld a,[wBaseCoordY]
	sub 4
	ld [wBaseCoordY],a
	ret

DragonbreathExtAnim:
	db DragonbreathExtAnimEnd - DragonbreathExtAnimData
DragonbreathExtAnimData:
	db $46,$51,$1F
	db $46,$FF,$0C
	db $42,$55,$29
	db $FF
DragonbreathExtAnimEnd:
	IF DragonbreathExtAnimEnd - DragonbreathExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

DragonClawExtAnim:
	db DragonClawExtAnimEnd - DragonClawExtAnimData
DragonClawExtAnimData:
	db $06,$A2,$0F
	db $46,$FF,$0E
	db $46,$FF,$05
	db $FF
DragonClawExtAnimEnd:
	IF DragonClawExtAnimEnd - DragonClawExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

DragonPulseExtAnim:
	db DragonPulseExtAnimEnd - DragonPulseExtAnimData
DragonPulseExtAnimData:
	; Dragon-flame burst feeds into a focused pulse beam and screen shock.
	db $46,$51,$1F ; Dragon Rage flame
	db $46,$FF,$0C ; follow-up flame spiral
	db $03,$3B,$2E ; Psybeam-style pulse beam
	db SE_WAVY_SCREEN,$FF
	db SE_SHAKE_SCREEN,$FF
	db $FF
DragonPulseExtAnimEnd:
	IF DragonPulseExtAnimEnd - DragonPulseExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

TwisterExtAnim:
	db TwisterExtAnimEnd - TwisterExtAnimData
TwisterExtAnimData:
	db $46,$0F,$10
	db $46,$2D,$15
	db SE_SHAKE_SCREEN,$FF
	db $FF
TwisterExtAnimEnd:
	IF TwisterExtAnimEnd - TwisterExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

OutrageExtAnim:
	db OutrageExtAnimEnd - OutrageExtAnimData
OutrageExtAnimData:
	db SE_DARK_SCREEN_FLASH,$FF
	db $06,$62,$01
	db $46,$FF,$05
	db SE_SHAKE_SCREEN,$FF
	db $FF
OutrageExtAnimEnd:
	IF OutrageExtAnimEnd - OutrageExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

ShadowClawExtAnim:
	db ShadowClawExtAnimEnd - ShadowClawExtAnimData
ShadowClawExtAnimData:
	db SE_DARK_SCREEN_PALETTE,$FF
	db $06,$A2,$0F
	db SE_DARK_SCREEN_FLASH,$FF
	db SE_RESET_SCREEN_PALETTE,$FF
	db $FF
ShadowClawExtAnimEnd:
	IF ShadowClawExtAnimEnd - ShadowClawExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

SteelWingExtAnim:
	db SteelWingExtAnimEnd - SteelWingExtAnimData
SteelWingExtAnimData:
	db $46,$10,$04
	; Cut's slash component normally includes a preceding impact flash.
	db SE_DARK_SCREEN_FLASH,$0E
	db $04,$FF,$16
	db $46,$FF,$05
	db $FF
SteelWingExtAnimEnd:
	IF SteelWingExtAnimEnd - SteelWingExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

IronDefenseExtAnim:
	db IronDefenseExtAnimEnd - IronDefenseExtAnimData
IronDefenseExtAnimData:
	db $46,$6F,$33
	db $46,$6F,$33
	db SE_DARK_SCREEN_FLASH,$FF
	db $FF
IronDefenseExtAnimEnd:
	IF IronDefenseExtAnimEnd - IronDefenseExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

AirSlashExtAnim:
	db AirSlashExtAnimEnd - AirSlashExtAnimData
AirSlashExtAnimData:
	db $46,$0F,$10
	db SE_DARK_SCREEN_FLASH,$0E
	db $04,$FF,$16
	db $FF
AirSlashExtAnimEnd:
	IF AirSlashExtAnimEnd - AirSlashExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

FireFangExtAnim:
	db FireFangExtAnimEnd - FireFangExtAnimData
FireFangExtAnimData:
	db $08,$2B,$02
	db $46,$33,$11
	db $46,$FF,$0C
	db $FF
FireFangExtAnimEnd:
	IF FireFangExtAnimEnd - FireFangExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

FlareBlitzExtAnim:
	db FlareBlitzExtAnimEnd - FlareBlitzExtAnimData
FlareBlitzExtAnimData:
	db SE_MOVE_MON_HORIZONTALLY,$48
	db $46,$34,$1F
	db $46,$FF,$0C
	db SE_DARK_SCREEN_FLASH,$FF
	db SE_RESET_MON_POSITION,$FF
	db $FF
FlareBlitzExtAnimEnd:
	IF FlareBlitzExtAnimEnd - FlareBlitzExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

BlastBurnExtAnim:
	db BlastBurnExtAnimEnd - BlastBurnExtAnimData
BlastBurnExtAnimData:
	db SE_DARK_SCREEN_PALETTE,$FF
	db $46,$7D,$1F
	db $46,$FF,$20
	db $43,$77,$34
	db SE_SHAKE_SCREEN,$FF
	db SE_RESET_SCREEN_PALETTE,$FF
	db $FF
BlastBurnExtAnimEnd:
	IF BlastBurnExtAnimEnd - BlastBurnExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

IceFangExtAnim:
	db IceFangExtAnimEnd - IceFangExtAnimData
IceFangExtAnimData:
	db $08,$2B,$02
	; Blizzard's snow subanimation relies on frame-counter flashes in the legacy
	; engine. Request them explicitly while the ice sprites are active.
	db EXT_ANIM_SET_FRAME_EFFECT,EXT_FRAME_BLIZZARD
	db $04,$3A,$38
	db $04,$37,$38
	db EXT_ANIM_SET_FRAME_EFFECT,EXT_FRAME_NONE
	db $FF
IceFangExtAnimEnd:
	IF IceFangExtAnimEnd - IceFangExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

ThunderFangExtAnim:
	db ThunderFangExtAnimEnd - ThunderFangExtAnimData
ThunderFangExtAnimData:
	db $08,$2B,$02
	db SE_DARK_SCREEN_PALETTE,$FF
	db EXT_ANIM_SET_FRAME_EFFECT,EXT_FRAME_FLASH_8
	db $41,$54,$29
	db EXT_ANIM_SET_FRAME_EFFECT,EXT_FRAME_NONE
	db SE_RESET_SCREEN_PALETTE,$FF
	db $FF
ThunderFangExtAnimEnd:
	IF ThunderFangExtAnimEnd - ThunderFangExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

WaterPulseExtAnim:
	db WaterPulseExtAnimEnd - WaterPulseExtAnimData
WaterPulseExtAnimData:
	db $12,$3C,$35
	db SE_DARK_SCREEN_FLASH,$FF
	db SE_WAVY_SCREEN,$FF
	db $06,$37,$1A
	db $FF
WaterPulseExtAnimEnd:
	IF WaterPulseExtAnimEnd - WaterPulseExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

AquaTailExtAnim:
	db AquaTailExtAnimEnd - AquaTailExtAnimData
AquaTailExtAnimData:
	db SE_WATER_DROPLETS_EVERYWHERE,$38
	db $06,$37,$1A
	db $06,$14,$02
	db $FF
AquaTailExtAnimEnd:
	IF AquaTailExtAnimEnd - AquaTailExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

HydroCannonExtAnim:
	db HydroCannonExtAnimEnd - HydroCannonExtAnimData
HydroCannonExtAnimData:
	db SE_WATER_DROPLETS_EVERYWHERE,$38
	db SE_DARK_SCREEN_FLASH,$FF
	; Treat the cannon beam like other dedicated high-power beam recipes instead
	; of depending on HYPER_BEAM as an animation identity.
	db EXT_ANIM_SET_FRAME_EFFECT,EXT_FRAME_FLASH_4
	db $02,$3E,$2E
	db EXT_ANIM_SET_FRAME_EFFECT,EXT_FRAME_NONE
	db $46,$FF,$04
	db SE_SHAKE_SCREEN,$FF
	db $FF
HydroCannonExtAnimEnd:
	IF HydroCannonExtAnimEnd - HydroCannonExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

FrenzyPlantExtAnim:
	db FrenzyPlantExtAnimEnd - FrenzyPlantExtAnimData
FrenzyPlantExtAnimData:
	db SE_LEAVES_FALLING,$4A
	db $01,$15,$16
	db $46,$FF,$05
	db SE_SHAKE_SCREEN,$FF
	db $FF
FrenzyPlantExtAnimEnd:
	IF FrenzyPlantExtAnimEnd - FrenzyPlantExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

SuckerPunchExtAnim:
	db SuckerPunchExtAnimEnd - SuckerPunchExtAnimData
SuckerPunchExtAnimData:
	db SE_SLIDE_MON_OFF,$43
	db SE_DARK_SCREEN_FLASH,$FF
	db $46,$04,$04
	db SE_SHOW_MON_PIC,$FF
	db $FF
SuckerPunchExtAnimEnd:
	IF SuckerPunchExtAnimEnd - SuckerPunchExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

ShadowBallExtAnim:
	db ShadowBallExtAnimEnd - ShadowBallExtAnimData
ShadowBallExtAnimData:
	; V7+ structure: dark background, one Sludge Bomb SFX, 32-frame wave-to-target
	; orb, then the V7 16-frame/40x40 poof. Keep the background dark for another
	; 10 frames before restoring it, approximating Gold's post-impact tail.
	db SE_DARK_SCREEN_PALETTE,$FF
	db EXT_ANIM_SHADOW_BALL_PROJECTILE
	db $03,$FF,$3C
	db SE_DELAY_ANIMATION_10,$FF
	db SE_RESET_SCREEN_PALETTE,$FF
	db $FF
ShadowBallExtAnimEnd:
	IF ShadowBallExtAnimEnd - ShadowBallExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

FlameWheelExtAnim:
	db FlameWheelExtAnimEnd - FlameWheelExtAnimData
FlameWheelExtAnimData:
	db SE_MOVE_MON_HORIZONTALLY,$48
	db $46,$33,$11
	db $46,$FF,$05
	db SE_RESET_MON_POSITION,$FF
	db $FF
FlameWheelExtAnimEnd:
	IF FlameWheelExtAnimEnd - FlameWheelExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

MoonlightExtAnim:
	db MoonlightExtAnimEnd - MoonlightExtAnimData
MoonlightExtAnimData:
	db SE_LIGHT_SCREEN_PALETTE,$FF
	db SE_SPIRAL_BALLS_INWARD,$73
	db SE_DARK_SCREEN_FLASH,$FF
	db SE_RESET_SCREEN_PALETTE,$FF
	db $FF
MoonlightExtAnimEnd:
	IF MoonlightExtAnimEnd - MoonlightExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

HexExtAnim:
	db HexExtAnimEnd - HexExtAnimData
HexExtAnimData:
	db SE_DARK_SCREEN_PALETTE,$5C
	db SE_WAVY_SCREEN,$FF
	db SE_FLASH_SCREEN_LONG,$FF
	db SE_RESET_SCREEN_PALETTE,$FF
	db $FF
HexExtAnimEnd:
	IF HexExtAnimEnd - HexExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

ShadowPunchExtAnim:
	db ShadowPunchExtAnimEnd - ShadowPunchExtAnimData
ShadowPunchExtAnimData:
	db SE_DARK_SCREEN_PALETTE,$FF
	db $46,$04,$04
	db SE_DARK_SCREEN_FLASH,$FF
	db SE_RESET_SCREEN_PALETTE,$FF
	db $FF
ShadowPunchExtAnimEnd:
	IF ShadowPunchExtAnimEnd - ShadowPunchExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

AerialAceExtAnim:
	db AerialAceExtAnimEnd - AerialAceExtAnimData
AerialAceExtAnimData:
	db $46,$10,$04
	db $46,$FF,$04
	db $06,$FF,$02
	db $FF
AerialAceExtAnimEnd:
	IF AerialAceExtAnimEnd - AerialAceExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

AcrobaticsExtAnim:
	db AcrobaticsExtAnimEnd - AcrobaticsExtAnimData
AcrobaticsExtAnimData:
	db SE_SLIDE_MON_OFF,$61
	db $46,$10,$04
	db $46,$FF,$04
	db SE_SHOW_MON_PIC,$FF
	db $FF
AcrobaticsExtAnimEnd:
	IF AcrobaticsExtAnimEnd - AcrobaticsExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

AirCutterExtAnim:
	db AirCutterExtAnimEnd - AirCutterExtAnimData
AirCutterExtAnimData:
	db $46,$0F,$10
	db SE_DARK_SCREEN_FLASH,$0E
	db $04,$FF,$16
	db $06,$FF,$02
	db $FF
AirCutterExtAnimEnd:
	IF AirCutterExtAnimEnd - AirCutterExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

IcyWindExtAnim:
	db IcyWindExtAnimEnd - IcyWindExtAnimData
IcyWindExtAnimData:
	db EXT_ANIM_SET_FRAME_EFFECT,EXT_FRAME_BLIZZARD
	db $04,$3A,$38
	db EXT_ANIM_SET_FRAME_EFFECT,EXT_FRAME_NONE
	db $46,$0F,$10
	db EXT_ANIM_SET_FRAME_EFFECT,EXT_FRAME_BLIZZARD
	db $04,$37,$38
	db EXT_ANIM_SET_FRAME_EFFECT,EXT_FRAME_NONE
	db $FF
IcyWindExtAnimEnd:
	IF IcyWindExtAnimEnd - IcyWindExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

IceShardExtAnim:
	db IceShardExtAnimEnd - IceShardExtAnimData
IceShardExtAnimData:
	db $03,$29,$01
	db EXT_ANIM_SET_FRAME_EFFECT,EXT_FRAME_BLIZZARD
	db $04,$3A,$38
	db EXT_ANIM_SET_FRAME_EFFECT,EXT_FRAME_NONE
	db $46,$FF,$05
	db $FF
IceShardExtAnimEnd:
	IF IceShardExtAnimEnd - IceShardExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

SheerColdExtAnim:
	db SheerColdExtAnimEnd - SheerColdExtAnimData
SheerColdExtAnimData:
	db SE_DARK_SCREEN_PALETTE,$FF
	db EXT_ANIM_SET_FRAME_EFFECT,EXT_FRAME_BLIZZARD
	db $04,$3A,$38
	db $04,$37,$38
	db EXT_ANIM_SET_FRAME_EFFECT,EXT_FRAME_NONE
	db SE_DARK_SCREEN_FLASH,$FF
	db SE_RESET_SCREEN_PALETTE,$FF
	db $FF
SheerColdExtAnimEnd:
	IF SheerColdExtAnimEnd - SheerColdExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

ElectroBallExtAnim:
	db ElectroBallExtAnimEnd - ElectroBallExtAnimData
ElectroBallExtAnimData:
	db SE_SPIRAL_BALLS_INWARD,$FF
	db EXT_ANIM_SET_FRAME_EFFECT,EXT_FRAME_FLASH_8
	db $41,$54,$29
	db $41,$54,$29
	db EXT_ANIM_SET_FRAME_EFFECT,EXT_FRAME_NONE
	db $FF
ElectroBallExtAnimEnd:
	IF ElectroBallExtAnimEnd - ElectroBallExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

NuzzleExtAnim:
	db NuzzleExtAnimEnd - NuzzleExtAnimData
NuzzleExtAnimData:
	db SE_MOVE_MON_HORIZONTALLY,$48
	db $02,$FF,$23
	db $46,$FF,$05
	db SE_RESET_MON_POSITION,$FF
	db $FF
NuzzleExtAnimEnd:
	IF NuzzleExtAnimEnd - NuzzleExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

DischargeExtAnim:
	db DischargeExtAnimEnd - DischargeExtAnimData
DischargeExtAnimData:
	db SE_DARK_SCREEN_PALETTE,$56
	db EXT_ANIM_SET_FRAME_EFFECT,EXT_FRAME_FLASH_8
	db $41,$54,$29
	db $42,$54,$29
	db EXT_ANIM_SET_FRAME_EFFECT,EXT_FRAME_NONE
	db SE_RESET_SCREEN_PALETTE,$FF
	db $FF
DischargeExtAnimEnd:
	IF DischargeExtAnimEnd - DischargeExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

VoltTackleExtAnim:
	db VoltTackleExtAnimEnd - VoltTackleExtAnimData
VoltTackleExtAnimData:
	db SE_MOVE_MON_HORIZONTALLY,$48
	db SE_DARK_SCREEN_FLASH,$FF
	db EXT_ANIM_SET_FRAME_EFFECT,EXT_FRAME_FLASH_8
	db $41,$54,$29
	db EXT_ANIM_SET_FRAME_EFFECT,EXT_FRAME_NONE
	db $46,$FF,$04
	db SE_SHAKE_SCREEN,$FF
	db SE_RESET_MON_POSITION,$FF
	db $FF
VoltTackleExtAnimEnd:
	IF VoltTackleExtAnimEnd - VoltTackleExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

MuddyWaterExtAnim:
	db MuddyWaterExtAnimEnd - MuddyWaterExtAnimData
MuddyWaterExtAnimData:
	db SE_WATER_DROPLETS_EVERYWHERE,$38
	db $06,$37,$1A
	db $46,$1B,$28
	db $FF
MuddyWaterExtAnimEnd:
	IF MuddyWaterExtAnimEnd - MuddyWaterExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

WhirlpoolExtAnim:
	db WhirlpoolExtAnimEnd - WhirlpoolExtAnimData
WhirlpoolExtAnimData:
	db SE_WATER_DROPLETS_EVERYWHERE,$38
	db $46,$2D,$15
	db SE_WAVY_SCREEN,$FF
	db $FF
WhirlpoolExtAnimEnd:
	IF WhirlpoolExtAnimEnd - WhirlpoolExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

GunkShotExtAnim:
	db GunkShotExtAnimEnd - GunkShotExtAnimData
GunkShotExtAnimData:
	db $46,$7B,$13
	db $43,$8B,$41
	db $46,$7B,$14
	db $FF
GunkShotExtAnimEnd:
	IF GunkShotExtAnimEnd - GunkShotExtAnimData > 30
		fail "Gunk Shot animation recipe exceeds wBuffer"
	ENDC

PoisonFangExtAnim:
	db PoisonFangExtAnimEnd - PoisonFangExtAnimData
PoisonFangExtAnimData:
	db $08,$2B,$02
	db $46,$32,$13
	db $46,$32,$14
	db $FF
PoisonFangExtAnimEnd:
	IF PoisonFangExtAnimEnd - PoisonFangExtAnimData > 30
		fail "Poison Fang animation recipe exceeds wBuffer"
	ENDC

HyperVoiceExtAnim:
	db HyperVoiceExtAnimEnd - HyperVoiceExtAnimData
HyperVoiceExtAnimData:
	; Play the attacker's actual cry using ROAR's pitch/tempo profile, then layer
	; the old sound-wave components without relying on wAnimationID == ROAR.
	db EXT_ANIM_PLAY_USER_CRY,ROAR
	db $46,$FF,$12
	db $46,$2D,$15
	db $50,$FF,$40
	db $FF
HyperVoiceExtAnimEnd:
	IF HyperVoiceExtAnimEnd - HyperVoiceExtAnimData > 30
		fail "Hyper Voice animation recipe exceeds wBuffer"
	ENDC

GigaDrainExtAnim:
	db GigaDrainExtAnimEnd - GigaDrainExtAnimData
GigaDrainExtAnimData:
	db SE_LEAVES_FALLING,$4A
	db $06,$FF,$21
	db $06,$FF,$22
	db $FF
GigaDrainExtAnimEnd:
	IF GigaDrainExtAnimEnd - GigaDrainExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

PetalBlizzardExtAnim:
	db PetalBlizzardExtAnimEnd - PetalBlizzardExtAnimData
PetalBlizzardExtAnimData:
	db SE_LIGHT_SCREEN_PALETTE,$4F
	db SE_PETALS_FALLING,$FF
	db $01,$0C,$16
	db SE_RESET_SCREEN_PALETTE,$FF
	db $FF
PetalBlizzardExtAnimEnd:
	IF PetalBlizzardExtAnimEnd - PetalBlizzardExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

LeafBladeExtAnim:
	db LeafBladeExtAnimEnd - LeafBladeExtAnimData
LeafBladeExtAnimData:
	db SE_LEAVES_FALLING,$4A
	db $06,$A2,$0F
	db $01,$0C,$16
	db $FF
LeafBladeExtAnimEnd:
	IF LeafBladeExtAnimEnd - LeafBladeExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

WoodHammerExtAnim:
	db WoodHammerExtAnimEnd - WoodHammerExtAnimData
WoodHammerExtAnimData:
	db SE_MOVE_MON_HORIZONTALLY,$48
	db $04,$57,$30
	db $46,$FF,$05
	db SE_RESET_MON_POSITION,$FF
	db $FF
WoodHammerExtAnimEnd:
	IF WoodHammerExtAnimEnd - WoodHammerExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

PoisonJabExtAnim:
	db PoisonJabExtAnimEnd - PoisonJabExtAnimData
PoisonJabExtAnimData:
	db $06,$27,$00
	db $46,$04,$04
	db $46,$7B,$14
	db $FF
PoisonJabExtAnimEnd:
	IF PoisonJabExtAnimEnd - PoisonJabExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

SludgeWaveExtAnim:
	db SludgeWaveExtAnimEnd - SludgeWaveExtAnimData
SludgeWaveExtAnimData:
	db SE_DARKEN_MON_PALETTE,$48
	db $46,$7B,$13
	db SE_WAVY_SCREEN,$FF
	db SE_RESET_SCREEN_PALETTE,$FF
	db $FF
SludgeWaveExtAnimEnd:
	IF SludgeWaveExtAnimEnd - SludgeWaveExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

SilverWindExtAnim:
	db SilverWindExtAnimEnd - SilverWindExtAnimData
SilverWindExtAnimData:
	db SE_LIGHT_SCREEN_PALETTE,$FF
	db $46,$0F,$10
	db SE_WATER_DROPLETS_EVERYWHERE,$38
	db SE_RESET_SCREEN_PALETTE,$FF
	db $FF
SilverWindExtAnimEnd:
	IF SilverWindExtAnimEnd - SilverWindExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

BugBuzzExtAnim:
	db BugBuzzExtAnimEnd - BugBuzzExtAnimData
BugBuzzExtAnimData:
	db $06,$2F,$31
	db $46,$2D,$15
	db SE_WAVY_SCREEN,$FF
	db $FF
BugBuzzExtAnimEnd:
	IF BugBuzzExtAnimEnd - BugBuzzExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

MegahornExtAnim:
	db MegahornExtAnimEnd - MegahornExtAnimData
MegahornExtAnimData:
	db $06,$1D,$45
	db $03,$29,$01
	db $46,$FF,$05
	db $FF
MegahornExtAnimEnd:
	IF MegahornExtAnimEnd - MegahornExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

XScissorExtAnim:
	db XScissorExtAnimEnd - XScissorExtAnimData
XScissorExtAnimData:
	db SE_DARK_SCREEN_FLASH,$0E
	db $04,$FF,$16
	db $04,$FF,$16
	db $FF
XScissorExtAnimEnd:
	IF XScissorExtAnimEnd - XScissorExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

SignalBeamExtAnim:
	db SignalBeamExtAnimEnd - SignalBeamExtAnimData
SignalBeamExtAnimData:
	db $03,$3B,$2E
	db $03,$29,$01
	db SE_FLASH_SCREEN_LONG,$FF
	db $FF
SignalBeamExtAnimEnd:
	IF SignalBeamExtAnimEnd - SignalBeamExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

EarthPowerExtAnim:
	db EarthPowerExtAnimEnd - EarthPowerExtAnimData
EarthPowerExtAnimData:
	db SE_SHAKE_SCREEN,$58
	db $03,$3B,$2E
	db SE_SHAKE_SCREEN,$FF
	db $FF
EarthPowerExtAnimEnd:
	IF EarthPowerExtAnimEnd - EarthPowerExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

MudSlapExtAnim:
	db MudSlapExtAnimEnd - MudSlapExtAnimData
MudSlapExtAnimData:
	db $46,$1B,$28
	db $08,$FF,$01
	db $FF
MudSlapExtAnimEnd:
	IF MudSlapExtAnimEnd - MudSlapExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

MudBombExtAnim:
	db MudBombExtAnimEnd - MudBombExtAnimData
MudBombExtAnimData:
	db $43,$8B,$41
	db $46,$1B,$28
	db SE_SHAKE_SCREEN,$FF
	db $FF
MudBombExtAnimEnd:
	IF MudBombExtAnimEnd - MudBombExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

ExtrasensoryExtAnim:
	db ExtrasensoryExtAnimEnd - ExtrasensoryExtAnimData
ExtrasensoryExtAnimData:
	db SE_FLASH_SCREEN_LONG,$5D
	db $06,$FF,$02
	db SE_WAVY_SCREEN,$FF
	db $FF
ExtrasensoryExtAnimEnd:
	IF ExtrasensoryExtAnimEnd - ExtrasensoryExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

ZenHeadbuttExtAnim:
	db ZenHeadbuttExtAnimEnd - ZenHeadbuttExtAnimData
ZenHeadbuttExtAnimData:
	db SE_FLASH_SCREEN_LONG,$5C
	db $46,$1C,$05
	db $46,$FF,$05
	db $FF
ZenHeadbuttExtAnimEnd:
	IF ZenHeadbuttExtAnimEnd - ZenHeadbuttExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

PsychoCutExtAnim:
	db PsychoCutExtAnimEnd - PsychoCutExtAnimData
PsychoCutExtAnimData:
	db SE_FLASH_SCREEN_LONG,$FF
	db $06,$A2,$0F
	db $04,$FF,$16
	db $FF
PsychoCutExtAnimEnd:
	IF PsychoCutExtAnimEnd - PsychoCutExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

ExtremespeedExtAnim:
	db ExtremespeedExtAnimEnd - ExtremespeedExtAnimData
ExtremespeedExtAnimData:
	db SE_SLIDE_MON_OFF,$61
	db $46,$FF,$04
	db $46,$FF,$05
	db SE_SHOW_MON_PIC,$FF
	db $FF
ExtremespeedExtAnimEnd:
	IF ExtremespeedExtAnimEnd - ExtremespeedExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

GigaImpactExtAnim:
	db GigaImpactExtAnimEnd - GigaImpactExtAnimData
GigaImpactExtAnimData:
	db SE_MOVE_MON_HORIZONTALLY,$48
	db SE_DARK_SCREEN_FLASH,$FF
	db $46,$04,$04
	db SE_SHAKE_SCREEN,$FF
	db SE_RESET_MON_POSITION,$FF
	db $FF
GigaImpactExtAnimEnd:
	IF GigaImpactExtAnimEnd - GigaImpactExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

PowerGemExtAnim:
	db PowerGemExtAnimEnd - PowerGemExtAnimData
PowerGemExtAnimData:
	db SE_LIGHT_SCREEN_PALETTE,$FF
	db $04,$57,$30
	db SE_DARK_SCREEN_FLASH,$FF
	db SE_RESET_SCREEN_PALETTE,$FF
	db $FF
PowerGemExtAnimEnd:
	IF PowerGemExtAnimEnd - PowerGemExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

RockBlastExtAnim:
	db RockBlastExtAnimEnd - RockBlastExtAnimData
RockBlastExtAnimData:
	db $04,$57,$30
	db $04,$57,$30
	db $04,$57,$30
	db $FF
RockBlastExtAnimEnd:
	IF RockBlastExtAnimEnd - RockBlastExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

RockPolishExtAnim:
	db RockPolishExtAnimEnd - RockPolishExtAnimData
RockPolishExtAnimData:
	db SE_LIGHT_SCREEN_PALETTE,$FF
	db $46,$6F,$33
	db SE_DARK_SCREEN_FLASH,$FF
	db SE_RESET_SCREEN_PALETTE,$FF
	db $FF
RockPolishExtAnimEnd:
	IF RockPolishExtAnimEnd - RockPolishExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

RockTombExtAnim:
	db RockTombExtAnimEnd - RockTombExtAnimData
RockTombExtAnimData:
	; Rock Slide's falling-rock frames expect frame-counter shakes/flash.
	db EXT_ANIM_SET_FRAME_EFFECT,EXT_FRAME_ROCK_SLIDE
	db $04,$9C,$1D
	db $03,$9C,$1E
	db EXT_ANIM_SET_FRAME_EFFECT,EXT_FRAME_NONE
	db SE_SHAKE_SCREEN,$FF
	db $FF
RockTombExtAnimEnd:
	IF RockTombExtAnimEnd - RockTombExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

DynamicpunchExtAnim:
	db DynamicpunchExtAnimEnd - DynamicpunchExtAnimData
DynamicpunchExtAnimData:
	db $46,$04,$04
	db SE_FLASH_SCREEN_LONG,$5C
	db SE_SHAKE_SCREEN,$FF
	db $FF
DynamicpunchExtAnimEnd:
	IF DynamicpunchExtAnimEnd - DynamicpunchExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

StormThrowExtAnim:
	db StormThrowExtAnimEnd - StormThrowExtAnimData
StormThrowExtAnimData:
	db $08,$01,$03
	db $46,$FF,$05
	db SE_SHAKE_SCREEN,$FF
	db $FF
StormThrowExtAnimEnd:
	IF StormThrowExtAnimEnd - StormThrowExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

CrossChopExtAnim:
	db CrossChopExtAnimEnd - CrossChopExtAnimData
CrossChopExtAnimData:
	db $08,$01,$03
	db $04,$FF,$16
	db $08,$01,$03
	db $FF
CrossChopExtAnimEnd:
	IF CrossChopExtAnimEnd - CrossChopExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

LowSweepExtAnim:
	db LowSweepExtAnimEnd - LowSweepExtAnimData
LowSweepExtAnimData:
	; Dedicated recipes bypass MEGA_KICK's hard-coded flash, so add an explicit
	; impact flash instead of depending on the legacy animation identity.
	db $46,$18,$04
	db SE_DARK_SCREEN_FLASH,$FF
	db $46,$FF,$05
	db SE_SHAKE_SCREEN,$FF
	db $FF
LowSweepExtAnimEnd:
	IF LowSweepExtAnimEnd - LowSweepExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

HurricaneExtAnim:
	db HurricaneExtAnimEnd - HurricaneExtAnimData
HurricaneExtAnimData:
	db $46,$0F,$10
	db $46,$2D,$15
	db SE_WAVY_SCREEN,$FF
	db SE_SHAKE_SCREEN,$FF
	db $FF
HurricaneExtAnimEnd:
	IF HurricaneExtAnimEnd - HurricaneExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

BabydolleyesExtAnim:
	db BabydolleyesExtAnimEnd - BabydolleyesExtAnimData
BabydolleyesExtAnimData:
	db $06,$8D,$12
	db SE_LIGHT_SCREEN_PALETTE,$FF
	db SE_DARK_SCREEN_FLASH,$FF
	db SE_RESET_SCREEN_PALETTE,$FF
	db $FF
BabydolleyesExtAnimEnd:
	IF BabydolleyesExtAnimEnd - BabydolleyesExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

BoneRushExtAnim:
	db BoneRushExtAnimEnd - BoneRushExtAnimData
BoneRushExtAnimData:
	db $06,$9A,$02
	db $06,$9A,$02
	db $06,$9A,$02
	db $FF
BoneRushExtAnimEnd:
	IF BoneRushExtAnimEnd - BoneRushExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

AeroblastExtAnim:
	db AeroblastExtAnimEnd - AeroblastExtAnimData
AeroblastExtAnimData:
	db $03,$3D,$2E
	db $46,$0F,$10
	db SE_DARK_SCREEN_FLASH,$FF
	db $FF
AeroblastExtAnimEnd:
	IF AeroblastExtAnimEnd - AeroblastExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

AncientpowerExtAnim:
	db AncientpowerExtAnimEnd - AncientpowerExtAnimData
AncientpowerExtAnimData:
	db $04,$9C,$1D
	db $04,$57,$30
	db SE_LIGHT_SCREEN_PALETTE,$FF
	db SE_RESET_SCREEN_PALETTE,$FF
	db $FF
AncientpowerExtAnimEnd:
	IF AncientpowerExtAnimEnd - AncientpowerExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

DiveExtAnim:
	db DiveExtAnimEnd - DiveExtAnimData
DiveExtAnimData:
	db SE_WATER_DROPLETS_EVERYWHERE,$38
	db SE_SLIDE_MON_DOWN,$48
	db $06,$37,$1A
	db SE_SLIDE_MON_UP,$FF
	db $FF
DiveExtAnimEnd:
	IF DiveExtAnimEnd - DiveExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

LusterPurgeExtAnim:
	db LusterPurgeExtAnimEnd - LusterPurgeExtAnimData
LusterPurgeExtAnimData:
	db SE_LIGHT_SCREEN_PALETTE,$48
	db $03,$3B,$2E
	db SE_DARK_SCREEN_FLASH,$FF
	db SE_RESET_SCREEN_PALETTE,$FF
	db $FF
LusterPurgeExtAnimEnd:
	IF LusterPurgeExtAnimEnd - LusterPurgeExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

MindBlastExtAnim:
	db MindBlastExtAnimEnd - MindBlastExtAnimData
MindBlastExtAnimData:
	db SE_DARK_SCREEN_PALETTE,$5D
	db SE_FLASH_SCREEN_LONG,$FF
	db SE_WAVY_SCREEN,$FF
	db SE_DARK_SCREEN_FLASH,$FF
	db SE_RESET_SCREEN_PALETTE,$FF
	db $FF
MindBlastExtAnimEnd:
	IF MindBlastExtAnimEnd - MindBlastExtAnimData > 30
		fail "extended move animation recipe exceeds wBuffer"
	ENDC

; Exact Gold BARRAGE_BALL source tiles after egg.2bpp --remove-whitespace:
; compact tiles $0A and $0B (source PNG tiles 14 and 16).  The right half is
; produced with OAM_HFLIP, just like Gold's BATTLE_ANIM_OAMSET_95.
GoldOrbAnimationTileset::
	db $00,$00,$00,$00,$03,$03,$0D,$0E,$12,$1C,$12,$1C,$21,$3E,$20,$3F
	db $20,$3F,$20,$3F,$10,$1F,$10,$1F,$0C,$0F,$03,$03,$00,$00,$00,$00
GoldOrbAnimationTilesetEnd::
	IF GoldOrbAnimationTilesetEnd - GoldOrbAnimationTileset != 2 * 16
		fail "Gold orb animation tileset must contain exactly 2 tiles"
	ENDC
