SECTION "MoveDex Descriptions A", ROMX, BANK[$3B]

; MoveDex 正式说明独立于 $35 UI bank。
; 每项固定 3 bytes：page-list 所在 bank + 16-bit page-list 地址。
; 之后若说明扩展到 $39/$34 等 bank，只需让对应 page-list 与其页面留在同一 bank。

movedex_desc_ptr: MACRO
	db BANK(\1)
	dw \1
ENDM

MoveDexDescriptionPointerTable::
	movedex_desc_ptr MoveDexDescPoundPages ; POUND
	movedex_desc_ptr MoveDexDescKarateChopPages ; KARATE_CHOP
	movedex_desc_ptr MoveDexDescDoubleSlapPages ; DOUBLESLAP
	movedex_desc_ptr MoveDexDescCometPunchPages ; COMET_PUNCH
	movedex_desc_ptr MoveDexDescMegaPunchPages ; MEGA_PUNCH
	movedex_desc_ptr MoveDexDescPayDayPages ; PAY_DAY
	movedex_desc_ptr MoveDexDescFirePunchPages ; FIRE_PUNCH
	movedex_desc_ptr MoveDexDescIcePunchPages ; ICE_PUNCH
	movedex_desc_ptr MoveDexDescThunderPunchPages ; THUNDERPUNCH
	movedex_desc_ptr MoveDexDescScratchPages ; SCRATCH
	movedex_desc_ptr MoveDexDescViceGripPages ; VICEGRIP
	movedex_desc_ptr MoveDexDescGuillotinePages ; GUILLOTINE
	movedex_desc_ptr MoveDexDescRazorWindPages ; RAZOR_WIND
	movedex_desc_ptr MoveDexDescSwordsDancePages ; SWORDS_DANCE
	movedex_desc_ptr MoveDexDescCutPages ; CUT
	movedex_desc_ptr MoveDexDescGustPages ; GUST
	movedex_desc_ptr MoveDexDescWingAttackPages ; WING_ATTACK
	movedex_desc_ptr MoveDexDescWhirlwindPages ; WHIRLWIND
	movedex_desc_ptr MoveDexDescFlyPages ; FLY
	movedex_desc_ptr MoveDexDescBindPages ; BIND
	movedex_desc_ptr MoveDexDescSlamPages ; SLAM
	movedex_desc_ptr MoveDexDescVineWhipPages ; VINE_WHIP
	movedex_desc_ptr MoveDexDescStompPages ; STOMP
	movedex_desc_ptr MoveDexDescDoubleKickPages ; DOUBLE_KICK
	movedex_desc_ptr MoveDexDescMegaKickPages ; MEGA_KICK
	movedex_desc_ptr MoveDexDescJumpKickPages ; JUMP_KICK
	movedex_desc_ptr MoveDexDescRollingKickPages ; ROLLING_KICK
	movedex_desc_ptr MoveDexDescSandAttackPages ; SAND_ATTACK
	movedex_desc_ptr MoveDexDescHeadbuttPages ; HEADBUTT
	movedex_desc_ptr MoveDexDescHornAttackPages ; HORN_ATTACK
	movedex_desc_ptr MoveDexDescFuryAttackPages ; FURY_ATTACK
	movedex_desc_ptr MoveDexDescHornDrillPages ; HORN_DRILL
	movedex_desc_ptr MoveDexDescTacklePages ; TACKLE
	movedex_desc_ptr MoveDexDescBodySlamPages ; BODY_SLAM
	movedex_desc_ptr MoveDexDescWrapPages ; WRAP
	movedex_desc_ptr MoveDexDescTakeDownPages ; TAKE_DOWN
	movedex_desc_ptr MoveDexDescThrashPages ; THRASH
	movedex_desc_ptr MoveDexDescDoubleEdgePages ; DOUBLE_EDGE
	movedex_desc_ptr MoveDexDescTailWhipPages ; TAIL_WHIP
	movedex_desc_ptr MoveDexDescPoisonStingPages ; POISON_STING
	movedex_desc_ptr MoveDexDescTwineedlePages ; TWINEEDLE
	movedex_desc_ptr MoveDexDescPinMissilePages ; PIN_MISSILE
	movedex_desc_ptr MoveDexDescLeerPages ; LEER
	movedex_desc_ptr MoveDexDescBitePages ; BITE
	movedex_desc_ptr MoveDexDescGrowlPages ; GROWL
	movedex_desc_ptr MoveDexDescRoarPages ; ROAR
	movedex_desc_ptr MoveDexDescSingPages ; SING
	movedex_desc_ptr MoveDexDescSupersonicPages ; SUPERSONIC
	movedex_desc_ptr MoveDexDescSonicBoomPages ; SONICBOOM
	movedex_desc_ptr MoveDexDescDisablePages ; DISABLE
	movedex_desc_ptr MoveDexDescAcidPages ; ACID
	movedex_desc_ptr MoveDexDescEmberPages ; EMBER
	movedex_desc_ptr MoveDexDescFlamethrowerPages ; FLAMETHROWER
	movedex_desc_ptr MoveDexDescMistPages ; MIST
	movedex_desc_ptr MoveDexDescWaterGunPages ; WATER_GUN
	movedex_desc_ptr MoveDexDescHydroPumpPages ; HYDRO_PUMP
	movedex_desc_ptr MoveDexDescSurfPages ; SURF
	movedex_desc_ptr MoveDexDescIceBeamPages ; ICE_BEAM
	movedex_desc_ptr MoveDexDescBlizzardPages ; BLIZZARD
	movedex_desc_ptr MoveDexDescPsybeamPages ; PSYBEAM
	movedex_desc_ptr MoveDexDescBubbleBeamPages ; BUBBLEBEAM
	movedex_desc_ptr MoveDexDescAuroraBeamPages ; AURORA_BEAM
	movedex_desc_ptr MoveDexDescHyperBeamPages ; HYPER_BEAM
	movedex_desc_ptr MoveDexDescPeckPages ; PECK
	movedex_desc_ptr MoveDexDescDrillPeckPages ; DRILL_PECK
	movedex_desc_ptr MoveDexDescSubmissionPages ; SUBMISSION
	movedex_desc_ptr MoveDexDescLowKickPages ; LOW_KICK
	movedex_desc_ptr MoveDexDescCounterPages ; COUNTER
	movedex_desc_ptr MoveDexDescSeismicTossPages ; SEISMIC_TOSS
	movedex_desc_ptr MoveDexDescStrengthPages ; STRENGTH
	movedex_desc_ptr MoveDexDescAbsorbPages ; ABSORB
	movedex_desc_ptr MoveDexDescMegaDrainPages ; MEGA_DRAIN
	movedex_desc_ptr MoveDexDescLeechSeedPages ; LEECH_SEED
	movedex_desc_ptr MoveDexDescGrowthPages ; GROWTH
	movedex_desc_ptr MoveDexDescRazorLeafPages ; RAZOR_LEAF
	movedex_desc_ptr MoveDexDescSolarBeamPages ; SOLARBEAM
	movedex_desc_ptr MoveDexDescPoisonPowderPages ; POISONPOWDER
	movedex_desc_ptr MoveDexDescStunSporePages ; STUN_SPORE
	movedex_desc_ptr MoveDexDescSleepPowderPages ; SLEEP_POWDER
	movedex_desc_ptr MoveDexDescPetalDancePages ; PETAL_DANCE
	movedex_desc_ptr MoveDexDescStringShotPages ; STRING_SHOT
	movedex_desc_ptr MoveDexDescDragonRagePages ; DRAGON_RAGE
	movedex_desc_ptr MoveDexDescFireSpinPages ; FIRE_SPIN
	movedex_desc_ptr MoveDexDescThunderShockPages ; THUNDERSHOCK
	movedex_desc_ptr MoveDexDescThunderboltPages ; THUNDERBOLT
	movedex_desc_ptr MoveDexDescThunderWavePages ; THUNDER_WAVE
	movedex_desc_ptr MoveDexDescThunderPages ; THUNDER
	movedex_desc_ptr MoveDexDescRockThrowPages ; ROCK_THROW
	movedex_desc_ptr MoveDexDescEarthquakePages ; EARTHQUAKE
	movedex_desc_ptr MoveDexDescFissurePages ; FISSURE
	movedex_desc_ptr MoveDexDescDigPages ; DIG
	movedex_desc_ptr MoveDexDescToxicPages ; TOXIC
	movedex_desc_ptr MoveDexDescConfusionPages ; CONFUSION
	movedex_desc_ptr MoveDexDescPsychicPages ; PSYCHIC_M
	movedex_desc_ptr MoveDexDescHypnosisPages ; HYPNOSIS
	movedex_desc_ptr MoveDexDescMeditatePages ; MEDITATE
	movedex_desc_ptr MoveDexDescAgilityPages ; AGILITY
	movedex_desc_ptr MoveDexDescQuickAttackPages ; QUICK_ATTACK
	movedex_desc_ptr MoveDexDescRagePages ; RAGE
	movedex_desc_ptr MoveDexDescTeleportPages ; TELEPORT
	movedex_desc_ptr MoveDexDescNightShadePages ; NIGHT_SHADE
	movedex_desc_ptr MoveDexDescMimicPages ; MIMIC
	movedex_desc_ptr MoveDexDescScreechPages ; SCREECH
	movedex_desc_ptr MoveDexDescDoubleTeamPages ; DOUBLE_TEAM
	movedex_desc_ptr MoveDexDescRecoverPages ; RECOVER
	movedex_desc_ptr MoveDexDescHardenPages ; HARDEN
	movedex_desc_ptr MoveDexDescMinimizePages ; MINIMIZE
	movedex_desc_ptr MoveDexDescSmokescreenPages ; SMOKESCREEN
	movedex_desc_ptr MoveDexDescConfuseRayPages ; CONFUSE_RAY
	movedex_desc_ptr MoveDexDescWithdrawPages ; WITHDRAW
	movedex_desc_ptr MoveDexDescDefenseCurlPages ; DEFENSE_CURL
	movedex_desc_ptr MoveDexDescBarrierPages ; BARRIER
	movedex_desc_ptr MoveDexDescLightScreenPages ; LIGHT_SCREEN
	movedex_desc_ptr MoveDexDescHazePages ; HAZE
	movedex_desc_ptr MoveDexDescReflectPages ; REFLECT
	movedex_desc_ptr MoveDexDescFocusEnergyPages ; FOCUS_ENERGY
	movedex_desc_ptr MoveDexDescBidePages ; BIDE
	movedex_desc_ptr MoveDexDescMetronomePages ; METRONOME
	movedex_desc_ptr MoveDexDescMirrorMovePages ; MIRROR_MOVE
	movedex_desc_ptr MoveDexDescSelfdestructPages ; SELFDESTRUCT
	movedex_desc_ptr MoveDexDescEggBombPages ; EGG_BOMB
	movedex_desc_ptr MoveDexDescLickPages ; LICK
	movedex_desc_ptr MoveDexDescSmogPages ; SMOG
	movedex_desc_ptr MoveDexDescSludgePages ; SLUDGE
	movedex_desc_ptr MoveDexDescBoneClubPages ; BONE_CLUB
	movedex_desc_ptr MoveDexDescFireBlastPages ; FIRE_BLAST
	movedex_desc_ptr MoveDexDescWaterfallPages ; WATERFALL
	movedex_desc_ptr MoveDexDescClampPages ; CLAMP
	movedex_desc_ptr MoveDexDescSwiftPages ; SWIFT
	movedex_desc_ptr MoveDexDescSkullBashPages ; SKULL_BASH
	movedex_desc_ptr MoveDexDescSpikeCannonPages ; SPIKE_CANNON
	movedex_desc_ptr MoveDexDescConstrictPages ; CONSTRICT
	movedex_desc_ptr MoveDexDescAmnesiaPages ; AMNESIA
	movedex_desc_ptr MoveDexDescKinesisPages ; KINESIS
	movedex_desc_ptr MoveDexDescSoftboiledPages ; SOFTBOILED
	movedex_desc_ptr MoveDexDescHiJumpKickPages ; HI_JUMP_KICK
	movedex_desc_ptr MoveDexDescGlarePages ; GLARE
	movedex_desc_ptr MoveDexDescDreamEaterPages ; DREAM_EATER
	movedex_desc_ptr MoveDexDescPoisonGasPages ; POISON_GAS
	movedex_desc_ptr MoveDexDescBarragePages ; BARRAGE
	movedex_desc_ptr MoveDexDescLeechLifePages ; LEECH_LIFE
	movedex_desc_ptr MoveDexDescLovelyKissPages ; LOVELY_KISS
	movedex_desc_ptr MoveDexDescSkyAttackPages ; SKY_ATTACK
	movedex_desc_ptr MoveDexDescTransformPages ; TRANSFORM
	movedex_desc_ptr MoveDexDescBubblePages ; BUBBLE
	movedex_desc_ptr MoveDexDescDizzyPunchPages ; DIZZY_PUNCH
	movedex_desc_ptr MoveDexDescSporePages ; SPORE
	movedex_desc_ptr MoveDexDescFlashPages ; FLASH
	movedex_desc_ptr MoveDexDescPsywavePages ; PSYWAVE
	movedex_desc_ptr MoveDexDescSplashPages ; SPLASH
	movedex_desc_ptr MoveDexDescAcidArmorPages ; ACID_ARMOR #151
	movedex_desc_ptr MoveDexDescCrabhammerPages ; CRABHAMMER #152
	movedex_desc_ptr MoveDexDescExplosionPages ; EXPLOSION #153
	movedex_desc_ptr MoveDexDescFurySwipesPages ; FURY_SWIPES #154
	movedex_desc_ptr MoveDexDescBonemerangPages ; BONEMERANG #155
	movedex_desc_ptr MoveDexDescRestPages ; REST #156
	movedex_desc_ptr MoveDexDescRockSlidePages ; ROCK_SLIDE #157
	movedex_desc_ptr MoveDexDescHyperFangPages ; HYPER_FANG #158
	movedex_desc_ptr MoveDexDescHoneClawsPages ; HONE_CLAWS #159
	movedex_desc_ptr MoveDexDescConversionPages ; CONVERSION #160
	movedex_desc_ptr MoveDexDescTriAttackPages ; TRI_ATTACK #161
	movedex_desc_ptr MoveDexDescSuperFangPages ; SUPER_FANG #162
	movedex_desc_ptr MoveDexDescSlashPages ; SLASH #163
	movedex_desc_ptr MoveDexDescSubstitutePages ; SUBSTITUTE #164
	movedex_desc_ptr MoveDexDescStrugglePages ; STRUGGLE #165
	movedex_desc_ptr MoveDexDescMetalClawPages ; METAL_CLAW #166
	movedex_desc_ptr MoveDexDescBulletPunchPages ; BULLET_PUNCH #167
	movedex_desc_ptr MoveDexDescFlashCannonPages ; FLASH_CANNON #168
	movedex_desc_ptr MoveDexDescIronTailPages ; IRON_TAIL #169
	movedex_desc_ptr MoveDexDescMeteorMashPages ; METEOR_MASH #170
	movedex_desc_ptr MoveDexDescCrunchPages ; CRUNCH #171
	movedex_desc_ptr MoveDexDescDarkPulsePages ; DARK_PULSE #172
	movedex_desc_ptr MoveDexDescFeintAttackPages ; FEINT_ATTACK #173
	movedex_desc_ptr MoveDexDescNightSlashPages ; NIGHT_SLASH #174
	movedex_desc_ptr MoveDexDescMoonblastPages ; MOONBLAST #175
	movedex_desc_ptr MoveDexDescDrainingKissPages ; DRAININGKISS #176
	movedex_desc_ptr MoveDexDescDisarmingVoicePages ; DISARM_VOICE #177
	movedex_desc_ptr MoveDexDescDazzlingGleamPages ; DAZZLINGLEAM #178
	movedex_desc_ptr MoveDexDescDracoMeteorPages ; DRACO_METEOR #179
	movedex_desc_ptr MoveDexDescDragonbreathPages ; DRAGONBREATH #180
	movedex_desc_ptr MoveDexDescDragonClawPages ; DRAGON_CLAW #181
	movedex_desc_ptr MoveDexDescDragonPulsePages ; DRAGON_PULSE #182
	movedex_desc_ptr MoveDexDescTwisterPages ; TWISTER #183
	movedex_desc_ptr MoveDexDescOutragePages ; OUTRAGE #184
	movedex_desc_ptr MoveDexDescShadowClawPages ; SHADOW_CLAW #185
	movedex_desc_ptr MoveDexDescSteelWingPages ; STEEL_WING #186
	movedex_desc_ptr MoveDexDescIronDefensePages ; IRON_DEFENSE #187
	movedex_desc_ptr MoveDexDescAirSlashPages ; AIR_SLASH #188
	movedex_desc_ptr MoveDexDescFireFangPages ; FIRE_FANG #189
	movedex_desc_ptr MoveDexDescFlareBlitzPages ; FLARE_BLITZ #190
	movedex_desc_ptr MoveDexDescBlastBurnPages ; BLAST_BURN #191
	movedex_desc_ptr MoveDexDescIceFangPages ; ICE_FANG #192
	movedex_desc_ptr MoveDexDescThunderFangPages ; THUNDER_FANG #193
	movedex_desc_ptr MoveDexDescWaterPulsePages ; WATER_PULSE #194
	movedex_desc_ptr MoveDexDescAquaTailPages ; AQUA_TAIL #195
	movedex_desc_ptr MoveDexDescHydroCannonPages ; HYDRO_CANNON #196
	movedex_desc_ptr MoveDexDescFrenzyPlantPages ; FRENZY_PLANT #197
	movedex_desc_ptr MoveDexDescSuckerPunchPages ; SUCKER_PUNCH #198
	movedex_desc_ptr MoveDexDescShadowBallPages ; SHADOW_BALL #199
	movedex_desc_ptr MoveDexDescFlameWheelPages ; FLAME_WHEEL #200
	movedex_desc_ptr MoveDexDescHealingLightPages ; HEALINGLIGHT #201
	movedex_desc_ptr MoveDexDescHexPages ; HEX #202
	movedex_desc_ptr MoveDexDescShadowPunchPages ; SHADOW_PUNCH #203
	movedex_desc_ptr MoveDexDescAerialAcePages ; AERIAL_ACE #204
	movedex_desc_ptr MoveDexDescAcrobaticsPages ; ACROBATICS #205
	movedex_desc_ptr MoveDexDescAirCutterPages ; AIR_CUTTER #206
	movedex_desc_ptr MoveDexDescIcyWindPages ; ICY_WIND #207
	movedex_desc_ptr MoveDexDescIceShardPages ; ICE_SHARD #208
	movedex_desc_ptr MoveDexDescSheerColdPages ; SHEER_COLD #209
	movedex_desc_ptr MoveDexDescElectroBallPages ; ELECTRO_BALL #210
	movedex_desc_ptr MoveDexDescNuzzlePages ; NUZZLE #211
	movedex_desc_ptr MoveDexDescDischargePages ; DISCHARGE #212
	movedex_desc_ptr MoveDexDescVoltTacklePages ; VOLT_TACKLE #213
	movedex_desc_ptr MoveDexDescMuddyWaterPages ; MUDDY_WATER #214
	movedex_desc_ptr MoveDexDescWhirlpoolPages ; WHIRLPOOL #215
	movedex_desc_ptr MoveDexDescGigaDrainPages ; GIGA_DRAIN #216
	movedex_desc_ptr MoveDexDescPetalBlizzardPages ; PETALBLIZARD #217
	movedex_desc_ptr MoveDexDescLeafBladePages ; LEAF_BLADE #218
	movedex_desc_ptr MoveDexDescWoodHammerPages ; WOOD_HAMMER #219
	movedex_desc_ptr MoveDexDescPoisonJabPages ; POISON_JAB #220
	movedex_desc_ptr MoveDexDescGunkShotPages ; GUNK_SHOT #221
	movedex_desc_ptr MoveDexDescPoisonFangPages ; POISON_FANG #222
	movedex_desc_ptr MoveDexDescSludgeWavePages ; SLUDGE_WAVE #223
	movedex_desc_ptr MoveDexDescSilverWindPages ; SILVER_WIND #224
	movedex_desc_ptr MoveDexDescBugBuzzPages ; BUG_BUZZ #225
	movedex_desc_ptr MoveDexDescMegahornPages ; MEGAHORN #226
	movedex_desc_ptr MoveDexDescXScissorPages ; X_SCISSOR #227
	movedex_desc_ptr MoveDexDescSignalBeamPages ; SIGNAL_BEAM #228
	movedex_desc_ptr MoveDexDescEarthPowerPages ; EARTH_POWER #229
	movedex_desc_ptr MoveDexDescMudSlapPages ; MUD_SLAP #230
	movedex_desc_ptr MoveDexDescMudBombPages ; MUD_BOMB #231
	movedex_desc_ptr MoveDexDescExtrasensoryPages ; EXTRASENSORY #232
	movedex_desc_ptr MoveDexDescZenHeadbuttPages ; ZEN_HEADBUTT #233
	movedex_desc_ptr MoveDexDescPsychoCutPages ; PSYCHO_CUT #234
	movedex_desc_ptr MoveDexDescHyperVoicePages ; HYPER_VOICE #235
	movedex_desc_ptr MoveDexDescExtremeSpeedPages ; EXTREMESPEED #236
	movedex_desc_ptr MoveDexDescGigaImpactPages ; GIGA_IMPACT #237
	movedex_desc_ptr MoveDexDescPowerGemPages ; POWER_GEM #238
	movedex_desc_ptr MoveDexDescRockBlastPages ; ROCK_BLAST #239
	movedex_desc_ptr MoveDexDescRockPolishPages ; ROCK_POLISH #240
	movedex_desc_ptr MoveDexDescRockTombPages ; ROCK_TOMB #241
	movedex_desc_ptr MoveDexDescDynamicPunchPages ; DYNAMICPUNCH #242
	movedex_desc_ptr MoveDexDescStormThrowPages ; STORM_THROW #243
	movedex_desc_ptr MoveDexDescCrossChopPages ; CROSS_CHOP #244
	movedex_desc_ptr MoveDexDescLowSweepPages ; LOW_SWEEP #245
	movedex_desc_ptr MoveDexDescHurricanePages ; HURRICANE #246
	movedex_desc_ptr MoveDexDescBabyDollEyesPages ; BABYDOLLEYES #247
	movedex_desc_ptr MoveDexDescBoneRushPages ; BONE_RUSH #248
	movedex_desc_ptr MoveDexDescAeroblastPages ; AEROBLAST #249
	movedex_desc_ptr MoveDexDescAncientPowerPages ; ANCIENTPOWER #250
	movedex_desc_ptr MoveDexDescDivePages ; DIVE #251
	movedex_desc_ptr MoveDexDescLusterPurgePages ; LUSTER_PURGE #252
	movedex_desc_ptr MoveDexDescMindBlastPages ; MIND_BLAST #253
