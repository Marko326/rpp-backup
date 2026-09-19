AttackAnimationPointers:
	dw PoundAnim
	dw KarateChopAnim
	dw DoubleSlapAnim
	dw CometPunchAnim
	dw MegaPunchAnim
	dw PayDayAnim
	dw FirePunchAnim
	dw IcePunchAnim
	dw ThunderPunchAnim
	dw ScratchAnim
	dw VicegripAnim
	dw GuillotineAnim
	dw RazorWindAnim
	dw SwordsDanceAnim
	dw CutAnim
	dw GustAnim
	dw WingAttackAnim
	dw WhirlwindAnim
	dw FlyAnim
	dw BindAnim
	dw SlamAnim
	dw VineWhipAnim
	dw StompAnim
	dw DoubleKickAnim
	dw MegaKickAnim
	dw JumpKickAnim
	dw RollingKickAnim
	dw SandAttackAnim
	dw HeatButtAnim
	dw HornAttackAnim
	dw FuryAttackAnim
	dw HornDrillAnim
	dw TackleAnim
	dw BodySlamAnim
	dw WrapAnim
	dw TakeDownAnim
	dw ThrashAnim
	dw DoubleEdgeAnim
	dw TailWhipAnim
	dw PoisonStingAnim
	dw TwineedleAnim
	dw PinMissileAnim
	dw LeerAnim
	dw BiteAnim
	dw GrowlAnim
	dw RoarAnim
	dw SingAnim
	dw SupersonicAnim
	dw SonicBoomAnim
	dw DisableAnim
	dw AcidAnim
	dw EmberAnim
	dw FlamethrowerAnim
	dw MistAnim
	dw WaterGunAnim
	dw HydroPumpAnim
	dw SurfAnim
	dw IceBeamAnim
	dw BlizzardAnim
	dw PsyBeamAnim
	dw BubbleBeamAnim
	dw AuroraBeamAnim
	dw HyperBeamAnim
	dw PeckAnim
	dw DrillPeckAnim
	dw SubmissionAnim
	dw LowKickAnim
	dw CounterAnim
	dw SeismicTossAnim
	dw StrengthAnim
	dw AbsorbAnim
	dw MegaDrainAnim
	dw LeechSeedAnim
	dw GrowthAnim
	dw RazorLeafAnim
	dw SolarBeamAnim
	dw PoisonPowderAnim
	dw StunSporeAnim
	dw SleepPowderAnim
	dw PedalDanceAnim
	dw StringShotAnim
	dw DragonRageAnim
	dw FireSpinAnim
	dw ThunderShockAnim
	dw ThunderBoltAnim
	dw ThunderWaveAnim
	dw ThunderAnim
	dw RockThrowAnim
	dw EarthquakeAnim
	dw FissureAnim
	dw DigAnim
	dw ToxicAnim
	dw ConfusionAnim
	dw PsychicAnim
	dw HypnosisAnim
	dw MeditateAnim
	dw AgilityAnim
	dw QuickAttackAnim
	dw RageAnim
	dw TeleportAnim
	dw NightShadeAnim
	dw MimicAnim
	dw ScreechAnim
	dw DoubleTeamAnim
	dw RecoverAnim
	dw HardenAnim
	dw MinimizeAnim
	dw SmokeScreenAnim
	dw ConfuseRayAnim
	dw WithdrawAnim
	dw DefenseCurlAnim
	dw BarrierAnim
	dw LightScreenAnim
	dw HazeAnim
	dw ReflectAnim
	dw FocusEnergyAnim
	dw BideAnim
	dw MetronomeAnim
	dw MirrorMoveAnim
	dw SelfdestructAnim
	dw EggBombAnim
	dw LickAnim
	dw SmogAnim
	dw SludgeAnim
	dw BoneClubAnim
	dw FireBlastAnim
	dw WaterfallAnim
	dw ClampAnim
	dw SwiftAnim
	dw SkullBashAnim
	dw SpikeCannonAnim
	dw ConstrictAnim
	dw AmnesiaAnim
	dw KinesisAnim
	dw SoftboiledAnim
	dw HiJumpKickAnim
	dw GlareAnim
	dw DreamEaterAnim
	dw PoisonGasAnim
	dw BarrageAnim
	dw LeechLifeAnim
	dw LovelyKissAnim
	dw SkyAttackAnim
	dw TransformAnim
	dw BubbleAnim
	dw DizzyPunchAnim
	dw SporeAnim
	dw FlashAnim
	dw PsywaveAnim
	dw SplashAnim
	dw AcidArmorAnim
	dw CrabHammerAnim
	dw ExplosionAnim
	dw FurySwipesAnim
	dw BonemerangAnim
	dw RestAnim
	dw RockSlideAnim
	dw HyperFangAnim
	dw SharpenAnim
	dw ConversionAnim
	dw TriAttackAnim
	dw SuperFangAnim
	dw SlashAnim
	dw SubstituteAnim
	dw StruggleAnim
	dw ShowPicAnim
	dw EnemyFlashAnim
	dw PlayerFlashAnim
	dw EnemyHUDShakeAnim
	dw TradeBallDropAnim
	dw TradeBallAppear1Anim
	dw TradeBallAppear2Anim
	dw TradeBallPoofAnim
	dw XStatItemAnim
	dw XStatItemAnim
	dw ShrinkingSquareAnim
	dw ShrinkingSquareAnim
	dw XStatItemBlackAnim
	dw XStatItemBlackAnim
	dw ShrinkingSquareBlackAnim
	dw ShrinkingSquareBlackAnim
	dw UnusedAnim
	dw UnusedAnim
	dw ParalyzeAnim
	dw ParalyzeAnim
	dw PoisonAnim
	dw PoisonAnim
	dw SleepPlayerAnim
	dw SleepEnemyAnim
	dw ConfusedPlayerAnim
	dw ConfusedEnemyAnim
	dw FaintAnim
	dw BallTossAnim
	dw BallShakeAnim
	dw BallPoofAnim
	dw BallBlockAnim
	dw GreatTossAnim
	dw UltraTossAnim
	dw ShakeScreenAnim
	dw HidePicAnim
	dw ThrowRockAnim
	dw ThrowBaitAnim
	dw ZigZagScreenAnim

; each animation is a list of subanimations and special effects
; if first byte < $56
;	db tileset_and_delay, sound_id, subanimation_id
; if first byte >= $D8
;	db special_effect_id, sound_id
; $FF terminated
PoundAnim:
StruggleAnim:
	db $08,$00,$01
	db $FF

KarateChopAnim:
	db $08,$01,$03
	db $FF

DoubleSlapAnim:
	db $05,$02,$01
	db $05,$02,$01
	db $FF

CometPunchAnim:
	db $04,$03,$02
	db $04,$03,$02
	db $FF

MegaPunchAnim:
	db $46,$04,$04
	db $FF

PayDayAnim:
	db $08,$00,$01
	db $04,$05,$52
	db $FF

FirePunchAnim:
	db $06,$06,$02
	db $46,$FF,$11
	db $FF

IcePunchAnim:
	db $06,$07,$02
	db $10,$FF,$2F
	db $FF

ThunderPunchAnim:
	db $06,$08,$02
	db SE_DARK_SCREEN_PALETTE, $FF
	db $46,$FF,$2B
	db SE_RESET_SCREEN_PALETTE, $FF
	db $FF

ScratchAnim:
	db $06,$09,$0F
	db $FF

VicegripAnim:
	db $08,$0A,$2A
	db $FF

GuillotineAnim:
	db $06,$0B,$2A
	db $FF

RazorWindAnim:
	db $04,$0C,$16
	db $FF

SwordsDanceAnim:
	db $46,$0D,$18
	db $46,$0D,$18
	db $46,$0D,$18
	db $FF

CutAnim:
	db SE_DARK_SCREEN_FLASH, $0E
	db $04,$FF,$16
	db $FF

GustAnim:
	db $46,$0F,$10
	db $06,$FF,$02
	db $FF

WingAttackAnim:
	db $46,$10,$04
	db $FF

WhirlwindAnim:
	db $46,$11,$10
	db SE_SLIDE_ENEMY_MON_OFF, $FF
	db $FF

FlyAnim:
	db $46,$12,$04
; EnemyFlashAnim is Fly's exact show-mon suffix.
EnemyFlashAnim:
	db SE_SHOW_MON_PIC, $FF
	db $FF

BindAnim:
	db $04,$13,$23
	db $04,$13,$23
	db $FF

SlamAnim:
	db $06,$14,$02
	db $FF

VineWhipAnim:
	db $01,$15,$16
	db $08,$FF,$01
	db $FF

StompAnim:
	db $48,$16,$05
	db $FF

DoubleKickAnim:
	db $08,$17,$01
	db $08,$17,$01
	db $FF

MegaKickAnim:
	db $46,$18,$04
	db $FF

JumpKickAnim:
	db $46,$19,$04
	db $FF

RollingKickAnim:
	db SE_DARK_SCREEN_FLASH, $1A
	db $46,$FF,$04
	db $FF

SandAttackAnim:
	db $46,$1B,$28
	db $FF

HeatButtAnim:
	db $46,$1C,$05
	db $FF

HornAttackAnim:
	db $06,$1D,$45
	db $46,$FF,$05
	db $FF

FuryAttackAnim:
	db $02,$1E,$46
	db $02,$FF,$46
	db $FF

HornDrillAnim:
	db $42,$1F,$05
	db $42,$FF,$05
	db $42,$FF,$05
	db $42,$FF,$05
	db $42,$FF,$05
	db $FF

TackleAnim:
	db SE_MOVE_MON_HORIZONTALLY, $48
	db SE_RESET_MON_POSITION, $FF
	db $FF

BodySlamAnim:
	db SE_MOVE_MON_HORIZONTALLY, $48
	db SE_DARK_SCREEN_FLASH, $FF
	db SE_DARK_SCREEN_FLASH, $FF
	db SE_RESET_MON_POSITION, $FF
	db $FF

WrapAnim:
	db $04,$22,$23
	db $04,$22,$23
	db $04,$22,$23
	db $FF

TakeDownAnim:
	db SE_MOVE_MON_HORIZONTALLY, $48
	db SE_DARK_SCREEN_FLASH, $23
	db SE_RESET_MON_POSITION, $FF
	db $FF

ThrashAnim:
	db $46,$24,$04
	db $FF

DoubleEdgeAnim:
	db SE_LIGHT_SCREEN_PALETTE, $48
	db $06,$FF,$2D
	db SE_RESET_SCREEN_PALETTE, $FF
	db SE_MOVE_MON_HORIZONTALLY, $FF
	db SE_DARK_SCREEN_FLASH, $25
	db SE_RESET_MON_POSITION, $FF
	db $FF

TailWhipAnim:
MetronomeAnim: ; identical script; share one immutable command stream
	db SE_MOVE_MON_HORIZONTALLY, $84
	db SE_DELAY_ANIMATION_10, $FF
	db SE_RESET_MON_POSITION, $84
	db SE_DELAY_ANIMATION_10, $FF
	db SE_MOVE_MON_HORIZONTALLY, $84
	db SE_DELAY_ANIMATION_10, $FF
	db SE_RESET_MON_POSITION, $84
	db $FF

PoisonStingAnim:
	db $06,$27,$00
	db $FF

TwineedleAnim:
	db $05,$28,$01
	db $05,$28,$01
	db $FF

PinMissileAnim:
	db $03,$29,$01
	db $FF

LeerAnim:
DisableAnim: ; identical script
	db SE_DARK_SCREEN_PALETTE, $48
	db SE_DARK_SCREEN_FLASH, $2A
	db SE_DARK_SCREEN_FLASH, $2A
	db SE_RESET_SCREEN_PALETTE, $FF
	db $FF

BiteAnim:
	db $08,$2B,$02
	db $FF

GrowlAnim:
	db $46,$2C,$12
	db $FF

RoarAnim:
	db $46,$2D,$15
	db $46,$2D,$15
	db $46,$2D,$15
	db $FF

SingAnim:
	db $46,$2E,$12
	db $50,$FF,$40
	db $50,$FF,$40
	db $FF

SupersonicAnim:
	db $06,$2F,$31
	db $FF

SonicBoomAnim:
	db $46,$2D,$15
	db $46,$2D,$15
	db $46,$0F,$10
	db $46,$FF,$05
	db $FF

AcidAnim:
	db $46,$32,$13
	db $46,$32,$14
	db $FF

EmberAnim:
	db $46,$33,$11
	db $FF

FlamethrowerAnim:
	db $46,$34,$1F
	db $46,$34,$0C
	db $46,$34,$0D
	db $FF

MistAnim:
	db SE_LIGHT_SCREEN_PALETTE, $FF
	db SE_WATER_DROPLETS_EVERYWHERE, $38
	db SE_RESET_SCREEN_PALETTE, $FF
	db $FF

WaterGunAnim:
	db $06,$36,$2C
	db $FF

HydroPumpAnim:
	db $06,$37,$1A
	db $06,$37,$1A
	db $FF

SurfAnim:
	db SE_WATER_DROPLETS_EVERYWHERE, $38
	db $06,$37,$1A
	db $FF

