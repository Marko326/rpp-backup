; Mimic body moved out of Bank F; MimicEffect remains as a jpab entry there.
MimicEffect_:
	ld c, 50
	call DelayFrames
	callab MoveHitTest
	ld a, [wMoveMissed]
	and a
	jp nz, .mimicMissed
	ld a, [H_WHOSETURN]
	and a
	ld hl, wBattleMonMoves
	ld a, [wPlayerBattleStatus1]
	jr nz, .enemyTurn
	ld a, [wLinkState]
	cp LINK_STATE_BATTLING
	jr nz, .letPlayerChooseMove
	ld hl, wEnemyMonMoves
	ld a, [wEnemyBattleStatus1]
.enemyTurn
	bit Invulnerable, a
	jp nz, .mimicMissed
.getRandomMove
	push hl
	callab BattleRandomFar
	ld a, e
	pop hl ; callab clobbers HL, so restore the move-list base first
	and $3
	ld c, a
	ld b, $0
	push hl ; preserve the base across the indexed slot read, as in the original code
	add hl, bc
	ld a, [hl]
	pop hl
	and a
	jr z, .getRandomMove
	ld d, a
	ld a, [H_WHOSETURN]
	and a
	ld hl, wBattleMonMoves
	ld a, [wPlayerMoveListIndex]
	jr z, .playerTurn
	ld hl, wEnemyMonMoves
	ld a, [wEnemyMoveListIndex]
	jr .playerTurn
.letPlayerChooseMove
	ld a, [wEnemyBattleStatus1]
	bit Invulnerable, a
	jp nz, .mimicMissed
	ld a, [wCurrentMenuItem]
	push af
	ld a, $1
	ld [wMoveMenuType], a
	callab MoveSelectionMenu
	call LoadScreenTilesFromBuffer1
	ld hl, wEnemyMonMoves
	ld a, [wCurrentMenuItem]
	ld c, a
	ld b, $0
	add hl, bc
	ld d, [hl]
	pop af
	ld hl, wBattleMonMoves
.playerTurn
	ld c, a
	ld b, $0
	add hl, bc
	ld a, d
	ld [hl], a
	ld [wd11e], a
	call GetMoveName
	callab PlayCurrentMoveAnimation
	ld hl, MimicLearnedMoveText
	jp PrintText
.mimicMissed
	jpab PrintButItFailedText_

MimicLearnedMoveText:
	TX_FAR _MimicLearnedMoveText
	db "@"
