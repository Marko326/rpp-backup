SilphCo2Script:
	; SCK-5.48.00: keep the per-frame flag check local; only bank-switch when
	; entering the map or after a Card Key door was opened.
	ld hl, wCurrentMapScriptFlags
	bit 5, [hl]
	jr z, .skipCardKeyDoorUpdate
	res 5, [hl]
	callba HandleSilphCoCardKeyDoors
.skipCardKeyDoorUpdate
	; TMD-5.47.00: use the bank-local shared trainer dispatcher/table.
	ld hl, SilphCo2TrainerHeader0
	ld bc, wSilphCo2CurScript
	jp Bank16RunStandardTrainerMapScript

SilphCo2TextPointers:
	dw SilphCo2Text1
	dw SilphCo2Text2
	dw SilphCo2Text3
	dw SilphCo2Text4
	dw SilphCo2Text5

SilphCo2TrainerHeader0:
	dbEventFlagBit EVENT_BEAT_SILPH_CO_2F_TRAINER_0
	db ($3 << 4) ; trainer's view range
	dwEventFlagAddress EVENT_BEAT_SILPH_CO_2F_TRAINER_0
	dw SilphCo2BattleText1 ; TextBeforeBattle
	dw SilphCo2AfterBattleText1 ; TextAfterBattle
	dw SilphCo2EndBattleText1 ; TextEndBattle

SilphCo2TrainerHeader1:
	dbEventFlagBit EVENT_BEAT_SILPH_CO_2F_TRAINER_1
	db ($4 << 4) ; trainer's view range
	dwEventFlagAddress EVENT_BEAT_SILPH_CO_2F_TRAINER_1
	dw SilphCo2BattleText2 ; TextBeforeBattle
	dw SilphCo2AfterBattleText2 ; TextAfterBattle
	dw SilphCo2EndBattleText2 ; TextEndBattle

SilphCo2TrainerHeader2:
	dbEventFlagBit EVENT_BEAT_SILPH_CO_2F_TRAINER_2
	db ($3 << 4) ; trainer's view range
	dwEventFlagAddress EVENT_BEAT_SILPH_CO_2F_TRAINER_2
	dw SilphCo2BattleText3 ; TextBeforeBattle
	dw SilphCo2AfterBattleText3 ; TextAfterBattle
	dw SilphCo2EndBattleText3 ; TextEndBattle

SilphCo2TrainerHeader3:
	dbEventFlagBit EVENT_BEAT_SILPH_CO_2F_TRAINER_3
	db ($3 << 4) ; trainer's view range
	dwEventFlagAddress EVENT_BEAT_SILPH_CO_2F_TRAINER_3
	dw SilphCo2BattleText4 ; TextBeforeBattle
	dw SilphCo2AfterBattleText4 ; TextAfterBattle
	dw SilphCo2EndBattleText4 ; TextEndBattle

	db $ff

SilphCo2Text1:
	TX_ASM
	CheckEvent EVENT_GOT_TM36
	jr nz, .asm_59de4
	ld hl, SilphCo2Text_59ded
	call PrintText
	lb bc, TM_01, 1
	call GiveItem
	ld hl, TM36NoRoomText
	jr nc, .asm_59de7
	SetEvent EVENT_GOT_TM36
	ld hl, ReceivedTM36Text
	jr .asm_59de7
.asm_59de4
	ld hl, TM36ExplanationText
.asm_59de7
	call PrintText
	jp TextScriptEnd

SilphCo2Text_59ded:
	TX_FAR _SilphCo2Text_59ded
	db "@"

ReceivedTM36Text:
	TX_FAR _ReceivedTM36Text
	TX_SFX_ITEM_1
	db "@"

TM36ExplanationText:
	TX_FAR _TM36ExplanationText
	db "@"

TM36NoRoomText:
	TX_FAR _TM36NoRoomText
	db "@"

SilphCo2Text2:
	TX_TRAINER SilphCo2TrainerHeader0

SilphCo2Text3:
	TX_TRAINER SilphCo2TrainerHeader1

SilphCo2Text4:
	TX_TRAINER SilphCo2TrainerHeader2

SilphCo2Text5:
	TX_TRAINER SilphCo2TrainerHeader3

SilphCo2BattleText1:
	TX_FAR _SilphCo2BattleText1
	db "@"

SilphCo2EndBattleText1:
	TX_FAR _SilphCo2EndBattleText1
	db "@"

SilphCo2AfterBattleText1:
	TX_FAR _SilphCo2AfterBattleText1
	db "@"

SilphCo2BattleText2:
	TX_FAR _SilphCo2BattleText2
	db "@"

SilphCo2EndBattleText2:
	TX_FAR _SilphCo2EndBattleText2
	db "@"

SilphCo2AfterBattleText2:
	TX_FAR _SilphCo2AfterBattleText2
	db "@"

SilphCo2BattleText3:
	TX_FAR _SilphCo2BattleText3
	db "@"

SilphCo2EndBattleText3:
	TX_FAR _SilphCo2EndBattleText3
	db "@"

SilphCo2AfterBattleText3:
	TX_FAR _SilphCo2AfterBattleText3
	db "@"

SilphCo2BattleText4:
	TX_FAR _SilphCo2BattleText4
	db "@"

SilphCo2EndBattleText4:
	TX_FAR _SilphCo2EndBattleText4
	db "@"

SilphCo2AfterBattleText4:
	TX_FAR _SilphCo2AfterBattleText4
	db "@"