IceBeamAnim:
	db $03,$39,$2E
	db $10,$FF,$2F
	db $FF

BlizzardAnim:
	db $04,$3A,$38
	db $04,$37,$38
	db $FF

PsyBeamAnim:
	db $03,$3B,$2E
	db SE_FLASH_SCREEN_LONG, $FF
	db $FF

BubbleBeamAnim:
	db $12,$3C,$35
	db $FF

AuroraBeamAnim:
	db $03,$3D,$2E
	db SE_DELAY_ANIMATION_10, $FF
	db SE_DELAY_ANIMATION_10, $FF
	db $FF

HyperBeamAnim:
	db SE_DARK_SCREEN_PALETTE, $48
	db SE_SPIRAL_BALLS_INWARD, $FF
	db $02,$3E,$2E
	db SE_DARK_SCREEN_FLASH, $FF
	db SE_DARK_SCREEN_FLASH, $FF
	db $46,$04,$04
	db SE_RESET_SCREEN_PALETTE, $FF
	db $FF

PeckAnim:
	db $08,$3F,$01
	db $FF

DrillPeckAnim:
	db $46,$40,$04
	db $FF

SubmissionAnim:
	db SE_SLIDE_MON_OFF, $41
	db $06,$FF,$01
	db SE_SHOW_MON_PIC, $FF
	db $FF

LowKickAnim:
	db SE_SLIDE_MON_OFF, $42
	db $46,$FF,$04
	db SE_SHOW_MON_PIC, $FF
	db $FF

CounterAnim:
	db SE_SLIDE_MON_OFF, $43
	db $46,$FF,$04
	db SE_SHOW_MON_PIC, $FF
	db $FF

SeismicTossAnim:
	db SE_BLINK_ENEMY_MON, $FF
	db $41,$8B,$4E
	db SE_HIDE_ENEMY_MON_PIC, $FF
	db SE_SLIDE_MON_OFF, $FF
	db $42,$44,$4F
	db SE_DELAY_ANIMATION_10, $FF
	db SE_DELAY_ANIMATION_10, $FF
	db SE_SHOW_MON_PIC, $FF
	db $41,$44,$50
	db SE_SHOW_ENEMY_MON_PIC, $FF
	db SE_SHAKE_SCREEN, $FF
	db $FF

StrengthAnim:
	db SE_MOVE_MON_HORIZONTALLY, $48
	db SE_RESET_MON_POSITION, $FF
	db $46,$06,$04
	db $FF

AbsorbAnim:
	db SE_LIGHT_SCREEN_PALETTE, $46
	db $06,$FF,$21
	db $06,$FF,$22
	db SE_RESET_SCREEN_PALETTE, $FF
	db $FF

MegaDrainAnim:
	db SE_LIGHT_SCREEN_PALETTE, $47
	db SE_DARK_SCREEN_FLASH, $FF
	db $06,$FF,$21
	db $06,$FF,$22
	db SE_DARK_SCREEN_FLASH, $FF
	db SE_RESET_SCREEN_PALETTE, $FF
	db $FF

LeechSeedAnim:
	db $46,$48,$1B
	db $55,$4D,$1C
	db $FF

GrowthAnim:
	db SE_LIGHT_SCREEN_PALETTE, $49
	db SE_SPIRAL_BALLS_INWARD, $FF
	db SE_RESET_SCREEN_PALETTE, $FF
	db $FF

RazorLeafAnim:
	db SE_LEAVES_FALLING, $4A
	db $41,$80,$44
	db $01,$0C,$16
	db $FF

SolarBeamAnim:
	db $06,$4B,$2E
	db $06,$FF,$01
	db $FF

PoisonPowderAnim:
	db $06,$4C,$36
	db $FF

StunSporeAnim:
	db $06,$4D,$36
	db $FF

SleepPowderAnim:
	db $06,$4E,$36
	db $FF

PedalDanceAnim:
	db SE_LIGHT_SCREEN_PALETTE, $4F
	db SE_PETALS_FALLING, $FF
	db SE_RESET_SCREEN_PALETTE, $FF
	db $FF

StringShotAnim:
	db $08,$50,$37
	db $FF

DragonRageAnim:
	db $46,$51,$1F
	db $46,$FF,$0C
	db $46,$FF,$0D
	db $46,$FF,$0E
	db $FF

FireSpinAnim:
	db $46,$52,$0C
	db $46,$FF,$0D
	db $46,$FF,$0E
	db $FF

ThunderShockAnim:
	db $42,$53,$29
	db $FF

ThunderBoltAnim:
	db $41,$54,$29
	db $41,$54,$29
	db $FF

ThunderWaveAnim:
	db $42,$55,$29
	db $02,$FF,$23
	db $04,$FF,$23
	db $FF

ThunderAnim:
	db SE_DARK_SCREEN_PALETTE, $56
	db SE_DARK_SCREEN_FLASH, $FF
	db $46,$FF,$2B
	db SE_DARK_SCREEN_FLASH, $FF
	db $42,$54,$29
	db SE_RESET_SCREEN_PALETTE, $FF
	db $FF

RockThrowAnim:
	db $04,$57,$30
	db $FF

EarthquakeAnim:
	db SE_SHAKE_SCREEN, $58
	db SE_SHAKE_SCREEN, $58
	db $FF

FissureAnim:
	db SE_DARK_SCREEN_FLASH, $59
	db SE_SHAKE_SCREEN, $FF
	db SE_DARK_SCREEN_FLASH, $59
; Standalone screen-shake animation is Fissure's exact final suffix.
ShakeScreenAnim:
	db SE_SHAKE_SCREEN, $FF
	db $FF

DigAnim:
	db $46,$5A,$04
	db SE_SLIDE_MON_UP, $FF
	db $FF

ToxicAnim:
	db SE_WATER_DROPLETS_EVERYWHERE, $38
	db $46,$5B,$14
	db $FF

ConfusionAnim:
	db SE_FLASH_SCREEN_LONG, $5C
	db $FF

PsychicAnim:
	db SE_FLASH_SCREEN_LONG, $5D
; Legacy animation ID $CB is just Psychic's wavy-screen suffix.  Keep the
; public pointer-table entry, but share these final three bytes instead of
; storing a second identical command stream.
ZigZagScreenAnim:
	db SE_WAVY_SCREEN, $FF
	db $FF

HypnosisAnim:
	db SE_FLASH_SCREEN_LONG, $5E
	db $FF

MeditateAnim:
	db SE_LIGHT_SCREEN_PALETTE, $5F
	db $46,$FF,$43
	db SE_DARK_SCREEN_FLASH, $FF
	db SE_RESET_SCREEN_PALETTE, $FF
	db $FF

AgilityAnim:
	db SE_LIGHT_SCREEN_PALETTE, $60
	db SE_RESET_SCREEN_PALETTE, $FF
	db $FF

QuickAttackAnim:
	db SE_SLIDE_MON_OFF, $61
	db $46,$FF,$04
	db SE_SHOW_MON_PIC, $FF
	db $FF

RageAnim:
	db $06,$62,$01
	db $FF

TeleportAnim:
	db SE_SQUISH_MON_PIC, $63
	db SE_SHOOT_BALLS_UPWARD, $FF
	db $FF

NightShadeAnim:
	db SE_DARK_SCREEN_PALETTE, $5C
	db SE_WAVY_SCREEN, $FF
	db SE_RESET_SCREEN_PALETTE, $FF
	db $FF

MimicAnim:
	db $46,$65,$21
	db $46,$65,$22
	db $FF

ScreechAnim:
	db $46,$66,$12
	db $FF

DoubleTeamAnim:
	db SE_DARK_SCREEN_PALETTE, $FF
	db SE_DELAY_ANIMATION_10, $FF
	db SE_DELAY_ANIMATION_10, $FF
	db SE_DARK_SCREEN_FLASH, $FF
	db SE_DARK_SCREEN_FLASH, $FF
	db SE_RESET_SCREEN_PALETTE, $FF
	db SE_SHAKE_BACK_AND_FORTH, $67
	db SE_SHOW_MON_PIC, $FF
	db $46,$6F,$33
	db $FF

RecoverAnim:
	db SE_BLINK_MON, $68
; X-stat animation is Recover's exact palette/orb/reset suffix.
XStatItemAnim:
	db SE_LIGHT_SCREEN_PALETTE, $FF
	db SE_SPIRAL_BALLS_INWARD, $FF
	db SE_RESET_SCREEN_PALETTE, $FF
	db $FF

HardenAnim:
	db SE_LIGHT_SCREEN_PALETTE, $69
	db $46,$FF,$43
	db SE_DARK_SCREEN_FLASH, $FF
	db SE_RESET_SCREEN_PALETTE, $FF
	db $FF

MinimizeAnim:
	db SE_LIGHT_SCREEN_PALETTE, $6A
	db SE_SPIRAL_BALLS_INWARD, $FF
	db SE_MINIMIZE_MON, $FF
	db SE_RESET_SCREEN_PALETTE, $FF
	db $FF

SmokeScreenAnim:
	db $46,$6B,$28
	db $04,$FF,$0A
	db SE_DARKEN_MON_PALETTE, $FF
	db SE_DELAY_ANIMATION_10, $FF
	db SE_DELAY_ANIMATION_10, $FF
	db SE_DARK_SCREEN_PALETTE, $FF
	db SE_DELAY_ANIMATION_10, $FF
	db SE_DELAY_ANIMATION_10, $FF
	db SE_DELAY_ANIMATION_10, $FF
	db SE_DELAY_ANIMATION_10, $FF
	db SE_DELAY_ANIMATION_10, $FF
	db SE_DELAY_ANIMATION_10, $FF
	db SE_DARKEN_MON_PALETTE, $FF
	db SE_DELAY_ANIMATION_10, $FF
	db SE_RESET_SCREEN_PALETTE, $FF
	db $FF

ConfuseRayAnim:
	db SE_DARK_SCREEN_PALETTE, $6C
	db $46,$FF,$3E
	db SE_RESET_SCREEN_PALETTE, $FF
	db $FF

WithdrawAnim:
	db SE_LIGHT_SCREEN_PALETTE, $6E
	db SE_SLIDE_MON_DOWN, $FF
	db $06,$FF,$51
	db SE_RESET_SCREEN_PALETTE, $FF
	db SE_SHOW_MON_PIC, $FF
	db $FF

DefenseCurlAnim:
	db SE_LIGHT_SCREEN_PALETTE, $6E
	db $06,$FF,$43
	db SE_DARK_SCREEN_FLASH, $FF
	db SE_RESET_SCREEN_PALETTE, $FF
	db $FF

BarrierAnim:
	db $46,$6F,$33
	db $46,$6F,$33
	db $FF

LightScreenAnim:
	db SE_LIGHT_SCREEN_PALETTE, $FF
	db $46,$70,$33
	db $46,$70,$33
	db SE_RESET_SCREEN_PALETTE, $FF
	db $FF

HazeAnim:
	db SE_DARKEN_MON_PALETTE, $FF
	db SE_WATER_DROPLETS_EVERYWHERE, $38
	db SE_RESET_SCREEN_PALETTE, $FF
	db $FF

ReflectAnim:
	db SE_DARK_SCREEN_PALETTE, $FF
	db $46,$72,$33
	db $46,$72,$33
	db SE_RESET_SCREEN_PALETTE, $FF
	db $FF

FocusEnergyAnim:
	db SE_SPIRAL_BALLS_INWARD, $73
	db $FF

BideAnim:
	db $46,$74,$04
	db $FF

MirrorMoveAnim:
	; PureRGB transition recipe adapted to RPP IDs:
	; Conversion sound + Barrier visual, tileset 1, short delay 2.
	db $42,$9F,$33
	db $FF

SelfdestructAnim:
	db $43,$77,$34
	db $FF

EggBombAnim:
	db $44,$78,$41
	db $44,$78,$42
	db $FF

SmogAnim:
	db SE_DARKEN_MON_PALETTE, $48
	db $46,$7A,$19
	db SE_RESET_SCREEN_PALETTE, $FF
	db $FF

SludgeAnim:
	db $46,$7B,$13
; Lick is Sludge's final subanimation plus terminator.
LickAnim:
	db $46,$7B,$14
	db $FF

BoneClubAnim:
	db $08,$7C,$02
	db $FF

FireBlastAnim:
	db $46,$7D,$1F
	db $46,$FF,$20
	db $46,$FF,$20
	db $46,$FF,$0C
	db $46,$FF,$0D
	db $FF

WaterfallAnim:
	db SE_SLIDE_MON_DOWN, $48
	db $06,$37,$1A
	db $08,$FF,$02
	db SE_SLIDE_MON_UP, $FF
	db $FF

ClampAnim:
	db $08,$7F,$2A
	db $06,$83,$23
	db $06,$83,$23
	db $FF

SwiftAnim:
	db $43,$80,$3F
	db $FF

SkullBashAnim:
	db $46,$81,$05
	db $FF

SpikeCannonAnim:
	db $44,$82,$04
	db $FF

