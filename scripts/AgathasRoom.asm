AgathaScript:
	call AgathaShowOrHideExitBlock
	call EnableAutoTextBoxDrawing
	ld hl, AgathaTrainerHeader0
	ld de, AgathaScriptPointers
	ld a, [wAgathaCurScript]
	call ExecuteCurMapScriptInTable
	ld [wAgathaCurScript], a
	ret

AgathaShowOrHideExitBlock:
; Blocks or clears the exit to the next room.
	ld hl, wCurrentMapScriptFlags
	bit 5, [hl]
	res 5, [hl]
	ret z
	CheckEvent EVENT_BEAT_AGATHAS_ROOM_TRAINER_0
	jr z, .blockExitToNextRoom
	ld a, $e
	jp .setExitBlock
.blockExitToNextRoom
	ld a, $3b
.setExitBlock:
	ld [wNewTileBlockID], a
	lb bc, 0, 2
	predef_jump ReplaceTileBlock

ResetAgathaScript:
	xor a
	ld [wAgathaCurScript], a
	ret

AgathaScriptPointers:
	dw AgathaScript0
	dw DisplayEnemyTrainerTextAndStartBattle
	dw AgathaScript2
	dw EliteFourRoomEntranceWait
	dw EliteFourRoomNoOp

AgathaScript0:
	EventFlagAddress de, EVENT_AUTOWALKED_INTO_AGATHAS_ROOM
	ld b, 1 << (EVENT_AUTOWALKED_INTO_AGATHAS_ROOM % 8)
	jp EliteFourRoomEntranceScript

AgathaScript2:
	call EndTrainerBattle
	ld a, [wIsInBattle]
	cp $ff
	jp z, ResetAgathaScript
	ld a, $1
	ld [hSpriteIndexOrTextID], a
	call DisplayTextID
	ld a, $1
	ld [wGaryCurScript], a
	ret

AgathaTextPointers:
	dw AgathaText1
	dw AgathaDontRunAwayText

AgathaTrainerHeader0:
	dbEventFlagBit EVENT_BEAT_AGATHAS_ROOM_TRAINER_0
	db ($0 << 4) ; trainer's view range
	dwEventFlagAddress EVENT_BEAT_AGATHAS_ROOM_TRAINER_0
	dw AgathaBeforeBattleText ; TextBeforeBattle
	dw AgathaAfterBattleText ; TextAfterBattle
	dw AgathaEndBattleText ; TextEndBattle

	db $ff

AgathaText1:
	TX_TRAINER AgathaTrainerHeader0

AgathaBeforeBattleText:
	TX_FAR _AgathaBeforeBattleText
	db "@"

AgathaEndBattleText:
	TX_FAR _AgathaEndBattleText
	db "@"

AgathaAfterBattleText:
	TX_FAR _AgathaAfterBattleText
	db "@"

AgathaDontRunAwayText:
	TX_FAR _AgathaDontRunAwayText
	db "@"
