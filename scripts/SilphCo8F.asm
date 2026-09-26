SilphCo8Script:
	; SCK-5.48.00: keep the per-frame flag check local; only bank-switch when
	; entering the map or after a Card Key door was opened.
	ld hl, wCurrentMapScriptFlags
	bit 5, [hl]
	jr z, .skipCardKeyDoorUpdate
	res 5, [hl]
	callba HandleSilphCoCardKeyDoors
.skipCardKeyDoorUpdate
	; TMD-5.47.00: use the bank-local shared trainer dispatcher/table.
	ld hl, SilphCo8TrainerHeader0
	ld bc, wSilphCo8CurScript
	jp Bank15RunStandardTrainerMapScript

SilphCo8TextPointers:
	dw SilphCo8Text1
	dw SilphCo8Text2
	dw SilphCo8Text3
	dw SilphCo8Text4

SilphCo8TrainerHeader0:
	dbEventFlagBit EVENT_BEAT_SILPH_CO_8F_TRAINER_0
	db ($4 << 4) ; trainer's view range
	dwEventFlagAddress EVENT_BEAT_SILPH_CO_8F_TRAINER_0
	dw SilphCo8BattleText1 ; TextBeforeBattle
	dw SilphCo8AfterBattleText1 ; TextAfterBattle
	dw SilphCo8EndBattleText1 ; TextEndBattle

SilphCo8TrainerHeader1:
	dbEventFlagBit EVENT_BEAT_SILPH_CO_8F_TRAINER_1
	db ($4 << 4) ; trainer's view range
	dwEventFlagAddress EVENT_BEAT_SILPH_CO_8F_TRAINER_1
	dw SilphCo8BattleText2 ; TextBeforeBattle
	dw SilphCo8AfterBattleText2 ; TextAfterBattle
	dw SilphCo8EndBattleText2 ; TextEndBattle

SilphCo8TrainerHeader2:
	dbEventFlagBit EVENT_BEAT_SILPH_CO_8F_TRAINER_2
	db ($4 << 4) ; trainer's view range
	dwEventFlagAddress EVENT_BEAT_SILPH_CO_8F_TRAINER_2
	dw SilphCo8BattleText3 ; TextBeforeBattle
	dw SilphCo8AfterBattleText3 ; TextAfterBattle
	dw SilphCo8EndBattleText3 ; TextEndBattle

	db $ff

SilphCo8Text1:
	TX_ASM
	CheckEvent EVENT_BEAT_SILPH_CO_GIOVANNI
	ld hl, SilphCo8Text_565c3
	jr nz, .asm_565b8
	ld hl, SilphCo8Text_565be
.asm_565b8
	jp PrintTextAndTextScriptEnd

SilphCo8Text_565be:
	TX_FAR _SilphCo8Text_565be
	db "@"

SilphCo8Text_565c3:
	TX_FAR _SilphCo8Text_565c3
	db "@"

SilphCo8Text2:
	TX_TRAINER SilphCo8TrainerHeader0

SilphCo8Text3:
	TX_TRAINER SilphCo8TrainerHeader1

SilphCo8Text4:
	TX_TRAINER SilphCo8TrainerHeader2

SilphCo8BattleText1:
	TX_FAR _SilphCo8BattleText1
	db "@"

SilphCo8EndBattleText1:
	TX_FAR _SilphCo8EndBattleText1
	db "@"

SilphCo8AfterBattleText1:
	TX_FAR _SilphCo8AfterBattleText1
	db "@"

SilphCo8BattleText2:
	TX_FAR _SilphCo8BattleText2
	db "@"

SilphCo8EndBattleText2:
	TX_FAR _SilphCo8EndBattleText2
	db "@"

SilphCo8AfterBattleText2:
	TX_FAR _SilphCo8AfterBattleText2
	db "@"

SilphCo8BattleText3:
	TX_FAR _SilphCo8BattleText3
	db "@"

SilphCo8EndBattleText3:
	TX_FAR _SilphCo8EndBattleText3
	db "@"

SilphCo8AfterBattleText3:
	TX_FAR _SilphCo8AfterBattleText3
	db "@"