ConstrictAnim:
	db $06,$83,$23
	db $06,$83,$23
	db $06,$83,$23
	db $FF

AmnesiaAnim:
ConfusedPlayerAnim: ; identical script
	db $08,$84,$25
	db $08,$84,$25
	db $FF

KinesisAnim:
	db $08,$85,$01
	db $FF

SoftboiledAnim:
	db SE_SLIDE_MON_HALF_OFF, $48
	db $08,$86,$4C
	db SE_LIGHT_SCREEN_PALETTE, $FF
	db SE_SPIRAL_BALLS_INWARD, $FF
	db SE_RESET_SCREEN_PALETTE, $FF
	db SE_SHOW_MON_PIC, $FF
	db $FF

HiJumpKickAnim:
	db $46,$87,$04
	db $FF

GlareAnim:
	db SE_DARK_SCREEN_PALETTE, $48
	db SE_DARK_SCREEN_FLASH, $88
	db SE_DARK_SCREEN_FLASH, $FF
	db SE_RESET_SCREEN_PALETTE, $FF
	db $FF

DreamEaterAnim:
	db SE_FLASH_SCREEN_LONG, $89
	db SE_DARK_SCREEN_PALETTE, $89
	db $08,$89,$02
	db SE_RESET_SCREEN_PALETTE, $FF
	db $FF

PoisonGasAnim:
	db $46,$8A,$19
	db $FF

BarrageAnim:
	db $43,$8B,$41
	db $05,$FF,$55
	db $FF

LeechLifeAnim:
	db $08,$8C,$02
	db SE_DARK_SCREEN_FLASH, $FF
	db $06,$FF,$21
	db $06,$FF,$22
	db SE_DARK_SCREEN_FLASH, $FF
	db $FF

LovelyKissAnim:
	db $06,$8D,$12
	db $FF

SkyAttackAnim:
	db SE_SQUISH_MON_PIC, $8E
	db SE_SHOOT_BALLS_UPWARD, $FF
	db $46,$87,$04
	db SE_SHOW_MON_PIC, $FF
	db $FF

TransformAnim:
	db $46,$8F,$21
	db $44,$8F,$22
	db $08,$FF,$47
	db SE_TRANSFORM_MON, $FF
	db $FF

BubbleAnim:
	db $16,$90,$35
	db $FF

DizzyPunchAnim:
	db $06,$91,$17
	db $06,$91,$17
	db $06,$91,$17
	db $06,$02,$02
	db $FF

SporeAnim:
	db $06,$92,$36
	db $FF

FlashAnim:
	db SE_LIGHT_SCREEN_PALETTE, $48
	db SE_DARK_SCREEN_FLASH, $88
	db SE_DARK_SCREEN_FLASH, $FF
	db SE_RESET_SCREEN_PALETTE, $FF
	db $FF

PsywaveAnim:
	db $06,$2F,$31
	db SE_WAVY_SCREEN, $5C
	db $FF

SplashAnim:
	db SE_BOUNCE_UP_AND_DOWN, $95
	db $FF

AcidArmorAnim:
	db SE_SLIDE_MON_DOWN_AND_HIDE, $96
	db $FF

CrabHammerAnim:
	db $46,$97,$05
	db $06,$FF,$2A
	db $FF

ExplosionAnim:
	db $43,$98,$34
	db $FF

FurySwipesAnim:
	db $04,$99,$0F
	db $FF

BonemerangAnim:
	db $06,$9A,$02
	db $FF

RestAnim:
SleepPlayerAnim: ; identical script
	db $10,$9B,$3A
	db $10,$9B,$3A
	db $FF

RockSlideAnim:
	db $04,$9C,$1D
	db $03,$9C,$1E
	db $46,$9D,$04
	db $FF

HyperFangAnim:
	db $06,$9D,$02
	db $FF

SharpenAnim:
	db SE_LIGHT_SCREEN_PALETTE, $9E
	db $46,$FF,$43
	db SE_DARK_SCREEN_FLASH, $FF
	db SE_RESET_SCREEN_PALETTE, $FF
	db $FF

ConversionAnim:
	db SE_DARK_SCREEN_FLASH, $9F
	db $46,$FF,$21
	db $46,$FF,$22
	db SE_DARK_SCREEN_FLASH, $FF
	db $FF

TriAttackAnim:
	db SE_DARK_SCREEN_FLASH, $A0
	db $46,$FF,$4D
	db SE_DARK_SCREEN_FLASH, $FF
	db $FF

SuperFangAnim:
	db SE_DARK_SCREEN_PALETTE, $48
	db $46,$A1,$04
	db SE_RESET_SCREEN_PALETTE, $FF
	db $FF

SlashAnim:
	db $06,$A2,$0F
	db $FF

SubstituteAnim:
	db SE_SLIDE_MON_OFF, $A3
	db $08,$FF,$47
	db SE_SUBSTITUTE_MON, $FF
	db $FF

BallTossAnim:
	db $03,$FF,$06
	db $FF

GreatTossAnim:
	db $03,$FF,$07
	db $FF

UltraTossAnim:
	db $02,$FF,$08
	db $FF

BallShakeAnim:
	db $04,$FF,$09
	db $FF

BallPoofAnim:
	db $04,$FF,$0A
	db $FF

ShowPicAnim:
	db SE_SHOW_ENEMY_MON_PIC, $FF
	db $FF

HidePicAnim:
	db SE_HIDE_ENEMY_MON_PIC, $FF
	db $FF

PlayerFlashAnim:
	db SE_FLASH_MON_PIC, $FF
	db $FF

EnemyHUDShakeAnim:
	db SE_SHAKE_ENEMY_HUD, $FF
	db $FF

TradeBallDropAnim:
	db $86,$FF,$48
	db $FF

TradeBallAppear1Anim:
	db $84,$FF,$49
	db $FF

TradeBallAppear2Anim:
	db $86,$FF,$4A
	db $FF

TradeBallPoofAnim:
	db $86,$FF,$4B
	db $FF

ShrinkingSquareAnim:
	db SE_LIGHT_SCREEN_PALETTE, $FF
	db $46,$FF,$43
	db SE_RESET_SCREEN_PALETTE, $FF
	db $FF

XStatItemBlackAnim:
	db SE_DARKEN_MON_PALETTE, $FF
	db SE_SPIRAL_BALLS_INWARD, $FF
	db SE_RESET_SCREEN_PALETTE, $FF
	db $FF

ShrinkingSquareBlackAnim:
	db SE_DARKEN_MON_PALETTE, $FF
	db $46,$FF,$43
	db SE_RESET_SCREEN_PALETTE, $FF
	db $FF

UnusedAnim:
	db SE_LIGHT_SCREEN_PALETTE, $FF
	db SE_SHOOT_MANY_BALLS_UPWARD, $FF
	db SE_RESET_SCREEN_PALETTE, $FF
	db $FF

ParalyzeAnim:
	db $04,$13,$24
	db $04,$13,$24
	db $FF

PoisonAnim:
	db $08,$13,$27
	db $08,$13,$27
	db $FF

SleepEnemyAnim:
	db $10,$9B,$3B
	db $10,$9B,$3B
	db $FF

ConfusedEnemyAnim:
	db $08,$84,$26
	db $08,$84,$26
	db $FF

BallBlockAnim:
	db $03,$FF,$0B
	db $FF

FaintAnim:
	db SE_SLIDE_MON_DOWN, $5A
	db $FF

ThrowRockAnim:
	db $03,$8B,$53
	db $FF

ThrowBaitAnim:
	db $03,$8B,$54
	db $FF

; Subanimation source stays semantic even though ROM entries are packed to 2 bytes.
; Usage: subentry FrameBlock, BaseCoord, Mode
;   Mode 0 stores BaseCoord directly.
;   Modes 2/3/4 store a 6-bit index into SubanimationCoordTable and encode
;   the mode in byte 1 bits 7-6. Byte 0 bit 7 marks the packed-mode form.
; Keep SubanimationCoordTable append-only: existing coordinate indices are stable.
; To add a new nonzero-mode BaseCoord, append it to SubanimationCoordTable and
; add one matching lookup clause below using the next free index (currently 52-63).
subentry: MACRO
	assert (\1) < $80
	assert (\3) == 0 || (\3) == 2 || (\3) == 3 || (\3) == 4
	IF (\3) == 0
		db \1, \2
	ELSE
		DEF _subanim_coord_index = -1
		IF (\2) == $21
			DEF _subanim_coord_index = 0
		ENDC
		IF (\2) == $03
			DEF _subanim_coord_index = 1
		ENDC
		IF (\2) == $38
			DEF _subanim_coord_index = 2
		ENDC
		IF (\2) == $20
			DEF _subanim_coord_index = 3
		ENDC
		IF (\2) == $23
			DEF _subanim_coord_index = 4
		ENDC
		IF (\2) == $15
			DEF _subanim_coord_index = 5
		ENDC
		IF (\2) == $17
			DEF _subanim_coord_index = 6
		ENDC
		IF (\2) == $19
			DEF _subanim_coord_index = 7
		ENDC
		IF (\2) == $30
			DEF _subanim_coord_index = 8
		ENDC
		IF (\2) == $40
			DEF _subanim_coord_index = 9
		ENDC
		IF (\2) == $41
			DEF _subanim_coord_index = 10
		ENDC
		IF (\2) == $42
			DEF _subanim_coord_index = 11
		ENDC
		IF (\2) == $43
			DEF _subanim_coord_index = 12
		ENDC
		IF (\2) == $52
			DEF _subanim_coord_index = 13
		ENDC
		IF (\2) == $63
			DEF _subanim_coord_index = 14
		ENDC
		IF (\2) == $4d
			DEF _subanim_coord_index = 15
		ENDC
		IF (\2) == $97
			DEF _subanim_coord_index = 16
		ENDC
		IF (\2) == $98
			DEF _subanim_coord_index = 17
		ENDC
		IF (\2) == $58
			DEF _subanim_coord_index = 18
		ENDC
		IF (\2) == $00
			DEF _subanim_coord_index = 19
		ENDC
		IF (\2) == $02
			DEF _subanim_coord_index = 20
		ENDC
		IF (\2) == $07
			DEF _subanim_coord_index = 21
		ENDC
		IF (\2) == $0e
			DEF _subanim_coord_index = 22
		ENDC
		IF (\2) == $24
			DEF _subanim_coord_index = 23
		ENDC
		IF (\2) == $1c
			DEF _subanim_coord_index = 24
		ENDC
		IF (\2) == $16
			DEF _subanim_coord_index = 25
		ENDC
		IF (\2) == $05
			DEF _subanim_coord_index = 26
		ENDC
		IF (\2) == $0c
			DEF _subanim_coord_index = 27
		ENDC
		IF (\2) == $11
			DEF _subanim_coord_index = 28
		ENDC
		IF (\2) == $1b
			DEF _subanim_coord_index = 29
		ENDC
		IF (\2) == $2f
			DEF _subanim_coord_index = 30
		ENDC
		IF (\2) == $10
			DEF _subanim_coord_index = 31
		ENDC
		IF (\2) == $1d
			DEF _subanim_coord_index = 32
		ENDC
		IF (\2) == $22
			DEF _subanim_coord_index = 33
		ENDC
		IF (\2) == $2c
			DEF _subanim_coord_index = 34
		ENDC
		IF (\2) == $2a
			DEF _subanim_coord_index = 35
		ENDC
		IF (\2) == $99
			DEF _subanim_coord_index = 36
		ENDC
		IF (\2) == $62
			DEF _subanim_coord_index = 37
		ENDC
		IF (\2) == $0f
			DEF _subanim_coord_index = 38
		ENDC
		IF (\2) == $68
			DEF _subanim_coord_index = 39
		ENDC
		IF (\2) == $6a
			DEF _subanim_coord_index = 40
		ENDC
		IF (\2) == $69
			DEF _subanim_coord_index = 41
		ENDC
		IF (\2) == $73
			DEF _subanim_coord_index = 42
		ENDC
		IF (\2) == $83
			DEF _subanim_coord_index = 43
		ENDC
		IF (\2) == $84
			DEF _subanim_coord_index = 44
		ENDC
		IF (\2) == $85
			DEF _subanim_coord_index = 45
		ENDC
		IF (\2) == $01
			DEF _subanim_coord_index = 46
		ENDC
		IF (\2) == $28
			DEF _subanim_coord_index = 47
		ENDC
		IF (\2) == $26
			DEF _subanim_coord_index = 48
		ENDC
		IF (\2) == $12
			DEF _subanim_coord_index = 49
		ENDC
		IF (\2) == $1e
			DEF _subanim_coord_index = 50
		ENDC
		IF (\2) == $48
			DEF _subanim_coord_index = 51
		ENDC
		assert _subanim_coord_index >= 0
		assert _subanim_coord_index < $40
		db $80 | (\1), (((\3) - 1) << 6) | _subanim_coord_index
	ENDC
ENDM