MoveDexDescriptionPointerTableEnd::
; 固定表为 (NUM_ATTACKS - 1) * 3 = 759 bytes（253 个技能）。

; #001 Pound
MoveDexDescPoundPages:
	; 没有附加效果的技能只保留动作描述，不额外写 No added effect。
	dw MoveDexDescPound1, 0
MoveDexDescPound1:
	db   "Pounds with a limb"
	next "or a strong tail.@"

; #002 Karate Chop
MoveDexDescKarateChopPages:
	dw MoveDexDescKarateChop1, MoveDexDescEffectHighCrit, 0
MoveDexDescKarateChop1:
	db   "A martial chop"
	next "with hand or paw.@"

; #003 DoubleSlap
MoveDexDescDoubleSlapPages:
	dw MoveDexDescDoubleSlap1, MoveDexDescEffectHits2To5, 0
MoveDexDescDoubleSlap1:
	db   "Slaps repeatedly"
	next "with both hands.@"

; #004 Comet Punch
MoveDexDescCometPunchPages:
	; 与 DoubleSlap 共用 RPP TWO_TO_FIVE_ATTACKS_EFFECT 的机制页。
	dw MoveDexDescCometPunch1, MoveDexDescEffectHits2To5, 0
MoveDexDescCometPunch1:
	db   "Strikes with a"
	next "flurry of punches.@"

; #005 Mega Punch
MoveDexDescMegaPunchPages:
	dw MoveDexDescMegaPunch1, 0
MoveDexDescMegaPunch1:
	; RPP 当前没有 PureRGB 的追加畏缩效果，因此只写动作描述。
	db   "Throws a heavy"
	next "powerful punch.@"

; #006 Pay Day
MoveDexDescPayDayPages:
	dw MoveDexDescPayDay1, MoveDexDescPayDay2, 0
MoveDexDescPayDay1:
	db   "Scatters coins"
	next "around the foe.@"
MoveDexDescPayDay2:
	; RPP 每次使用累加 user level * 2，战斗结束后结算。
	db   "Gain extra money"
	next "after battle: 2x"
	next "the user's level.@"

; #007 Fire Punch
MoveDexDescFirePunchPages:
	dw MoveDexDescFirePunch1, MoveDexDescEffectBurn10, MoveDexDescEffectBurnFireImmune, 0
MoveDexDescFirePunch1:
	db   "Strikes with a"
	next "burning fist.@"

; #008 Ice Punch
MoveDexDescIcePunchPages:
	dw MoveDexDescIcePunch1, MoveDexDescEffectFreeze10, MoveDexDescEffectFreezeIceImmune, 0
MoveDexDescIcePunch1:
	db   "Punches with an"
	next "icy-cold fist.@"

; #009 ThunderPunch
MoveDexDescThunderPunchPages:
	dw MoveDexDescThunderPunch1, MoveDexDescEffectParalyze10, MoveDexDescEffectParalyzeElectricImmune, 0
MoveDexDescThunderPunch1:
	db   "Strikes with an"
	next "electric fist.@"

; #010 Scratch
MoveDexDescScratchPages:
	dw MoveDexDescScratch1, 0
MoveDexDescScratch1:
	db   "Rakes with sharp"
	next "claws or barbs.@"

; #011 ViceGrip
MoveDexDescViceGripPages:
	dw MoveDexDescViceGrip1, 0
MoveDexDescViceGrip1:
	; RPP 当前没有 PureRGB 的追加麻痹效果。
	db   "Crushes the foe"
	next "in strong pincers.@"

; #012 Guillotine
MoveDexDescGuillotinePages:
	dw MoveDexDescGuillotine1, MoveDexDescEffectOHKO, 0
MoveDexDescGuillotine1:
	db   "Crushes the foe"
	next "with huge pincers.@"

; #013 Razor Wind
MoveDexDescRazorWindPages:
	dw MoveDexDescRazorWind1, 0
MoveDexDescRazorWind1:
	; RPP CHARGE_EFFECT：第一回合蓄力，下一回合攻击；不会像 Fly 那样进入无敌状态。
	db   "Whips up a sharp"
	next "wind on turn one."
	next "Strikes next turn.@"

; #014 Swords Dance
MoveDexDescSwordsDancePages:
	dw MoveDexDescSwordsDance1, MoveDexDescEffectAttackUp2, 0
MoveDexDescSwordsDance1:
	db   "Performs a fierce"
	next "battle dance.@"

; #015 Cut
MoveDexDescCutPages:
	dw MoveDexDescCut1, 0
MoveDexDescCut1:
	db   "Slashes with a"
	next "sharp claw or"
	next "cutting edge.@"

; #016 Gust
MoveDexDescGustPages:
	dw MoveDexDescGust1, 0
MoveDexDescGust1:
	db   "Whips up a gust"
	next "toward the foe.@"

; #017 Wing Attack
MoveDexDescWingAttackPages:
	dw MoveDexDescWingAttack1, 0
MoveDexDescWingAttack1:
	db   "Batters the foe"
	next "with its wings.@"

; #018 Whirlwind
MoveDexDescWhirlwindPages:
	dw MoveDexDescWhirlwind1, MoveDexDescEffectWildEscape1, MoveDexDescEffectWildEscape2, 0
MoveDexDescWhirlwind1:
	db   "Blows the foe away"
	next "with a whirlwind.@"

; #019 Fly
MoveDexDescFlyPages:
	dw MoveDexDescFly1, MoveDexDescFly2, 0
MoveDexDescFly1:
	db   "Flies high on the"
	next "first turn, then"
	next "dives next turn.@"
MoveDexDescFly2:
	db   "Most attacks miss"
	next "while airborne.@"

; #020 Bind
MoveDexDescBindPages:
	dw MoveDexDescBind1, MoveDexDescEffectTrapTurns, MoveDexDescEffectTrapLock, 0
MoveDexDescBind1:
	db   "Grips and traps"
	next "the foe tightly.@"

; #021 Slam
MoveDexDescSlamPages:
	dw MoveDexDescSlam1, 0
MoveDexDescSlam1:
	db   "Slams into the foe"
	next "with body or tail.@"

; #022 Vine Whip
MoveDexDescVineWhipPages:
	dw MoveDexDescVineWhip1, 0
MoveDexDescVineWhip1:
	db   "Whips using a vine"
	next "to lash the foe.@"

; #023 Stomp
MoveDexDescStompPages:
	dw MoveDexDescStomp1, MoveDexDescEffectFlinch30, 0
MoveDexDescStomp1:
	db   "Stomps on the foe"
	next "with great force.@"

; #024 Double Kick
MoveDexDescDoubleKickPages:
	dw MoveDexDescDoubleKick1, MoveDexDescEffectHitsTwice, 0
MoveDexDescDoubleKick1:
	db   "Delivers two kicks"
	next "one after another.@"

; #025 Mega Kick
MoveDexDescMegaKickPages:
	dw MoveDexDescMegaKick1, 0
MoveDexDescMegaKick1:
	db   "Launches a massive"
	next "full-power kick.@"

; #026 Jump Kick
MoveDexDescJumpKickPages:
	dw MoveDexDescJumpKick1, MoveDexDescEffectJumpKickMiss, 0
MoveDexDescJumpKick1:
	db   "Leaps up to land"
	next "a jumping kick.@"

; #027 Rolling Kick
MoveDexDescRollingKickPages:
	dw MoveDexDescRollingKick1, MoveDexDescEffectFlinch30, 0
MoveDexDescRollingKick1:
	db   "Rolls into the foe"
	next "with a hard kick.@"

; #028 Sand-Attack
MoveDexDescSandAttackPages:
	dw MoveDexDescSandAttack1, MoveDexDescEffectAccuracyDown1, 0
MoveDexDescSandAttack1:
	db   "Blasts the foe's"
	next "eyes with sand.@"

; #029 Headbutt
MoveDexDescHeadbuttPages:
	dw MoveDexDescHeadbutt1, MoveDexDescEffectFlinch30, 0
MoveDexDescHeadbutt1:
	db   "Rams the foe with"
	next "a hard headbutt.@"

; #030 Horn Attack
MoveDexDescHornAttackPages:
	dw MoveDexDescHornAttack1, 0
MoveDexDescHornAttack1:
	db   "Strikes the foe"
	next "with a sharp horn.@"

; #031 Fury Attack
MoveDexDescFuryAttackPages:
	dw MoveDexDescFuryAttack1, MoveDexDescEffectHits2To5, 0
