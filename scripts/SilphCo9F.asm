SilphCo9Script:
	; SCK-5.48.00: keep the per-frame flag check local; only bank-switch when
	; entering the map or after a Card Key door was opened.
	ld hl, wCurrentMapScriptFlags
	bit 5, [hl]
	jr z, .skipCardKeyDoorUpdate
	res 5, [hl]
	callba HandleSilphCoCardKeyDoors
.skipCardKeyDoorUpdate
	; TMD-5.47.00: use the bank-local trainer map dispatcher.
	ld hl, SilphCo9TrainerHeader0
	ld de, SilphCo9ScriptPointers
	ld bc, wSilphCo9CurScript
	jp Bank17RunTrainerMapScript

SilphCo9ScriptPointers:
	dw CheckFightingMapTrainers
	dw DisplayEnemyTrainerTextAndStartBattle
	dw EndTrainerBattle

SilphCo9TextPointers:
	dw SilphCo9Text1
	dw SilphCo9Text2
	dw SilphCo9Text3
	dw SilphCo9Text4

SilphCo9TrainerHeader0:
	dbEventFlagBit EVENT_BEAT_SILPH_CO_9F_TRAINER_0
	db ($4 << 4) ; trainer's view range
	dwEventFlagAddress EVENT_BEAT_SILPH_CO_9F_TRAINER_0
	dw SilphCo9BattleText1 ; TextBeforeBattle
	dw SilphCo9AfterBattleText1 ; TextAfterBattle
	dw SilphCo9EndBattleText1 ; TextEndBattle

SilphCo9TrainerHeader1:
	dbEventFlagBit EVENT_BEAT_SILPH_CO_9F_TRAINER_1
	db ($2 << 4) ; trainer's view range
	dwEventFlagAddress EVENT_BEAT_SILPH_CO_9F_TRAINER_1
	dw SilphCo9BattleText2 ; TextBeforeBattle
	dw SilphCo9AfterBattleText2 ; TextAfterBattle
	dw SilphCo9EndBattleText2 ; TextEndBattle

SilphCo9TrainerHeader2:
	dbEventFlagBit EVENT_BEAT_SILPH_CO_9F_TRAINER_2
	db ($4 << 4) ; trainer's view range
	dwEventFlagAddress EVENT_BEAT_SILPH_CO_9F_TRAINER_2
	dw SilphCo9BattleText3 ; TextBeforeBattle
	dw SilphCo9AfterBattleText3 ; TextAfterBattle
	dw SilphCo9EndBattleText3 ; TextEndBattle

	db $ff

SilphCo9Text1:
	TX_ASM
	CheckEvent EVENT_BEAT_SILPH_CO_GIOVANNI
	jr nz, .asm_5d8dc
	ld hl, SilphCo9Text_5d8e5
	call PrintText
	predef HealParty
	call GBFadeOutToWhite
	call Delay3
	call GBFadeInFromWhite
	ld hl, SilphCo9Text_5d8ea
	call PrintText
	jr .asm_5d8e2
.asm_5d8dc
	ld hl, SilphCo9Text_5d8ef
	call PrintText
.asm_5d8e2
	jp TextScriptEnd

SilphCo9Text_5d8e5:
	TX_FAR _SilphCo9Text_5d8e5
	db "@"

SilphCo9Text_5d8ea:
	TX_FAR _SilphCo9Text_5d8ea
	db "@"

SilphCo9Text_5d8ef:
	TX_FAR _SilphCo9Text_5d8ef
	db "@"

SilphCo9Text2:
	TX_TRAINER SilphCo9TrainerHeader0

SilphCo9Text3:
	TX_TRAINER SilphCo9TrainerHeader1

SilphCo9Text4:
	TX_TRAINER SilphCo9TrainerHeader2

SilphCo9BattleText1:
	TX_FAR _SilphCo9BattleText1
	db "@"

SilphCo9EndBattleText1:
	TX_FAR _SilphCo9EndBattleText1
	db "@"

SilphCo9AfterBattleText1:
	TX_FAR _SilphCo9AfterBattleText1
	db "@"

SilphCo9BattleText2:
	TX_FAR _SilphCo9BattleText2
	db "@"

SilphCo9EndBattleText2:
	TX_FAR _SilphCo9EndBattleText2
	db "@"

SilphCo9AfterBattleText2:
	TX_FAR _SilphCo9AfterBattleText2
	db "@"

SilphCo9BattleText3:
	TX_FAR _SilphCo9BattleText3
	db "@"

SilphCo9EndBattleText3:
	TX_FAR _SilphCo9EndBattleText3
	db "@"

SilphCo9AfterBattleText3:
	TX_FAR _SilphCo9AfterBattleText3
	db "@"