SubanimationPointers:
	dw Subanimation00
	dw Subanimation01
	dw Subanimation02
	dw Subanimation03
	dw Subanimation04
	dw Subanimation05
	dw Subanimation06
	dw Subanimation07
	dw Subanimation08
	dw Subanimation09
	dw Subanimation0a
	dw Subanimation0b
	dw Subanimation0c
	dw Subanimation0d
	dw Subanimation0e
	dw Subanimation0f
	dw Subanimation10
	dw Subanimation11
	dw Subanimation12
	dw Subanimation13
	dw Subanimation14
	dw Subanimation15
	dw Subanimation16
	dw Subanimation17
	dw Subanimation18
	dw Subanimation19
	dw Subanimation1a
	dw Subanimation1b
	dw Subanimation1c
	dw Subanimation1d
	dw Subanimation1e
	dw Subanimation1f
	dw Subanimation20
	dw Subanimation21
	dw Subanimation22
	dw Subanimation23
	dw Subanimation24
	dw Subanimation25
	dw Subanimation26
	dw Subanimation27
	dw Subanimation28
	dw Subanimation29
	dw Subanimation2a
	dw Subanimation2b
	dw Subanimation2c
	dw Subanimation2d
	dw Subanimation2e
	dw Subanimation2f
	dw Subanimation30
	dw Subanimation31
	dw Subanimation32
	dw Subanimation33
	dw Subanimation34
	dw Subanimation35
	dw Subanimation36
	dw Subanimation37
	dw Subanimation38
	dw Subanimation39
	dw Subanimation3a
	dw Subanimation3b
	dw Subanimation3c
	dw Subanimation3d
	dw Subanimation3e
	dw Subanimation3f
	dw Subanimation40
	dw Subanimation41
	dw Subanimation42
	dw Subanimation43
	dw Subanimation44
	dw Subanimation45
	dw Subanimation46
	dw Subanimation47
	dw Subanimation48
	dw Subanimation49
	dw Subanimation4a
	dw Subanimation4b
	dw Subanimation4c
	dw Subanimation4d
	dw Subanimation4e
	dw Subanimation4f
	dw Subanimation50
	dw Subanimation51
	dw Subanimation52
	dw Subanimation53
	dw Subanimation54
	dw Subanimation55

Subanimation04:
	db $43
	subentry $02, $1a, 0
	subentry $02, $10, 0
	subentry $02, $03, 0

Subanimation05:
	db $41
	subentry $02, $10, 0

Subanimation08:
	db $0b
	subentry $03, $30, 0
	subentry $03, $44, 0
	subentry $03, $94, 0
	subentry $03, $60, 0
	subentry $03, $76, 0
	subentry $03, $9f, 0
	subentry $03, $8d, 0
	subentry $03, $a0, 0
	subentry $03, $1a, 0
	subentry $03, $a1, 0
	subentry $03, $34, 0

Subanimation07:
	db $0b
	subentry $03, $30, 0
	subentry $03, $a2, 0
	subentry $03, $31, 0
	subentry $03, $a3, 0
	subentry $03, $32, 0
	subentry $03, $a4, 0
	subentry $03, $92, 0
	subentry $03, $a5, 0
	subentry $03, $15, 0
	subentry $03, $a6, 0
	subentry $03, $34, 0

Subanimation06:
	db $0b
	subentry $03, $30, 0
	subentry $03, $a2, 0
	subentry $03, $93, 0
	subentry $03, $61, 0
	subentry $03, $73, 0
	subentry $03, $a7, 0
	subentry $03, $33, 0
	subentry $03, $a8, 0
	subentry $03, $0e, 0
	subentry $03, $a9, 0
	subentry $03, $34, 0

Subanimation09:
	db $04
	subentry $03, $21, 4
	subentry $04, $21, 4
	subentry $03, $21, 4
	subentry $05, $21, 4

Subanimation0a:
	db $46
	subentry $06, $1b, 0
	subentry $07, $1b, 0
	subentry $08, $36, 0
	subentry $09, $36, 0
	subentry $0a, $15, 0
	subentry $0a, $15, 0

Subanimation0b:
	db $04
	subentry $01, $2d, 0
	subentry $03, $2f, 0
	subentry $03, $35, 0
	subentry $03, $4d, 0

Subanimation55:
	db $41
	subentry $01, $9d, 0

Subanimation11:
	db $4c
	subentry $0b, $26, 0
	subentry $0c, $26, 0
	subentry $0b, $26, 0
	subentry $0c, $26, 0
	subentry $0b, $28, 0
	subentry $0c, $28, 0
	subentry $0b, $28, 0
	subentry $0c, $28, 0
	subentry $0b, $27, 0
	subentry $0c, $27, 0
	subentry $0b, $27, 0
	subentry $0c, $27, 0

Subanimation2b:
	db $4b
	subentry $0d, $03, 3
	subentry $0e, $03, 3
	subentry $0f, $03, 0
	subentry $0d, $11, 0
	subentry $0d, $11, 0
	subentry $0d, $37, 0
	subentry $0d, $37, 0
	subentry $10, $21, 0
	subentry $10, $21, 0
	subentry $11, $1b, 0
	subentry $11, $1b, 0

Subanimation2c:
	db $4c
	subentry $12, $01, 0
	subentry $12, $0f, 0
	subentry $12, $1b, 0
	subentry $12, $25, 0
	subentry $13, $38, 0
	subentry $13, $38, 2
	subentry $14, $38, 0
	subentry $14, $38, 2
	subentry $15, $38, 0
	subentry $15, $38, 0
	subentry $16, $38, 0
	subentry $16, $38, 0

Subanimation12:
	db $69
	subentry $17, $30, 0
	subentry $17, $39, 0
	subentry $17, $3a, 0
	subentry $17, $3b, 0
	subentry $17, $3c, 0
	subentry $17, $3d, 0
	subentry $17, $3e, 0
	subentry $17, $3f, 0
	subentry $17, $1f, 0

Subanimation00:
	db $41
	subentry $01, $17, 0

Subanimation01:
	db $42
	subentry $01, $0f, 0
	subentry $01, $1d, 0

Subanimation02:
	db $43
	subentry $01, $12, 0
	subentry $01, $15, 0
	subentry $01, $1c, 0

Subanimation03:
	db $44
	subentry $01, $0b, 0
	subentry $01, $11, 0
	subentry $01, $18, 0
	subentry $01, $1d, 0

Subanimation0c:
	db $43
	subentry $0c, $20, 0
	subentry $0c, $21, 0
	subentry $0c, $23, 0

Subanimation0d:
	db $46
	subentry $0c, $20, 2
	subentry $0c, $15, 0
	subentry $0c, $21, 2
	subentry $0c, $17, 0
	subentry $0c, $23, 2
	subentry $0c, $19, 0

Subanimation0e:
	db $49
	subentry $0c, $20, 2
	subentry $0c, $15, 2
	subentry $0c, $07, 0
	subentry $0c, $21, 2
	subentry $0c, $17, 2
	subentry $0c, $09, 0
	subentry $0c, $23, 2
	subentry $0c, $19, 2
	subentry $0c, $0c, 0

Subanimation1f:
	db $85
	subentry $0c, $30, 3
	subentry $0c, $40, 3
	subentry $0c, $41, 3
	subentry $0c, $42, 3
	subentry $0c, $21, 0

Subanimation2e:
	db $2e
	subentry $18, $43, 2
	subentry $75, $52, 4
	subentry $19, $43, 2
	subentry $75, $63, 4
	subentry $1a, $43, 2
	subentry $75, $4d, 4
	subentry $1b, $43, 2
	subentry $75, $97, 4
	subentry $1c, $43, 2
	subentry $75, $98, 4
	subentry $1d, $43, 2
	subentry $75, $58, 4
	subentry $1e, $43, 2
	subentry $75, $1b, 0

Subanimation2f:
	db $44
	subentry $1f, $24, 0
	subentry $20, $20, 0
	subentry $21, $1a, 0
	subentry $22, $15, 0

Subanimation30:
	db $52
	subentry $23, $00, 2
	subentry $23, $02, 2
	subentry $23, $04, 0
	subentry $23, $07, 2
	subentry $23, $02, 2
	subentry $23, $04, 0
	subentry $23, $0e, 2
	subentry $23, $02, 2
	subentry $23, $0c, 0
	subentry $25, $07, 0
	subentry $25, $0e, 0
	subentry $25, $15, 0
	subentry $24, $24, 2
	subentry $23, $1c, 2
	subentry $23, $23, 0
	subentry $23, $21, 2
	subentry $24, $28, 0
	subentry $24, $28, 0

Subanimation0f:
	db $4c
	subentry $26, $0e, 2
	subentry $26, $16, 2
	subentry $26, $1c, 0
	subentry $27, $0e, 2
	subentry $27, $16, 2
	subentry $27, $1c, 0
	subentry $28, $0e, 2
	subentry $28, $16, 2
	subentry $28, $1c, 0
	subentry $29, $0e, 2
	subentry $29, $16, 2
	subentry $29, $1c, 0

Subanimation16:
	db $4c
	subentry $2a, $05, 0
	subentry $2b, $05, 2
	subentry $2b, $0c, 2
	subentry $2a, $11, 4
	subentry $2b, $11, 2
	subentry $2b, $17, 2
	subentry $2a, $1b, 4
	subentry $2b, $1b, 2
	subentry $2b, $20, 2
	; Keep the final complete Cut head in its own OAM slots.  Mode 3 advances
	; the destination after the normal delay, so the following off-screen $2c
	; cleanup frames cannot overwrite half of FrameBlock2a.
	subentry $2a, $2f, 3
	subentry $2c, $00, 2
	subentry $2c, $00, 0

Subanimation10:
	db $88
	subentry $2d, $44, 0
	subentry $2e, $45, 0
	subentry $2d, $46, 0
	subentry $2e, $47, 0
	subentry $2d, $48, 0
	subentry $2e, $49, 0
	subentry $2d, $2f, 0
	subentry $2e, $1a, 0

Subanimation31:
	db $2a
	subentry $2f, $46, 0
	subentry $2f, $4a, 0
	subentry $2f, $4b, 0
	subentry $2f, $4c, 0
	subentry $2f, $4d, 0
	subentry $2f, $4e, 0
	subentry $2f, $4f, 0
	subentry $2f, $50, 0
	subentry $2f, $2e, 0
	subentry $2f, $51, 0

Subanimation13:
	db $86
	subentry $30, $31, 0
	subentry $30, $32, 0
	subentry $30, $92, 0
	subentry $30, $0e, 0
	subentry $30, $0f, 0
	subentry $30, $10, 0

Subanimation14:
	db $49
	subentry $30, $10, 0
	subentry $30, $10, 3
	subentry $31, $1c, 4
	subentry $31, $21, 4
	subentry $31, $26, 0
	subentry $30, $10, 2
	subentry $31, $1d, 4
	subentry $31, $22, 4
	subentry $31, $27, 0

Subanimation41:
	db $85
	subentry $03, $31, 0
	subentry $03, $32, 0
	subentry $03, $92, 0
	subentry $03, $0e, 0
	subentry $03, $10, 0

Subanimation42:
	db $43
	subentry $48, $08, 0
	subentry $49, $08, 0
	subentry $5a, $08, 0

Subanimation15:
	db $22
	subentry $35, $52, 0
	subentry $35, $53, 0

Subanimation17:
	db $44
	subentry $36, $54, 0
	subentry $36, $55, 0
	subentry $37, $56, 0
	subentry $37, $57, 0

Subanimation18:
	db $a4
	subentry $36, $54, 0
	subentry $36, $55, 0
	subentry $37, $56, 0
	subentry $37, $57, 0

Subanimation40:
	db $46
	subentry $17, $54, 0
	subentry $17, $55, 0
	subentry $17, $0e, 0
	subentry $17, $56, 0
	subentry $17, $57, 0
	subentry $17, $13, 0

Subanimation19:
	db $8c
	subentry $38, $31, 0
	subentry $39, $31, 0
	subentry $38, $32, 0
	subentry $39, $32, 0
	subentry $38, $92, 0
	subentry $39, $92, 0
	subentry $38, $0e, 0
	subentry $39, $0e, 0
	subentry $38, $0f, 0
	subentry $39, $0f, 0
	subentry $38, $10, 0
	subentry $39, $10, 0

Subanimation1a:
	db $50
	subentry $3a, $08, 0
	subentry $3b, $08, 0
	subentry $3c, $08, 0
	subentry $3d, $08, 0
	subentry $3e, $08, 0
	subentry $3f, $08, 0
	subentry $3e, $08, 0
	subentry $3f, $08, 0
	subentry $3a, $0b, 0
	subentry $3b, $0b, 0
	subentry $3c, $0b, 0
	subentry $3d, $0b, 0
	subentry $3e, $0b, 0
	subentry $3f, $0b, 0
	subentry $3e, $0b, 0
	subentry $3f, $0b, 0

Subanimation1b:
	db $84
	subentry $40, $31, 0
	subentry $40, $32, 0
	subentry $40, $92, 0
	subentry $40, $15, 0

Subanimation1c:
	db $43
	subentry $41, $58, 0
	subentry $41, $59, 0
	subentry $41, $21, 0