MoveDexDescFuryAttack1:
	db   "Rapidly jabs with"
	next "a beak or horn.@"

; #032 Horn Drill
MoveDexDescHornDrillPages:
	dw MoveDexDescHornDrill1, MoveDexDescEffectOHKO, 0
MoveDexDescHornDrill1:
	db   "Drills with a horn"
	next "to pierce the foe.@"

; #033 Tackle
MoveDexDescTacklePages:
	dw MoveDexDescTackle1, 0
MoveDexDescTackle1:
	db   "A full-body charge"
	next "strikes the foe.@"

; #034 Body Slam
MoveDexDescBodySlamPages:
	dw MoveDexDescBodySlam1, MoveDexDescEffectParalyze30, MoveDexDescBodySlam2, 0
MoveDexDescBodySlam1:
	db   "Slams full weight"
	next "down on the foe.@"
MoveDexDescBodySlam2:
	; RPP 的通用状态追加效果按招式属性判同属性免疫，Normal 招式因此不能麻痹 Normal 属性目标。
	db   "Cannot paralyze a"
	next "Normal-type foe.@"

; #035 Wrap
MoveDexDescWrapPages:
	dw MoveDexDescWrap1, MoveDexDescEffectTrapTurns, MoveDexDescEffectTrapLock, 0
MoveDexDescWrap1:
	db   "Wraps the foe up"
	next "in its long body.@"

; #036 Take Down
MoveDexDescTakeDownPages:
	dw MoveDexDescTakeDown1, MoveDexDescEffectRecoil25, 0
MoveDexDescTakeDown1:
	db   "Recklessly charges"
	next "the foe head-on.@"

; #037 Thrash
MoveDexDescThrashPages:
	dw MoveDexDescThrash1, MoveDexDescEffectThrashTurns, MoveDexDescEffectThrashConfuse, MoveDexDescEffectConfusionDuration, 0
MoveDexDescThrash1:
	db   "Flails at the foe"
	next "in a wild rage.@"

; #038 Double-Edge
MoveDexDescDoubleEdgePages:
	dw MoveDexDescDoubleEdge1, MoveDexDescEffectRecoil25, 0
MoveDexDescDoubleEdge1:
	db   "Risking its life,"
	next "tackles the foe.@"

; #039 Tail Whip
MoveDexDescTailWhipPages:
	dw MoveDexDescTailWhip1, MoveDexDescEffectDefenseDown1, 0
MoveDexDescTailWhip1:
	db   "Wags its tail at"
	next "the foe cutely.@"

; #040 Poison Sting
MoveDexDescPoisonStingPages:
	dw MoveDexDescPoisonSting1, MoveDexDescEffectPoison20, MoveDexDescEffectPoisonImmunity, 0
MoveDexDescPoisonSting1:
	db   "Stabs the foe with"
	next "a poisoned barb.@"

; #041 Twineedle
MoveDexDescTwineedlePages:
	dw MoveDexDescTwineedle1, MoveDexDescEffectHitsTwice, MoveDexDescEffectPoison20, MoveDexDescEffectPoisonImmunity, 0
MoveDexDescTwineedle1:
	db   "Jabs the foe with"
	next "two sharp barbs.@"

; #042 Pin Missile
MoveDexDescPinMissilePages:
	dw MoveDexDescPinMissile1, MoveDexDescEffectHits2To5, 0
MoveDexDescPinMissile1:
	db   "Sharp pins rain in"
	next "a rapid barrage.@"

; #043 Leer
MoveDexDescLeerPages:
	dw MoveDexDescLeer1, MoveDexDescEffectDefenseDown1, 0
MoveDexDescLeer1:
	db   "Glares fiercely at"
	next "the foe's guard.@"

; #044 Bite
MoveDexDescBitePages:
	dw MoveDexDescBite1, MoveDexDescEffectFlinch10, 0
MoveDexDescBite1:
	db   "Bites the foe with"
	next "sharp teeth.@"

; #045 Growl
MoveDexDescGrowlPages:
	dw MoveDexDescGrowl1, MoveDexDescEffectAttackDown1, 0
MoveDexDescGrowl1:
	db   "Growls to weaken"
	next "the foe's attack.@"

; #046 Roar
MoveDexDescRoarPages:
	dw MoveDexDescRoar1, MoveDexDescEffectWildEscape1, MoveDexDescEffectWildEscape2, 0
MoveDexDescRoar1:
	db   "Lets out a fierce"
	next "roar at the foe.@"

; #047 Sing
MoveDexDescSingPages:
	dw MoveDexDescSing1, MoveDexDescEffectSleep, 0
MoveDexDescSing1:
	db   "Sings a soft song"
	next "to lull the foe.@"

; #048 Supersonic
MoveDexDescSupersonicPages:
	dw MoveDexDescSupersonic1, MoveDexDescEffectConfuseAlways, MoveDexDescEffectConfusionDuration, 0
MoveDexDescSupersonic1:
	db   "Emits odd sound"
	next "waves at the foe.@"

; #049 Sonic Boom
MoveDexDescSonicBoomPages:
	dw MoveDexDescSonicBoom1, MoveDexDescEffectFixed20, 0
MoveDexDescSonicBoom1:
	db   "Fires a compressed"
	next "wave of sound.@"

; #050 Disable
MoveDexDescDisablePages:
	dw MoveDexDescDisable1, MoveDexDescEffectDisable, 0
MoveDexDescDisable1:
	db   "Disrupts one of"
	next "the foe's moves.@"

; #051 Acid
MoveDexDescAcidPages:
	dw MoveDexDescAcid1, MoveDexDescEffectSpecialDown33, 0
MoveDexDescAcid1:
	db   "Sprays corrosive"
	next "acid at the foe.@"

; #052 Ember
MoveDexDescEmberPages:
	dw MoveDexDescEmber1, MoveDexDescEffectBurn10, MoveDexDescEffectBurnFireImmune, 0
MoveDexDescEmber1:
	db   "Scorches the foe"
	next "with small flames.@"

; #053 Flamethrower
MoveDexDescFlamethrowerPages:
	dw MoveDexDescFlamethrower1, MoveDexDescEffectBurn10, MoveDexDescEffectBurnFireImmune, 0
MoveDexDescFlamethrower1:
	db   "Blasts the foe"
	next "with a stream of"
	next "searing flame.@"

; #054 Mist
MoveDexDescMistPages:
	dw MoveDexDescMist1, MoveDexDescEffectMist, MoveDexDescEffectMistDuration, 0
MoveDexDescMist1:
	db   "Covers the user"
	next "in a cooling mist.@"

; #055 Water Gun
MoveDexDescWaterGunPages:
	dw MoveDexDescWaterGun1, 0
MoveDexDescWaterGun1:
	db   "Fires a water jet"
	next "toward the foe.@"

; #056 Hydro Pump
MoveDexDescHydroPumpPages:
	dw MoveDexDescHydroPump1, 0
MoveDexDescHydroPump1:
	db   "A huge water jet"
	next "blasts the foe.@"

; #057 Surf
MoveDexDescSurfPages:
	dw MoveDexDescSurf1, 0
MoveDexDescSurf1:
	db   "A powerful wave"
	next "swamps the foe.@"

; #058 Ice Beam
MoveDexDescIceBeamPages:
	dw MoveDexDescIceBeam1, MoveDexDescEffectFreeze10, MoveDexDescEffectFreezeIceImmune, 0
MoveDexDescIceBeam1:
	db   "Fires a freezing"
	next "beam at the foe.@"

; #059 Blizzard
MoveDexDescBlizzardPages:
	dw MoveDexDescBlizzard1, MoveDexDescEffectFreeze10, MoveDexDescEffectFreezeIceImmune, 0
MoveDexDescBlizzard1:
	db   "Whips up a fierce"
	next "icy snowstorm.@"

; #060 Psybeam
MoveDexDescPsybeamPages:
	dw MoveDexDescPsybeam1, MoveDexDescEffectConfuse10, MoveDexDescEffectConfusionDuration, 0
MoveDexDescPsybeam1:
	db   "Fires a strange"
	next "psychic beam.@"

; #061 Bubble Beam
MoveDexDescBubbleBeamPages:
	dw MoveDexDescBubbleBeam1, MoveDexDescEffectSpeedDown33, 0
MoveDexDescBubbleBeam1:
	db   "Blasts the foe in"
	next "a rush of bubbles.@"

; #062 Aurora Beam
MoveDexDescAuroraBeamPages:
	dw MoveDexDescAuroraBeam1, MoveDexDescEffectAttackDown33, 0
MoveDexDescAuroraBeam1:
	db   "Fires a colorful"
	next "beam of icy light.@"

; #063 Hyper Beam
MoveDexDescHyperBeamPages:
	dw MoveDexDescHyperBeam1, MoveDexDescEffectRecharge, 0
MoveDexDescHyperBeam1:
	db   "Fires a massive"
	next "beam of energy.@"

; #064 Peck
MoveDexDescPeckPages:
	dw MoveDexDescPeck1, 0
MoveDexDescPeck1:
	db   "Pecks the foe with"
	next "a beak or horn.@"

; #065 Drill Peck
MoveDexDescDrillPeckPages:
	dw MoveDexDescDrillPeck1, 0
MoveDexDescDrillPeck1:
	db   "Spins into the foe"
	next "with a drill beak.@"

; #066 Submission
MoveDexDescSubmissionPages:
	dw MoveDexDescSubmission1, MoveDexDescEffectRecoil25, 0
MoveDexDescSubmission1:
	db   "Tackles the foe in"
	next "a rough body slam.@"

; #067 Low Kick
MoveDexDescLowKickPages:
	dw MoveDexDescLowKick1, MoveDexDescEffectFlinch30, 0
MoveDexDescLowKick1:
	db   "Sweeps low at the"
	next "foe with a kick.@"

; #068 Counter
MoveDexDescCounterPages:
	dw MoveDexDescCounter1, MoveDexDescCounter2, 0
MoveDexDescCounter1:
	db   "Waits for a blow,"
	next "then strikes back.@"
MoveDexDescCounter2:
	db   "Returns twice the"
	next "physical damage"
	next "just received.@"

; #069 Seismic Toss
MoveDexDescSeismicTossPages:
	dw MoveDexDescSeismicToss1, MoveDexDescEffectLevelDamage, 0
MoveDexDescSeismicToss1:
	db   "Hurls the foe with"
	next "a powerful throw.@"

; #070 Strength
MoveDexDescStrengthPages:
	dw MoveDexDescStrength1, 0
MoveDexDescStrength1:
	db   "Hits the foe with"
	next "immense strength.@"

; #082 Dragon Rage
MoveDexDescDragonRagePages:
	dw MoveDexDescDragonRage1, MoveDexDescDragonRage2, 0
MoveDexDescDragonRage1:
	db   "Unleashes dragon"
	next "rage at the foe.@"
MoveDexDescDragonRage2:
	; 固定伤害仍受属性无效判定影响，因此不写 Always。
	db   "Deals exactly"
	next "40 HP damage.@"

; ---------------------------------------------------------------------------
; 共用机制页
; 只共用“战斗机制完全一致”的页面；动作/风格描述仍由每个技能自己保留。
; 不根据 effect ID 自动生成说明，因为 RPP 有不少按 move ID 特判或复合效果。
; ---------------------------------------------------------------------------

MoveDexDescEffectHighCrit:
	; RPP 高暴击技能的基础临界率约为 25%。
	db   "About 25", $d9, " of hits"
	next "are critical hits.@"

MoveDexDescEffectHits2To5:
	; RPP TWO_TO_FIVE_ATTACKS_EFFECT：2/3 次各 3/8，4/5 次各 1/8。
	db   "Hits 2-5 times."
	next "2-3 hits: 37.5", $d9
	next "4-5 hits: 12.5", $d9, "@"

MoveDexDescEffectBurn10:
	db   "10", $d9, " chance to"
	next "burn the foe.@"

MoveDexDescEffectBurnFireImmune:
	; 这里只描述烧伤追加效果；Fire 属性目标仍会正常进行伤害属性判定。
	db   "Cannot burn a"
	next "Fire-type foe.@"

MoveDexDescEffectFreeze10:
	db   "10", $d9, " chance to"
	next "freeze the foe.@"

MoveDexDescEffectFreezeIceImmune:
	; 这里只描述冻结追加效果，避免 Fails vs Ice 被误解成 Ice Beam 整招无效。
	db   "Cannot freeze an"
	next "Ice-type foe.@"

MoveDexDescEffectParalyze10:
	db   "10", $d9, " chance to"
	next "paralyze the foe.@"

MoveDexDescEffectParalyzeElectricImmune:
	; Electric 伤害招式的追加麻痹不能作用于 Electric 属性目标。
	db   "Cannot paralyze an"
	next "Electric-type foe.@"

MoveDexDescEffectOHKO:
	; RPP OHKO：只要对手当前 Speed 更高就直接失败；命中率仍由详情页 Accuracy 显示。
	db   "One-hit KO."
	next "Fails against"
	next "a faster foe.@"

MoveDexDescEffectAttackUp2:
	db   "Raises Attack"
	next "by 2 stages.@"

MoveDexDescEffectTrapTurns:
	; RPP TRAPPING_EFFECT 总持续 2-5 回合，分布与 2-5 连击相同。
	db   "Lasts 2-5 turns."
	next "2-3 turns: 37.5", $d9
	next "4-5 turns: 12.5", $d9, "@"

MoveDexDescEffectTrapLock:
	db   "Foe cannot move"
	next "while trapped.@"

MoveDexDescEffectFlinch10:
	db   "10", $d9, " chance to make"
	next "the foe flinch.@"

MoveDexDescEffectSpecialDown33:
	db   "33", $d9, " chance."
	next "Foe's Special stat"
	next "drops 1 stage.@"

MoveDexDescEffectSpeedDown33:
	db   "33", $d9, " chance."
	next "Foe's Speed"
	next "drops 1 stage.@"

MoveDexDescEffectConfuse10:
	db   "10", $d9, " chance to"
	next "confuse the foe.@"

MoveDexDescEffectConfusionDuration:
	; RPP 混乱持续 2-5 回合，每种时长各 25%。
	db   "Duration is 2-5"
	next "turns, 25", $d9, " each.@"

MoveDexDescEffectFlinch30:
	db   "30", $d9, " chance to make"
	next "the foe flinch.@"

MoveDexDescEffectHitsTwice:
	db   "Always hits twice.@"

MoveDexDescEffectJumpKickMiss:
	; 当前 RPP 的 Jump Kick miss 路径在 wDamage=0 后取最小值，因此实战固定只损失 1 HP。
	db   "If it misses, user"
	next "loses just 1 HP.@"

MoveDexDescEffectAccuracyDown1:
	db   "Lowers Accuracy"
	next "by 1 stage.@"

MoveDexDescEffectParalyze30:
	db   "30", $d9, " chance to"
	next "paralyze the foe.@"

MoveDexDescEffectRecoil25:
	; RPP RECOIL_EFFECT（Struggle 除外）为造成伤害的 1/4，最低 1 HP。
	db   "User takes 25", $d9, " of"
	next "damage as recoil.@"

MoveDexDescEffectThrashTurns:
	; 初次命中后再锁定 2 或 3 次，因此当前 RPP 的总持续时间是 3-4 回合，各 50%。
	db   "Lasts 3-4 turns."
	next "3 or 4: 50", $d9, " each.@"

MoveDexDescEffectThrashConfuse:
	db   "Confuses the user"
	next "after it ends.@"

MoveDexDescEffectDefenseDown1:
	db   "Lowers Defense"
	next "by 1 stage.@"

