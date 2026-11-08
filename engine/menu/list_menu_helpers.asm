; List-menu helpers moved out of ROM0. Public ROM0 entry points remain in home.asm.

DisplayChooseQuantityMenu_::
; REF-356: quantity input has its own 40/5-frame key repeat timing.
; Keep the shared input timer/output intact for the menu that called us.
	ld a,[H_FRAMECOUNTER]
	push af
	ld a,[hJoy5]
	push af
	ld a,40
	ld [H_FRAMECOUNTER],a
; text box dimensions/coordinates for just quantity
	coord hl, 15, 9
	ld b,1 ; height
	ld c,3 ; width
	ld a,[wListMenuID]
	cp PRICEDITEMLISTMENU
	jr nz,.drawTextBox
; text box dimensions/coordinates for quantity and price
	coord hl, 7, 9
	ld b,1  ; height
	ld c,11 ; width
.drawTextBox
	call TextBoxBorder
	coord hl, 16, 10
	ld a,[wListMenuID]
	cp PRICEDITEMLISTMENU
	jr nz,.printInitialQuantity
	coord hl, 8, 10
.printInitialQuantity
	ld de,InitialQuantityText
	call PlaceString
	xor a
	ld [wItemQuantity],a ; initialize current quantity to 0
	jp .incrementQuantity
.waitForKeyPressLoop
	call .readQuantityMenuKeys
	; Confirm and cancel are always *new* presses, never held repeats.
	ld a,[hJoyPressed]
	bit 0,a ; A
	jp nz,.buttonAPressed
	bit 1,a ; B
	jp nz,.buttonBPressed
	; Directions accept the 40/5-frame local repeat stream.
	; Ignore ambiguous diagonals rather than changing two quantities.
	ld a,[hJoy5]
	and D_UP | D_DOWN | D_LEFT | D_RIGHT
	cp D_UP
	jr z,.incrementQuantity
	cp D_DOWN
	jr z,.decrementQuantity
	cp D_LEFT
	jr z,.decrementQuantityBy10
	cp D_RIGHT
	jr z,.incrementQuantityBy10
	jr .waitForKeyPressLoop
.incrementQuantity
	; A held UP may reach the maximum, but must not roll during
	; that hold. Only a fresh UP at the maximum wraps to 1.
	ld hl,wItemQuantity
	ld a,[wMaxItemQuantity]
	cp 1
	jp c,.waitForKeyPressLoop ; zero is not a valid dialog range
	cp [hl]
	jr z,.atMaximum
	jr c,.atMaximum
	inc [hl]
	jp .handleNewQuantity
.atMaximum
	ld a,[hJoyPressed]
	and D_UP
	jp z,.waitForKeyPressLoop ; still holding: stay at max
	ld a,[wMaxItemQuantity]
	cp 1
	jp z,.waitForKeyPressLoop ; a one-item range cannot roll
	ld [hl],1
	jp .handleNewQuantity
.decrementQuantity
	; Mirror UP: hold DOWN at 1 without rolling. A new DOWN at 1
	; wraps to the current maximum (provided maximum > 1).
	ld hl,wItemQuantity
	ld a,[wMaxItemQuantity]
	cp 1
	jp c,.waitForKeyPressLoop
	ld a,[hl]
	cp 2
	jr c,.atMinimum
	dec [hl]
	jp .handleNewQuantity
.atMinimum
	ld a,[hJoyPressed]
	and D_DOWN
	jp z,.waitForKeyPressLoop ; still holding: stay at 1
	ld a,[wMaxItemQuantity]
	cp 1
	jp z,.waitForKeyPressLoop
	ld [hl],a
	jp .handleNewQuantity
.decrementQuantityBy10
; Left: subtract ten, clamp at one in every quantity dialog.
	ld hl,wItemQuantity
	ld a,[hl]
	sub 10
	jr c,.setMinimumQuantity
	jr z,.setMinimumQuantity
	ld [hl],a
	jr .handleNewQuantity
.setMinimumQuantity
	ld a,[hl]
	cp 1
	jp z,.waitForKeyPressLoop
	ld [hl],1
	jr .handleNewQuantity
.incrementQuantityBy10
; Right: add ten, clamp at the current maximum in every quantity dialog.
	ld hl,wItemQuantity
	ld a,[hl]
	add 10
	ld b,a
	ld a,[wMaxItemQuantity]
	cp b
	jr nc,.storeIncreasedQuantity
	ld b,a
