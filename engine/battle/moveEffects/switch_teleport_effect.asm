; SWITCH/TELEPORT/ROAR/WHIRLWIND effect body moved out of Bank F.
; SwitchAndTeleportEffect in Bank F remains as the MoveEffectPointerTable entry.
SwitchAndTeleportEffect_:
	ld a, [H_WHOSETURN]
	and a
	jp nz, .handleEnemy
	ld a, [wIsInBattle]
	dec a
	jr nz, .notWildBattle1
	ld a, [wCurEnemyLVL]
	ld b, a
	ld a, [wBattleMonLevel]
	cp b ; is the player's level greater than the enemy's level?
	jr nc, .playerMoveWasSuccessful ; if so, teleport will always succeed
	add b
	ld c, a
	inc c ; c = sum of player level and enemy level
.rejectionSampleLoop1
	push bc
	callab BattleRandomFar
	ld a, e
	pop bc
	cp c ; get a random number between 0 and c
	jr nc, .rejectionSampleLoop1
	srl b
	srl b  ; b = enemyLevel / 4
	cp b ; is rand[0, playerLevel + enemyLevel) >= (enemyLevel / 4)?
	jr nc, .playerMoveWasSuccessful ; if so, allow teleporting
	ld c, 50
	call DelayFrames
	call GetCurrentMoveID
	cp TELEPORT
	jr z, .playerTeleportFailed
	jpab PrintDidntAffectText
.playerTeleportFailed
	jpab PrintButItFailedText_
.playerMoveWasSuccessful
	callab ReadPlayerMonCurHPAndStatus
	xor a
	ld [wAnimationType], a
	inc a
	ld [wEscapedFromBattle], a
	ld a, [wPlayerMoveNum]
	jp .playAnimAndPrintText
.notWildBattle1
	ld c, 50
	call DelayFrames
	ld hl, IsUnaffectedText
	call GetCurrentMoveID
	cp TELEPORT
	jp nz, PrintText
	jpab PrintButItFailedText_
.handleEnemy
	ld a, [wIsInBattle]
	dec a
	jr nz, .notWildBattle2
	ld a, [wBattleMonLevel]
	ld b, a
	ld a, [wCurEnemyLVL]
	cp b
	jr nc, .enemyMoveWasSuccessful
	add b
	ld c, a
	inc c
.rejectionSampleLoop2
	push bc
	callab BattleRandomFar
	ld a, e
	pop bc
	cp c
	jr nc, .rejectionSampleLoop2
	srl b
	srl b
	cp b
	jr nc, .enemyMoveWasSuccessful
	ld c, 50
	call DelayFrames
	call GetCurrentMoveID
	cp TELEPORT
	jr z, .enemyTeleportFailed
	jpab PrintDidntAffectText
.enemyTeleportFailed
	jpab PrintButItFailedText_
.enemyMoveWasSuccessful
	callab ReadPlayerMonCurHPAndStatus
	xor a
	ld [wAnimationType], a
	inc a
	ld [wEscapedFromBattle], a
	ld a, [wEnemyMoveNum]
	jr .playAnimAndPrintText
.notWildBattle2
	ld c, 50
	call DelayFrames
	ld hl, IsUnaffectedText
	call GetCurrentMoveID
	cp TELEPORT
	jp nz, PrintText
	jpab ConditionalPrintButItFailed
.playAnimAndPrintText
	; PlayBattleAnimation normally consumes A directly. A cannot survive callab's
	; bank restore, so commit the animation ID first and call the memory-based entry.
	ld [wAnimationID], a
	callab PlayBattleAnimationGotID
	ld c, 20
	call DelayFrames
	call GetCurrentMoveID
	ld hl, RanFromBattleText
	cp TELEPORT
	jr z, .printText
	ld hl, RanAwayScaredText
	cp ROAR
	jr z, .printText
	ld hl, WasBlownAwayText
.printText
	jp PrintText

RanFromBattleText:
	TX_FAR _RanFromBattleText
	db "@"

RanAwayScaredText:
	TX_FAR _RanAwayScaredText
	db "@"

WasBlownAwayText:
	TX_FAR _WasBlownAwayText
	db "@"

IsUnaffectedText:
	TX_FAR _IsUnaffectedText
	db "@"