MoveDexDescEffectPoison20:
	; POISON_SIDE_EFFECT1 使用 $34/256，约 20%。
	db   "20", $d9, " chance to"
	next "poison the foe.@"

; ---------------------------------------------------------------------------
; #041-#070 新增共用机制页（Bank $3B）。
; ---------------------------------------------------------------------------

MoveDexDescEffectPoisonImmunity:
	; 这里只描述中毒免疫，不表示伤害招式本身对这些属性完全无效。
	db   "Cannot poison"
	next "Poison/Steel foes.@"

MoveDexDescEffectAttackDown1:
	db   "Lowers Attack"
	next "by 1 stage.@"

MoveDexDescEffectWildEscape1:
	; Roar / Whirlwind / Teleport 在野外战共用等级判定。
	db   "In wild battles,"
	next "success depends on"
	next "user/foe levels.@"

MoveDexDescEffectWildEscape2:
	db   "User equal/higher:"
	next "always succeeds."
	next "Fails vs Trainers.@"

MoveDexDescEffectSleep:
	; 外部睡眠写入 2-5；按实际行动检查会跳过 1-4 次行动，每种各 25%。
	db   "Puts foe to sleep."
	next "Foe skips 1-4"
	next "actions, 25", $d9, " each.@"

MoveDexDescEffectConfuseAlways:
	db   "Confuses the foe"
	next "whenever it hits.@"

MoveDexDescEffectFixed20:
	; 固定伤害仍受属性无效判定影响，因此不写 Always。
	db   "Deals exactly"
	next "20 HP damage.@"

MoveDexDescEffectDisable:
	; RPP 随机选择一个可用技能，并随机禁用 1-8 回合，各时长等概率。
	db   "Disables one move."
	next "Lasts 1-8 turns."
	next "Each length: 12.5", $d9, "@"

MoveDexDescEffectMist:
	db   "Blocks foe-caused"
	next "stat reductions.@"

MoveDexDescEffectMistDuration:
	; ProtectedByMist 会在换人或 Haze 时清除。
	db   "Lasts until user"
	next "switches or Haze.@"

MoveDexDescEffectAttackDown33:
	db   "33", $d9, " chance."
	next "Foe's Attack"
	next "drops 1 stage.@"

MoveDexDescEffectRecharge:
	db   "User must recharge"
	next "on the next turn.@"

MoveDexDescEffectLevelDamage:
	db   "Deals damage equal"
	next "to user's level.@"

; ---------------------------------------------------------------------------
; Bank $39：#071-#150。
; page-list 与其正文/共用机制页保持同 bank，避免二级跨 bank 指针。
; ---------------------------------------------------------------------------

SECTION "MoveDex Descriptions B", ROMX, BANK[$39]

; #071 Absorb
MoveDexDescAbsorbPages:
	dw MoveDexDescAbsorb1, MoveDexDescEffectBDrainHalf, 0
MoveDexDescAbsorb1:
	db   "Saps life energy"
	next "from the foe.@"

; #072 Mega Drain
MoveDexDescMegaDrainPages:
	dw MoveDexDescMegaDrain1, MoveDexDescEffectBDrainHalf, 0
MoveDexDescMegaDrain1:
	db   "Drains life energy"
	next "from the foe.@"

; #073 Leech Seed
MoveDexDescLeechSeedPages:
	dw MoveDexDescLeechSeed1, MoveDexDescEffectBLeechSeed, MoveDexDescEffectBLeechSeedImmune, 0
MoveDexDescLeechSeed1:
	db   "Seeds the foe to"
	next "drain its energy.@"

; #074 Growth
MoveDexDescGrowthPages:
	dw MoveDexDescGrowth1, MoveDexDescEffectBGrowth, 0
MoveDexDescGrowth1:
	db   "Stimulates growth"
	next "to gain strength.@"

; #075 Razor Leaf
MoveDexDescRazorLeafPages:
	dw MoveDexDescRazorLeaf1, MoveDexDescEffectBHighCrit, 0
MoveDexDescRazorLeaf1:
	db   "Hurls razor leaves"
	next "toward the foe.@"

; #076 Solar Beam
MoveDexDescSolarBeamPages:
	dw MoveDexDescSolarBeam1, 0
MoveDexDescSolarBeam1:
	db   "Stores sunlight,"
	next "then fires a beam"
	next "on the next turn.@"

; #077 PoisonPowder
MoveDexDescPoisonPowderPages:
	dw MoveDexDescPoisonPowder1, MoveDexDescEffectBPoisonAlways, MoveDexDescEffectBPoisonImmunity, 0
MoveDexDescPoisonPowder1:
	db   "Covers the foe in"
	next "poisonous powder.@"

; #078 Stun Spore
MoveDexDescStunSporePages:
	dw MoveDexDescStunSpore1, MoveDexDescEffectBParalyzeAlways, 0
MoveDexDescStunSpore1:
	db   "Scatters numbing"
	next "spores on the foe.@"

; #079 Sleep Powder
MoveDexDescSleepPowderPages:
	dw MoveDexDescSleepPowder1, MoveDexDescEffectBSleep, 0
MoveDexDescSleepPowder1:
	db   "Scatters drowsy"
	next "powder on the foe.@"

; #080 Petal Dance
MoveDexDescPetalDancePages:
	dw MoveDexDescPetalDance1, MoveDexDescEffectBThrashTurns, MoveDexDescEffectBThrashConfuse, MoveDexDescEffectBConfusionDuration, 0
MoveDexDescPetalDance1:
	db   "Dances in a storm"
	next "of flower petals.@"

; #081 String Shot
MoveDexDescStringShotPages:
	dw MoveDexDescStringShot1, MoveDexDescEffectBSpeedDown1, 0
MoveDexDescStringShot1:
	db   "Fires sticky silk"
	next "around the foe.@"

; #082 Dragon Rage 已在 Bank $3B，保持现有已验证说明。

; #083 Fire Spin
MoveDexDescFireSpinPages:
	dw MoveDexDescFireSpin1, MoveDexDescEffectBTrapTurns, MoveDexDescEffectBTrapLock, 0
MoveDexDescFireSpin1:
	db   "Traps the foe in"
	next "a swirling fire.@"

; #084 Thundershock
MoveDexDescThunderShockPages:
	dw MoveDexDescThunderShock1, MoveDexDescEffectBParalyze10, MoveDexDescEffectBParalyzeElectricImmune, 0
MoveDexDescThunderShock1:
	db   "Sends a mild shock"
	next "through the foe.@"

; #085 Thunderbolt
MoveDexDescThunderboltPages:
	dw MoveDexDescThunderbolt1, MoveDexDescEffectBParalyze10, MoveDexDescEffectBParalyzeElectricImmune, 0
MoveDexDescThunderbolt1:
	db   "A powerful shock"
	next "strikes the foe.@"

; #086 Thunder Wave
MoveDexDescThunderWavePages:
	dw MoveDexDescThunderWave1, MoveDexDescEffectBThunderWave, MoveDexDescEffectBGroundImmune, 0
MoveDexDescThunderWave1:
	db   "Sends a shock wave"
	next "through the foe.@"

; #087 Thunder
MoveDexDescThunderPages:
	dw MoveDexDescThunder1, MoveDexDescEffectBParalyze10, MoveDexDescEffectBParalyzeElectricImmune, 0
MoveDexDescThunder1:
	db   "Calls down a bolt"
	next "of mighty thunder.@"

; #088 Rock Throw
MoveDexDescRockThrowPages:
	dw MoveDexDescRockThrow1, 0
MoveDexDescRockThrow1:
	db   "Hurls a heavy rock"
	next "toward the foe.@"

; #089 Earthquake
MoveDexDescEarthquakePages:
	dw MoveDexDescEarthquake1, 0
MoveDexDescEarthquake1:
	db   "Shakes the ground"
	next "with a hard quake.@"

; #090 Fissure
MoveDexDescFissurePages:
	dw MoveDexDescFissure1, MoveDexDescEffectBOHKO, 0
MoveDexDescFissure1:
	db   "Opens a fissure"
	next "beneath the foe.@"

; #091 Dig
MoveDexDescDigPages:
	dw MoveDexDescDig1, MoveDexDescEffectBUnderground, 0
MoveDexDescDig1:
	db   "Digs underground"
	next "on the first turn."
	next "Strikes next turn.@"

; #092 Toxic
MoveDexDescToxicPages:
	dw MoveDexDescToxic1, MoveDexDescEffectBToxic1, MoveDexDescEffectBToxic2, MoveDexDescEffectBPoisonImmunity, 0
MoveDexDescToxic1:
	db   "Covers the foe in"
	next "a deadly toxin.@"

; #093 Confusion
MoveDexDescConfusionPages:
	dw MoveDexDescConfusion1, MoveDexDescEffectBConfuse10, MoveDexDescEffectBConfusionDuration, 0
MoveDexDescConfusion1:
	db   "Uses psychic force"
	next "against the foe.@"

; #094 Psychic
MoveDexDescPsychicPages:
	dw MoveDexDescPsychic1, MoveDexDescEffectBSpecialDown33, 0
MoveDexDescPsychic1:
	db   "Unleashes psychic"
	next "power at the foe.@"

; #095 Hypnosis
MoveDexDescHypnosisPages:
	dw MoveDexDescHypnosis1, MoveDexDescEffectBSleep, 0
MoveDexDescHypnosis1:
	db   "Lulls the foe with"
	next "deep hypnosis.@"

; #096 Meditate
MoveDexDescMeditatePages:
	dw MoveDexDescMeditate1, MoveDexDescEffectBAttackUp1, 0
MoveDexDescMeditate1:
	db   "Focuses the mind"
	next "to build strength.@"

; #097 Agility
MoveDexDescAgilityPages:
	dw MoveDexDescAgility1, MoveDexDescEffectBSpeedUp2, 0
MoveDexDescAgility1:
	db   "Moves with a burst"
	next "of sudden speed.@"

; #098 Quick Attack
MoveDexDescQuickAttackPages:
	dw MoveDexDescQuickAttack1, MoveDexDescEffectBPriority, 0
MoveDexDescQuickAttack1:
	db   "Lunges at the foe"
	next "with great speed.@"

; #099 Rage
MoveDexDescRagePages:
	dw MoveDexDescRage1, MoveDexDescEffectBRage1, MoveDexDescEffectBRage2, 0
MoveDexDescRage1:
	db   "Attacks the foe in"
	next "a growing rage.@"

; #100 Teleport
MoveDexDescTeleportPages:
	dw MoveDexDescTeleport1, MoveDexDescEffectBWildEscape1, MoveDexDescEffectBWildEscape2, 0
MoveDexDescTeleport1:
	db   "Teleports away"
	next "from the battle.@"


; #101 Night Shade
MoveDexDescNightShadePages:
	dw MoveDexDescNightShade1, MoveDexDescEffectBLevelDamage, 0
MoveDexDescNightShade1:
	db   "Shows a terrifying"
	next "mirage to the foe.@"

; #102 Mimic
MoveDexDescMimicPages:
	dw MoveDexDescMimic1, MoveDexDescMimic2, MoveDexDescEffectBTargetInvulnerable, 0
MoveDexDescMimic1:
	db   "Copies a foe's"
	next "move for battle.@"
MoveDexDescMimic2:
	; RPP 会把复制到的招式直接写回 Mimic 当前所在的招式槽。
	db   "It replaces Mimic"
	next "in the move slot.@"

; #103 Screech
MoveDexDescScreechPages:
	dw MoveDexDescScreech1, MoveDexDescEffectBDefenseDown2, 0
MoveDexDescScreech1:
	db   "Lets out a harsh"
	next "piercing screech.@"

; #104 Double Team
MoveDexDescDoubleTeamPages:
	dw MoveDexDescDoubleTeam1, MoveDexDescEffectBEvasionUp1, 0
MoveDexDescDoubleTeam1:
	db   "Makes afterimages"
	next "to evade attacks.@"

; #105 Recover
MoveDexDescRecoverPages:
	dw MoveDexDescRecover1, MoveDexDescEffectBHealHalf, 0
MoveDexDescRecover1:
	db   "Regenerates cells"
	next "to restore HP.@"

; #106 Harden
MoveDexDescHardenPages:
	dw MoveDexDescHarden1, MoveDexDescEffectBDefenseUp1, 0
MoveDexDescHarden1:
	db   "Hardens the body"
	next "against attacks.@"

; #107 Minimize
MoveDexDescMinimizePages:
	dw MoveDexDescMinimize1, MoveDexDescEffectBEvasionUp1, 0
MoveDexDescMinimize1:
	db   "Shrinks the body"
	next "to evade attacks.@"

; #108 Smokescreen
MoveDexDescSmokescreenPages:
	dw MoveDexDescSmokescreen1, MoveDexDescEffectBAccuracyDown1, 0
MoveDexDescSmokescreen1:
	db   "Covers the foe in"
	next "thick black smoke.@"

; #109 Confuse Ray
MoveDexDescConfuseRayPages:
	dw MoveDexDescConfuseRay1, MoveDexDescEffectBConfuseAlways, MoveDexDescEffectBConfusionDuration, 0
MoveDexDescConfuseRay1:
	db   "Bathes the foe in"
	next "strange light.@"

; #110 Withdraw
MoveDexDescWithdrawPages:
	dw MoveDexDescWithdraw1, MoveDexDescEffectBDefenseUp1, 0
MoveDexDescWithdraw1:
	db   "Withdraws into its"
	next "protective shell.@"

; #111 Defense Curl
MoveDexDescDefenseCurlPages:
	dw MoveDexDescDefenseCurl1, MoveDexDescEffectBDefenseUp1, 0
MoveDexDescDefenseCurl1:
	db   "Curls into a ball"
	next "to guard its body.@"

; #112 Barrier
MoveDexDescBarrierPages:
	dw MoveDexDescBarrier1, MoveDexDescEffectBDefenseUp2, 0
MoveDexDescBarrier1:
	db   "Creates a sturdy"
	next "defensive barrier.@"

; #113 Light Screen
MoveDexDescLightScreenPages:
	dw MoveDexDescLightScreen1, MoveDexDescEffectBLightScreen, MoveDexDescEffectBScreenDuration, 0
MoveDexDescLightScreen1:
	db   "Creates a wall of"
	next "protective light.@"

; #114 Haze
MoveDexDescHazePages:
	dw MoveDexDescHaze1, MoveDexDescHaze2, MoveDexDescHaze3, MoveDexDescHaze4, MoveDexDescHaze5, 0
MoveDexDescHaze1:
	db   "A cold haze fills"
	next "the battlefield.@"
MoveDexDescHaze2:
	; RPP 会把双方所有 stat modifier 重置为中立。
	db   "Resets both sides'"
	next "stat changes.@"
MoveDexDescHaze3:
	; 非易失状态只清除目标一侧。
	db   "Cures target's"
	next "major status.@"
MoveDexDescHaze4:
	; 双方都会清 Confused、Disable 和 Leech Seed。
	db   "Both sides lose"
	next "confusion, Disable"
	next "and Leech Seed.@"
MoveDexDescHaze5:
	; 同时清 Mist、Focus Energy、Reflect、Light Screen 等战斗状态。
	db   "Also clears Mist,"
	next "Focus Energy and"
	next "both screens.@"

; #115 Reflect
MoveDexDescReflectPages:
	dw MoveDexDescReflect1, MoveDexDescEffectBReflect, MoveDexDescEffectBScreenDuration, 0
MoveDexDescReflect1:
	db   "Raises a psychic"
	next "reflective wall.@"

; #116 Focus Energy
MoveDexDescFocusEnergyPages:
	dw MoveDexDescFocusEnergy1, MoveDexDescEffectBFocusEnergy, 0