Subanimation1d:
	db $af
	subentry $24, $9a, 0
	subentry $23, $1b, 2
	subentry $24, $22, 0
	subentry $23, $16, 2
	subentry $23, $1d, 2
	subentry $24, $98, 0
	subentry $25, $2c, 4
	subentry $25, $2a, 4
	subentry $25, $99, 4
	subentry $25, $62, 4
	subentry $25, $99, 4
	subentry $25, $62, 4
	subentry $25, $99, 4
	subentry $25, $62, 4
	subentry $25, $99, 3

Subanimation1e:
	db $01
	subentry $25, $75, 0

Subanimation20:
	db $42
	subentry $42, $07, 0
	subentry $43, $07, 0

Subanimation21:
	db $43
	subentry $44, $00, 0
	subentry $45, $08, 0
	subentry $46, $10, 2

Subanimation22:
	db $8b
	subentry $47, $10, 0
	subentry $47, $56, 0
	subentry $47, $07, 0
	subentry $47, $aa, 0
	subentry $47, $ab, 0
	subentry $47, $ac, 0
	subentry $47, $ad, 0
	subentry $47, $ae, 0
	subentry $47, $af, 0
	subentry $47, $89, 0
	subentry $47, $b0, 0

Subanimation2d:
	db $26
	subentry $44, $64, 0
	subentry $45, $65, 0
	subentry $46, $66, 0
	subentry $47, $66, 0
	subentry $47, $66, 0
	subentry $47, $66, 0

; Reserved unused subanimation slot $39: currently has no runtime references.
; Safe to replace with a future custom subanimation; keep this pointer ID stable.
Subanimation39:
	db $61
	subentry $47, $67, 0

Subanimation4e:
	db $41
	subentry $71, $0f, 3

Subanimation4f:
	db $47
	subentry $71, $0f, 0
	subentry $71, $08, 0
	subentry $71, $01, 0
	subentry $71, $95, 0
	subentry $72, $95, 0
	subentry $73, $95, 0
	subentry $74, $95, 0

Subanimation50:
	db $48
	subentry $74, $95, 0
	subentry $73, $95, 0
	subentry $72, $95, 0
	subentry $71, $95, 0
	subentry $71, $01, 0
	subentry $71, $08, 0
	subentry $71, $0f, 0
	subentry $71, $16, 0

Subanimation29:
	db $5d
	subentry $48, $0f, 0
	subentry $4a, $68, 3
	subentry $4b, $2a, 3
	subentry $49, $0f, 0
	subentry $4a, $68, 3
	subentry $4b, $2a, 0
	subentry $4c, $6a, 3
	subentry $4d, $69, 3
	subentry $49, $6b, 0
	subentry $4c, $6a, 3
	subentry $4d, $69, 0
	subentry $4a, $68, 3
	subentry $4b, $2a, 3
	subentry $49, $6c, 0
	subentry $4a, $68, 3
	subentry $4b, $2a, 0
	subentry $4c, $6a, 3
	subentry $4d, $69, 3
	subentry $49, $6d, 0
	subentry $4c, $6a, 3
	subentry $4d, $2a, 0
	subentry $4a, $68, 3
	subentry $4b, $2a, 3
	subentry $49, $0f, 0
	subentry $4a, $68, 3
	subentry $4b, $2a, 0
	subentry $4c, $6a, 3
	subentry $4d, $2a, 3
	subentry $49, $6b, 0

Subanimation2a:
	db $44
	subentry $4e, $2b, 0
	subentry $4f, $2b, 0
	subentry $50, $2b, 0
	subentry $50, $2b, 0

Subanimation23:
	db $42
	subentry $51, $2d, 0
	subentry $51, $6e, 0

Subanimation24:
	db $a2
	subentry $51, $2d, 0
	subentry $51, $6e, 0

Subanimation25:
	db $62
	subentry $52, $71, 0
	subentry $52, $72, 0

Subanimation26:
	db $02
	subentry $52, $01, 0
	subentry $52, $2c, 0

Subanimation3a:
	db $63
	subentry $53, $71, 0
	subentry $53, $7f, 0
	subentry $53, $81, 0

Subanimation3b:
	db $03
	subentry $53, $01, 0
	subentry $53, $15, 0
	subentry $53, $2c, 0

Subanimation27:
	db $a2
	subentry $54, $01, 0
	subentry $54, $2c, 0

Subanimation28:
	db $23
	subentry $55, $73, 3
	subentry $56, $73, 3
	subentry $57, $73, 0

; Reserved unused subanimation slot $32: currently has no runtime references.
; Safe to replace with a future custom subanimation; keep this pointer ID stable.
Subanimation32:
	db $63
	subentry $47, $74, 0
	subentry $47, $43, 0
	subentry $47, $75, 0

Subanimation33:
	db $26
	subentry $58, $76, 0
	subentry $34, $76, 0
	subentry $58, $76, 0
	subentry $34, $76, 0
	subentry $58, $76, 0
	subentry $34, $76, 0

; Reserved unused subanimation slot $3C: currently has no runtime references.
; Safe to replace with a future custom subanimation; keep this pointer ID stable.
Subanimation3c:
	; Shadow Ball V7-style short poof: FrameBlocks 06-09 only.
	; Type 2 mirrors the poof for an enemy attacker, matching Subanimation0a.
	db $44
	subentry $06, $1b, 0
	subentry $07, $1b, 0
	subentry $08, $36, 0
	subentry $09, $36, 0

; Reserved unused subanimation slot $3D: currently has no runtime references.
; Safe to replace with a future custom subanimation; keep this pointer ID stable.
Subanimation3d:
	db $08
	subentry $3a, $4d, 0
	subentry $3b, $4d, 0
	subentry $3c, $4d, 0
	subentry $3d, $4d, 0
	subentry $3e, $4d, 0
	subentry $3f, $4d, 0
	subentry $3e, $4d, 0
	subentry $3f, $4d, 0

Subanimation34:
	db $35
	subentry $48, $7d, 0
	subentry $49, $7d, 0
	subentry $5a, $7d, 0
	subentry $48, $30, 0
	subentry $49, $30, 0
	subentry $5a, $30, 0
	subentry $48, $7e, 0
	subentry $49, $7e, 0
	subentry $5a, $7e, 0
	subentry $48, $7f, 0
	subentry $49, $7f, 0
	subentry $5a, $7f, 0
	subentry $48, $80, 0
	subentry $49, $80, 0
	subentry $5a, $80, 0
	subentry $48, $81, 0
	subentry $49, $81, 0
	subentry $5a, $81, 0
	subentry $48, $82, 0
	subentry $49, $82, 0
	subentry $5a, $82, 0

Subanimation35:
	db $24
	subentry $5b, $83, 3
	subentry $5c, $84, 3
	subentry $5d, $85, 3
	subentry $5e, $09, 0

Subanimation36:
	db $48
	subentry $5f, $2a, 0
	subentry $5f, $00, 0
	subentry $60, $2a, 0
	subentry $60, $00, 0
	subentry $61, $2a, 0
	subentry $61, $00, 0
	subentry $62, $2a, 0
	subentry $62, $00, 0

Subanimation37:
	db $2a
	subentry $63, $89, 0
	subentry $64, $75, 0
	subentry $63, $76, 0
	subentry $65, $0d, 0
	subentry $65, $86, 0
	subentry $65, $12, 0
	subentry $65, $87, 0
	subentry $65, $17, 0
	subentry $65, $88, 0
	subentry $65, $1a, 0

Subanimation38:
	db $50
	subentry $66, $8a, 0
	subentry $66, $33, 0
	subentry $66, $2e, 0
	subentry $67, $24, 3
	subentry $66, $01, 4
	subentry $66, $10, 4
	subentry $66, $1d, 4
	subentry $67, $28, 3
	subentry $66, $2a, 4
	subentry $66, $0e, 4
	subentry $66, $1b, 4
	subentry $67, $26, 3
	subentry $66, $03, 4
	subentry $66, $12, 4
	subentry $66, $1e, 4
	subentry $67, $29, 0

Subanimation3e:
	db $92
	subentry $02, $31, 0
	subentry $34, $31, 0
	subentry $02, $31, 0
	subentry $02, $32, 0
	subentry $34, $32, 0
	subentry $02, $32, 0
	subentry $02, $92, 0
	subentry $34, $92, 0
	subentry $02, $92, 0
	subentry $02, $0e, 0
	subentry $34, $0e, 0
	subentry $02, $0e, 0
	subentry $02, $0f, 0
	subentry $34, $0f, 0
	subentry $02, $0f, 0
	subentry $02, $10, 0
	subentry $34, $10, 0
	subentry $02, $10, 0

Subanimation3f:
	db $72
	subentry $68, $4b, 0
	subentry $68, $8c, 0
	subentry $68, $20, 0
	subentry $68, $1c, 0
	subentry $68, $19, 0
	subentry $68, $14, 0
	subentry $68, $76, 0
	subentry $68, $8d, 0
	subentry $68, $15, 0
	subentry $68, $10, 0
	subentry $68, $0c, 0
	subentry $68, $06, 0
	subentry $68, $8e, 0
	subentry $68, $8f, 0
	subentry $68, $90, 0
	subentry $68, $26, 0
	subentry $68, $23, 0
	subentry $68, $1f, 0

Subanimation44:
	db $2c
	subentry $69, $4b, 0
	subentry $69, $8c, 0
	subentry $69, $20, 0
	subentry $69, $1c, 0
	subentry $69, $19, 0
	subentry $69, $14, 0
	subentry $69, $76, 0
	subentry $69, $8d, 0
	subentry $69, $15, 0
	subentry $69, $10, 0
	subentry $69, $0c, 0
	subentry $69, $06, 0

Subanimation43:
	db $a3
	subentry $6a, $07, 0
	subentry $6b, $0f, 0
	subentry $6c, $17, 0

Subanimation45:
	db $24
	subentry $6d, $8b, 0
	subentry $6d, $84, 0
	subentry $6d, $63, 0
	subentry $6d, $8c, 0

Subanimation46:
	db $26
	subentry $6d, $8b, 0
	subentry $6d, $84, 0
	subentry $6d, $63, 0
	subentry $6d, $8c, 0
	subentry $6d, $0a, 0
	subentry $6d, $89, 0

Subanimation47:
	db $23
	subentry $06, $82, 0
	subentry $07, $82, 0
	subentry $08, $96, 0

Subanimation48:
	db $06
	subentry $03, $41, 4
	subentry $03, $48, 4
	subentry $04, $48, 4
	subentry $03, $48, 4
	subentry $05, $48, 4
	subentry $03, $48, 3

Subanimation49:
	db $04
	subentry $04, $48, 4
	subentry $03, $48, 4
	subentry $05, $48, 4
	subentry $03, $48, 3

Subanimation4a:
	db $01
	subentry $04, $84, 3

Subanimation4b:
	db $03
	subentry $06, $72, 0
	subentry $07, $72, 0
	subentry $08, $72, 0

Subanimation4c:
	db $68
	subentry $6f, $30, 0
	subentry $6e, $30, 0
	subentry $70, $30, 0
	subentry $6e, $30, 0
	subentry $6f, $30, 0
	subentry $6e, $30, 0
	subentry $70, $30, 0
	subentry $6e, $30, 0

Subanimation4d:
	db $26
	subentry $32, $4b, 0
	subentry $33, $4f, 0
	subentry $32, $20, 0
	subentry $33, $16, 0
	subentry $32, $19, 0
	subentry $33, $0d, 0

Subanimation51:
	db $a6
	subentry $76, $1b, 0
	subentry $34, $1b, 0
	subentry $76, $1b, 0
	subentry $34, $1b, 0
	subentry $76, $1b, 0
	subentry $34, $1b, 0

Subanimation52:
	db $47
	subentry $77, $25, 0
	subentry $77, $9b, 0
	subentry $77, $1a, 0
	subentry $77, $9c, 0
	subentry $77, $2f, 0
	subentry $77, $50, 0
	subentry $77, $8c, 0

Subanimation53:
	db $0c
	subentry $78, $30, 0
	subentry $78, $a2, 0
	subentry $78, $93, 0
	subentry $78, $61, 0
	subentry $78, $73, 0
	subentry $78, $a7, 0
	subentry $78, $33, 0
	subentry $78, $a8, 0
	subentry $78, $0e, 0
	subentry $78, $a9, 0
	subentry $78, $34, 0
	subentry $01, $9e, 0

Subanimation54:
	db $0b
	subentry $79, $30, 0
	subentry $79, $a2, 0
	subentry $79, $93, 0
	subentry $79, $61, 0
	subentry $79, $73, 0
	subentry $79, $a7, 0
	subentry $79, $33, 0
	subentry $79, $a8, 0
	subentry $79, $0e, 0
	subentry $79, $a9, 0
	subentry $79, $34, 0