.storeIncreasedQuantity
	ld a,[hl]
	cp b
	jp z,.waitForKeyPressLoop
	ld [hl],b
.handleNewQuantity
	coord hl, 17, 10
	ld a,[wListMenuID]
	cp PRICEDITEMLISTMENU
	jr nz,.printQuantity
.printPrice
	ld c,$03
	ld a,[wItemQuantity]
	ld b,a
	ld hl,hMoney ; total price
; initialize total price to 0
	xor a
	ld [hli],a
	ld [hli],a
	ld [hl],a
.addLoop ; loop to multiply the individual price by the quantity to get the total price
	ld de,hMoney + 2
	ld hl,hItemPrice + 2
	push bc
	predef AddBCDPredef ; add the individual price to the current sum
	pop bc
	dec b
	jr nz,.addLoop
	ld a,[hHalveItemPrices]
	and a ; should the price be halved (for selling items)?
	jr z,.skipHalvingPrice
	xor a
	ld [hDivideBCDDivisor],a
	ld [hDivideBCDDivisor + 1],a
	ld a,$02
	ld [hDivideBCDDivisor + 2],a
	predef DivideBCDPredef3 ; halves the price
; store the halved price
	ld a,[hDivideBCDQuotient]
	ld [hMoney],a
	ld a,[hDivideBCDQuotient + 1]
	ld [hMoney + 1],a
	ld a,[hDivideBCDQuotient + 2]
	ld [hMoney + 2],a
.skipHalvingPrice
	coord hl, 12, 10
	ld de,SpacesBetweenQuantityAndPriceText
	call PlaceString
	ld de,hMoney ; total price
	ld c,$a3
	call PrintBCDNumber
	coord hl, 9, 10
.printQuantity
	ld de,wItemQuantity ; current quantity
	lb bc, LEADING_ZEROES | 1, 2 ; 1 byte, 2 digits
	call PrintNumber
	jp .waitForKeyPressLoop
.buttonAPressed ; the player chose to make the transaction
	xor a
	ld [wMenuItemToSwap],a ; 0 means no item is currently being swapped
	ld e,a
	jr .restoreInputState
.buttonBPressed ; the player chose to cancel the transaction
	xor a
	ld [wMenuItemToSwap],a
	ld e,$ff
.restoreInputState
	pop af
	ld [hJoy5],a
	pop af
	ld [H_FRAMECOUNTER],a
	ret

; Local repeated-directions stream; no change to JoypadLowSensitivity or
; the global menu repeat policy. VBlank decrements H_FRAMECOUNTER.
; All four directions share this exact timing: the new press fires at once,
; then 40 frames to the first held repeat and 5 frames between repeats.
; LEFT/RIGHT differ only in their +/-10 step and their no-wrap limits.
.readQuantityMenuKeys
	call Joypad
	ld a,[hJoyPressed]
	and a
	jr nz,.newKey
	ld a,[hJoyReleased]
	and a
	jr nz,.resetDelay
	ld a,[hJoyHeld]
	and D_UP | D_DOWN | D_LEFT | D_RIGHT
	jr z,.resetDelay
	ld a,[H_FRAMECOUNTER]
	and a
	jr z,.repeatHeld
	xor a
	ld [hJoy5],a
	ret
.newKey
	ld a,[hJoyPressed]
	ld [hJoy5],a
	ld a,40 ; first repeat after ~40 VBlanks
	ld [H_FRAMECOUNTER],a
	ret
.resetDelay
	xor a
	ld [hJoy5],a
	ld a,40
	ld [H_FRAMECOUNTER],a
	ret
.repeatHeld
	ld a,[hJoyHeld]
	and D_UP | D_DOWN | D_LEFT | D_RIGHT
	ld [hJoy5],a
	ld a,5 ; subsequent repeats every ~5 VBlanks
	ld [H_FRAMECOUNTER],a
	ret

