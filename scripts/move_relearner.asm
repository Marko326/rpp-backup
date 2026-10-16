MoveRelearnerText1:
	TX_ASM
; Display the list of moves to the player.
	ld hl, MoveRelearnerGreetingText
	call PrintTextAndYesNoChoice
	jp nz, .exit
	xor a
	ldh [$9f], a
	ldh [$a1], a
	ld a, 5
	ldh [$a0], a  ; 500 money
	call HasEnoughMoney
	jr nc, .enoughMoney
	; not enough money
	ld hl, MoveRelearnerNotEnoughMoneyText
	jp PrintTextAndTextScriptEnd
.enoughMoney
	; Select pokemon from party.
	call SaveScreenTilesToBuffer2
.chooseMon
	; MENU-5.61.06: child-menu restoration re-enables overworld sprite updates.
	; Reapply the complete Party-menu state on every entry so its icon OAM is not
	; replaced by the map sprite updater after returning from the move list.
	xor a
	ld [wListScrollOffset], a
	ld [wPartyMenuTypeOrMessageID], a
	ld [wUpdateSpritesEnabled], a
	ld [wMenuItemToSwap], a
	; MENU-5.61.06: Party is the parent of the relearnable-move list. Returning
	; from a child menu keeps the selected Pokémon via the existing Party cursor.
	call DisplayPartyMenu
	push af
	call GBPalWhiteOutWithDelay3
	call RestoreScreenTilesAndReloadTilePatterns
	call LoadGBPal
	pop af
	jp c, .exit
	ld a, [wWhichPokemon]
	ld b, a
	push bc
	ld hl, PrepareRelearnableMoveList
	ld b, Bank(PrepareRelearnableMoveList)
	call Bankswitch
	pop bc ; restore the selected Party index after the far call
	ld a, [wRelearnableMoves]
	and a
	jr nz, .initMoveCursor
	ld hl, MoveRelearnerNoMovesText
	call PrintText
	jp .chooseMon
.initMoveCursor
	xor a
	ld [wListScrollOffset], a
	ld [wCurrentMenuItem], a
.chooseMove
	; 将当前选择的宝可梦昵称复制到 wcd6d，供后面的文本使用。
	call GetPartyMonName2
	push bc
	ld hl, MoveRelearnerWhichMoveText
	call PrintText
	ld a, MOVESLISTMENU
	ld [wListMenuID], a
	ld de, wRelearnableMoves
	ld hl, wListPointer
	ld [hl], e
	inc hl
	ld [hl], d
	xor a
	ld [wPrintItemPrices], a ; don't print prices
	; The list renderer changes wWhichPokemon to a row index. Cache the
	; selected species during this menu only, then restore the prior mode.
	ld a, [wMoveMenuType]
	push af
	callab SetRockPolishNPCMoveListSpecies
	call DisplayListMenuID
	pop bc ; B = previous move-menu mode; carry still means Cancel.
	ld a, b
	ld [wMoveMenuType], a
	pop bc
	jp c, .chooseMon ; B/Cancel backs out one level to the Pokémon list
	; MENU-5.61.06: keep the absolute move-list index across LearnMove so an
	; abandoned learn attempt can return to the same move instead of closing out.
	ld a, [wWhichPokemon]
	push af
	push bc
	; The $ff menu placeholders are not stored move IDs. Look up
	; the selected row's expanded identity and hand LearnMove the
	; nonzero low byte plus its explicit ordinal.
	ld a, [wWhichPokemon]
	ld e, a
	ld d, 0
	ld hl, wExtendedNPCListMoveOrdinals
	add hl, de
	ld a, [hl]
	ld [wExtendedLearningMoveOrdinal], a
	and a
	jr z, .ordinarySelected
	ld [wMoveNum], a ; 1=Power Whip, 2=Play Rough
	ld [wd11e], a
	cp 1
	jr z, .relearnerWhipName
	callba LoadExperimentalPlayRoughNameToCD6D
	jr .relearnerNameReady
.relearnerWhipName
	callba LoadExperimentalPowerWhipNameToCD6D
	jr .relearnerNameReady
.ordinarySelected
	ld a, [wcf91]
	ld [wMoveNum], a
	ld [wd11e], a
	cp EXT_MOVE_SLOT_ESCAPE
	jr nz, .stockRelearnerName
	callba LoadExperimentalPowerWhipNameToCD6D
	jr .relearnerNameReady
.stockRelearnerName
	call GetMoveName
.relearnerNameReady
	pop bc
	ld a, b
	ld [wWhichPokemon], a
	push bc ; preserve the Party index while LearnMove returns its result in B
	callab MaybeRenameRockPolishLearningMoveName
	call CopyStringToCF4B ; LearnMove consumes the species-aware wcf4b name.
	ld a, [wLetterPrintingDelayFlags]
	push af
	xor a
	ld [wLetterPrintingDelayFlags], a
	predef LearnMove
	xor a
	ld [wExtendedLearningMoveOrdinal], a
	pop af
	ld [wLetterPrintingDelayFlags], a
	ld a, b
	pop bc
	and a
	jr nz, .learnedMove
	pop af
	ld [wWhichPokemon], a
	push bc
	callba RestoreItemListPosition
	pop bc
	ld a, b
	ld [wWhichPokemon], a
	jp .chooseMove
.learnedMove
	pop af ; discard the saved move-list index
	; Charge 500 money
	xor a
	ld [wWhichTrade], a
	ld [wTrainerFacingDirection], a
	ld a, $5
	ld [wTrainerEngageDistance], a
	ld hl, wTrainerFacingDirection
	ld de, wPlayerMoney + 2
	ld c, $3
	predef SubBCDPredef
	ld hl, MoveRelearnerByeText
	jp PrintTextAndTextScriptEnd
.exit
	ld hl, MoveRelearnerByeText
	jp PrintTextAndTextScriptEnd

MoveRelearnerGreetingText:
	TX_FAR _MoveRelearnerGreetingText
	db "@"

MoveRelearnerNotEnoughMoneyText:
	TX_FAR _MoveRelearnerNotEnoughMoneyText
	db "@"

MoveRelearnerWhichMoveText:
	TX_FAR _MoveRelearnerWhichMoveText
	db "@"

MoveRelearnerByeText:
	TX_FAR _MoveRelearnerByeText
	db "@"

MoveRelearnerNoMovesText:
	TX_FAR _MoveRelearnerNoMovesText
	db "@"
