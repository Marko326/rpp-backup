; sed 's/(\(.*\) - SFX_Headers_[0-9a-z]*) \/ 3/RB\1/g'

;02: entire      sfx_02_5f.asm
;08: from $40    sfx_08_77.asm
;1f: from $5d    sfx_1f_67.asm

; see music_constants.asm

SFX:
RedSfxHeaderPointers:
	dbw 0, 0
	dbw BANK(SFX_Get_Item1_1), SFX_Get_Item1_1

	dbw BANK(SFX_Get_Item2_1), SFX_Get_Item2_1
	dbw BANK(SFX_Tink_1), SFX_Tink_1
	dbw BANK(SFX_Heal_HP_1), SFX_Heal_HP_1
	dbw BANK(SFX_Heal_Ailment_1), SFX_Heal_Ailment_1
	dbw BANK(SFX_Start_Menu_1), SFX_Start_Menu_1
	dbw BANK(SFX_Press_AB_1), SFX_Press_AB_1

	dbw BANK(SFX_Pokedex_Rating_1), SFX_Pokedex_Rating_1
	dbw BANK(SFX_Get_Key_Item_1), SFX_Get_Key_Item_1
	dbw BANK(SFX_Poisoned_1), SFX_Poisoned_1
	dbw BANK(SFX_Trade_Machine_1), SFX_Trade_Machine_1
	dbw BANK(SFX_Turn_On_PC_1), SFX_Turn_On_PC_1
	dbw BANK(SFX_Turn_Off_PC_1), SFX_Turn_Off_PC_1
	dbw BANK(SFX_Enter_PC_1), SFX_Enter_PC_1
	dbw BANK(SFX_Shrink_1), SFX_Shrink_1
	dbw BANK(SFX_Switch_1), SFX_Switch_1
	dbw BANK(SFX_Healing_Machine_1), SFX_Healing_Machine_1
	dbw BANK(SFX_Teleport_Exit1_1), SFX_Teleport_Exit1_1
	dbw BANK(SFX_Teleport_Enter1_1), SFX_Teleport_Enter1_1
	dbw BANK(SFX_Teleport_Exit2_1), SFX_Teleport_Exit2_1
	dbw BANK(SFX_Ledge_1), SFX_Ledge_1
	dbw BANK(SFX_Teleport_Enter2_1), SFX_Teleport_Enter2_1
	dbw BANK(SFX_Fly_1), SFX_Fly_1
	dbw BANK(SFX_Denied_1), SFX_Denied_1
	dbw BANK(SFX_Arrow_Tiles_1), SFX_Arrow_Tiles_1
	dbw BANK(SFX_Push_Boulder_1), SFX_Push_Boulder_1
	dbw BANK(SFX_SS_Anne_Horn_1), SFX_SS_Anne_Horn_1
	dbw BANK(SFX_Withdraw_Deposit_1), SFX_Withdraw_Deposit_1
	dbw BANK(SFX_Cut_1), SFX_Cut_1
	dbw BANK(SFX_Go_Inside_1), SFX_Go_Inside_1
	dbw BANK(SFX_Swap_1), SFX_Swap_1
	dbw BANK(SFX_59_1), SFX_59_1
	dbw BANK(SFX_Purchase_1), SFX_Purchase_1
	dbw BANK(SFX_Collision_1), SFX_Collision_1
	dbw BANK(SFX_Go_Outside_1), SFX_Go_Outside_1
	dbw BANK(SFX_Save_1), SFX_Save_1

	dbw BANK(SFX_Pokeflute), SFX_Pokeflute
	dbw BANK(SFX_Safari_Zone_PA), SFX_Safari_Zone_PA

	dbw BANK(SFX_Level_Up), SFX_Level_Up

	dbw BANK(SFX_Ball_Toss), SFX_Ball_Toss
	dbw BANK(SFX_Ball_Poof), SFX_Ball_Poof
	dbw BANK(SFX_Faint_Thud), SFX_Faint_Thud
	dbw BANK(SFX_Run), SFX_Run
	dbw BANK(SFX_Dex_Page_Added), SFX_Dex_Page_Added
	dbw BANK(SFX_Caught_Mon), SFX_Caught_Mon
	dbw BANK(SFX_Peck), SFX_Peck
	dbw BANK(SFX_Faint_Fall), SFX_Faint_Fall
	dbw BANK(SFX_Battle_09), SFX_Battle_09
	dbw BANK(SFX_Pound), SFX_Pound
	dbw BANK(SFX_Battle_0B), SFX_Battle_0B
	dbw BANK(SFX_Battle_0C), SFX_Battle_0C
	dbw BANK(SFX_Battle_0D), SFX_Battle_0D
	dbw BANK(SFX_Battle_0E), SFX_Battle_0E
	dbw BANK(SFX_Battle_0F), SFX_Battle_0F
	dbw BANK(SFX_Damage), SFX_Damage
	dbw BANK(SFX_Not_Very_Effective), SFX_Not_Very_Effective
	dbw BANK(SFX_Battle_12), SFX_Battle_12
	dbw BANK(SFX_Battle_13), SFX_Battle_13
	dbw BANK(SFX_Battle_14), SFX_Battle_14
	dbw BANK(SFX_Vine_Whip), SFX_Vine_Whip
	dbw BANK(SFX_Battle_16), SFX_Battle_16
	dbw BANK(SFX_Battle_17), SFX_Battle_17
	dbw BANK(SFX_Battle_18), SFX_Battle_18
	dbw BANK(SFX_Battle_19), SFX_Battle_19
	dbw BANK(SFX_Super_Effective), SFX_Super_Effective
	dbw BANK(SFX_Battle_1B), SFX_Battle_1B
	dbw BANK(SFX_Battle_1C), SFX_Battle_1C
	dbw BANK(SFX_Doubleslap), SFX_Doubleslap
	dbw BANK(SFX_Battle_1E), SFX_Battle_1E
	dbw BANK(SFX_Horn_Drill), SFX_Horn_Drill
	dbw BANK(SFX_Battle_20), SFX_Battle_20
	dbw BANK(SFX_Battle_21), SFX_Battle_21
	dbw BANK(SFX_Battle_22), SFX_Battle_22
	dbw BANK(SFX_Battle_23), SFX_Battle_23
	dbw BANK(SFX_Battle_24), SFX_Battle_24
	dbw BANK(SFX_Battle_25), SFX_Battle_25
	dbw BANK(SFX_Battle_26), SFX_Battle_26
	dbw BANK(SFX_Battle_27), SFX_Battle_27
	dbw BANK(SFX_Battle_28), SFX_Battle_28
	dbw BANK(SFX_Battle_29), SFX_Battle_29
	dbw BANK(SFX_Battle_2A), SFX_Battle_2A
	dbw BANK(SFX_Battle_2B), SFX_Battle_2B
	dbw BANK(SFX_Battle_2C), SFX_Battle_2C
	dbw BANK(SFX_Psybeam), SFX_Psybeam
	dbw BANK(SFX_Battle_2E), SFX_Battle_2E
	dbw BANK(SFX_Battle_2F), SFX_Battle_2F
	dbw BANK(SFX_Psychic_M), SFX_Psychic_M
	dbw BANK(SFX_Battle_31), SFX_Battle_31
	dbw BANK(SFX_Battle_32), SFX_Battle_32
	dbw BANK(SFX_Battle_33), SFX_Battle_33
	dbw BANK(SFX_Battle_34), SFX_Battle_34
	dbw BANK(SFX_Battle_35), SFX_Battle_35
	dbw BANK(SFX_Battle_36), SFX_Battle_36
	dbw BANK(SFX_Silph_Scope), SFX_Silph_Scope

	dbw BANK(SFX_Intro_Lunge), SFX_Intro_Lunge
	dbw BANK(SFX_Intro_Hip), SFX_Intro_Hip
	dbw BANK(SFX_Intro_Hop), SFX_Intro_Hop
	dbw BANK(SFX_Intro_Raise), SFX_Intro_Raise
	dbw BANK(SFX_Intro_Crash), SFX_Intro_Crash
	dbw BANK(SFX_Intro_Whoosh), SFX_Intro_Whoosh
	dbw BANK(SFX_Slots_Stop_Wheel), SFX_Slots_Stop_Wheel
	dbw BANK(SFX_Slots_Reward), SFX_Slots_Reward
	dbw BANK(SFX_Slots_New_Spin), SFX_Slots_New_Spin
	dbw BANK(SFX_Shooting_Star), SFX_Shooting_Star

	; Egg Bomb lower-pitch Ball Toss option: private audio data lives in a
	; floating ROMX section, leaving the stock capture Ball Toss untouched.
	dbw BANK(EggBombBallTossLow), EggBombBallTossLow
	dbw BANK(Sfx_Damage), Sfx_Damage
	dbw BANK(Sfx_SuperEffective), Sfx_SuperEffective

	; ANM-5.61.45: Gold Sludge Bomb launch plus the exact Toxic bubble SFX.
	; Sfx_Unknown7F is byte-for-byte Gold's Sfx_Toxic, so reuse it instead of
	; duplicating audio data. Shadow Ball continues sharing Sfx_SludgeBomb.
	dbw BANK(Sfx_SludgeBomb), Sfx_SludgeBomb
	dbw BANK(Sfx_Unknown7F), Sfx_Unknown7F

	; ANM-5.61.46: exact Gold Aeroblast SFX; audio data already exists in sfx.asm.
	dbw BANK(Sfx_Aeroblast), Sfx_Aeroblast

	; ANM-5.61.48: exact Gold/Crystal DynamicPunch explosion SFX.
	dbw BANK(Sfx_EggBomb), Sfx_EggBomb

	; MOV-5.61.53: Sacred Fire reuses the exact Gold Ember SFX data already present.
	dbw BANK(Sfx_Ember), Sfx_Ember

	; ANM-5.61.59: Shadow Punch reuses Gold Quick Attack's exact SFX_MENU data.
	dbw BANK(Sfx_Menu), Sfx_Menu

	; ANM-5.61.67: Cross Chop reuses the exact Gold Cut/Vicegrip data already present.
	dbw BANK(Sfx_Cut), Sfx_Cut
	dbw BANK(Sfx_Vicegrip), Sfx_Vicegrip

	; ANM-5.61.69: Crunch reuses the exact Gold/Crystal Bite SFX already present.
	dbw BANK(Sfx_Bite), Sfx_Bite

	; ANM-5.61.72: Gold Spark reuses the exact audio data already present in crysaudio/sfx.asm.
	dbw BANK(Sfx_ZapCannon), Sfx_ZapCannon
	dbw BANK(Sfx_Spark), Sfx_Spark
	dbw BANK(Sfx_Thundershock), Sfx_Thundershock

	; ANM-5.61.81: Icy Wind reuses Gold/Crystal Psychic SFX data.
	dbw BANK(Sfx_Psychic), Sfx_Psychic

	; ANM-5.62.05: Energy Ball reuses the existing Polished Crystal / Gen II SFX data.
	dbw BANK(Sfx_WarpTo), Sfx_WarpTo
	dbw BANK(Sfx_Present), Sfx_Present
	dbw BANK(Sfx_SweetScent), Sfx_SweetScent

	; ANM-5.62.07: Iron Tail reuses the exact Gold/Crystal Mega Kick impact data.
	dbw BANK(Sfx_MegaKick), Sfx_MegaKick

	; ANM-5.62.07: exact Gold Iron Tail opening / Metallic audio.
	dbw BANK(Sfx_Rage), Sfx_Rage
	dbw BANK(Sfx_Shine), Sfx_Shine
