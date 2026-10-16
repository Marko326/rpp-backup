MoveDeleterText1:
	TX_ASM
	ld hl, MoveDeleterGreetingText
	call PrintTextAndYesNoChoice
	jp nz, .exit
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
	; MENU-5.61.06: the Pokémon list owns the move list; child cancellation only
	; backs out one level and the existing Party cursor keeps the same Pokémon.
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
	call PrepareDeletableMoveList
	pop bc
	ld a, [wDeletableMoves]
	cp 2
	jr nc, .initMoveCursor
	ld hl, MoveDeleterOneMoveText
	call PrintText
	jp .chooseMon
.initMoveCursor
	xor a
	ld [wListScrollOffset], a
	ld [wCurrentMenuItem], a
.chooseMove
	call GetPartyMonName2
	push bc
	ld hl, MoveDeleterWhichMoveText
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
	; The list renderer reuses wWhichPokemon as a row. Cache the selected
	; species only for this menu, restoring the old move-menu mode afterward.
	ld a, [wMoveMenuType]
	push af
	callab SetRockPolishNPCMoveListSpecies
	call DisplayListMenuID
	pop bc ; B = previous move-menu mode; preserve the menu's carry flag.
	ld a, b
	ld [wMoveMenuType], a
	pop bc
	jp c, .chooseMon ; B/Cancel backs out one level to the Pokémon list
	; DisplayListMenuID leaves the selected absolute move-list index in
	; wWhichPokemon. Preserve it across the confirmation box so choosing No can
	; return to the same move without adding another WRAM cursor variable.
	ld a, [wWhichPokemon]
	push af
	; Capture the selected row's full identity before confirming.
	ld a, [wWhichPokemon]
	ld e, a
	ld d, 0
	ld hl, wExtendedNPCListMoveOrdinals
	add hl, de
	ld a, [hl]
	ld [wExtendedActiveMoveOrdinal], a
	; Save the selected move id.
	ld a, [wcf91]
	ld d, a
	push de
	push bc
	ld [wMoveNum], a
	ld [wd11e],a
	ld a, [wExtendedActiveMoveOrdinal]
	cp 1
	jr z, .confirmationWhip
	cp 2
	jr z, .confirmationRough
	ld a, [wd11e]
	cp EXT_MOVE_SLOT_ESCAPE
	jr nz, .stockConfirmationName
.confirmationWhip
	callba LoadExperimentalPowerWhipNameToCD6D
	jr .confirmationNameReady
.confirmationRough
	callba LoadExperimentalPlayRoughNameToCD6D
	jr .confirmationNameReady
.stockConfirmationName
	call GetMoveName
.confirmationNameReady
	; DisplayListMenuID reused wWhichPokemon for the move-list index.
	; Restore the party slot before aliasing the confirmation/result name.
	pop bc
	push bc
	ld a, b
	ld [wWhichPokemon], a
	callab MaybeRenameRockPolishLearningMoveName
	call CopyStringToCF4B ; wcf4b survives the nickname lookup below.
	call GetPartyMonName2 ; wcd6d = 当前选择的宝可梦昵称
	ld hl, MoveDeleterConfirmText
	call PrintText
	call YesNoChoice
	pop bc
	pop de
	ld a, [wCurrentMenuItem]
	and a
	jr z, .forgetMove
	; YesNoChoice overwrites wCurrentMenuItem. Restore the move list from the
	; absolute index saved above, then put wWhichPokemon back on the party mon
	; before redrawing the Move Deleter prompt.
	pop af
	ld [wWhichPokemon], a
	push bc
	callba RestoreItemListPosition
	pop bc
	ld a, b
	ld [wWhichPokemon], a
	jp .chooseMove
.forgetMove
	pop af ; absolute position in the compact move list
	ld [wExtendedMoveFlagsScratch], a
	push de
	ld a, b ; a = mon index
	ld [wWhichPokemon], a
	ld hl, wPartyMon1Moves
	ld bc, wPartyMon2 - wPartyMon1
	call AddNTimes
	; hl = pointer to mon's moves
	; Search for the move, and set it to 0.
	pop de ; d = move id
	call DeleteMove
	; DeleteMove stored the actual slot index; its move/PP compaction
	; must be matched by the same shift of the identity-mask bits.
	callba ShiftExtendedPartyMoveFlagsOnDelete
	ld hl, MoveDeleterForgotText
	call PrintText
