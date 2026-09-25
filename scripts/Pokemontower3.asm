; TMD-5.47.00: standard three-state trainer maps in bank 18
; share one script table and the generic bank-local dispatcher.
Bank18RunStandardTrainerMapScript:
	ld de, Bank18StandardTrainerScriptPointers
	; fall through
; TMD-5.47.00: bank-local trainer map dispatcher.
; HL = first TrainerHeader, DE = script table, BC = map script state.
Bank18RunTrainerMapScript:
	call EnableAutoTextBoxDrawing
	ld a, [bc]
	push bc
	call ExecuteCurMapScriptInTable
	pop bc
	ld [bc], a
	ret

Bank18StandardTrainerScriptPointers:
	dw CheckFightingMapTrainers
	dw DisplayEnemyTrainerTextAndStartBattle
	dw EndTrainerBattle

PokemonTower3Script:
	; TMD-5.47.00: use the bank-local shared trainer dispatcher/table.
	ld hl, PokemonTower3TrainerHeader0
	ld bc, wPokemonTower3CurScript
	jp Bank18RunStandardTrainerMapScript

PokemonTower3TextPointers:
	dw PokemonTower3Text1
	dw PokemonTower3Text2
	dw PokemonTower3Text3
	dw PickUpItemText

PokemonTower3TrainerHeader0:
	dbEventFlagBit EVENT_BEAT_POKEMONTOWER_3_TRAINER_0
	db ($2 << 4) ; trainer's view range
	dwEventFlagAddress EVENT_BEAT_POKEMONTOWER_3_TRAINER_0
	dw PokemonTower3BattleText1 ; TextBeforeBattle
	dw PokemonTower3AfterBattleText1 ; TextAfterBattle
	dw PokemonTower3EndBattleText1 ; TextEndBattle

PokemonTower3TrainerHeader1:
	dbEventFlagBit EVENT_BEAT_POKEMONTOWER_3_TRAINER_1
	db ($3 << 4) ; trainer's view range
	dwEventFlagAddress EVENT_BEAT_POKEMONTOWER_3_TRAINER_1
	dw PokemonTower3BattleText2 ; TextBeforeBattle
	dw PokemonTower3AfterBattleText2 ; TextAfterBattle
	dw PokemonTower3EndBattleText2 ; TextEndBattle

PokemonTower3TrainerHeader2:
	dbEventFlagBit EVENT_BEAT_POKEMONTOWER_3_TRAINER_2
	db ($2 << 4) ; trainer's view range
	dwEventFlagAddress EVENT_BEAT_POKEMONTOWER_3_TRAINER_2
	dw PokemonTower3BattleText3 ; TextBeforeBattle
	dw PokemonTower3AfterBattleText3 ; TextAfterBattle
	dw PokemonTower3EndBattleText3 ; TextEndBattle
	db $ff

PokemonTower3Text1:
	TX_TRAINER PokemonTower3TrainerHeader0

PokemonTower3Text2:
	TX_TRAINER PokemonTower3TrainerHeader1

PokemonTower3Text3:
	TX_TRAINER PokemonTower3TrainerHeader2

PokemonTower3BattleText1:
	TX_FAR _PokemonTower3BattleText1
	db "@"

PokemonTower3EndBattleText1:
	TX_FAR _PokemonTower3EndBattleText1
	db "@"

PokemonTower3AfterBattleText1:
	TX_FAR _PokemonTower3AfterBattleText1
	db "@"

PokemonTower3BattleText2:
	TX_FAR _PokemonTower3BattleText2
	db "@"

PokemonTower3EndBattleText2:
	TX_FAR _PokemonTower3EndBattleText2
	db "@"

PokemonTower3AfterBattleText2:
	TX_FAR _PokemonTower3AfterBattleText2
	db "@"

PokemonTower3BattleText3:
	TX_FAR _PokemonTower3BattleText3
	db "@"

PokemonTower3EndBattleText3:
	TX_FAR _PokemonTower3EndBattleText3
	db "@"

PokemonTower3AfterBattleText3:
	TX_FAR _PokemonTower3AfterBattleText3
	db "@"