MoveDexDescFocusEnergy1:
	db   "Focuses energy for"
	next "critical hits.@"

; #117 Bide
MoveDexDescBidePages:
	dw MoveDexDescBide1, MoveDexDescEffectBBideTurns, MoveDexDescEffectBBideDamage, 0
MoveDexDescBide1:
	db   "Endures and stores"
	next "damage taken.@"

; #118 Metronome
MoveDexDescMetronomePages:
	dw MoveDexDescMetronome1, MoveDexDescMetronome2, 0
MoveDexDescMetronome1:
	db   "Waggles a finger,"
	next "then uses a random"
	next "move.@"
MoveDexDescMetronome2:
	; MetronomePickMove 排除 Metronome、Struggle，以及从 Dive 起的 #251-#253。
	db   "Won't call itself,"
	next "Struggle, Dive or"
	next "later moves.@"

; #119 Mirror Move
MoveDexDescMirrorMovePages:
	dw MoveDexDescMirrorMove1, MoveDexDescMirrorMove2, MoveDexDescMirrorMove3, 0
MoveDexDescMirrorMove1:
	db   "Copies the foe's"
	next "selected move.@"
MoveDexDescMirrorMove2:
	; RPP 实际执行的是对手本回合 selected move，但仍要求 used-move 记录非空。
	db   "Needs the foe to"
	next "have used a move"
	next "earlier in battle.@"
MoveDexDescMirrorMove3:
	db   "Also fails after"
	next "foe's Mirror Move.@"

; #120 SelfDestruct
MoveDexDescSelfdestructPages:
	dw MoveDexDescSelfdestruct1, MoveDexDescEffectBExplode1, MoveDexDescEffectBExplode2, 0
MoveDexDescSelfdestruct1:
	db   "Explodes with huge"
	next "force at the foe.@"

; #121 Egg Bomb
MoveDexDescEggBombPages:
	dw MoveDexDescEggBomb1, 0
MoveDexDescEggBomb1:
	db   "Throws a large egg"
	next "at the foe.@"

; #122 Lick
MoveDexDescLickPages:
	dw MoveDexDescLick1, MoveDexDescEffectBParalyze30Ghost, MoveDexDescEffectBParalyzeGhostImmune, 0
MoveDexDescLick1:
	db   "Licks the foe with"
	next "a long tongue.@"

; #123 Smog
MoveDexDescSmogPages:
	dw MoveDexDescSmog1, MoveDexDescEffectBPoison40, MoveDexDescEffectBPoisonImmunity, 0
MoveDexDescSmog1:
	db   "Blasts poisonous"
	next "smog at the foe.@"

; #124 Sludge
MoveDexDescSludgePages:
	dw MoveDexDescSludge1, MoveDexDescEffectBPoison40, MoveDexDescEffectBPoisonImmunity, 0
MoveDexDescSludge1:
	db   "Covers the foe in"
	next "poisonous sludge.@"

; #125 Bone Club
MoveDexDescBoneClubPages:
	dw MoveDexDescBoneClub1, MoveDexDescEffectBFlinch10, 0
MoveDexDescBoneClub1:
	db   "Clubs the foe with"
	next "a hard bone.@"

; #126 Fire Blast
MoveDexDescFireBlastPages:
	dw MoveDexDescFireBlast1, MoveDexDescEffectBBurn30, MoveDexDescEffectBBurnFireImmune, 0
MoveDexDescFireBlast1:
	db   "Engulfs the foe in"
	next "a blast of fire.@"

; #127 Waterfall
MoveDexDescWaterfallPages:
	dw MoveDexDescWaterfall1, 0
MoveDexDescWaterfall1:
	; RPP 当前 Waterfall 没有追加畏缩效果。
	db   "Charges the foe on"
	next "a rushing wave.@"

; #128 Clamp
MoveDexDescClampPages:
	dw MoveDexDescClamp1, MoveDexDescEffectBTrapTurns, MoveDexDescEffectBTrapLock, 0
MoveDexDescClamp1:
	db   "Clamps the foe in"
	next "a hard shell grip.@"

; #129 Swift
MoveDexDescSwiftPages:
	dw MoveDexDescSwift1, MoveDexDescEffectBSwift, 0
MoveDexDescSwift1:
	db   "Fires star-shaped"
	next "rays at the foe.@"

; #130 Skull Bash
MoveDexDescSkullBashPages:
	dw MoveDexDescSkullBash1, 0
MoveDexDescSkullBash1:
	; RPP 当前只蓄力后攻击，没有额外提升 Defense。
	db   "Lowers its head on"
	next "the first turn."
	next "Strikes next turn.@"

; #131 Spike Cannon
MoveDexDescSpikeCannonPages:
	dw MoveDexDescSpikeCannon1, MoveDexDescEffectBHits2To5, 0
MoveDexDescSpikeCannon1:
	db   "Fires sharp spikes"
	next "in rapid volleys.@"

; #132 Constrict
MoveDexDescConstrictPages:
	dw MoveDexDescConstrict1, MoveDexDescEffectBSpeedDown33, 0
MoveDexDescConstrict1:
	db   "Tightly squeezes"
	next "the foe in coils.@"

; #133 Amnesia
MoveDexDescAmnesiaPages:
	dw MoveDexDescAmnesia1, MoveDexDescEffectBSpecialUp2, 0
MoveDexDescAmnesia1:
	db   "Clears the mind to"
	next "focus its power.@"

; #134 Kinesis
MoveDexDescKinesisPages:
	dw MoveDexDescKinesis1, MoveDexDescEffectBAccuracyDown1, 0
MoveDexDescKinesis1:
	db   "Distracts the foe"
	next "with a bent spoon.@"

; #135 Softboiled
MoveDexDescSoftboiledPages:
	dw MoveDexDescSoftboiled1, MoveDexDescEffectBHealHalf, 0
MoveDexDescSoftboiled1:
	db   "Restores HP with a"
	next "nourishing egg.@"

; #136 Hi Jump Kick
MoveDexDescHiJumpKickPages:
	dw MoveDexDescHiJumpKick1, MoveDexDescEffectBJumpKickCrash, 0
MoveDexDescHiJumpKick1:
	db   "Leaps high to land"
	next "a powerful kick.@"

; #137 Glare
MoveDexDescGlarePages:
	dw MoveDexDescGlare1, MoveDexDescEffectBParalyzeAlways, 0
MoveDexDescGlare1:
	; GLARE 是 Normal 属性，RPP 的 ParalyzeEffect 只对 Electric 招式检查 Ground 免疫。
	db   "Glares at the foe"
	next "with fierce eyes.@"

; #138 Dream Eater
MoveDexDescDreamEaterPages:
	dw MoveDexDescDreamEater1, MoveDexDescDreamEater2, MoveDexDescEffectBDrainHalf, 0
MoveDexDescDreamEater1:
	db   "Feeds on dreams of"
	next "a sleeping foe.@"
MoveDexDescDreamEater2:
	db   "Works only if foe"
	next "is asleep.@"

; #139 Poison Gas
MoveDexDescPoisonGasPages:
	dw MoveDexDescPoisonGas1, MoveDexDescEffectBPoisonAlways, MoveDexDescEffectBPoisonImmunity, 0
MoveDexDescPoisonGas1:
	db   "Releases a cloud"
	next "of poisonous gas.@"

; #140 Barrage
MoveDexDescBarragePages:
	dw MoveDexDescBarrage1, MoveDexDescEffectBHits2To5, 0
MoveDexDescBarrage1:
	db   "Pelts the foe with"
	next "round objects.@"

; #141 Leech Life
MoveDexDescLeechLifePages:
	dw MoveDexDescLeechLife1, MoveDexDescEffectBDrainHalf, 0
MoveDexDescLeechLife1:
	db   "Bites the foe and"
	next "drains its energy.@"

; #142 Lovely Kiss
MoveDexDescLovelyKissPages:
	dw MoveDexDescLovelyKiss1, MoveDexDescEffectBSleep, 0
MoveDexDescLovelyKiss1:
	db   "Lulls the foe with"
	next "a strange kiss.@"

; #143 Sky Attack
MoveDexDescSkyAttackPages:
	dw MoveDexDescSkyAttack1, 0
MoveDexDescSkyAttack1:
	; RPP 当前只有标准两回合蓄力，没有追加畏缩或高暴击。
	db   "Charges on turn 1."
	next "Strikes on turn 2.@"

; #144 Transform
MoveDexDescTransformPages:
	dw MoveDexDescTransform1, MoveDexDescTransform2, MoveDexDescTransform3, MoveDexDescEffectBTargetInvulnerable, 0
MoveDexDescTransform1:
	db   "Copies the foe's"
	next "form in battle.@"
MoveDexDescTransform2:
	; RPP 复制 type、DVs、Attack/Defense/Speed/Special、stat mods 和招式。
	db   "Copies foe types"
	next "stats and moves.@"
MoveDexDescTransform3:
	db   "Copied moves have"
	next "5 PP each.@"

; #145 Bubble
MoveDexDescBubblePages:
	dw MoveDexDescBubble1, MoveDexDescEffectBSpeedDown33, 0
MoveDexDescBubble1:
	db   "Blows bubbles that"
	next "burst on the foe.@"

; #146 Dizzy Punch
MoveDexDescDizzyPunchPages:
	dw MoveDexDescDizzyPunch1, MoveDexDescEffectBConfuse10, MoveDexDescEffectBConfusionDuration, 0
MoveDexDescDizzyPunch1:
	db   "Lands a dizzying"
	next "punch on the foe.@"

; #147 Spore
MoveDexDescSporePages:
	dw MoveDexDescSpore1, MoveDexDescEffectBSleep, 0
MoveDexDescSpore1:
	db   "Covers the foe in"
	next "potent spores.@"

; #148 Flash
MoveDexDescFlashPages:
	dw MoveDexDescFlash1, MoveDexDescEffectBAccuracyDown1, 0
MoveDexDescFlash1:
	db   "Blinds the foe in"
	next "a brilliant flash.@"

; #149 Psywave
MoveDexDescPsywavePages:
	dw MoveDexDescPsywave1, MoveDexDescEffectBPsywave, 0
MoveDexDescPsywave1:
	db   "Sends a strange"
	next "psychic wave.@"

; #150 Splash
MoveDexDescSplashPages:
	dw MoveDexDescSplash1, 0
MoveDexDescSplash1:
	db   "Flops around"
	next "pointlessly.@"

; ---------------------------------------------------------------------------
; Bank $39 共用机制页。
; 与 $3B 同概念的页面只在本 bank 复制一份，避免 page-list 二级跨 bank。
; ---------------------------------------------------------------------------


MoveDexDescEffectBLevelDamage:
	db   "Deals damage equal"
	next "to user's level.@"

MoveDexDescEffectBDefenseDown2:
	db   "Lowers Defense"
	next "by 2 stages.@"

MoveDexDescEffectBEvasionUp1:
	db   "Raises Evasion"
	next "by 1 stage.@"

MoveDexDescEffectBHealHalf:
	; HealEffect_ 对 Recover / Softboiled 在满 HP 时会直接失败。
	db   "Restores 50", $d9, " of"
	next "the user's max HP."
	next "Fails at full HP.@"

MoveDexDescEffectBDefenseUp1:
	db   "Raises Defense"
	next "by 1 stage.@"

MoveDexDescEffectBAccuracyDown1:
	db   "Lowers Accuracy"
	next "by 1 stage.@"

MoveDexDescEffectBConfuseAlways:
	db   "Confuses the foe"
	next "whenever it hits.@"

MoveDexDescEffectBDefenseUp2:
	db   "Raises Defense"
	next "by 2 stages.@"

MoveDexDescEffectBLightScreen:
	db   "Special damage is"
	next "roughly halved.@"

MoveDexDescEffectBReflect:
	db   "Physical damage is"
	next "roughly halved.@"

MoveDexDescEffectBScreenDuration:
	db   "Lasts until user"
	next "switches or Haze.@"

MoveDexDescEffectBFocusEnergy:
	; 普通招式从约 6.25% 提到约 12.1%；高暴击招式也会进一步提高。
	db   "Crit chance rises."
	next "Effect ends after"
	next "switch or Haze.@"

MoveDexDescEffectBBideTurns:
	; Bide counter 随机为 2/3，各 50%。
	db   "Waits 2-3 turns."
	next "2 or 3: 50", $d9, " each.@"

MoveDexDescEffectBBideDamage:
	db   "Deals twice the"
	next "stored damage.@"

MoveDexDescEffectBExplode1:
	; EXPLODE_EFFECT 在 CalculateDamage 中将目标 Defense 减半。
	db   "Foe's Defense is"
	next "halved for damage."
	next "User then faints.@"

MoveDexDescEffectBExplode2:
	; 即使爆炸招式 miss，ExplodeEffect 仍会执行。
	db   "User faints even"
	next "after a miss.@"

MoveDexDescEffectBParalyze30Ghost:
	db   "30", $d9, " chance to"
	next "paralyze the foe.@"

MoveDexDescEffectBParalyzeGhostImmune:
	; Lick 为 Ghost 属性，因此通用追加状态逻辑会阻止对 Ghost 属性目标的麻痹。
	db   "Cannot paralyze a"
	next "Ghost-type foe.@"

MoveDexDescEffectBPoison40:
	; POISON_SIDE_EFFECT2 在 RPP 为 $67/256，约 40%。
	db   "40", $d9, " chance to"
	next "poison the foe.@"

MoveDexDescEffectBFlinch10:
	db   "10", $d9, " chance to make"
	next "the foe flinch.@"

MoveDexDescEffectBBurn30:
	; BURN_SIDE_EFFECT2 为 $4D/256，约 30%。
	db   "30", $d9, " chance to"
	next "burn the foe.@"

MoveDexDescEffectBBurnFireImmune:
	; Fire 属性目标只免疫追加烧伤，不表示 Fire Blast 本身无效。
	db   "Cannot burn a"
	next "Fire-type foe.@"

MoveDexDescEffectBSwift:
	; Swift 跳过普通命中测试，但 Fly/Dig 的 Invulnerable 检查仍然优先。
	db   "Cannot miss unless"
	next "foe is flying high"
	next "or underground.@"

MoveDexDescEffectBTargetInvulnerable:
	; Mimic / Transform 都会对 Fly / Dig 的 Invulnerable 目标直接失败。
	db   "Fails if foe is"
	next "flying high or"
	next "underground.@"

MoveDexDescEffectBHits2To5:
	db   "Hits 2-5 times."
	next "2-3 hits: 37.5", $d9
	next "4-5 hits: 12.5", $d9, "@"

MoveDexDescEffectBSpeedDown33:
	; SPEED_DOWN_SIDE_EFFECT 通过 85/256 判定，约 33%。
	db   "33", $d9, " chance."
	next "Foe's Speed"
	next "drops 1 stage.@"

MoveDexDescEffectBSpecialUp2:
	db   "Raises Special"
	next "by 2 stages.@"

MoveDexDescEffectBJumpKickCrash:
	; 当前 RPP miss 时 wDamage 已为 0，最低 crash damage 因而固定为 1 HP。
	db   "If it misses, user"
	next "loses just 1 HP.@"

MoveDexDescEffectBPsywave:
	; 随机值范围为 [1, floor(level*1.5))。
	db   "Damage is random:"
	next "1 to below 1.5x"
	next "user's level.@"

MoveDexDescEffectBDrainHalf:
	; DRAIN_HP_EFFECT 恢复造成伤害的一半，最低恢复 1 HP。
	db   "Heals half of the"
	next "damage it deals.@"

MoveDexDescEffectBLeechSeed:
	; 每回合吸取目标 1/8 最大 HP，并按实际扣除量等量回复使用者。
	db   "Drains 1/8 max HP"
	next "from foe each turn"
	next "and heals user.@"