; REF-356: calculate the largest BUY quantity affordable with current BCD
; money and selected item's BCD price. Output: wMaxItemQuantity = 0..99.
; 0 lets the caller show the existing "not enough money" text without opening
; a quantity dialog that would otherwise allow an impossible choice of one.
; A zero-priced item is limited by the menu's existing 99-item cap.
; SELL / Player PC / Bag never call this routine.
SetMartBuyAffordableQuantity356::
	ld a,[hItemPrice]
	ld b,a
	ld a,[hItemPrice + 1]
	or b
	ld b,a
	ld a,[hItemPrice + 2]
	or b
	jr z,.cap99
	; DivideBCDPredef3 consumes hMoney as dividend and the divisor scratch.
	; The quantity dialog recalculates hMoney from scratch before displaying
	; its total price; hItemPrice and the actual wPlayerMoney stay untouched.
	ld a,[wPlayerMoney]
	ld [hMoney],a
	ld a,[wPlayerMoney + 1]
	ld [hMoney + 1],a
	ld a,[wPlayerMoney + 2]
	ld [hMoney + 2],a
	ld a,[hItemPrice]
	ld [hDivideBCDDivisor],a
	ld a,[hItemPrice + 1]
	ld [hDivideBCDDivisor + 1],a
	ld a,[hItemPrice + 2]
	ld [hDivideBCDDivisor + 2],a
	predef DivideBCDPredef3
	; A quotient of 100 or more must be capped at 99.
	ld a,[hDivideBCDQuotient]
	and a
	jr nz,.cap99
	ld a,[hDivideBCDQuotient + 1]
	and a
	jr nz,.cap99
	; The last packed-BCD byte is now 00..99; convert to binary.
	ld a,[hDivideBCDQuotient + 2]
	ld b,a
	swap a
	and $0f
	ld c,a
	add a
	add a
	add c
	add a ; tens digit * 10
	ld c,a
	ld a,b
	and $0f
	add c
	jr .store
.cap99
	ld a,99
.store
	ld [wMaxItemQuantity],a
	ret

InitialQuantityText::
	db "×01@"

SpacesBetweenQuantityAndPriceText::
	db "      @"


PrintListMenuEntries_::
	ld a,[wBagPocketActive]
	and a
	jr z,.printConventionalEntries
	callba PrintBagPocketListEntries
	ret
.printConventionalEntries
	coord hl, 5, 3
	ld b,9
	ld c,14
	call ClearScreenArea
	ld a,[wListPointer]
	ld e,a
	ld a,[wListPointer + 1]
	ld d,a
	inc de ; de = beginning of list entries
	ld a,[wListScrollOffset]
	ld c,a
	ld a,[wListMenuID]
	cp ITEMLISTMENU
	ld a,c
	jr nz,.skipMultiplying
; if it's an item menu
; item entries are 2 bytes long, so multiply by 2
	sla a
	sla c
.skipMultiplying
	add e
	ld e,a
	jr nc,.noCarry
	inc d
.noCarry
	coord hl, 6, 4 ; coordinates of first list entry name
	ld b,4 ; print 4 names
.loop
	ld a,b
	ld [wWhichPokemon],a
	ld a,[de]
	ld [wd11e],a
	cp $ff
	jr nz,.realEntry
	ld a,[wListMenuID]
	cp MOVESLISTMENU
	jp nz,.printCancelMenuItem
	; In move lists, $ff is also the experimental Power Whip ID.
	; The count in the first byte distinguishes an actual slot from Cancel.
	push bc
	ld a,4
	sub b
	ld c,a
	ld a,[wListScrollOffset]
	add c
	ld c,a
	ld a,[wListCount]
	cp c
	pop bc
	jp z,.printCancelMenuItem
.realEntry
	push bc
	push de
	push hl
	push hl
	push de
	ld a,[wListMenuID]
	and a
	jr z,.pokemonPCMenu
	cp MOVESLISTMENU
	jr z,.movesMenu
.itemMenu
	call GetItemName
	jr .placeNameString
.pokemonPCMenu
	push hl
	ld hl,wPartyCount
	ld a,[wListPointer]
	cp l ; is it a list of party pokemon or box pokemon?
	ld hl,wPartyMonNicks
	jr z,.getPokemonName
	ld hl, wBoxMonNicks ; box pokemon names
.getPokemonName
	ld a,[wWhichPokemon]
	ld b,a
	ld a,4
	sub b
	ld b,a
	ld a,[wListScrollOffset]
	add b
	call GetPartyMonName
	pop hl
	jr .placeNameString
.movesMenu
	; MOVESLISTMENU's row has a companion full-identity ordinal.
	; It is valid for either the Relearner or Deleter list and remains
	; independent of the low 8-bit move ID and the Cancel sentinel.
	push bc
	push de
	push hl
	ld a, 4
	sub b
	ld c, a
	ld a, [wListScrollOffset]
	add c
	ld e, a
	ld d, 0
	ld hl, wExtendedNPCListMoveOrdinals
	add hl, de
	ld a, [hl]
	pop hl
	pop de
	pop bc
	and a
	jr z,.checkLegacyMove
	push bc
	push de
	push hl
	ld e, a ; one-based extended ordinal
	callba LoadExtendedMoveNameByOrdinalToCD6D
	jr c,.extendedNameInvalid
	pop hl
	pop de
	pop bc
	ld de, wcd6d
	jr .placeNameString