; Compact nonzero-mode coordinate table for 2-byte subanimation entries.
; Entry byte 0: bit 7 marks a nonzero mode, bits 0-6 are FrameBlock ID.
; Entry byte 1: mode-0 entries store BaseCoord ID directly. For marked entries,
; bits 7-6 encode modes 2/3/4 as 1/2/3 and bits 5-0 index this table.
; Shared BaseCoord table for nonzero-mode subentries.
; IMPORTANT: append new coordinates only; do not reorder existing entries.
; The subentry macro resolves raw BaseCoord values to these stable 6-bit indices.
SubanimationCoordTable:
	db $21,$03,$38,$20,$23,$15,$17,$19,$30,$40,$41,$42 ; indices 0-11
	db $43,$52,$63,$4d,$97,$98,$58,$00,$02,$07,$0e,$24 ; indices 12-23
	db $1c,$16,$05,$0c,$11,$1b,$2f,$10,$1d,$22,$2c,$2a ; indices 24-35
	db $99,$62,$0f,$68,$6a,$69,$73,$83,$84,$85,$01,$28 ; indices 36-47
	db $26,$12,$1e,$48 ; indices 48-51
SubanimationCoordTableEnd:

ASSERT SubanimationCoordTableEnd - SubanimationCoordTable == 52
ASSERT SubanimationCoordTableEnd - SubanimationCoordTable <= $40

FrameBlockPointers:
	dw FrameBlock00
	dw FrameBlock01
	dw FrameBlock02
	dw FrameBlock03
	dw FrameBlock04
	dw FrameBlock05
	dw FrameBlock06
	dw FrameBlock07
	dw FrameBlock08
	dw FrameBlock09
	dw FrameBlock0a
	dw FrameBlock0b
	dw FrameBlock0c
	dw FrameBlock0d
	dw FrameBlock0e
	dw FrameBlock0f
	dw FrameBlock10
	dw FrameBlock11
	dw FrameBlock12
	dw FrameBlock13
	dw FrameBlock14
	dw FrameBlock15
	dw FrameBlock16
	dw FrameBlock17
	dw FrameBlock18
	dw FrameBlock19
	dw FrameBlock1a
	dw FrameBlock1b
	dw FrameBlock1c
	dw FrameBlock1d
	dw FrameBlock1e
	dw FrameBlock1f
	dw FrameBlock20
	dw FrameBlock21
	dw FrameBlock22
	dw FrameBlock23
	dw FrameBlock24
	dw FrameBlock25
	dw FrameBlock26
	dw FrameBlock27
	dw FrameBlock28
	dw FrameBlock29
	dw FrameBlock2a
	dw FrameBlock2b
	dw FrameBlock2c
	dw FrameBlock2d
	dw FrameBlock2e
	dw FrameBlock2f
	dw FrameBlock30
	dw FrameBlock31
	dw FrameBlock32
	dw FrameBlock33
	dw FrameBlock34
	dw FrameBlock35
	dw FrameBlock36
	dw FrameBlock37
	dw FrameBlock38
	dw FrameBlock39
	dw FrameBlock3a
	dw FrameBlock3b
	dw FrameBlock3c
	dw FrameBlock3d
	dw FrameBlock3e
	dw FrameBlock3f
	dw FrameBlock40
	dw FrameBlock41
	dw FrameBlock42
	dw FrameBlock43
	dw FrameBlock44
	dw FrameBlock45
	dw FrameBlock46
	dw FrameBlock47
	dw SmallBlackCircleFrameBlock
	dw LargeBlockCircleFrameBlock
	dw FrameBlock4a
	dw FrameBlock4b
	dw FrameBlock4c
	dw FrameBlock4d
	dw FrameBlock4e
	dw FrameBlock4f
	dw FrameBlock50
	dw FrameBlock51
	dw FrameBlock52
	dw FrameBlock53
	dw FrameBlock54
	dw FrameBlock55
	dw FrameBlock56
	dw FrameBlock57
	dw FrameBlock58
	dw FrameBlock59
	dw FrameBlock5a
	dw FrameBlock5b
	dw FrameBlock5c
	dw FrameBlock5d
	dw FrameBlock5e
	dw FrameBlock5f
	dw FrameBlock60
	dw FrameBlock61
	dw FrameBlock62
	dw FrameBlock63
	dw FrameBlock64
	dw FrameBlock65
	dw FrameBlock66
	dw FrameBlock67
	dw FrameBlock68
	dw FrameBlock69
	dw FrameBlock6a
	dw FrameBlock6b
	dw FrameBlock6c
	dw FrameBlock6d
	dw FrameBlock6e
	dw FrameBlock6f
	dw FrameBlock70
	dw FrameBlock71
	dw FrameBlock72
	dw FrameBlock73
	dw FrameBlock74
	dw FrameBlock75
	dw FrameBlock76
	dw FrameBlock77
	dw FrameBlock78
	dw FrameBlock79
	dw PunchFrameBlock ; $7A - shared Punch family 16x16 contact object

