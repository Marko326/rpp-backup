; Dedicated animation recipes for expanded moves.
;
; Expanded move data still keeps a legacy animation byte for compatibility.
; PrepareCurrentMoveAnimation asks this bank for a dedicated recipe by REAL move
; ID. If no entry exists yet, the move safely falls back to its legacy animation.
;
; Each recipe starts with its byte length (including the $FF terminator). The
; command stream itself is copied into the existing 30-byte wBuffer.

LoadExtendedMoveAnimation:
; input: e = real move ID
; output: wMoveAnimScriptLoaded = 1 only if a dedicated recipe was found/staged
; callab/Bankswitch overwrites BC with its return trampoline, so DE carries the
; argument and is preserved across the bank switch.
	ld hl, ExtendedMoveAnimationTable
.search
	ld a, [hli]
	and a
	ret z
	cp e
	jr z, .found
	inc hl
	inc hl
	jr .search
.found
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

; Sparse table: batches are enabled only after their engine behavior is validated.
; Batches A6-B8 and B9-D7 are enabled as validated contiguous move-ID ranges.
ExtendedMoveAnimationTable:
	db METAL_CLAW
	dw MetalClawExtAnim
	db BULLET_PUNCH
	dw BulletPunchExtAnim
	db FLASH_CANNON
	dw FlashCannonExtAnim
	db IRON_TAIL
	dw IronTailExtAnim
	db METEOR_MASH
	dw MeteorMashExtAnim
	db CRUNCH
	dw CrunchExtAnim
	db DARK_PULSE
	dw DarkPulseExtAnim
	db FEINT_ATTACK
	dw FeintAttackExtAnim
	db NIGHT_SLASH
	dw NightSlashExtAnim
	db MOONBLAST
	dw MoonblastExtAnim
	db DRAININGKISS
	dw DrainingKissExtAnim
	db DISARM_VOICE
	dw DisarmingVoiceExtAnim
	db DAZZLINGLEAM
	dw DazzlingGleamExtAnim
	db DRACO_METEOR
	dw DracoMeteorExtAnim
	db DRAGONBREATH
	dw DragonbreathExtAnim
	db DRAGON_CLAW
	dw DragonClawExtAnim
	db DRAGON_PULSE
	dw DragonPulseExtAnim
	db TWISTER
	dw TwisterExtAnim
	db OUTRAGE
	dw OutrageExtAnim
	db SHADOW_CLAW
	dw ShadowClawExtAnim
	db STEEL_WING
	dw SteelWingExtAnim
	db IRON_DEFENSE
	dw IronDefenseExtAnim
	db AIR_SLASH
	dw AirSlashExtAnim
	db FIRE_FANG
	dw FireFangExtAnim
	db FLARE_BLITZ
	dw FlareBlitzExtAnim
	db BLAST_BURN
	dw BlastBurnExtAnim
	db ICE_FANG
	dw IceFangExtAnim
	db THUNDER_FANG
	dw ThunderFangExtAnim
	db WATER_PULSE
	dw WaterPulseExtAnim
	db AQUA_TAIL
	dw AquaTailExtAnim
	db HYDRO_CANNON
	dw HydroCannonExtAnim
	db FRENZY_PLANT
	dw FrenzyPlantExtAnim
	db SUCKER_PUNCH
	dw SuckerPunchExtAnim
	db SHADOW_BALL
	dw ShadowBallExtAnim
	db FLAME_WHEEL
	dw FlameWheelExtAnim
	db HEALINGLIGHT
	dw MoonlightExtAnim
	db HEX
	dw HexExtAnim
	db SHADOW_PUNCH
	dw ShadowPunchExtAnim
	db AERIAL_ACE
	dw AerialAceExtAnim
	db ACROBATICS
	dw AcrobaticsExtAnim
	db AIR_CUTTER
	dw AirCutterExtAnim
	db ICY_WIND
	dw IcyWindExtAnim
	db ICE_SHARD
	dw IceShardExtAnim
	db SHEER_COLD
	dw SheerColdExtAnim
	db ELECTRO_BALL
	dw ElectroBallExtAnim
	db NUZZLE
	dw NuzzleExtAnim
	db DISCHARGE
	dw DischargeExtAnim
	db VOLT_TACKLE
	dw VoltTackleExtAnim
	db MUDDY_WATER
	dw MuddyWaterExtAnim
	db WHIRLPOOL
	dw WhirlpoolExtAnim
	db GUNK_SHOT
	dw GunkShotExtAnim
	db POISON_FANG
	dw PoisonFangExtAnim
	db HYPER_VOICE
	dw HyperVoiceExtAnim
	db 0

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
	db SE_DARK_SCREEN_PALETTE,$FF
	db $04,$9C,$1D
	db $03,$9C,$1E
	db SE_SHAKE_SCREEN,$FF
	db SE_RESET_SCREEN_PALETTE,$FF
	db $FF
DracoMeteorExtAnimEnd:
	IF DracoMeteorExtAnimEnd - DracoMeteorExtAnimData > 30
		fail "Draco Meteor animation recipe exceeds wBuffer"
	ENDC

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
	; Darken, condense energy, launch a ball, then distort the screen on impact.
	db SE_DARK_SCREEN_PALETTE,$FF
	db SE_SPIRAL_BALLS_INWARD,$FF
	db $43,$8B,$41
	db $05,$FF,$55
	db SE_DARK_SCREEN_FLASH,$FF
	db SE_WAVY_SCREEN,$FF
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
