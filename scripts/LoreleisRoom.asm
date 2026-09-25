LoreleiScript:
	call LoreleiShowOrHideExitBlock
	call EnableAutoTextBoxDrawing
	ld hl, LoreleiTrainerHeader0
	ld de, LoreleiScriptPointers
	ld a, [wLoreleiCurScript]
	call ExecuteCurMapScriptInTable
	ld [wLoreleiCurScript], a
	ret

LoreleiShowOrHideExitBlock:
; Blocks or clears the exit to the next room.
	ld hl, wCurrentMapScriptFlags
	bit 5, [hl]
	res 5, [hl]
	ret z
	ld hl, wBeatLorelei
	set 1, [hl]
	CheckEvent EVENT_BEAT_LORELEIS_ROOM_TRAINER_0
	jr z, .blockExitToNextRoom
	ld a, $5
	jr .setExitBlock
.blockExitToNextRoom
	ld a, $24
.setExitBlock
	ld [wNewTileBlockID], a
	lb bc, 0, 2
	predef_jump ReplaceTileBlock

ResetLoreleiScript:
	xor a
	ld [wLoreleiCurScript], a
	ret

LoreleiScriptPointers:
	dw LoreleiScript0
	dw DisplayEnemyTrainerTextAndStartBattle
	dw LoreleiScript2
	dw EliteFourRoomEntranceWait
	dw EliteFourRoomNoOp

EliteFourRoomNoOp:
	ret

LoreleiScript0:
	EventFlagAddress de, EVENT_AUTOWALKED_INTO_LORELEIS_ROOM
	ld b, 1 << (EVENT_AUTOWALKED_INTO_LORELEIS_ROOM % 8)
	jp EliteFourRoomEntranceScript

; E4R-5.37.00: Lorelei, Bruno, and Agatha share the same entrance flow.
; Each room keeps its own auto-walk event; the visible six-step walk and
; "Don't run away!" pushback behavior are unchanged.
EliteFourRoomEntranceScript:
	push de
	push bc
	ld hl, EliteFourRoomEntranceCoords
	call ArePlayerCoordsInArray
	pop bc
	pop de
	jp nc, CheckFightingMapTrainers
	xor a
	ld [hJoyPressed], a
	ld [hJoyHeld], a
	ld [wSimulatedJoypadStatesEnd], a
	ld [wSimulatedJoypadStatesIndex], a
	ld a, [wCoordIndex]
	cp $3  ; Is player standing one tile above the exit?
	jr c, .stopPlayerFromLeaving
	ld a, [de]
	ld c, a
	or b
	ld [de], a
	ld a, c
	and b
	jr z, .walkIntoRoom
.stopPlayerFromLeaving
	ld a, $2
	ld [hSpriteIndexOrTextID], a
	call DisplayTextID  ; "Don't run away!"
	ld a, D_UP
	ld [wSimulatedJoypadStatesEnd], a
	ld a, $1
	ld [wSimulatedJoypadStatesIndex], a
	call StartSimulatingJoypadStates
	jr .waitForMovement
.walkIntoRoom
; Walk six steps upward.
	ld hl, wSimulatedJoypadStatesEnd
	ld a, D_UP
	ld [hli], a
	ld [hli], a
	ld [hli], a
	ld [hli], a
	ld [hli], a
	ld [hl], a
	ld a, $6
	ld [wSimulatedJoypadStatesIndex], a
	call StartSimulatingJoypadStates
.waitForMovement
	ld a, $3
	ld [wCurMapScript], a
	ret

EliteFourRoomEntranceCoords:
	db $0A,$04
	db $0A,$05
	db $0B,$04
	db $0B,$05
	db $FF

EliteFourRoomEntranceWait:
	ld a, [wSimulatedJoypadStatesIndex]
	and a
	ret nz
	call Delay3
	xor a
	ld [wJoyIgnore], a
	ld [wCurMapScript], a
	ret

LoreleiScript2:
	call EndTrainerBattle
	ld a, [wIsInBattle]
	cp $ff
	jp z, ResetLoreleiScript
	ld a, $1
	ld [hSpriteIndexOrTextID], a
	jp DisplayTextID

LoreleiTextPointers:
	dw LoreleiText1
	dw LoreleiDontRunAwayText

LoreleiTrainerHeader0:
	dbEventFlagBit EVENT_BEAT_LORELEIS_ROOM_TRAINER_0
	db ($0 << 4) ; trainer's view range
	dwEventFlagAddress EVENT_BEAT_LORELEIS_ROOM_TRAINER_0
	dw LoreleiBeforeBattleText ; TextBeforeBattle
	dw LoreleiAfterBattleText ; TextAfterBattle
	dw LoreleiEndBattleText ; TextEndBattle

	db $ff

LoreleiText1:
	TX_ASM
	ld hl, LoreleiTrainerHeader0
	call TalkToTrainer
	jp TextScriptEnd

LoreleiBeforeBattleText:
	TX_FAR _LoreleiBeforeBattleText
	db "@"

LoreleiEndBattleText:
	TX_FAR _LoreleiEndBattleText
	db "@"

LoreleiAfterBattleText:
	TX_FAR _LoreleiAfterBattleText
	db "@"

LoreleiDontRunAwayText:
	TX_FAR _LoreleiDontRunAwayText
	db "@"
