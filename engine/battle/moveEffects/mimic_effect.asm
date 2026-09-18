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
	; MIMIC-5.19.14: restore the HUD after returning from the target move menu.
	callab DrawHUDsAndHPBars
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
	push af ; MIMIC-5.19.14: keep the copied move ID across the learned-move message
	ld [wd11e], a
	call GetMoveName
	callab PlayCurrentMoveAnimation
	ld hl, MimicLearnedMoveText
	call PrintText
	ld a, [H_WHOSETURN]
	and a
	ld hl, wPlayerSelectedMove
	ld de, wPlayerMoveNum
	jr z, .executeCopiedMove
	ld hl, wEnemySelectedMove
	ld de, wEnemyMoveNum
.executeCopiedMove
	pop af
	ld [hl], a
	; ReloadMoveData normally receives the move ID in A. A cross-bank callab
	; cannot be used for it because Bankswitch overwrites A with BANK($F),
	; which is $0f (CUT). Reproduce the small reload sequence in this roomy
	; bank so the copied move ID reaches the Moves lookup intact.
	call .reloadCopiedMoveData
	ld a, [H_WHOSETURN]
	and a
	ld hl, CheckIfPlayerNeedsToChargeUp
	ret z
	ld hl, CheckIfEnemyNeedsToChargeUp
	ret

.reloadCopiedMoveData
	ld [wd11e], a
	dec a
	ld hl, Moves
	ld bc, MoveEnd - Moves
	call AddNTimes
	ld a, BANK(Moves)
	call FarCopyData
	; IncrementMovePP does not consume A, so it is safe to call across banks.
	callab IncrementMovePP
	call GetMoveName
	call CopyStringToCF4B
	ld a, $1
	and a
	ret

.mimicMissed
	callab PrintButItFailedText_
	ld a, [H_WHOSETURN]
	and a
	ld hl, ExecutePlayerMoveDone
	ret z
	ld hl, ExecuteEnemyMoveDone
	ret

MimicLearnedMoveText:
	TX_FAR _MimicLearnedMoveText
	db "@"