MoveDexDescEffectBLeechSeedImmune:
	db   "Grass-type foes"
	next "cannot be seeded.@"

MoveDexDescEffectBGrowth:
	; RPP Growth 同时提升 Attack 与 Special 各 1 stage。
	db   "Attack and Special"
	next "rise by 1 stage.@"

MoveDexDescEffectBHighCrit:
	db   "About 25", $d9, " of hits"
	next "are critical hits.@"

MoveDexDescEffectBPoisonAlways:
	db   "Poisons the foe"
	next "whenever it hits.@"

MoveDexDescEffectBPoisonImmunity:
	; 这里只描述中毒免疫，不表示伤害招式本身对这些属性完全无效。
	db   "Cannot poison"
	next "Poison/Steel foes.@"

MoveDexDescEffectBParalyzeAlways:
	db   "Paralyzes the foe"
	next "whenever it hits.@"

MoveDexDescEffectBSleep:
	db   "Puts foe to sleep."
	next "Foe skips 1-4"
	next "actions, 25", $d9, " each.@"

MoveDexDescEffectBThrashTurns:
	; Petal Dance 与 Thrash 共用：初次攻击后再锁 2/3 次，总计 3-4 回合，各 50%。
	db   "Lasts 3-4 turns."
	next "3 or 4: 50", $d9, " each.@"

MoveDexDescEffectBThrashConfuse:
	db   "Confuses the user"
	next "after it ends.@"

MoveDexDescEffectBConfusionDuration:
	db   "Duration is 2-5"
	next "turns, 25", $d9, " each.@"

MoveDexDescEffectBSpeedDown1:
	db   "Lowers Speed"
	next "by 1 stage.@"

MoveDexDescEffectBTrapTurns:
	db   "Lasts 2-5 turns."
	next "2-3 turns: 37.5", $d9
	next "4-5 turns: 12.5", $d9, "@"

MoveDexDescEffectBTrapLock:
	db   "Foe cannot move"
	next "while trapped.@"

MoveDexDescEffectBParalyze10:
	db   "10", $d9, " chance to"
	next "paralyze the foe.@"

MoveDexDescEffectBParalyzeElectricImmune:
	; 这里只描述追加麻痹；Electric 属性目标仍按正常伤害属性判定。
	db   "Cannot paralyze an"
	next "Electric-type foe.@"

MoveDexDescEffectBThunderWave:
	; THUNDER_WAVE 走独立 ParalyzeEffect：Electric 属性招式只检查 Ground 免疫。
	db   "Paralyzes the foe"
	next "whenever it hits.@"

MoveDexDescEffectBGroundImmune:
	db   "Does not affect"
	next "Ground-type foes.@"

MoveDexDescEffectBOHKO:
	db   "One-hit KO."
	next "Fails against"
	next "a faster foe.@"

MoveDexDescEffectBUnderground:
	db   "Most attacks miss"
	next "while underground.@"

MoveDexDescEffectBToxic1:
	db   "Badly poisons the"
	next "foe when it hits.@"

MoveDexDescEffectBToxic2:
	; Toxic 从 1/16 最大 HP 起步，之后每次残余伤害增加一个 1/16 档位。
	db   "Damage starts at"
	next "1/16 max HP and"
	next "grows each turn.@"

MoveDexDescEffectBConfuse10:
	db   "10", $d9, " chance to"
	next "confuse the foe.@"

MoveDexDescEffectBSpecialDown33:
	db   "33", $d9, " chance."
	next "Foe's Special stat"
	next "drops 1 stage.@"

MoveDexDescEffectBAttackUp1:
	db   "Raises Attack"
	next "by 1 stage.@"

MoveDexDescEffectBSpeedUp2:
	db   "Raises Speed"
	next "by 2 stages.@"

MoveDexDescEffectBPriority:
	db   "Moves before most"
	next "other attacks.@"

MoveDexDescEffectBRage1:
	db   "Locks user into"
	next "Rage every turn.@"

MoveDexDescEffectBRage2:
	db   "When hit, Attack"
	next "rises by 1 stage.@"

MoveDexDescEffectBWildEscape1:
	db   "In wild battles,"
	next "success depends on"
	next "user/foe levels.@"

MoveDexDescEffectBWildEscape2:
	db   "User equal/higher:"
	next "always succeeds."
	next "Fails vs Trainers.@"


; ---------------------------------------------------------------------------
; Bank $34：#151-#200。
; $39 保留安全余量，后续说明继续按大空闲 bank 分段。
; 本 bank 的 page-list 只引用本 bank 页面，避免二级跨 bank 指针。
; ---------------------------------------------------------------------------

SECTION "MoveDex Descriptions C", ROMX, BANK[$34]

; #151 Acid Armor
MoveDexDescAcidArmorPages:
	dw MoveDexDescAcidArmor1, MoveDexDescEffectCDefenseUp2, 0
MoveDexDescAcidArmor1:
	db   "Liquefies the body"
	next "to boost Defense.@"

; #152 Crabhammer
MoveDexDescCrabhammerPages:
	dw MoveDexDescCrabhammer1, MoveDexDescEffectCHighCrit, 0
MoveDexDescCrabhammer1:
	db   "Slams a heavy claw"
	next "down on the foe.@"

; #153 Explosion
MoveDexDescExplosionPages:
	dw MoveDexDescExplosion1, MoveDexDescEffectCExplode1, MoveDexDescEffectCExplode2, 0
MoveDexDescExplosion1:
	db   "Triggers a massive"
	next "self-explosion.@"

; #154 Fury Swipes
MoveDexDescFurySwipesPages:
	dw MoveDexDescFurySwipes1, MoveDexDescEffectCHits2To5, 0
MoveDexDescFurySwipes1:
	db   "Rakes in a flurry"
	next "with sharp claws.@"

; #155 Bonemerang
MoveDexDescBonemerangPages:
	dw MoveDexDescBonemerang1, MoveDexDescEffectCHitsTwice, 0
MoveDexDescBonemerang1:
	db   "A thrown bone hits"
	next "the foe twice.@"

; #156 Rest
MoveDexDescRestPages:
	dw MoveDexDescRest1, MoveDexDescRest2, MoveDexDescRest3, 0
MoveDexDescRest1:
	db   "User falls into"
	next "a deep sleep to"
	next "recover fully.@"
MoveDexDescRest2:
	db   "Restores all HP."
	next "Clears old status.@"
MoveDexDescRest3:
	; Rest 写入睡眠计数 2；使用回合已完成，下一次行动跳过，再下一次检查会醒来并正常行动。
	; HealEffect_ 会先检查 HP；满 HP 时即使带异常状态也会直接失败。
	db   "Skips next action."
	next "Then wakes to act."
	next "Fails at full HP.@"

; #157 Rock Slide
MoveDexDescRockSlidePages:
	dw MoveDexDescRockSlide1, MoveDexDescEffectCFlinch10, 0
MoveDexDescRockSlide1:
	db   "Drops heavy rocks"
	next "onto the foe.@"

; #158 Hyper Fang
MoveDexDescHyperFangPages:
	dw MoveDexDescHyperFang1, MoveDexDescEffectCFlinch10, 0
MoveDexDescHyperFang1:
	db   "Snaps at the foe"
	next "with sharp fangs.@"

; #159 Hone Claws
MoveDexDescHoneClawsPages:
	dw MoveDexDescHoneClaws1, MoveDexDescEffectCHoneClaws, 0
MoveDexDescHoneClaws1:
	db   "Sharpens its claws"
	next "to improve focus.@"

; #160 Conversion
MoveDexDescConversionPages:
	dw MoveDexDescConversion1, MoveDexDescConversion2, 0
MoveDexDescConversion1:
	; 当前 RPP 复制目标的两个属性槽；改用 both 避免 two / to 在小字体下看岔。
	db   "Copies both of"
	next "the foe's types.@"
MoveDexDescConversion2:
	; ConversionEffect_ 对 Fly/Dig 的 Invulnerable 目标直接失败。
	db   "Fails if foe is"
	next "flying high or"
	next "underground.@"

; #161 Tri Attack
MoveDexDescTriAttackPages:
	dw MoveDexDescTriAttack1, MoveDexDescEffectCTriAttack1, MoveDexDescEffectCTriAttack2, MoveDexDescEffectCTriAttackNormalImmune, 0
MoveDexDescTriAttack1:
	db   "Fires three kinds"
	next "of energy at once.@"

; #162 Super Fang
MoveDexDescSuperFangPages:
	dw MoveDexDescSuperFang1, MoveDexDescEffectCSuperFang, 0
MoveDexDescSuperFang1:
	db   "Chomps with huge"
	next "front fangs.@"

; #163 Slash
MoveDexDescSlashPages:
	dw MoveDexDescSlash1, MoveDexDescEffectCHighCrit, 0
MoveDexDescSlash1:
	db   "Slashes with sharp"
	next "claws or blades.@"

; #164 Substitute
MoveDexDescSubstitutePages:
	dw MoveDexDescSubstitute1, MoveDexDescEffectCSubstituteCost, MoveDexDescEffectCSubstituteBlock, MoveDexDescEffectCSubstituteFail, 0
MoveDexDescSubstitute1:
	db   "Creates a decoy"
	next "using its own HP.@"

; #165 Struggle
MoveDexDescStrugglePages:
	dw MoveDexDescStruggle1, MoveDexDescEffectCRecoil50, 0
MoveDexDescStruggle1:
	db   "A desperate attack"
	next "used with no PP.@"

; #166 Metal Claw
MoveDexDescMetalClawPages:
	dw MoveDexDescMetalClaw1, MoveDexDescEffectCAttackUp10, 0
MoveDexDescMetalClaw1:
	db   "Rakes the foe with"
	next "steel-hard claws.@"

; #167 Bullet Punch
MoveDexDescBulletPunchPages:
	dw MoveDexDescBulletPunch1, MoveDexDescEffectCPriority, 0
MoveDexDescBulletPunch1:
	db   "Throws a swift"
	next "steel-hard punch.@"

; #168 Flash Cannon
MoveDexDescFlashCannonPages:
	dw MoveDexDescFlashCannon1, MoveDexDescEffectCSpecialDown33, 0
MoveDexDescFlashCannon1:
	db   "Fires a steel beam"
	next "of bright energy.@"

; #169 Iron Tail
MoveDexDescIronTailPages:
	dw MoveDexDescIronTail1, MoveDexDescEffectCDefenseDown33, 0
MoveDexDescIronTail1:
	db   "Slams with a hard"
	next "steel-coated tail.@"

; #170 Meteor Mash
MoveDexDescMeteorMashPages:
	dw MoveDexDescMeteorMash1, MoveDexDescEffectCAttackUp20, 0
MoveDexDescMeteorMash1:
	db   "Hits like a meteor"
	next "from high above.@"

; #171 Crunch
MoveDexDescCrunchPages:
	dw MoveDexDescCrunch1, MoveDexDescEffectCDefenseDown33, 0
MoveDexDescCrunch1:
	db   "Bites the foe with"
	next "razor-sharp fangs.@"

; #172 Dark Pulse
MoveDexDescDarkPulsePages:
	dw MoveDexDescDarkPulse1, MoveDexDescEffectCFlinch10, 0
MoveDexDescDarkPulse1:
	db   "Sends dark power"
	next "in a pulsing wave.@"

; #173 Feint Attack
MoveDexDescFeintAttackPages:
	dw MoveDexDescFeintAttack1, MoveDexDescEffectCSwift, 0
MoveDexDescFeintAttack1:
	db   "Closes in before"
	next "striking the foe.@"

; #174 Night Slash
MoveDexDescNightSlashPages:
	dw MoveDexDescNightSlash1, MoveDexDescEffectCHighCrit, 0
MoveDexDescNightSlash1:
	db   "Slashes at a weak"
	next "point in the dark.@"

; #175 Moonblast
MoveDexDescMoonblastPages:
	dw MoveDexDescMoonblast1, MoveDexDescEffectCSpecialDown33, 0
MoveDexDescMoonblast1:
	db   "Draws on moonlight"
	next "to attack the foe.@"

; #176 Draining Kiss
MoveDexDescDrainingKissPages:
	dw MoveDexDescDrainingKiss1, MoveDexDescEffectCDrainHalf, 0
MoveDexDescDrainingKiss1:
	db   "Steals energy with"
	next "a draining kiss.@"

; #177 Disarming Voice
MoveDexDescDisarmingVoicePages:
	dw MoveDexDescDisarmingVoice1, MoveDexDescEffectCSwift, 0
MoveDexDescDisarmingVoice1:
	db   "Cries out with a"
	next "charming voice.@"

; #178 Dazzling Gleam
MoveDexDescDazzlingGleamPages:
	dw MoveDexDescDazzlingGleam1, 0
MoveDexDescDazzlingGleam1:
	db   "Bathes the foe in"
	next "dazzling light.@"

; #179 Draco Meteor
MoveDexDescDracoMeteorPages:
	; 当前 RPP 为 SPECIAL_DOWN_SIDE_EFFECT：约 33% 降低目标 Special 1 stage。
	dw MoveDexDescDracoMeteor1, MoveDexDescEffectCSpecialDown33, 0
MoveDexDescDracoMeteor1:
	db   "Calls down fierce"
	next "dragon meteors.@"

; #180 Dragonbreath
MoveDexDescDragonbreathPages:
	; 通用状态追加按“招式属性 = 目标属性”阻止，因此这里是 Dragon 目标免疫追加麻痹。
	dw MoveDexDescDragonbreath1, MoveDexDescEffectCParalyze10Dragon, MoveDexDescEffectCParalyzeDragonImmune, 0
MoveDexDescDragonbreath1:
	db   "Breathes a blast"
	next "of dragon energy.@"

; #181 Dragon Claw
MoveDexDescDragonClawPages:
	dw MoveDexDescDragonClaw1, 0
MoveDexDescDragonClaw1:
	db   "Tears at the foe"
	next "with dragon claws.@"

; #182 Dragon Pulse
MoveDexDescDragonPulsePages:
	dw MoveDexDescDragonPulse1, 0
MoveDexDescDragonPulse1:
	db   "Fires a pulse of"
	next "dragon energy.@"

; #183 Twister
MoveDexDescTwisterPages:
	dw MoveDexDescTwister1, MoveDexDescEffectCFlinch10, 0
MoveDexDescTwister1:
	db   "Whips up a fierce"
	next "dragon tornado.@"

; #184 Outrage
MoveDexDescOutragePages:
	dw MoveDexDescOutrage1, MoveDexDescEffectCThrashTurns, MoveDexDescEffectCThrashConfuse, MoveDexDescEffectCConfusionDuration, 0
MoveDexDescOutrage1:
	db   "Attacks in a wild"
	next "dragon rampage.@"

; #185 Shadow Claw
MoveDexDescShadowClawPages:
	dw MoveDexDescShadowClaw1, MoveDexDescEffectCHighCrit, 0
MoveDexDescShadowClaw1:
	db   "Slashes using a"
	next "shadowy claw.@"

; #186 Steel Wing
MoveDexDescSteelWingPages:
	dw MoveDexDescSteelWing1, MoveDexDescEffectCDefenseUp10, 0
MoveDexDescSteelWing1:
	db   "Strikes with hard"
	next "steel-like wings.@"

; #187 Iron Defense
MoveDexDescIronDefensePages:
	dw MoveDexDescIronDefense1, MoveDexDescEffectCDefenseUp2, 0
MoveDexDescIronDefense1:
	db   "Hardens the body"
	next "like solid iron.@"

; #188 Air Slash
MoveDexDescAirSlashPages:
	dw MoveDexDescAirSlash1, MoveDexDescEffectCFlinch30, 0
