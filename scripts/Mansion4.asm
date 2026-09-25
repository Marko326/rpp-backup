Mansion4Script:
	call Mansion4Script_523cf
	; TMD-5.47.00: use the bank-local shared trainer dispatcher/table.
	ld hl, Mansion4TrainerHeader0
	ld bc, wMansion4CurScript
	jp Bank14RunStandardTrainerMapScript

Mansion4Script_523cf:
	ld hl, wCurrentMapScriptFlags
	bit 5, [hl]
	res 5, [hl]
	ret z
	CheckEvent EVENT_MANSION_SWITCH_ON
	jr nz, .asm_523ff
	ld a, $e
	ld bc, $80d
	call Mansion2Script_5202f
	ld a, $e
	ld bc, $b06
	call Mansion2Script_5202f
	ld a, $5f
	ld bc, $304
	call Mansion2Script_5202f
	ld a, $54
	ld bc, $808
	call Mansion2Script_5202f
	ret
.asm_523ff
	ld a, $2d
	ld bc, $80d
	call Mansion2Script_5202f
	ld a, $5f
	ld bc, $b06
	call Mansion2Script_5202f
	ld a, $e
	ld bc, $304
	call Mansion2Script_5202f
	ld a, $e
	ld bc, $808
	call Mansion2Script_5202f
	ret

Mansion4Script_Switches:
	ld a, [wSpriteStateData1 + 9]
	cp SPRITE_FACING_UP
	ret nz
	xor a
	ld [hJoyHeld], a
	ld a, $9
	ld [hSpriteIndexOrTextID], a
	jp DisplayTextID

Mansion4TextPointers:
	dw Mansion4Text1
	dw Mansion4Text2
	dw PickUpItemText
	dw PickUpItemText
	dw PickUpItemText
	dw PickUpItemText
	dw Mansion4Text7
	dw PickUpItemText
	dw Mansion3Text6

Mansion4TrainerHeader0:
	dbEventFlagBit EVENT_BEAT_MANSION_4_TRAINER_0
	db ($0 << 4) ; trainer's view range
	dwEventFlagAddress EVENT_BEAT_MANSION_4_TRAINER_0
	dw Mansion4BattleText1 ; TextBeforeBattle
	dw Mansion4AfterBattleText1 ; TextAfterBattle
	dw Mansion4EndBattleText1 ; TextEndBattle

Mansion4TrainerHeader1:
	dbEventFlagBit EVENT_BEAT_MANSION_4_TRAINER_1
	db ($3 << 4) ; trainer's view range
	dwEventFlagAddress EVENT_BEAT_MANSION_4_TRAINER_1
	dw Mansion4BattleText2 ; TextBeforeBattle
	dw Mansion4AfterBattleText2 ; TextAfterBattle
	dw Mansion4EndBattleText2 ; TextEndBattle

	db $ff

Mansion4Text1:
	TX_TRAINER Mansion4TrainerHeader0

Mansion4Text2:
	TX_TRAINER Mansion4TrainerHeader1

Mansion4BattleText1:
	TX_FAR _Mansion4BattleText1
	db "@"

Mansion4EndBattleText1:
	TX_FAR _Mansion4EndBattleText1
	db "@"

Mansion4AfterBattleText1:
	TX_FAR _Mansion4AfterBattleText1
	db "@"

Mansion4BattleText2:
	TX_FAR _Mansion4BattleText2
	db "@"

Mansion4EndBattleText2:
	TX_FAR _Mansion4EndBattleText2
	db "@"

Mansion4AfterBattleText2:
	TX_FAR _Mansion4AfterBattleText2
	db "@"

Mansion4Text7:
	TX_FAR _Mansion4Text7
	db "@"
