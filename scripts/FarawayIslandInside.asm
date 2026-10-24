; TMD-5.47.00: standard three-state trainer maps in bank 34
; share one script table and the generic bank-local dispatcher.
Bank34RunStandardTrainerMapScript:
	ld de, Bank34StandardTrainerScriptPointers
	; fall through
; TMD-5.47.00: bank-local trainer map dispatcher.
; HL = first TrainerHeader, DE = script table, BC = map script state.
Bank34RunTrainerMapScript:
	call EnableAutoTextBoxDrawing
	ld a, [bc]
	push bc
	call ExecuteCurMapScriptInTable
	pop bc
	ld [bc], a
	ret

Bank34StandardTrainerScriptPointers:
	dw CheckFightingMapTrainers
	dw DisplayEnemyTrainerTextAndStartBattle
	dw EndTrainerBattle

FarawayIslandInsideScript:
	; TMD-5.47.00: use the bank-local shared trainer dispatcher/table.
	ld hl, FarawayIslandInsideTrainerHeaders
	ld bc, wFarawayIslandInsideCurScript
	jp Bank34RunStandardTrainerMapScript

FarawayIslandInsideTextPointers:
	dw FarawayIslandInsideText1

FarawayIslandInsideTrainerHeaders:
FarawayIslandInsideTrainerHeader0:
	dbEventFlagBit EVENT_BEAT_FARAWAY_INSIDE_TRAINER_0
	db ($0 << 4) ; trainer's view range
	dwEventFlagAddress EVENT_BEAT_FARAWAY_INSIDE_TRAINER_0
	dw FarawayIslandInsideMewText ; TextBeforeBattle
	dw FarawayIslandInsideMewText ; TextAfterBattle
	dw FarawayIslandInsideMewText ; TextEndBattle

	db $ff

FarawayIslandInsideText1:
	TX_TRAINER FarawayIslandInsideTrainerHeader0

FarawayIslandInsideMewText:
	TX_FAR _FarawayIslandInsideMewText
	TX_ASM
	ld a, MEW
	call PlayCry
	call WaitForSoundToFinish
	jp TextScriptEnd