.extendedNameInvalid
	pop hl
	pop de
	pop bc
.checkLegacyMove
	ld a, [wd11e]
	cp EXT_MOVE_SLOT_ESCAPE
	jr nz,.ordinaryMoveName
	push hl
	callba LoadExperimentalPowerWhipNameToCD6D
	ld de, wcd6d
	pop hl
	jr .placeNameString
.ordinaryMoveName
	call GetMoveName
	; Relearner/Deleter menus carry their chosen species separately from
	; wWhichPokemon, which is overwritten by the list's row iterator.
	; Restore HL: PlaceString requires the current screen destination.
	push hl
	callab MaybeRenameRockPolishNPCListMoveName
	pop hl
.placeNameString
	call PlaceString
	pop de
	pop hl
	ld a,[wPrintItemPrices]
	and a ; should prices be printed?
	jr z,.skipPrintingItemPrice
.printItemPrice
	push hl
	ld a,[de]
	ld de,ItemPrices
	ld [wcf91],a
	call GetItemPrice ; get price
	pop hl
	ld bc, SCREEN_WIDTH + 5 ; 1 row down and 5 columns right
	add hl,bc
	ld c,$a3 ; no leading zeroes, right-aligned, print currency symbol, 3 bytes
	call PrintBCDNumber
.skipPrintingItemPrice
	ld a,[wListMenuID]
	and a
	jr nz,.skipPrintingPokemonLevel
.printPokemonLevel
	ld a,[wd11e]
	push af
	push hl
	ld hl,wPartyCount
	ld a,[wListPointer]
	cp l ; is it a list of party pokemon or box pokemon?
	ld a,PLAYER_PARTY_DATA
	jr z,.next
	ld a,BOX_DATA
.next
	ld [wMonDataLocation],a
	ld hl,wWhichPokemon
	ld a,[hl]
	ld b,a
	ld a,$04
	sub b
	ld b,a
	ld a,[wListScrollOffset]
	add b
	ld [hl],a
	call LoadMonData
	ld a,[wMonDataLocation]
	and a ; is it a list of party pokemon or box pokemon?
	jr z,.skipCopyingLevel
.copyLevel
	ld a,[wLoadedMonBoxLevel]
	ld [wLoadedMonLevel],a
.skipCopyingLevel
	pop hl
	ld bc,$001c
	add hl,bc
	call PrintLevel
	pop af
	ld [wd11e],a
.skipPrintingPokemonLevel
	pop hl
	pop de
	inc de
	ld a,[wListMenuID]
	cp ITEMLISTMENU
	jr nz,.nextListEntry
.printItemQuantity
	ld a,[wd11e]
	ld [wcf91],a
	call IsKeyItem ; check if item is unsellable
	ld a,[wIsKeyItem]
	and a ; is the item unsellable?
	jr nz,.skipPrintingItemQuantity ; if so, don't print the quantity
	push hl
	ld bc, SCREEN_WIDTH + 8 ; 1 row down and 8 columns right
	add hl,bc
	ld a,"×"
	ld [hli],a
	ld a,[wd11e]
	push af
	ld a,[de]
	ld [wMaxItemQuantity],a
	push de
	ld de,wd11e
	ld [de],a
	lb bc, 1, 2
	call PrintNumber
	pop de
	pop af
	ld [wd11e],a
	pop hl
.skipPrintingItemQuantity
	inc de
	pop bc
	inc c
	push bc
	inc c
	ld a,[wMenuItemToSwap] ; ID of item chosen for swapping (counts from 1)
	and a ; is an item being swapped?
	jr z,.nextListEntry
	sla a
	cp c ; is it this item?
	jr nz,.nextListEntry
	dec hl
	ld a,$ec ; unfilled right arrow menu cursor to indicate an item being swapped
	ld [hli],a
.nextListEntry
	ld bc,2 * SCREEN_WIDTH ; 2 rows
	add hl,bc
	pop bc
	inc c
	dec b
	jp nz,.loop
	ld bc,-8
	add hl,bc
	ld a,"▼"
	ld [hl],a
	ret
.printCancelMenuItem
	ld de,ListMenuCancelText
	jp PlaceString

