SilphCo10Script:
	; SCK-5.48.00: keep the per-frame flag check local; only bank-switch when
	; entering the map or after a Card Key door was opened.
	ld hl, wCurrentMapScriptFlags
	bit 5, [hl]
	jr z, .skipCardKeyDoorUpdate
	res 5, [hl]
	callba HandleSilphCoCardKeyDoors
.skipCardKeyDoorUpdate
	; TMD-5.47.00: use the bank-local shared trainer dispatcher/table.
	ld hl, SilphCo10TrainerHeader0
	ld bc, wSilphCo10CurScript
	jp Bank16RunStandardTrainerMapScript

SilphCo10TextPointers:
	dw SilphCo10Text1
	dw SilphCo10Text2
	dw SilphCo10Text3
	dw PickUpItemText
	dw PickUpItemText
	dw PickUpItemText

SilphCo10TrainerHeader0:
	dbEventFlagBit EVENT_BEAT_SILPH_CO_10F_TRAINER_0
	db ($3 << 4) ; trainer's view range
	dwEventFlagAddress EVENT_BEAT_SILPH_CO_10F_TRAINER_0
	dw SilphCo10BattleText1 ; TextBeforeBattle
	dw SilphCo10AfterBattleText1 ; TextAfterBattle
	dw SilphCo10EndBattleText1 ; TextEndBattle

SilphCo10TrainerHeader1:
	dbEventFlagBit EVENT_BEAT_SILPH_CO_10F_TRAINER_1
	db ($4 << 4) ; trainer's view range
	dwEventFlagAddress EVENT_BEAT_SILPH_CO_10F_TRAINER_1
	dw SilphCo10BattleText2 ; TextBeforeBattle
	dw SilphCo10AfterBattleText2 ; TextAfterBattle
	dw SilphCo10EndBattleText2 ; TextEndBattle

	db $ff

SilphCo10Text1:
	TX_TRAINER SilphCo10TrainerHeader0

SilphCo10Text2:
	TX_TRAINER SilphCo10TrainerHeader1

SilphCo10Text3:
	TX_ASM
	CheckEvent EVENT_BEAT_SILPH_CO_GIOVANNI
	ld hl, SilphCo10Text_5a1d8
	jr nz, .asm_cf85f
	ld hl, SilphCo10Text_5a1d3
.asm_cf85f
	jp PrintTextAndTextScriptEnd

SilphCo10Text_5a1d3:
	TX_FAR _SilphCo10Text_5a1d3
	db "@"

SilphCo10Text_5a1d8:
	TX_FAR _SilphCo10Text_5a1d8
	db "@"

SilphCo10BattleText1:
	TX_FAR _SilphCo10BattleText1
	db "@"

SilphCo10EndBattleText1:
	TX_FAR _SilphCo10EndBattleText1
	db "@"

SilphCo10AfterBattleText1:
	TX_FAR _SilphCo10AfterBattleText1
	db "@"

SilphCo10BattleText2:
	TX_FAR _SilphCo10BattleText2
	db "@"

SilphCo10EndBattleText2:
	TX_FAR _SilphCo10EndBattleText2
	db "@"

SilphCo10AfterBattleText2:
	TX_FAR _SilphCo10AfterBattleText2
	db "@"