; FrameBlock format is as follows:
; first byte = number of tiles in FrameBlock
;
; Next, each group of 4 bytes describes a tile in the FrameBlock
; first byte = y offset
; second byte = x offset
; third byte = tile id (it's actually tile id - $31)
; fourth byte = tile properties (xflip/yflip/etc.)
FrameBlock01:
	db $09
	db $00,$00,$2c,$00
	db $00,$08,$2d,$00
	db $00,$10,$2c,$20
	db $08,$00,$3c,$00
	db $08,$08,$3d,$00
	db $08,$10,$3c,$20
	db $10,$00,$2c,$40
	db $10,$08,$2d,$40
	db $10,$10,$2c,$60

FrameBlock02:
	db $10
	db $00,$00,$20,$00
	db $00,$08,$21,$00
	db $00,$10,$21,$20
	db $00,$18,$20,$20
	db $08,$00,$30,$00
	db $08,$08,$31,$00
	db $08,$10,$31,$20
	db $08,$18,$30,$20
	db $10,$00,$30,$40
	db $10,$08,$31,$40
	db $10,$10,$31,$60
	db $10,$18,$30,$60
	db $18,$00,$20,$40
	db $18,$08,$21,$40
	db $18,$10,$21,$60
	db $18,$18,$20,$60

FrameBlock03:
	db $04
	db $00,$00,$02,$00
	db $00,$08,$02,$20
	db $08,$00,$12,$00
	db $08,$08,$12,$20

FrameBlock04:
	db $04
	db $00,$00,$06,$00
	db $00,$08,$07,$00
	db $08,$00,$16,$00
	db $08,$08,$17,$00

FrameBlock05:
	db $04
	db $00,$00,$07,$20
	db $00,$08,$06,$20
	db $08,$00,$17,$20
	db $08,$08,$16,$20

FrameBlock06:
	db $0c
	db $00,$08,$23,$00
	db $08,$00,$32,$00
	db $08,$08,$33,$00
	db $00,$10,$23,$20
	db $08,$10,$33,$20
	db $08,$18,$32,$20
	db $10,$00,$32,$40
	db $10,$08,$33,$40
	db $18,$08,$23,$40
	db $10,$10,$33,$60
	db $10,$18,$32,$60
	db $18,$10,$23,$60

FrameBlock07:
	db $10
	db $00,$00,$20,$00
	db $00,$08,$21,$00
	db $08,$00,$30,$00
	db $08,$08,$31,$00
	db $00,$10,$21,$20
	db $00,$18,$20,$20
	db $08,$10,$31,$20
	db $08,$18,$30,$20
	db $10,$00,$30,$40
	db $10,$08,$31,$40
	db $18,$00,$20,$40
	db $18,$08,$21,$40
	db $10,$10,$31,$60
	db $10,$18,$30,$60
	db $18,$10,$21,$60
	db $18,$18,$20,$60

FrameBlock08:
	db $10
	db $00,$00,$20,$00
	db $00,$08,$21,$00
	db $08,$00,$30,$00
	db $08,$08,$31,$00
	db $00,$18,$21,$20
	db $00,$20,$20,$20
	db $08,$18,$31,$20
	db $08,$20,$30,$20
	db $18,$00,$30,$40
	db $18,$08,$31,$40
	db $20,$00,$20,$40
	db $20,$08,$21,$40
	db $18,$18,$31,$60
	db $18,$20,$30,$60
	db $20,$18,$21,$60
	db $20,$20,$20,$60

FrameBlock09:
	db $0c
	db $00,$00,$24,$00
	db $00,$08,$25,$00
	db $08,$00,$34,$00
	db $00,$18,$25,$20
	db $00,$20,$24,$20
	db $08,$20,$34,$20
	db $18,$00,$34,$40
	db $20,$00,$24,$40
	db $20,$08,$25,$40
	db $18,$20,$34,$60
	db $20,$18,$25,$60
	db $20,$20,$24,$60

FrameBlock0a:
	db $0c
	db $00,$00,$24,$00
	db $00,$08,$25,$00
	db $08,$00,$34,$00
	db $00,$20,$25,$20
	db $00,$28,$24,$20
	db $08,$28,$34,$20
	db $20,$00,$34,$40
	db $28,$00,$24,$40
	db $28,$08,$25,$40
	db $20,$28,$34,$60
	db $28,$20,$25,$60
	db $28,$28,$24,$60

FrameBlock0b:
	db $04
	db $00,$00,$05,$00
	db $00,$08,$05,$20
	db $08,$00,$15,$00
	db $08,$08,$15,$20

FrameBlock0c:
	db $04
	db $00,$00,$04,$00
	db $00,$08,$04,$20
	db $08,$00,$14,$00
	db $08,$08,$14,$20

FrameBlock0d:
	db $08
	db $00,$00,$0c,$00
	db $00,$08,$0d,$00
	db $08,$00,$1c,$00
	db $08,$08,$1d,$00
	db $10,$00,$1d,$60
	db $10,$08,$1c,$60
	db $18,$00,$0d,$60
	db $18,$08,$0c,$60

FrameBlock0e:
	db $04
	db $20,$00,$0c,$00
	db $20,$08,$0d,$00
	db $28,$00,$1c,$00
	db $28,$08,$1d,$00

FrameBlock0f:
	db $04
	db $30,$00,$1d,$60
	db $30,$08,$1c,$60
	db $38,$00,$0d,$60
	db $38,$08,$0c,$60

FrameBlock10:
	db $08
	db $00,$00,$0e,$00
	db $00,$08,$0f,$00
	db $08,$00,$1e,$00
	db $08,$08,$1f,$00
	db $00,$10,$0f,$20
	db $00,$18,$0e,$20
	db $08,$10,$1f,$20
	db $08,$18,$1e,$20

FrameBlock11:
	db $08
	db $00,$00,$0e,$00
	db $00,$08,$0f,$00
	db $08,$00,$1e,$00
	db $08,$08,$1f,$00
	db $00,$20,$0f,$20
	db $00,$28,$0e,$20
	db $08,$20,$1f,$20
	db $08,$28,$1e,$20

FrameBlock12:
	db $03
	db $00,$00,$37,$00
	db $08,$10,$37,$00
	db $00,$20,$37,$00

FrameBlock13:
	db $04
	db $00,$00,$36,$00
	db $00,$08,$36,$20
	db $08,$00,$36,$40
	db $08,$08,$36,$60

FrameBlock14:
	db $08
	db $00,$10,$28,$00
	db $00,$18,$28,$20
	db $08,$10,$38,$00
	db $08,$18,$38,$20
	db $00,$20,$36,$00
	db $00,$28,$36,$20
	db $08,$20,$36,$40
	db $08,$28,$36,$60

FrameBlock15:
	db $0c
	db $00,$00,$28,$00
	db $00,$08,$28,$20
	db $08,$00,$38,$00
	db $08,$08,$38,$20
	db $00,$10,$29,$00
	db $00,$18,$29,$20
	db $08,$10,$39,$00
	db $08,$18,$39,$20
	db $00,$20,$28,$00
	db $00,$28,$28,$20
	db $08,$20,$38,$00
	db $08,$28,$38,$20

FrameBlock16:
	db $08
	db $00,$00,$29,$00
	db $00,$08,$29,$20
	db $08,$00,$39,$00
	db $08,$08,$39,$20
	db $00,$20,$29,$00
	db $00,$28,$29,$20
	db $08,$20,$39,$00
	db $08,$28,$39,$20

FrameBlock17:
	db $04
	db $00,$00,$08,$00
	db $00,$08,$09,$00
	db $08,$00,$18,$00
	db $08,$08,$19,$00

FrameBlock18:
	db $01
	db $18,$00,$45,$60

FrameBlock19:
	db $02
	db $18,$08,$45,$00
	db $10,$08,$46,$60

FrameBlock1a:
	db $02
	db $10,$10,$45,$60
	db $18,$10,$46,$00

FrameBlock1b:
	db $02
	db $10,$18,$45,$00
	db $08,$18,$46,$60

FrameBlock1c:
	db $02
	db $08,$20,$45,$60
	db $10,$20,$46,$00

FrameBlock1d:
	db $02
	db $08,$28,$45,$00
	db $00,$28,$46,$60

FrameBlock1e:
	db $02
	db $00,$30,$45,$60
	db $08,$30,$46,$00

FrameBlock75:
	db $04
	db $00,$00,$43,$00
	db $00,$08,$43,$20
	db $08,$00,$22,$00
	db $08,$08,$43,$60

FrameBlock1f:
	db $02
	db $00,$00,$03,$00
	db $00,$30,$03,$20

FrameBlock20:
	db $06
	db $00,$00,$03,$00
	db $00,$30,$03,$20
	db $08,$08,$03,$00
	db $08,$28,$03,$20
	db $08,$00,$13,$00
	db $08,$30,$13,$20

FrameBlock21:
	db $0c
	db $00,$00,$03,$00
	db $00,$30,$03,$20
	db $08,$08,$03,$00
	db $08,$28,$03,$20
	db $08,$00,$13,$00
	db $08,$30,$13,$20
	db $10,$10,$03,$00
	db $10,$20,$03,$20
	db $10,$08,$13,$00
	db $10,$28,$13,$20
	db $10,$00,$03,$00
	db $10,$30,$03,$20

FrameBlock22:
	db $13
	db $00,$00,$03,$00
	db $08,$00,$13,$00
	db $10,$00,$03,$00
	db $18,$00,$13,$00
	db $08,$08,$03,$00
	db $10,$08,$13,$00
	db $18,$08,$03,$00
	db $10,$10,$03,$00
	db $18,$10,$13,$00
	db $18,$18,$03,$00
	db $10,$20,$03,$20
	db $18,$20,$13,$20
	db $08,$28,$03,$20
	db $10,$28,$13,$20
	db $18,$28,$03,$20
	db $00,$30,$03,$20
	db $08,$30,$13,$20
	db $10,$30,$03,$20
	db $18,$30,$13,$20

FrameBlock23:
FrameBlock38: ; byte-identical frame block
	db $04
	db $00,$00,$0a,$00
	db $00,$08,$0b,$00
	db $08,$00,$1a,$00
	db $08,$08,$1b,$00

FrameBlock24:
	db $02
	db $08,$00,$0a,$00
	db $08,$08,$0b,$00

FrameBlock25:
	db $0c
	db $10,$00,$0a,$00
	db $10,$08,$0b,$00
	db $18,$00,$1a,$00
	db $18,$08,$1b,$00
	db $00,$10,$0a,$00
	db $00,$18,$0b,$00
	db $08,$10,$1a,$00
	db $08,$18,$1b,$00
	db $08,$20,$0a,$00
	db $08,$28,$0b,$00
	db $10,$20,$1a,$00
	db $10,$28,$1b,$00

FrameBlock26:
	db $04
	db $00,$10,$44,$00
	db $00,$18,$44,$20
	db $08,$10,$44,$40
	db $08,$18,$44,$60

FrameBlock27:
	db $05
	db $08,$08,$44,$00
	db $08,$10,$44,$20
	db $10,$08,$44,$40
	db $10,$10,$44,$60
	db $00,$18,$47,$00

FrameBlock28:
	db $06
	db $10,$00,$44,$00
	db $10,$08,$44,$20
	db $18,$00,$44,$40
	db $18,$08,$44,$60
	db $08,$10,$47,$00
	db $02,$16,$47,$00

FrameBlock29:
	db $04
	db $18,$00,$47,$00
	db $12,$06,$47,$00
	db $0c,$0c,$47,$00
	db $06,$12,$47,$00

FrameBlock2a:
FrameBlock30: ; byte-identical frame block
	db $04
	db $00,$00,$44,$00
	db $00,$08,$44,$20
	db $08,$00,$44,$40
	db $08,$08,$44,$60

FrameBlock2b:
	db $02
	db $06,$02,$47,$00
	db $00,$08,$47,$00

FrameBlock2c:
	db $01
	db $a0,$00,$4d,$00

FrameBlock2d:
	db $08
	db $00,$00,$26,$00
	db $00,$08,$27,$00
	db $08,$00,$36,$00
	db $08,$08,$37,$00
	db $10,$00,$28,$00
	db $10,$08,$29,$00
	db $18,$00,$38,$00
	db $18,$08,$39,$00

FrameBlock2e:
	db $08
	db $00,$00,$27,$20
	db $00,$08,$26,$20
	db $08,$00,$37,$20
	db $08,$08,$36,$20
	db $10,$00,$29,$20
	db $10,$08,$28,$20
	db $18,$00,$39,$20
	db $18,$08,$38,$20

FrameBlock2f:
	db $04
	db $00,$00,$0c,$00
	db $00,$08,$0d,$00
	db $08,$00,$0c,$40
	db $08,$08,$0d,$40

FrameBlock31:
	db $01
	db $00,$00,$45,$00

FrameBlock32:
	db $07
	db $00,$00,$4d,$00
	db $00,$08,$2f,$00
	db $00,$10,$4d,$20
	db $08,$00,$4e,$00
	db $08,$08,$07,$00
	db $08,$10,$4e,$20
	db $10,$08,$3f,$00

FrameBlock33:
	db $07
	db $00,$08,$3f,$40
	db $08,$00,$4e,$40
	db $08,$08,$07,$40
	db $08,$10,$4e,$60
	db $10,$00,$4d,$40
	db $10,$08,$2f,$40
	db $10,$10,$4d,$60

FrameBlock34:
	db $01
	db $a0,$00,$00,$10

FrameBlock35:
	db $06
	db $00,$00,$2a,$00
	db $00,$08,$2b,$00
	db $08,$00,$3a,$00
	db $10,$00,$3a,$40
	db $18,$00,$2a,$40
	db $18,$08,$2b,$40

FrameBlock36:
	db $04
	db $00,$00,$00,$00
	db $00,$08,$01,$00
	db $08,$00,$10,$00
	db $08,$08,$11,$00

FrameBlock37:
	db $04
	db $00,$00,$01,$a0
	db $00,$08,$00,$a0
	db $08,$00,$11,$a0
	db $08,$08,$10,$a0

FrameBlock39:
	db $04
	db $00,$00,$0b,$20
	db $00,$08,$0a,$20
	db $08,$00,$1b,$20
	db $08,$08,$1a,$20

FrameBlock3a:
	db $04
	db $20,$00,$05,$00
	db $20,$08,$05,$20
	db $28,$00,$15,$00
	db $28,$08,$15,$20

FrameBlock3b:
	db $05
	db $18,$00,$04,$00
	db $18,$08,$04,$20
	db $20,$00,$14,$00
	db $20,$08,$14,$20
	db $28,$04,$41,$00

FrameBlock3c:
	db $06
	db $10,$00,$05,$00
	db $10,$08,$05,$20
	db $18,$00,$15,$00
	db $18,$08,$15,$20
	db $20,$04,$42,$00
	db $28,$04,$42,$00

FrameBlock3d:
	db $07
	db $08,$00,$04,$00
	db $08,$08,$04,$20
	db $10,$00,$14,$00
	db $10,$08,$14,$20
	db $18,$04,$41,$00
	db $20,$04,$41,$00
	db $28,$04,$41,$00

FrameBlock3e:
	db $08
	db $00,$00,$05,$00
	db $00,$08,$05,$20
	db $08,$00,$15,$00
	db $08,$08,$15,$20
	db $10,$04,$42,$00
	db $18,$04,$42,$00
	db $20,$04,$42,$00
	db $28,$04,$42,$00

FrameBlock3f:
	db $08
	db $00,$00,$04,$00
	db $00,$08,$04,$20
	db $08,$00,$14,$00
	db $08,$08,$14,$20
	db $10,$04,$41,$00
	db $18,$04,$41,$00
	db $20,$04,$41,$00
	db $28,$04,$41,$00

FrameBlock40:
	db $03
	db $00,$00,$3d,$00
	db $00,$08,$3d,$00
	db $08,$08,$3d,$00

FrameBlock41:
	db $04
	db $00,$00,$06,$00
	db $00,$08,$06,$20
	db $08,$00,$16,$00
	db $08,$08,$17,$00

FrameBlock42:
	db $0b
	db $00,$10,$42,$00
	db $08,$00,$42,$00
	db $08,$08,$42,$00
	db $08,$10,$42,$00
	db $08,$18,$42,$00
	db $08,$20,$42,$00
	db $10,$10,$42,$00
	db $18,$08,$42,$00
	db $18,$18,$42,$00
	db $20,$00,$42,$00
	db $20,$20,$42,$00

FrameBlock43:
	db $0b
	db $00,$10,$41,$00
	db $08,$00,$41,$00
	db $08,$08,$41,$00
	db $08,$10,$41,$00
	db $08,$18,$41,$00
	db $08,$20,$41,$00
	db $10,$10,$41,$00
	db $18,$08,$41,$00
	db $18,$18,$41,$00
	db $20,$00,$41,$00
	db $20,$20,$41,$00

FrameBlock44:
	db $04
	db $00,$00,$49,$00
	db $00,$28,$49,$00
	db $28,$00,$49,$00
	db $28,$28,$49,$00

FrameBlock45:
	db $04
	db $00,$00,$49,$00
	db $00,$18,$49,$00
	db $18,$00,$49,$00
	db $18,$18,$49,$00

FrameBlock46:
	db $04
	db $00,$00,$49,$00
	db $00,$08,$49,$00
	db $08,$00,$49,$00
	db $08,$08,$49,$00

FrameBlock47:
FrameBlock5b: ; byte-identical frame block
	db $04
	db $00,$00,$43,$00
	db $00,$08,$43,$20
	db $08,$00,$43,$40
	db $08,$08,$43,$60

SmallBlackCircleFrameBlock:
	db $04
	db $08,$08,$33,$00
	db $08,$10,$33,$20
	db $10,$08,$33,$40
	db $10,$10,$33,$60

LargeBlockCircleFrameBlock:
	db $10
	db $00,$00,$22,$00
	db $00,$08,$23,$00
	db $00,$10,$23,$20
	db $00,$18,$22,$20
	db $08,$00,$32,$00
	db $08,$08,$43,$00
	db $08,$10,$43,$20
	db $08,$18,$32,$20
	db $10,$00,$32,$40
	db $10,$08,$43,$40
	db $10,$10,$43,$60
	db $10,$18,$32,$60
	db $18,$00,$22,$40
	db $18,$08,$23,$40
	db $18,$10,$23,$60
	db $18,$18,$22,$60

FrameBlock71:
	db $10
	db $00,$00,$22,$00
	db $00,$08,$3b,$00
	db $00,$10,$23,$20
	db $00,$18,$22,$20
	db $08,$00,$32,$00
	db $08,$08,$43,$00
	db $08,$10,$43,$20
	db $08,$18,$32,$20
	db $10,$00,$32,$40
	db $10,$08,$43,$40
	db $10,$10,$43,$60
	db $10,$18,$32,$60
	db $18,$00,$22,$40
	db $18,$08,$23,$40
	db $18,$10,$23,$60
	db $18,$18,$22,$60

FrameBlock72:
	db $0c
	db $00,$00,$32,$00
	db $00,$08,$43,$00
	db $00,$10,$43,$20
	db $00,$18,$32,$20
	db $08,$00,$32,$40
	db $08,$08,$43,$40
	db $08,$10,$43,$60
	db $08,$18,$32,$60
	db $10,$00,$22,$40
	db $10,$08,$23,$40
	db $10,$10,$23,$60
	db $10,$18,$22,$60

FrameBlock73:
	db $08
	db $00,$00,$32,$40
	db $00,$08,$43,$40
	db $00,$10,$43,$60
	db $00,$18,$32,$60
	db $08,$00,$22,$40
	db $08,$08,$23,$40
	db $08,$10,$23,$60
	db $08,$18,$22,$60

FrameBlock74:
	db $04
	db $00,$00,$22,$40
	db $00,$08,$23,$40
	db $00,$10,$23,$60
	db $00,$18,$22,$60

FrameBlock4a:
	db $04
	db $08,$18,$4c,$20
	db $20,$08,$4b,$00
	db $30,$20,$4c,$00
	db $18,$30,$4b,$40

FrameBlock4b:
	db $04
	db $00,$18,$4c,$00
	db $20,$00,$4b,$40
	db $38,$20,$4c,$20
	db $18,$38,$4b,$00

FrameBlock4c:
	db $04
	db $10,$08,$4a,$40
	db $30,$10,$4a,$00
	db $28,$30,$4a,$20
	db $08,$28,$4a,$60

FrameBlock4d:
	db $04
	db $08,$00,$4a,$20
	db $38,$08,$4a,$60
	db $30,$38,$4a,$40
	db $00,$30,$4a,$00

FrameBlock4e:
	db $08
	db $00,$30,$44,$00
	db $00,$38,$44,$20
	db $08,$30,$44,$40
	db $08,$38,$44,$60
	db $26,$0a,$44,$00
	db $26,$12,$44,$20
	db $2e,$0a,$44,$40
	db $2e,$12,$44,$60

FrameBlock4f:
	db $0c
	db $0e,$22,$44,$00
	db $0e,$2a,$44,$20
	db $16,$22,$44,$40
	db $16,$2a,$44,$60
	db $06,$32,$47,$00
	db $00,$38,$47,$00
	db $1a,$16,$44,$00
	db $1a,$1e,$44,$20
	db $22,$16,$44,$40
	db $22,$1e,$44,$60
	db $30,$08,$47,$00
	db $2a,$0e,$47,$00

FrameBlock50:
	db $08
	db $06,$32,$47,$00
	db $00,$38,$47,$00
	db $12,$26,$47,$00
	db $0c,$2c,$47,$00
	db $1e,$1a,$47,$00
	db $18,$20,$47,$00
	db $2a,$0e,$47,$00
	db $24,$14,$47,$00

FrameBlock51:
	db $08
	db $00,$00,$35,$20
	db $08,$00,$35,$40
	db $10,$00,$35,$00
	db $18,$00,$35,$60
	db $00,$40,$35,$00
	db $08,$40,$35,$60
	db $10,$40,$35,$20
	db $18,$40,$35,$40

FrameBlock52:
	db $04
	db $00,$00,$2a,$00
	db $00,$08,$2b,$00
	db $08,$00,$3a,$00
	db $08,$08,$3b,$00

FrameBlock53:
	db $03
	db $00,$00,$3f,$00
	db $00,$08,$3f,$00
	db $08,$06,$3f,$00

FrameBlock54:
	db $04
	db $00,$00,$0e,$00
	db $00,$08,$0e,$20
	db $08,$00,$0f,$00
	db $08,$08,$0f,$20

FrameBlock55:
	db $03
	db $10,$00,$2c,$00
	db $10,$08,$3c,$00
	db $10,$10,$2d,$00

FrameBlock56:
	db $06
	db $10,$10,$31,$00
	db $10,$18,$31,$00
	db $08,$10,$2c,$00
	db $08,$18,$3c,$00
	db $08,$20,$2d,$00
	db $10,$20,$2d,$00

FrameBlock57:
	db $09
	db $08,$20,$31,$00
	db $10,$20,$31,$00
	db $08,$28,$31,$00
	db $10,$28,$31,$00
	db $00,$20,$2c,$00
	db $00,$28,$3c,$00
	db $00,$30,$2d,$00
	db $08,$30,$2d,$00
	db $10,$30,$2d,$00

FrameBlock58:
	db $07
	db $00,$00,$46,$00
	db $08,$02,$47,$00
	db $10,$03,$48,$00
	db $18,$04,$48,$00
	db $20,$05,$48,$00
	db $28,$05,$48,$00
	db $30,$05,$48,$00

FrameBlock59:
	db $01
	db $00,$00,$42,$00

FrameBlock5a:
	db $0c
	db $00,$00,$24,$00
	db $00,$08,$25,$00
	db $08,$00,$34,$00
	db $00,$10,$25,$20
	db $00,$18,$24,$20
	db $08,$18,$34,$20
	db $10,$00,$34,$40
	db $18,$00,$24,$40
	db $18,$08,$25,$40
	db $10,$18,$34,$60
	db $18,$10,$25,$60
	db $18,$18,$24,$60

FrameBlock5c:
	db $08
	db $00,$00,$49,$00
	db $02,$08,$49,$00
	db $18,$00,$49,$00
	db $10,$10,$49,$00
	db $08,$00,$43,$00
	db $08,$08,$43,$20
	db $10,$00,$43,$40
	db $10,$08,$43,$60

FrameBlock5d:
	db $0b
	db $00,$00,$49,$00
	db $18,$02,$49,$00
	db $14,$10,$49,$00
	db $08,$00,$43,$00
	db $00,$08,$43,$20
	db $10,$00,$43,$40
	db $10,$08,$43,$60
	db $04,$08,$43,$00
	db $04,$10,$43,$20
	db $0c,$08,$43,$40
	db $0c,$10,$43,$60

FrameBlock5e:
	db $0f
	db $00,$08,$49,$00
	db $08,$10,$49,$00
	db $20,$00,$49,$00
	db $08,$00,$43,$00
	db $08,$08,$43,$20
	db $10,$00,$43,$40
	db $10,$08,$43,$60
	db $10,$10,$43,$00
	db $10,$18,$43,$20
	db $18,$10,$43,$40
	db $18,$18,$43,$60
	db $20,$08,$43,$00
	db $20,$10,$43,$20
	db $28,$08,$43,$40
	db $28,$10,$43,$60

FrameBlock5f:
	db $04
	db $00,$00,$49,$00
	db $00,$10,$49,$00
	db $00,$20,$49,$00
	db $00,$30,$49,$00

FrameBlock60:
	db $08
	db $00,$00,$49,$00
	db $00,$10,$49,$00
	db $00,$20,$49,$00
	db $00,$30,$49,$00
	db $08,$08,$49,$00
	db $08,$18,$49,$00
	db $08,$28,$49,$00
	db $08,$38,$49,$00

FrameBlock61:
	db $0c
	db $00,$00,$49,$00
	db $00,$10,$49,$00
	db $00,$20,$49,$00
	db $00,$30,$49,$00
	db $08,$08,$49,$00
	db $08,$18,$49,$00
	db $08,$28,$49,$00
	db $08,$38,$49,$00
	db $10,$00,$49,$00
	db $10,$10,$49,$00
	db $10,$20,$49,$00
	db $10,$30,$49,$00

FrameBlock62:
	db $0f
	db $00,$00,$49,$00
	db $00,$10,$49,$00
	db $00,$20,$49,$00
	db $00,$30,$49,$00
	db $08,$08,$49,$00
	db $08,$18,$49,$00
	db $08,$28,$49,$00
	db $08,$38,$49,$00
	db $10,$00,$49,$00
	db $10,$10,$49,$00
	db $10,$20,$49,$00
	db $10,$30,$49,$00
	db $18,$08,$49,$00
	db $18,$18,$49,$00
	db $18,$28,$49,$00
	db $18,$38,$49,$00 ; unused

FrameBlock63:
	db $06
	db $10,$00,$26,$00
	db $10,$08,$27,$00
	db $08,$10,$26,$00
	db $08,$18,$27,$00
	db $00,$20,$26,$00
	db $00,$28,$27,$00

FrameBlock64:
	db $06
	db $18,$00,$27,$00
	db $10,$08,$26,$00
	db $10,$10,$27,$00
	db $08,$18,$26,$00
	db $08,$20,$27,$00
	db $00,$28,$26,$00

FrameBlock65:
	db $06
	db $00,$00,$1c,$00
	db $00,$08,$1d,$00
	db $10,$00,$1c,$00
	db $10,$08,$1d,$00
	db $20,$00,$1c,$00
	db $20,$08,$1d,$00

FrameBlock66:
	db $02
	db $00,$00,$03,$00
	db $08,$00,$13,$00

FrameBlock67:
	db $01
	db $00,$00,$03,$00

FrameBlock68:
	db $04
	db $00,$00,$03,$00
	db $00,$08,$03,$20
	db $08,$00,$13,$00
	db $08,$08,$13,$20

FrameBlock69:
	db $01
	db $00,$00,$06,$00

FrameBlock6a:
	db $08
	db $00,$00,$2e,$00
	db $00,$30,$2e,$20
	db $30,$00,$2e,$40
	db $30,$30,$2e,$60
	db $00,$18,$2f,$00
	db $30,$18,$2f,$40
	db $18,$00,$3e,$00
	db $18,$30,$3e,$20

FrameBlock6b:
	db $08
	db $00,$00,$2e,$00
	db $00,$20,$2e,$20
	db $20,$00,$2e,$40
	db $20,$20,$2e,$60
	db $00,$10,$2f,$00
	db $20,$10,$2f,$40
	db $10,$00,$3e,$00
	db $10,$20,$3e,$20

FrameBlock6c:
	db $08
	db $00,$00,$2e,$00
	db $00,$10,$2e,$20
	db $10,$00,$2e,$40
	db $10,$10,$2e,$60
	db $00,$08,$2f,$00
	db $10,$08,$2f,$40
	db $08,$00,$3e,$00
	db $08,$10,$3e,$20

FrameBlock6d:
	db $02
	db $00,$00,$1e,$00
	db $00,$08,$1f,$00

FrameBlock6e:
	db $04
	db $00,$00,$48,$00
	db $00,$08,$48,$20
	db $08,$00,$12,$00
	db $08,$08,$12,$20

FrameBlock6f:
	db $04
	db $00,$00,$4a,$00
	db $00,$08,$07,$00
	db $08,$00,$16,$00
	db $08,$08,$17,$00

FrameBlock70:
	db $04
	db $00,$00,$07,$20
	db $00,$08,$4a,$20
	db $08,$00,$17,$20
	db $08,$08,$16,$20

FrameBlock76:
	db $07
	db $00,$10,$2f,$00
	db $01,$08,$2f,$00
	db $01,$18,$2f,$00
	db $02,$00,$2e,$00
	db $02,$20,$2e,$20
	db $0a,$00,$3e,$00
	db $0a,$20,$3e,$20

FrameBlock77:
	db $04
	db $00,$02,$4b,$00
	db $00,$0a,$4c,$00
	db $08,$00,$4c,$60
	db $08,$08,$4b,$60

FrameBlock78:
	db $01
	db $00,$00,$4d,$00

FrameBlock79:
	db $01
	db $00,$00,$4e,$00

PunchFrameBlock:
	; Shared Punch-family object: user-selected 20x20 shadow-ring fist centered in
	; a 24x24 / 3x3 tile canvas.  The canvas stays smaller than Headbutt-class
	; impact objects while giving type palettes enough interior shading to read.
	db $09
	db $04,$04,$46,$00
	db $04,$0c,$47,$00
	db $04,$14,$48,$00
	db $0c,$04,$49,$00
	db $0c,$0c,$4a,$00
	db $0c,$14,$4b,$00
	db $14,$04,$4c,$00
	db $14,$0c,$4d,$00
	db $14,$14,$4e,$00

FrameBlockBaseCoords:
	db $10,$68
	db $10,$70
	db $10,$78
	db $10,$80
	db $10,$88
	db $10,$90
	db $10,$98
	db $18,$68
	db $18,$70
	db $18,$78
	db $34,$28
	db $18,$80
	db $18,$88
	db $18,$98
	db $20,$68
	db $20,$70
	db $20,$78
	db $20,$80
	db $20,$88
	db $20,$90
	db $20,$98
	db $28,$68
	db $28,$70
	db $28,$78
	db $28,$80
	db $28,$88
	db $30,$68
	db $30,$70
	db $30,$78
	db $30,$80
	db $30,$90
	db $30,$98
	db $38,$68
	db $38,$78
	db $38,$80
	db $38,$88
	db $40,$68
	db $40,$70
	db $40,$78
	db $40,$80
	db $40,$88
	db $40,$98
	db $10,$60
	db $18,$60
	db $20,$60
	db $28,$60
	db $30,$60
	db $40,$60
	db $58,$28
	db $43,$38
	db $33,$48
	db $20,$58
	db $32,$78
	db $58,$58
	db $2C,$6C
	db $34,$80
	db $48,$70
	db $42,$36
	db $38,$44
	db $40,$52
	db $48,$60
	db $3E,$6E
	db $28,$7C
	db $28,$8A
	db $50,$3C
	db $48,$50
	db $40,$64
	db $38,$38
	db $50,$30
	db $50,$38
	db $50,$40
	db $50,$48
	db $50,$50
	db $48,$58
	db $50,$44
	db $48,$48
	db $48,$4C
	db $40,$50
	db $40,$54
	db $38,$58
	db $38,$5C
	db $30,$64
	db $48,$40
	db $48,$39
	db $24,$88
	db $24,$70
	db $1C,$70
	db $1C,$88
	db $34,$68
	db $34,$88
	db $68,$50
	db $60,$50
	db $68,$60
	db $58,$50
	db $60,$60
	db $68,$40
	db $40,$40
	db $38,$40
	db $0B,$60
	db $44,$48
	db $40,$14
	db $48,$1C
	db $50,$24
	db $4C,$24
	db $10,$62
	db $12,$62
	db $12,$60
	db $20,$72
	db $22,$72
	db $22,$70
	db $28,$62
	db $50,$0A
	db $52,$0A
	db $38,$30
	db $40,$48
	db $30,$48
	db $40,$30
	db $30,$40
	db $38,$48
	db $40,$4A
	db $48,$4B
	db $50,$4C
	db $58,$4D
	db $60,$4D
	db $68,$4D
	db $38,$10
	db $50,$10
	db $38,$28
	db $48,$18
	db $40,$20
	db $48,$20
	db $40,$3C
	db $38,$50
	db $28,$64
	db $1C,$90
	db $24,$80
	db $2C,$70
	db $30,$38
	db $10,$50
	db $3C,$40
	db $40,$58
	db $30,$58
	db $58,$48
	db $50,$58
	db $48,$68
	db $40,$18
	db $28,$58
	db $40,$38
	db $48,$38
	db $08,$70
	db $44,$1C
	db $3C,$58
	db $38,$60
	db $08,$60
	db $38,$70
	db $38,$6C
	db $38,$64
	db $1C,$74
	db $2E,$74
	db $34,$50
	db $2F,$60
	db $31,$70
	db $4C,$30
	db $3B,$40
	db $2D,$50
	db $26,$60
	db $2D,$70
	db $28,$50
	db $1E,$60
	db $29,$70
	db $16,$60
	db $14,$58
	db $12,$54
	db $14,$50
	db $18,$4C
	db $1C,$48
	db $48,$28

FrameBlock00:
	db $00,$00
