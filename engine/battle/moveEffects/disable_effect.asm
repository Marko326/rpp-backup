; Disable body moved out of Bank F; DisableEffect remains as a jpab entry there.
DisableEffect_:
	callab MoveHitTest
	ld a, [wMoveMissed]
	and a
	jp nz, .moveMissed
	ld de, wEnemyDisabledMove
	ld hl, wEnemyMonMoves
	ld a, [H_WHOSETURN]
	and a
	jr z, .disableEffect
	ld de, wPlayerDisabledMove
	ld hl, wBattleMonMoves
.disableEffect
; no effect if target already has a move disabled
	ld a, [de]
	and a
	jp nz, .moveMissed
.pickMoveToDisable
	; BattleRandomFar returns in E, so preserve both pointer registers around it.
	push hl
	push de
	callab BattleRandomFar
	ld a, e
	pop de
	pop hl ; callab clobbers HL, so restore the move-list base first
	and $3
	ld c, a
	ld b, $0
	push hl ; preserve the base across the indexed slot read, as in the original code
	add hl, bc
	ld a, [hl]
	pop hl
	and a
	jr z, .pickMoveToDisable ; loop until a non-00 move slot is found
	ld [wd11e], a ; store move number
	push hl
	ld a, [H_WHOSETURN]
	and a
	ld hl, wBattleMonPP
	jr nz, .enemyTurn
	ld a, [wLinkState]
	cp LINK_STATE_BATTLING
	pop hl ; wEnemyMonMoves
	jr nz, .playerTurnNotLinkBattle
; .playerTurnLinkBattle
	push hl
	ld hl, wEnemyMonPP
.enemyTurn
	push hl
	ld a, [hli]
	or [hl]
	inc hl
	or [hl]
	inc hl
	or [hl]
	and $3f
	pop hl ; wBattleMonPP or wEnemyMonPP
	jr z, .moveMissedPopHL ; nothing to do if all moves have no PP left
	add hl, bc
	ld a, [hl]
	pop hl
	and a
	jr z, .pickMoveToDisable ; pick another move if this one had 0 PP
.playerTurnNotLinkBattle
; non-link battle enemies have unlimited PP so the previous checks aren't needed
	; C is the chosen move slot and DE is the disabled-move destination. Preserve
	; both across the far RNG call before generating the 1-8 turn duration.
	push bc
	push de
	callab BattleRandomFar
	ld a, e
	pop de
	pop bc
	and $7
	inc a ; 1-8 turns disabled
	inc c ; move 1-4 will be disabled
	swap c
	add c ; map disabled move to high nibble of wEnemyDisabledMove / wPlayerDisabledMove
	ld [de], a
	callab PlayCurrentMoveAnimation2
	ld hl, wPlayerDisabledMoveNumber
	ld a, [H_WHOSETURN]
	and a
	jr nz, .printDisableText
	inc hl ; wEnemyDisabledMoveNumber
.printDisableText
	ld a, [wd11e] ; move number
	ld [hl], a
	call GetMoveName
	ld hl, MoveWasDisabledText
	jp PrintText
.moveMissedPopHL
	pop hl
.moveMissed
	jpab PrintButItFailedText_

MoveWasDisabledText:
	TX_FAR _MoveWasDisabledText
	db "@"
