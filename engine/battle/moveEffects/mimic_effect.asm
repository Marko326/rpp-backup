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
	; MOVE-5.62.187: decode the target slot BEFORE choosing the
	; actor's own Mimic slot; a low byte alone is not the full identity.
	call .readTargetOrdinal
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
	; Save the slot actually USING Mimic, not the menu cursor that the
	; opponent move picker changes.
	ld a, [wPlayerMoveListIndex]
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
	call .readTargetOrdinal
	pop af
	ld hl, wBattleMonMoves
.playerTurn
	ld c, a
	ld b, $0
	add hl, bc
	; MIMIC-5.19.17: keep Gen I target selection intact.  The selected/random
	; candidate is judged only after Mimic's animation, so an invalid attempt
	; still consumes Mimic's PP and fails normally instead of being re-rolled.
	push hl ; preserve the Mimic slot to replace only on success
	push de ; animation may clobber both candidate byte and ordinal
	callab PlayCurrentMoveAnimation
	pop de
	ld a, d
	call .isCopyAllowed
	pop hl
	jp nc, .mimicMissed
	ld a, d
	ld [hl], a
	; Change only the live actor's matching sidecar bit, never Party/SRAM.
	call .setCopiedActorSlotFlag
	ld a, d
	push af ; keep the copied move byte across the learned message
	ld [wd11e], a
	ld a, e
	and a
	jr z, .ordinaryCopiedName
	push de
	callba LoadExtendedMoveNameByOrdinalToCD6D
	pop de
	jr .copiedNameReady
.ordinaryCopiedName
	ld a, d
	call GetMoveName
.copiedNameReady
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
	; If Mirror Move directly copied Mimic, Mimic's immediate child is a second
	; call layer and must not inherit Mirror Move's non-STAB damage bonus.
	call ClearMirrorMoveBoost
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

.readTargetOrdinal
	; C = target's zero-based slot, D = low byte; E returns ordinal
	; (0 = ordinary, $ff = invalid flagged identity). D/HL preserved.
	ldh a, [H_WHOSETURN]
	and a
	ld a, [wExtendedBattleMoveFlags]
	jr nz, .targetPlayer
	swap a ; player is copying from the enemy's high nibble
.targetPlayer
	and $0f
	ld b, c
	ld c, a
	ld a, b
	and a
	jr z, .targetFlag
.targetShift
	srl c
	dec b
	jr nz, .targetShift
.targetFlag
	ld e, 0
	bit 0, c
	ret z
	ld e, $ff
	ld a, d
	and a
	ret z
	cp NUM_EXTENDED_MOVES + 1
	ret nc
	ld e, a
	ret

.isCopyAllowed
	; MOVE-5.62.187: reject invalid identity and duplicate FULL identity.
	; Equal bytes with opposite extended bits are different moves.
	ld a, e
	cp $ff
	jr z, .copyRejected
	ld a, d
	cp MIMIC
	jr z, .copyRejected
	cp TRANSFORM
	jr z, .copyRejected
	cp STRUGGLE
	jr z, .copyRejected
	ld hl, wBattleMonMoves
	ld a, [wExtendedBattleMoveFlags]
	ld c, a
	ldh a, [H_WHOSETURN]
	and a
	jr z, .checkKnownMoves
	ld hl, wEnemyMonMoves
	swap c
.checkKnownMoves
	ld b, NUM_MOVES
.checkKnownMoveLoop
	ld a, [hli]
	cp d
	jr nz, .nextKnownSlot
	ld a, e
	and a
	jr z, .candidateOrdinary
	bit 0, c
	jr nz, .copyRejected
	jr .nextKnownSlot
.candidateOrdinary
	bit 0, c
	jr z, .copyRejected
.nextKnownSlot
	srl c
	dec b
	jr nz, .checkKnownMoveLoop
	scf
	ret
.copyRejected
	and a ; clear carry: candidate is not legal to copy
	ret

.setCopiedActorSlotFlag
	; MOVE-5.62.187: replace only Mimic's live slot identity.
	; E is 0 ordinary or 1..40 extended; BC/DE/HL are preserved.
	push bc
	push de
	push hl
	ld a, e
	push af
	ldh a, [H_WHOSETURN]
	and a
	ld a, [wPlayerMoveListIndex]
	jr z, .gotActingSlot
	ld a, [wEnemyMoveListIndex]
.gotActingSlot
	cp NUM_MOVES
	jr nc, .invalidActorSlot
	ld e, a
	ld d, 0
	ld hl, .slotBits
	add hl, de
	ld c, [hl]
	ldh a, [H_WHOSETURN]
	and a
	jr z, .sideBitReady
	swap c
.sideBitReady
	ld a, [wExtendedBattleMoveFlags]
	ld b, a
	ld a, c
	cpl
	and b
	ld b, a
	pop af ; original copied ordinal, independent of slot-index E
	and a
	jr z, .writeFlag
	ld a, b
	or c
	ld b, a
.writeFlag
	ld a, b
	ld [wExtendedBattleMoveFlags], a
	xor a
	ld [wExtendedActiveMoveOrdinal], a
	jr .slotFlagDone
.invalidActorSlot
	pop af
.slotFlagDone
	pop hl
	pop de
	pop bc
	ret
.slotBits
	db 1, 2, 4, 8

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
	; The copied slot now has its own identity. Re-resolve that full
	; identity before the immediate-use child executes.
	jpba FinalizeMimicCopiedMoveData

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