.exit
	ld hl, MoveDeleterByeText
	jp PrintTextAndTextScriptEnd

DeleteMove:
; HL = first move slot. The selected MOVESLISTMENU row is a compact
; nonempty-slot ordinal in wExtendedMoveFlagsScratch, not a move ID:
; ordinary Pound and expanded Power Whip may share the same raw byte.
	ld b, 0 ; raw slot index
	ld a, [wExtendedMoveFlagsScratch]
	ld c, a ; nonempty list row index
.searchLoop
	ld a, [hli]
	and a
	jr z, .nextSlot
	ld a, c
	and a
	jr z, .foundMoveLoop
	dec c
.nextSlot
	inc b
	ld a, b
	cp NUM_MOVES
	jr c, .searchLoop
	ret ; defensive guard against an invalid list index
.foundMoveLoop
	ld a, b
	ld [wExtendedMoveFlagsScratch], a
.shiftRemaining
	ld a, b
	cp 3
	jr z, .zeroLastMove
	ld a, [hl]
	dec hl
	ld [hli], a
	push hl
	ld de, wPartyMon1PP - wPartyMon1Moves
	add hl, de
	ld a, [hld]
	ld [hl], a ; copy move's PP
	pop hl
	inc hl
	inc b
	jr .shiftRemaining
.zeroLastMove
	dec hl
	xor a
	ld [hl], a
	ld de, wPartyMon1PP - wPartyMon1Moves
	add hl, de
	ld [hl], a ; clear last move's PP
	ret

PrepareDeletableMoveList:
; Places a list of the selected pokemon's moves at wDeletableMoves.
; First byte is count, and last byte is $ff. The renderer now uses the
; count to distinguish an actual pilot $ff move from this terminator.
; Input: party mon index = [wWhichPokemon]
	ld a, [wWhichPokemon]
	ld hl, wPartyMon1Moves
	ld bc, wPartyMon2 - wPartyMon1
	call AddNTimes
	; hl = pointer to mon's 4 moves
	ld b, 0 ; count of moves
	ld c, 4 + 1 ; 4 moves
	ld de, wDeletableMoves + 1
.loop
	dec c
	jr z, .done
	ld a, [hli]
	and a
	jr z, .loop
	ld [de], a
	inc de
	inc b
	jr .loop
.done
	ld a, $ff  ; terminate the list
	ld [de], a
	ld a, b  ; store number of moves
	ld [wDeletableMoves], a
	xor a
	ld hl, wExtendedNPCListMoveOrdinals
	ld bc, 8
	call FillMemory
	; Build a parallel identity for the compact list rows. A normal low
	; byte $01/$02 remains normal unless its original slot bit is set.
	ld a, [wWhichPokemon]
	ld e, a
	ld d, 0
	ld hl, wExtendedPartyMoveFlags
	add hl, de
	ld a, [hl]
	ld [wExtendedMoveFlagsScratch], a
	ld a, [wWhichPokemon]
	ld hl, wPartyMon1Moves
	ld bc, wPartyMon2 - wPartyMon1
	call AddNTimes
	ld de, wExtendedNPCListMoveOrdinals
	ld b, NUM_MOVES
.identityLoop
	ld a, [hli]
	and a
	jr z, .skipIdentity
	ld c, a
	ld a, [wExtendedMoveFlagsScratch]
	and 1
	jr z, .normalIdentity
	ld a, c
	and a
	jr z, .normalIdentity
	cp NUM_EXTENDED_MOVES + 1
	jr nc, .normalIdentity
	jr .storeIdentity
.normalIdentity
	xor a
.storeIdentity
	ld [de], a
	inc de
.skipIdentity
	ld a, [wExtendedMoveFlagsScratch]
	srl a
	ld [wExtendedMoveFlagsScratch], a
	dec b
	jr nz, .identityLoop
	ret

MoveDeleterGreetingText:
	TX_FAR _MoveDeleterGreetingText
	db "@"

MoveDeleterWhichMoveText:
	TX_FAR _MoveDeleterWhichMoveText
	db "@"

MoveDeleterConfirmText:
	TX_FAR _MoveDeleterConfirmText
	db "@"

MoveDeleterForgotText:
	TX_FAR _MoveDeleterForgotText
	db "@"

MoveDeleterByeText:
	TX_FAR _MoveDeleterByeText
	db "@"

MoveDeleterOneMoveText:
	TX_FAR _MoveDeleterOneMoveText
	db "@"