MoveDexDescAirSlash1:
	db   "Sends a blade of"
	next "compressed air.@"

; #189 Fire Fang
MoveDexDescFireFangPages:
	; FangAttacks 先走 FlinchSideEffect；非 FLINCH_SIDE_EFFECT1 因而实际约 30% 畏缩，再独立约 10% 状态。
	dw MoveDexDescFireFang1, MoveDexDescEffectCFlinch30, MoveDexDescEffectCBurn10Fire, MoveDexDescEffectCBurnFireImmune, 0
MoveDexDescFireFang1:
	db   "Bites with fangs"
	next "wrapped in flame.@"

; #190 Flare Blitz
MoveDexDescFlareBlitzPages:
	; 当前 move effect 只有 RECOIL_EFFECT；没有现代版烧伤追加，但 FrozenCheck 特判可自行解冻。
	dw MoveDexDescFlareBlitz1, MoveDexDescEffectCRecoil25, MoveDexDescEffectCSelfThaw, 0
MoveDexDescFlareBlitz1:
	db   "Charges in cloaked"
	next "in raging flames.@"

; #191 Blast Burn
MoveDexDescBlastBurnPages:
	dw MoveDexDescBlastBurn1, MoveDexDescEffectCRecharge, 0
MoveDexDescBlastBurn1:
	db   "Unleashes a huge"
	next "blast of fire.@"

; #192 Ice Fang
MoveDexDescIceFangPages:
	dw MoveDexDescIceFang1, MoveDexDescEffectCFlinch30, MoveDexDescEffectCFreeze10Ice, MoveDexDescEffectCFreezeIceImmune, 0
MoveDexDescIceFang1:
	db   "Bites with fangs"
	next "covered in frost.@"

; #193 Thunder Fang
MoveDexDescThunderFangPages:
	dw MoveDexDescThunderFang1, MoveDexDescEffectCFlinch30, MoveDexDescEffectCParalyze10Electric, MoveDexDescEffectCParalyzeElectricImmune, 0
MoveDexDescThunderFang1:
	db   "Bites with charged"
	next "electric fangs.@"

; #194 Water Pulse
MoveDexDescWaterPulsePages:
	; CONFUSION_SIDE_EFFECT 在当前 RPP 为约 10%，不是现代常见的 20%。
	dw MoveDexDescWaterPulse1, MoveDexDescEffectCConfuse10, MoveDexDescEffectCConfusionDuration, 0
MoveDexDescWaterPulse1:
	db   "Fires a pulsing"
	next "blast of water.@"

; #195 Aqua Tail
MoveDexDescAquaTailPages:
	dw MoveDexDescAquaTail1, 0
MoveDexDescAquaTail1:
	db   "Swings a powerful"
	next "water-coated tail.@"

; #196 Hydro Cannon
MoveDexDescHydroCannonPages:
	dw MoveDexDescHydroCannon1, MoveDexDescEffectCRecharge, 0
MoveDexDescHydroCannon1:
	db   "Blasts a huge jet"
	next "of raging water.@"

; #197 Frenzy Plant
MoveDexDescFrenzyPlantPages:
	dw MoveDexDescFrenzyPlant1, MoveDexDescEffectCRecharge, 0
MoveDexDescFrenzyPlant1:
	db   "Slams the foe with"
	next "wild plant roots.@"

; #198 Sucker Punch
MoveDexDescSuckerPunchPages:
	; 当前 RPP 只把 Sucker Punch 放入 priority move 列表，没有现代版“目标未选择攻击则失败”的判定。
	dw MoveDexDescSuckerPunch1, MoveDexDescEffectCPriority, 0
MoveDexDescSuckerPunch1:
	db   "Ambushes the foe"
	next "with a sudden hit.@"

; #199 Shadow Ball
MoveDexDescShadowBallPages:
	dw MoveDexDescShadowBall1, MoveDexDescEffectCSpecialDown33, 0
MoveDexDescShadowBall1:
	db   "Fires a shadow orb"
	next "of dark energy.@"

; #200 Flame Wheel
MoveDexDescFlameWheelPages:
	; BURN_SIDE_EFFECT1 约 10%；FrozenCheck 另有 move-ID 特判，可让冻结中的使用者先解冻再行动。
	dw MoveDexDescFlameWheel1, MoveDexDescEffectCBurn10Fire, MoveDexDescEffectCBurnFireImmune, MoveDexDescEffectCSelfThaw, 0
MoveDexDescFlameWheel1:
	db   "Rolls into the foe"
	next "wrapped in flame.@"

; ---------------------------------------------------------------------------
; Bank $34 共用机制页。
; ---------------------------------------------------------------------------

MoveDexDescEffectCDefenseUp2:
	db   "Raises Defense"
	next "by 2 stages.@"

MoveDexDescEffectCHighCrit:
	db   "About 25", $d9, " of hits"
	next "are critical hits.@"

MoveDexDescEffectCExplode1:
	db   "Foe's Defense is"
	next "halved for damage."
	next "User then faints.@"

MoveDexDescEffectCExplode2:
	db   "User faints even"
	next "after a miss.@"

MoveDexDescEffectCHits2To5:
	db   "Hits 2-5 times."
	next "2-3 hits: 37.5", $d9
	next "4-5 hits: 12.5", $d9, "@"

MoveDexDescEffectCHitsTwice:
	db   "Always hits twice.@"

MoveDexDescEffectCFlinch10:
	db   "10", $d9, " chance to make"
	next "the foe flinch.@"

MoveDexDescEffectCHoneClaws:
	; Hone Claws 同时提升 Attack 与 Accuracy，各 1 stage。
	db   "Attack, Accuracy"
	next "rise by 1 stage.@"

MoveDexDescEffectCTriAttack1:
	; TriAttackEffect 先随机选 burn/freeze/paralyze，再走约 10% 的状态追加判定。
	db   "10", $d9, " chance of one"
	next "random status.@"

MoveDexDescEffectCTriAttack2:
	db   "Burn, freeze, or"
	next "paralyze randomly.@"

MoveDexDescEffectCTriAttackNormalImmune:
	; Tri Attack 为 Normal 属性，因此通用状态追加逻辑会阻止 Normal 目标的三种追加状态。
	db   "No added status on"
	next "Normal-type foes.@"

MoveDexDescEffectCSuperFang:
	db   "Cuts current HP in"
	next "half, minimum 1.@"

MoveDexDescEffectCSubstituteCost:
	db   "Uses 1/4 max HP"
	next "to make the decoy.@"

MoveDexDescEffectCSubstituteBlock:
	db   "Takes hits, blocks"
	next "many effects.@"

MoveDexDescEffectCSubstituteFail:
	db   "Fails if active or"
	next "user is too weak.@"

MoveDexDescEffectCRecoil50:
	; RecoilEffect_ 对 Struggle 特判为造成伤害的 50%。
	db   "User takes 50", $d9, " of"
	next "damage as recoil.@"

MoveDexDescEffectCAttackUp10:
	db   "10", $d9, " chance to"
	next "raise Attack"
	next "by 1 stage.@"

MoveDexDescEffectCPriority:
	db   "Moves before most"
	next "other attacks.@"

MoveDexDescEffectCSpecialDown33:
	; SIDE_EFFECT stat-down 统一用 85/256，约 33%；作用目标是对手。
	db   "33", $d9, " chance."
	next "Foe's Special stat"
	next "drops 1 stage.@"

MoveDexDescEffectCDefenseDown33:
	db   "33", $d9, " chance."
	next "Foe's Defense"
	next "drops 1 stage.@"

MoveDexDescEffectCAttackUp20:
	; ATTACK_UP1_SIDE_EFFECT2 为 $34/256，约 20%。
	db   "20", $d9, " chance to"
	next "raise Attack"
	next "by 1 stage.@"

MoveDexDescEffectCSwift:
	db   "Cannot miss unless"
	next "foe is flying high"
	next "or underground.@"

MoveDexDescEffectCDrainHalf:
	db   "Heals half of the"
	next "damage it deals.@"

MoveDexDescEffectCParalyze10Dragon:
	db   "10", $d9, " chance to"
	next "paralyze the foe.@"

MoveDexDescEffectCParalyzeDragonImmune:
	; Dragonbreath 的追加麻痹按招式属性同属性免疫，因此 Dragon 目标不会被该追加效果麻痹。
	db   "Cannot paralyze a"
	next "Dragon-type foe.@"

MoveDexDescEffectCThrashTurns:
	db   "Lasts 3-4 turns."
	next "3 or 4: 50", $d9, " each.@"

MoveDexDescEffectCThrashConfuse:
	db   "Confuses the user"
	next "after it ends.@"

MoveDexDescEffectCConfusionDuration:
	db   "Duration is 2-5"
	next "turns, 25", $d9, " each.@"

MoveDexDescEffectCDefenseUp10:
	; DEFENSE_UP1_SIDE_EFFECT 为约 10%，作用于使用者。
	db   "10", $d9, " chance to"
	next "raise Defense"
	next "by 1 stage.@"

MoveDexDescEffectCFlinch30:
	db   "30", $d9, " chance to make"
	next "the foe flinch.@"

MoveDexDescEffectCBurn10Fire:
	db   "10", $d9, " chance to"
	next "burn the foe.@"

MoveDexDescEffectCBurnFireImmune:
	db   "Cannot burn a"
	next "Fire-type foe.@"

MoveDexDescEffectCRecoil25:
	db   "User takes 25", $d9, " of"
	next "damage as recoil.@"

MoveDexDescEffectCSelfThaw:
	db   "Thaws frozen user"
	next "before attacking.@"

MoveDexDescEffectCRecharge:
	db   "User must recharge"
	next "on the next turn.@"

MoveDexDescEffectCFreeze10Ice:
	db   "10", $d9, " chance to"
	next "freeze the foe.@"

MoveDexDescEffectCFreezeIceImmune:
	db   "Cannot freeze an"
	next "Ice-type foe.@"

MoveDexDescEffectCParalyze10Electric:
	db   "10", $d9, " chance to"
	next "paralyze the foe.@"

MoveDexDescEffectCParalyzeElectricImmune:
	db   "Cannot paralyze an"
	next "Electric-type foe.@"

MoveDexDescEffectCConfuse10:
	db   "10", $d9, " chance to"
	next "confuse the foe.@"

SECTION "MoveDex Descriptions D", ROMX, BANK[$38]

; ---------------------------------------------------------------------------
; #201-#253：最后一批连续技能说明。
; 本 bank 内的 page-list 只引用本 bank 页面，避免二级跨 bank 指针。
; ---------------------------------------------------------------------------

; #201 HealingLight
MoveDexDescHealingLightPages:
	dw MoveDexDescHealingLight1, MoveDexDescEffectDHealHalfMax, 0
MoveDexDescHealingLight1:
	db   "Basks in soft"
	next "healing light.@"

; #202 Hex
MoveDexDescHexPages:
	; RPP 在伤害计算前按目标状态把威力从 65 改为 130。
	dw MoveDexDescHex1, MoveDexDescEffectDHex, 0
MoveDexDescHex1:
	db   "Uses ghostly power"
	next "to strike the foe.@"

; #203 Shadow Punch
MoveDexDescShadowPunchPages:
	dw MoveDexDescShadowPunch1, MoveDexDescEffectDSwift, 0
MoveDexDescShadowPunch1:
	db   "Throws a shadow"
	next "punch at the foe.@"

; #204 Aerial Ace
MoveDexDescAerialAcePages:
	dw MoveDexDescAerialAce1, MoveDexDescEffectDSwift, 0
MoveDexDescAerialAce1:
	db   "Cuts the foe in a"
	next "swift aerial hit.@"

; #205 Acrobatics
MoveDexDescAcrobaticsPages:
	; 当前 RPP 固定 110 威力，没有现代版无道具增伤。
	dw MoveDexDescAcrobatics1, 0
MoveDexDescAcrobatics1:
	db   "A nimble aerial"
	next "strike at the foe.@"

; #206 Air Cutter
MoveDexDescAirCutterPages:
	; move effect 虽为 NO_ADDITIONAL_EFFECT，但技能列在 HighCriticalMoves。
	dw MoveDexDescAirCutter1, MoveDexDescEffectDHighCrit, 0
MoveDexDescAirCutter1:
	db   "Sends sharp blades"
	next "of cutting air.@"

; #207 Icy Wind
MoveDexDescIcyWindPages:
	dw MoveDexDescIcyWind1, MoveDexDescEffectDSpeedDown33, 0
MoveDexDescIcyWind1:
	db   "Sends icy wind"
	next "across the foe.@"

; #208 Ice Shard
MoveDexDescIceShardPages:
	dw MoveDexDescIceShard1, MoveDexDescEffectDPriority, 0
MoveDexDescIceShard1:
	db   "Hurls a sharp ice"
	next "shard at the foe.@"

; #209 Sheer Cold
MoveDexDescSheerColdPages:
	dw MoveDexDescSheerCold1, MoveDexDescEffectDOHKO, 0
MoveDexDescSheerCold1:
	db   "Unleashes cold air"
	next "to freeze the foe.@"

; #210 Electro Ball
MoveDexDescElectroBallPages:
	dw MoveDexDescElectroBall1, MoveDexDescElectroBall2, 0
MoveDexDescElectroBall1:
	db   "Hurls an electric"
	next "orb at the foe.@"
MoveDexDescElectroBall2:
	; RPP 使用三档速度比较，不采用现代 Electro Ball 的倍率表。
	db   "Power: 60 slower,"
	next "80 tied, 120 when"
	next "user is faster.@"

; #211 Nuzzle
MoveDexDescNuzzlePages:
	; NUZZLE_EFFECT 走 ParalyzeEffect：命中必定麻痹；Electric 招式会检查 Ground 免疫。
	dw MoveDexDescNuzzle1, MoveDexDescEffectDNuzzle, MoveDexDescEffectDGroundImmune, 0
MoveDexDescNuzzle1:
	db   "Nuzzles the foe"
	next "with electricity.@"

; #212 Discharge
MoveDexDescDischargePages:
	; 当前为 PARALYZE_SIDE_EFFECT1，约 10%；通用追加状态会让 Electric 目标免疫。
	dw MoveDexDescDischarge1, MoveDexDescEffectDParalyze10Electric, MoveDexDescEffectDParalyzeElectricImmune, 0
MoveDexDescDischarge1:
	db   "Releases a burst"
	next "of electricity.@"

; #213 Volt Tackle
MoveDexDescVoltTacklePages:
	; VOLT_TACKLE_EFFECT = 25% recoil + 独立约 10% 麻痹追加。
	dw MoveDexDescVoltTackle1, MoveDexDescEffectDRecoil25, MoveDexDescEffectDParalyze10Electric, MoveDexDescEffectDParalyzeElectricImmune, 0
MoveDexDescVoltTackle1:
	db   "Charges the foe"
	next "wrapped in sparks.@"

; #214 Muddy Water
MoveDexDescMuddyWaterPages:
	dw MoveDexDescMuddyWater1, MoveDexDescEffectDAccuracyDown33, 0
MoveDexDescMuddyWater1:
	db   "Hurls muddy water"
	next "all over the foe.@"

; #215 Whirlpool
MoveDexDescWhirlpoolPages:
	dw MoveDexDescWhirlpool1, MoveDexDescEffectDTrapTurns, MoveDexDescEffectDTrapLock, 0
MoveDexDescWhirlpool1:
	db   "Traps the foe in a"
	next "fierce whirlpool.@"

; #216 Giga Drain
MoveDexDescGigaDrainPages:
	dw MoveDexDescGigaDrain1, MoveDexDescEffectDDrainHalf, 0
