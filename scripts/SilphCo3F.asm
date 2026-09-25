SilphCo3Script:
	; SCK-5.48.00: keep the per-frame flag check local; only bank-switch when
	; entering the map or after a Card Key door was opened.
	ld hl, wCurrentMapScriptFlags
	bit 5, [hl]
	jr z, .skipCardKeyDoorUpdate
	res 5, [hl]
	callba HandleSilphCoCardKeyDoors
.skipCardKeyDoorUpdate
	; TMD-5.47.00: use the bank-local shared trainer dispatcher/table.
	ld hl, SilphCo3TrainerHeader0
	ld bc, wSilphCo3CurScript
	jp Bank16RunStandardTrainerMapScript

SilphCo3TextPointers:
	dw SilphCo3Text1
	dw SilphCo3Text2
	dw SilphCo3Text3
	dw PickUpItemText

SilphCo3TrainerHeader0:
	dbEventFlagBit EVENT_BEAT_SILPH_CO_3F_TRAINER_0
	db ($2 << 4) ; trainer's view range
	dwEventFlagAddress EVENT_BEAT_SILPH_CO_3F_TRAINER_0
	dw SilphCo3BattleText1 ; TextBeforeBattle
	dw SilphCo3AfterBattleText1 ; TextAfterBattle
	dw SilphCo3EndBattleText1 ; TextEndBattle

SilphCo3TrainerHeader1:
	dbEventFlagBit EVENT_BEAT_SILPH_CO_3F_TRAINER_1
	db ($3 << 4) ; trainer's view range
	dwEventFlagAddress EVENT_BEAT_SILPH_CO_3F_TRAINER_1
	dw SilphCo3BattleText2 ; TextBeforeBattle
	dw SilphCo3AfterBattleText2 ; TextAfterBattle
	dw SilphCo3EndBattleText2 ; TextEndBattle

	db $ff

SilphCo3Text1:
	TX_ASM
	CheckEvent EVENT_BEAT_SILPH_CO_GIOVANNI
	ld hl, SilphCo3Text_59ffe
	jr nz, .asm_59fee
	ld hl, SilphCo3Text_59ff9
.asm_59fee
	call PrintText
	jp TextScriptEnd

SilphCo3Text_59ff9:
	TX_FAR _SilphCo3Text_59ff9
	db "@"

SilphCo3Text_59ffe:
	TX_FAR _SilphCo3Text_59ffe
	db "@"

SilphCo3Text2:
	TX_TRAINER SilphCo3TrainerHeader0

SilphCo3BattleText1:
	TX_FAR _SilphCo3BattleText1
	db "@"

SilphCo3EndBattleText1:
	TX_FAR _SilphCo3EndBattleText1
	db "@"

SilphCo3AfterBattleText1:
	TX_FAR _SilphCo3AfterBattleText1
	db "@"

SilphCo3Text3:
	TX_TRAINER SilphCo3TrainerHeader1

SilphCo3BattleText2:
	TX_FAR _SilphCo3BattleText2
	db "@"

SilphCo3EndBattleText2:
	TX_FAR _SilphCo3EndBattleText2
	db "@"

SilphCo3AfterBattleText2:
	TX_FAR _SilphCo3AfterBattleText2
	db "@"
