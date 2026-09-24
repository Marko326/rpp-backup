BrunoScript:
	call BrunoShowOrHideExitBlock
	call EnableAutoTextBoxDrawing
	ld hl, BrunoTrainerHeader0
	ld de, BrunoScriptPointers
	ld a, [wBrunoCurScript]
	call ExecuteCurMapScriptInTable
	ld [wBrunoCurScript], a
	ret

BrunoShowOrHideExitBlock:
; Blocks or clears the exit to the next room.
	ld hl, wCurrentMapScriptFlags
	bit 5, [hl]
	res 5, [hl]
	ret z
	CheckEvent EVENT_BEAT_BRUNOS_ROOM_TRAINER_0
	jr z, .blockExitToNextRoom
	ld a, $5
	jp .setExitBlock
.blockExitToNextRoom
	ld a, $24
.setExitBlock
	ld [wNewTileBlockID], a
	lb bc, 0, 2
	predef_jump ReplaceTileBlock

ResetBrunoScript:
	xor a
	ld [wBrunoCurScript], a
	ret

BrunoScriptPointers:
	dw BrunoScript0
	dw DisplayEnemyTrainerTextAndStartBattle
	dw BrunoScript2
	dw EliteFourRoomEntranceWait
	dw EliteFourRoomNoOp

BrunoScript0:
	EventFlagAddress de, EVENT_AUTOWALKED_INTO_BRUNOS_ROOM
	ld b, 1 << (EVENT_AUTOWALKED_INTO_BRUNOS_ROOM % 8)
	jp EliteFourRoomEntranceScript

BrunoScript2:
	call EndTrainerBattle
	ld a, [wIsInBattle]
	cp $ff
	jp z, ResetBrunoScript
	ld a, $1
	ld [hSpriteIndexOrTextID], a
	jp DisplayTextID

BrunoTextPointers:
	dw BrunoText1
	dw BrunoDontRunAwayText

BrunoTrainerHeader0:
	dbEventFlagBit EVENT_BEAT_BRUNOS_ROOM_TRAINER_0
	db ($0 << 4) ; trainer's view range
	dwEventFlagAddress EVENT_BEAT_BRUNOS_ROOM_TRAINER_0
	dw BrunoBeforeBattleText ; TextBeforeBattle
	dw BrunoAfterBattleText ; TextAfterBattle
	dw BrunoEndBattleText ; TextEndBattle
	dw BrunoEndBattleText ; TextEndBattle

	db $ff

BrunoText1:
	TX_ASM
	ld hl, BrunoTrainerHeader0
	call TalkToTrainer
	jp TextScriptEnd

BrunoBeforeBattleText:
	TX_FAR _BrunoBeforeBattleText
	db "@"

BrunoEndBattleText:
	TX_FAR _BrunoEndBattleText
	db "@"

BrunoAfterBattleText:
	TX_FAR _BrunoAfterBattleText
	db "@"

BrunoDontRunAwayText:
	TX_FAR _BrunoDontRunAwayText
	db "@"