MoveDexDescGigaDrain1:
	db   "Drains energy"
	next "from the foe to"
	next "restore health.@"

; #217 Petal Blizzard
MoveDexDescPetalBlizzardPages:
	dw MoveDexDescPetalBlizzard1, 0
MoveDexDescPetalBlizzard1:
	db   "Hits the foe with"
	next "a storm of petals.@"

; #218 Leaf Blade
MoveDexDescLeafBladePages:
	dw MoveDexDescLeafBlade1, MoveDexDescEffectDHighCrit, 0
MoveDexDescLeafBlade1:
	db   "Slashes using a"
	next "sharp leaf blade.@"

; #219 Wood Hammer
MoveDexDescWoodHammerPages:
	dw MoveDexDescWoodHammer1, MoveDexDescEffectDRecoil25, 0
MoveDexDescWoodHammer1:
	db   "Slams the foe with"
	next "a wooden body.@"

; #220 Poison Jab
MoveDexDescPoisonJabPages:
	dw MoveDexDescPoisonJab1, MoveDexDescEffectDPoison40, MoveDexDescEffectDPoisonImmune, 0
MoveDexDescPoisonJab1:
	db   "Stabs the foe with"
	next "a poisoned limb.@"

; #221 Gunk Shot
MoveDexDescGunkShotPages:
	dw MoveDexDescGunkShot1, MoveDexDescEffectDPoison40, MoveDexDescEffectDPoisonImmune, 0
MoveDexDescGunkShot1:
	db   "Hurls toxic sludge"
	next "right at the foe.@"

; #222 Poison Fang
MoveDexDescPoisonFangPages:
	; POISON_FANG_EFFECT 约 40%；Bite 动画 ID 特判会设置 BadlyPoisoned。
	dw MoveDexDescPoisonFang1, MoveDexDescEffectDBadPoison40, MoveDexDescEffectDPoisonImmune, 0
MoveDexDescPoisonFang1:
	db   "Bites the foe with"
	next "toxic fangs.@"

; #223 Sludge Wave
MoveDexDescSludgeWavePages:
	dw MoveDexDescSludgeWave1, MoveDexDescEffectDPoison20, MoveDexDescEffectDPoisonImmune, 0
MoveDexDescSludgeWave1:
	db   "Sweeps the foe in"
	next "a sludge wave.@"

; #224 Silver Wind
MoveDexDescSilverWindPages:
	dw MoveDexDescSilverWind1, MoveDexDescEffectDAllStatsUp10, MoveDexDescEffectDAllStatsList, 0
MoveDexDescSilverWind1:
	db   "Sends silver wind"
	next "toward the foe.@"

; #225 Bug Buzz
MoveDexDescBugBuzzPages:
	dw MoveDexDescBugBuzz1, MoveDexDescEffectDSpecialDown33, 0
MoveDexDescBugBuzz1:
	db   "Hits with a harsh"
	next "buzzing vibration.@"

; #226 Megahorn
MoveDexDescMegahornPages:
	dw MoveDexDescMegahorn1, 0
MoveDexDescMegahorn1:
	db   "Rams with a huge"
	next "powerful horn.@"

; #227 X-Scissor
MoveDexDescXScissorPages:
	dw MoveDexDescXScissor1, 0
MoveDexDescXScissor1:
	db   "Slashes the foe"
	next "with crossed cuts.@"

; #228 Signal Beam
MoveDexDescSignalBeamPages:
	dw MoveDexDescSignalBeam1, MoveDexDescEffectDConfuse10, MoveDexDescEffectDConfusionDuration, 0
MoveDexDescSignalBeam1:
	db   "Fires a weird beam"
	next "of flashing light.@"

; #229 Earth Power
MoveDexDescEarthPowerPages:
	dw MoveDexDescEarthPower1, MoveDexDescEffectDSpecialDown33, 0
MoveDexDescEarthPower1:
	db   "Makes ground erupt"
	next "beneath the foe.@"

; #230 Mud-Slap
MoveDexDescMudSlapPages:
	dw MoveDexDescMudSlap1, MoveDexDescEffectDAccuracyDown33, 0
MoveDexDescMudSlap1:
	db   "Throws a clump"
	next "of mud into the"
	next "foe's face.@"

; #231 Mud Bomb
MoveDexDescMudBombPages:
	dw MoveDexDescMudBomb1, MoveDexDescEffectDAccuracyDown33, 0
MoveDexDescMudBomb1:
	db   "Hurls a mud bomb"
	next "right at the foe.@"

; #232 Extrasensory
MoveDexDescExtrasensoryPages:
	dw MoveDexDescExtrasensory1, MoveDexDescEffectDFlinch10, 0
MoveDexDescExtrasensory1:
	db   "Attacks with odd"
	next "psychic force.@"

; #233 Zen Headbutt
MoveDexDescZenHeadbuttPages:
	dw MoveDexDescZenHeadbutt1, MoveDexDescEffectDFlinch30, 0
MoveDexDescZenHeadbutt1:
	db   "Focuses its will"
	next "then rams the foe.@"

; #234 Psycho Cut
MoveDexDescPsychoCutPages:
	dw MoveDexDescPsychoCut1, MoveDexDescEffectDHighCrit, 0
MoveDexDescPsychoCut1:
	db   "Cuts the foe with"
	next "a psychic blade.@"

; #235 Hyper Voice
MoveDexDescHyperVoicePages:
	dw MoveDexDescHyperVoice1, 0
MoveDexDescHyperVoice1:
	db   "Blasts the foe"
	next "with a loud voice.@"

; #236 ExtremeSpeed
MoveDexDescExtremeSpeedPages:
	dw MoveDexDescExtremeSpeed1, MoveDexDescEffectDPriority, 0
MoveDexDescExtremeSpeed1:
	db   "Charges at extreme"
	next "speed to strike.@"

; #237 Giga Impact
MoveDexDescGigaImpactPages:
	dw MoveDexDescGigaImpact1, MoveDexDescEffectDRecharge, 0
MoveDexDescGigaImpact1:
	db   "Slams the foe with"
	next "all its strength.@"

; #238 Power Gem
MoveDexDescPowerGemPages:
	dw MoveDexDescPowerGem1, 0
MoveDexDescPowerGem1:
	db   "Fires bright rays"
	next "of gem-like light.@"

; #239 Rock Blast
MoveDexDescRockBlastPages:
	dw MoveDexDescRockBlast1, MoveDexDescEffectDHits2To5, 0
MoveDexDescRockBlast1:
	db   "Hurls hard rocks"
	next "again and again.@"

; #240 Rock Polish
MoveDexDescRockPolishPages:
	dw MoveDexDescRockPolish1, MoveDexDescEffectDSpeedUp2, 0
MoveDexDescRockPolish1:
	db   "Polishes its body"
	next "until it gleams.@"

; #241 Rock Tomb
MoveDexDescRockTombPages:
	dw MoveDexDescRockTomb1, MoveDexDescEffectDSpeedDown33, 0
MoveDexDescRockTomb1:
	db   "Drops rocks around"
	next "the foe to pin it.@"

; #242 DynamicPunch
MoveDexDescDynamicPunchPages:
	dw MoveDexDescDynamicPunch1, MoveDexDescEffectDConfuseAlways, MoveDexDescEffectDConfusionDuration, 0
MoveDexDescDynamicPunch1:
	db   "Throws a spinning"
	next "powerful punch.@"

; #243 Storm Throw
MoveDexDescStormThrowPages:
	; CriticalHitTest 对 STORM_THROW 直接设置必定暴击。
	dw MoveDexDescStormThrow1, MoveDexDescEffectDAlwaysCrit, 0
MoveDexDescStormThrow1:
	db   "Hurls the foe with"
	next "a forceful strike.@"

; #244 Cross Chop
MoveDexDescCrossChopPages:
	dw MoveDexDescCrossChop1, MoveDexDescEffectDHighCrit, 0
MoveDexDescCrossChop1:
	db   "Uses crossed chops"
	next "to strike the foe.@"

; #245 Low Sweep
MoveDexDescLowSweepPages:
	dw MoveDexDescLowSweep1, MoveDexDescEffectDSpeedDown33, 0
MoveDexDescLowSweep1:
	db   "Sweeps low at the"
	next "foe's legs.@"

; #246 Hurricane
MoveDexDescHurricanePages:
	; 当前 CONFUSION_SIDE_EFFECT 为约 10%，不是现代版 30%。
	dw MoveDexDescHurricane1, MoveDexDescEffectDConfuse10, MoveDexDescEffectDConfusionDuration, 0
MoveDexDescHurricane1:
	db   "Engulfs the foe"
	next "in a hurricane.@"

; #247 Baby-Doll Eyes
MoveDexDescBabyDollEyesPages:
	; BABYDOLLEYES 在 RPP priority 列表中，同时使用 ATTACK_DOWN1_EFFECT。
	dw MoveDexDescBabyDollEyes1, MoveDexDescEffectDPriority, MoveDexDescEffectDAttackDown1, 0
MoveDexDescBabyDollEyes1:
	db   "Stares with round"
	next "charming eyes.@"

; #248 Bone Rush
MoveDexDescBoneRushPages:
	dw MoveDexDescBoneRush1, MoveDexDescEffectDHits2To5, 0
MoveDexDescBoneRush1:
	db   "Strikes repeatedly"
	next "with a hard bone.@"

; #249 Aeroblast
MoveDexDescAeroblastPages:
	dw MoveDexDescAeroblast1, MoveDexDescEffectDHighCrit, 0
MoveDexDescAeroblast1:
	db   "Fires sharp blast"
	next "of compressed air.@"

; #250 AncientPower
MoveDexDescAncientPowerPages:
	dw MoveDexDescAncientPower1, MoveDexDescEffectDAllStatsUp10, MoveDexDescEffectDAllStatsList, 0
MoveDexDescAncientPower1:
	db   "Unleashes ancient"
	next "power at the foe.@"

; #251 Dive (unused)
MoveDexDescDivePages:
	; 当前为普通 CHARGE_EFFECT；只有 Fly/Dig 会设置 Invulnerable，所以 Dive 蓄力期间并不无敌。
	dw MoveDexDescDive1, MoveDexDescEffectDChargeOnly, 0
MoveDexDescDive1:
	db   "Dives beneath the"
	next "surface to strike.@"

; #252 Luster Purge
MoveDexDescLusterPurgePages:
	dw MoveDexDescLusterPurge1, MoveDexDescEffectDSpecialDown33, 0
MoveDexDescLusterPurge1:
	db   "Unleashes bright"
	next "psychic light.@"

; #253 Mind Blast
MoveDexDescMindBlastPages:
	; CriticalHitTest 对 MIND_BLAST 必定暴击；SILVER_WIND_EFFECT 另有约 10% 的四项主能力提升。
	dw MoveDexDescMindBlast1, MoveDexDescEffectDAlwaysCrit, MoveDexDescEffectDAllStatsUp10, MoveDexDescEffectDAllStatsList, 0
MoveDexDescMindBlast1:
	db   "Hits the foe with"
	next "raw psychic force.@"

; ---------------------------------------------------------------------------
; Bank $38 共用机制页。
; ---------------------------------------------------------------------------

MoveDexDescEffectDHealHalfMax:
	db   "Restores 50", $d9, " of"
	next "the user's max HP."
	next "Fails at full HP.@"

MoveDexDescEffectDHex:
	db   "Power doubles if"
	next "the foe has a"
	next "status condition.@"

MoveDexDescEffectDSwift:
	db   "Cannot miss unless"
	next "foe is flying high"
	next "or underground.@"

MoveDexDescEffectDHighCrit:
	db   "About 25", $d9, " of hits"
	next "are critical hits.@"

MoveDexDescEffectDSpeedDown33:
	db   "33", $d9, " chance."
	next "Foe's Speed"
	next "drops 1 stage.@"

MoveDexDescEffectDPriority:
	db   "Moves before most"
	next "other attacks.@"

MoveDexDescEffectDOHKO:
	db   "One-hit KO."
	next "Fails against"
	next "a faster foe.@"

MoveDexDescEffectDNuzzle:
	db   "Paralyzes the foe"
	next "whenever it hits.@"

MoveDexDescEffectDGroundImmune:
	db   "Does not affect"
	next "Ground-type foes.@"

MoveDexDescEffectDParalyze10Electric:
	db   "10", $d9, " chance to"
	next "paralyze the foe.@"

MoveDexDescEffectDParalyzeElectricImmune:
	; 这里只描述追加麻痹；并非说明 Electric 招式整体对 Electric 属性无效。
	db   "Cannot paralyze an"
	next "Electric-type foe.@"

MoveDexDescEffectDRecoil25:
	db   "User takes 25", $d9, " of"
	next "damage as recoil.@"

MoveDexDescEffectDAccuracyDown33:
	db   "33", $d9, " chance."
	next "Foe's Accuracy"
	next "drops 1 stage.@"

MoveDexDescEffectDTrapTurns:
	db   "Lasts 2-5 turns."
	next "2-3 turns: 37.5", $d9
	next "4-5 turns: 12.5", $d9, "@"

MoveDexDescEffectDTrapLock:
	db   "Foe cannot move"
	next "while trapped.@"

MoveDexDescEffectDDrainHalf:
	db   "Heals half of the"
	next "damage it deals.@"

MoveDexDescEffectDPoison40:
	db   "40", $d9, " chance to"
	next "poison the foe.@"

MoveDexDescEffectDPoison20:
	db   "20", $d9, " chance to"
	next "poison the foe.@"

MoveDexDescEffectDBadPoison40:
	db   "40", $d9, " chance to"
	next "badly poison"
	next "the foe.@"

MoveDexDescEffectDPoisonImmune:
	; 这里只描述中毒免疫，不表示伤害招式本身对这些属性完全无效。
	db   "Cannot poison"
	next "Poison/Steel foes.@"

MoveDexDescEffectDAllStatsUp10:
	; SilverWindEffect 只提升 Attack / Defense / Speed / Special，不含 Accuracy / Evasion。
	db   "10", $d9, " chance to"
	next "raise 4 stats by"
	next "1 stage.@"

MoveDexDescEffectDAllStatsList:
	db   "Attack, Defense,"
	next "Speed and Special.@"

MoveDexDescEffectDSpecialDown33:
	db   "33", $d9, " chance."
	next "Foe's Special stat"
	next "drops 1 stage.@"

MoveDexDescEffectDConfuse10:
	db   "10", $d9, " chance to"
	next "confuse the foe.@"

MoveDexDescEffectDConfusionDuration:
	db   "Duration is 2-5"
	next "turns, 25", $d9, " each.@"

MoveDexDescEffectDFlinch10:
	db   "10", $d9, " chance to make"
	next "the foe flinch.@"

MoveDexDescEffectDFlinch30:
	db   "30", $d9, " chance to make"
	next "the foe flinch.@"

MoveDexDescEffectDRecharge:
	db   "User must recharge"
	next "on the next turn.@"

MoveDexDescEffectDHits2To5:
	db   "Hits 2-5 times."
	next "2-3 hits: 37.5", $d9
	next "4-5 hits: 12.5", $d9, "@"

MoveDexDescEffectDSpeedUp2:
	db   "Raises Speed"
	next "by 2 stages.@"

MoveDexDescEffectDConfuseAlways:
	db   "Confuses the foe"
	next "whenever it hits.@"

MoveDexDescEffectDAlwaysCrit:
	db   "Every hit scores a"
	next "critical hit.@"

MoveDexDescEffectDAttackDown1:
	db   "Lowers Attack"
	next "by 1 stage.@"

MoveDexDescEffectDChargeOnly:
	; Dive 不会设置 Invulnerable；这里只描述实际两回合流程。
	db   "Charges on turn 1."
	next "Attacks on turn 2.@"

