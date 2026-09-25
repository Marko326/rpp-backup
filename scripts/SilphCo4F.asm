; TMD-5.47.00: standard three-state trainer maps in bank 06
; share one script table and the generic bank-local dispatcher.
Bank06RunStandardTrainerMapScript:
	ld de, Bank06StandardTrainerScriptPointers
	; fall through
; TMD-5.47.00: bank-local trainer map dispatcher.
; HL = first TrainerHeader, DE = script table, BC = map script state.
Bank06RunTrainerMapScript:
	call EnableAutoTextBoxDrawing
	ld a, [bc]
	push bc
	call ExecuteCurMapScriptInTable
	pop bc
	ld [bc], a
	ret

Bank06StandardTrainerScriptPointers:
	dw CheckFightingMapTrainers
	dw DisplayEnemyTrainerTextAndStartBattle
	dw EndTrainerBattle

SilphCo4Script:
	; SCK-5.48.00: keep the per-frame flag check local; only bank-switch when
	; entering the map or after a Card Key door was opened.
	ld hl, wCurrentMapScriptFlags
	bit 5, [hl]
	jr z, .skipCardKeyDoorUpdate
	res 5, [hl]
	callba HandleSilphCoCardKeyDoors
.skipCardKeyDoorUpdate
	; TMD-5.47.00: use the bank-local shared trainer dispatcher/table.
	ld hl, SilphCo4TrainerHeader0
	ld bc, wSilphCo4CurScript
	jp Bank06RunStandardTrainerMapScript

SilphCo4TextPointers:
	dw SilphCo4Text1
	dw SilphCo4Text2
	dw SilphCo4Text3
	dw SilphCo4Text4
	dw PickUpItemText
	dw PickUpItemText
	dw PickUpItemText

SilphCo4TrainerHeader0:
	dbEventFlagBit EVENT_BEAT_SILPH_CO_4F_TRAINER_0
	db ($4 << 4) ; trainer's view range
	dwEventFlagAddress EVENT_BEAT_SILPH_CO_4F_TRAINER_0
	dw SilphCo4BattleText2 ; TextBeforeBattle
	dw SilphCo4AfterBattleText2 ; TextAfterBattle
	dw SilphCo4EndBattleText2 ; TextEndBattle

SilphCo4TrainerHeader1:
	dbEventFlagBit EVENT_BEAT_SILPH_CO_4F_TRAINER_1
	db ($3 << 4) ; trainer's view range
	dwEventFlagAddress EVENT_BEAT_SILPH_CO_4F_TRAINER_1
	dw SilphCo4BattleText3 ; TextBeforeBattle
	dw SilphCo4AfterBattleText3 ; TextAfterBattle
	dw SilphCo4EndBattleText3 ; TextEndBattle

SilphCo4TrainerHeader2:
	dbEventFlagBit EVENT_BEAT_SILPH_CO_4F_TRAINER_2
	db ($4 << 4) ; trainer's view range
	dwEventFlagAddress EVENT_BEAT_SILPH_CO_4F_TRAINER_2
	dw SilphCo4BattleText4 ; TextBeforeBattle
	dw SilphCo4AfterBattleText4 ; TextAfterBattle
	dw SilphCo4EndBattleText4 ; TextEndBattle

	db $ff

SilphCo4Text1:
	TX_ASM
	ld hl, SilphCo4Text_19de0
	ld de, SilphCo4Text_19de5
	call SilphCo6Script_1a22f
	jp TextScriptEnd

SilphCo4Text_19de0:
	TX_FAR _SilphCo4Text_19de0
	db "@"

SilphCo4Text_19de5:
	TX_FAR _SilphCo4Text_19de5
	db "@"

SilphCo4Text2:
	TX_TRAINER SilphCo4TrainerHeader0

SilphCo4BattleText2:
	TX_FAR _SilphCo4BattleText2
	db "@"

SilphCo4EndBattleText2:
	TX_FAR _SilphCo4EndBattleText2
	db "@"

SilphCo4AfterBattleText2:
	TX_FAR _SilphCo4AfterBattleText2
	db "@"

SilphCo4Text3:
	TX_TRAINER SilphCo4TrainerHeader1

SilphCo4BattleText3:
	TX_FAR _SilphCo4BattleText3
	db "@"

SilphCo4EndBattleText3:
	TX_FAR _SilphCo4EndBattleText3
	db "@"

SilphCo4AfterBattleText3:
	TX_FAR _SilphCo4AfterBattleText3
	db "@"

SilphCo4Text4:
	TX_TRAINER SilphCo4TrainerHeader2

SilphCo4BattleText4:
	TX_FAR _SilphCo4BattleText4
	db "@"

SilphCo4EndBattleText4:
	TX_FAR _SilphCo4EndBattleText4
	db "@"

SilphCo4AfterBattleText4:
	TX_FAR _SilphCo4AfterBattleText4
	db "@"
