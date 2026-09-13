; List-menu helpers moved out of ROM0. Public ROM0 entry points remain in home.asm.

DisplayChooseQuantityMenu_::
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
	call JoypadLowSensitivity
	ld a,[hJoyPressed] ; newly pressed buttons
	bit 0,a ; was the A button pressed?
	jp nz,.buttonAPressed
	bit 1,a ; was the B button pressed?
	jp nz,.buttonBPressed
	bit 6,a ; was Up pressed?
	jr nz,.incrementQuantity
	bit 7,a ; was Down pressed?
	jr nz,.decrementQuantity
	ld b,a
	ld a,[wListMenuID]
	cp PRICEDITEMLISTMENU
	jr nz,.waitForKeyPressLoop ; only buying and selling use Left/Right shortcuts
	bit 5,b ; was Left pressed?
	jr nz,.decrementQuantityBy10
	bit 4,b ; was Right pressed?
	jr nz,.incrementQuantityBy10
	jr .waitForKeyPressLoop
.incrementQuantity
	ld a,[wMaxItemQuantity]
	inc a
	ld b,a
	ld hl,wItemQuantity ; current quantity
	inc [hl]
	ld a,[hl]
	cp b
	jr nz,.handleNewQuantity
; wrap to 1 if the player goes above the max quantity
	ld a,1
	ld [hl],a
	jr .handleNewQuantity
.decrementQuantity
	ld hl,wItemQuantity ; current quantity
	dec [hl]
	jr nz,.handleNewQuantity
; wrap to the max quantity if the player goes below 1
	ld a,[wMaxItemQuantity]
	ld [hl],a
	jr .handleNewQuantity
.decrementQuantityBy10
; Match Crystal's Left-key behavior: subtract 10 and clamp at 1.
	ld hl,wItemQuantity
	ld a,[hl]
	sub 10
	jr c,.setMinimumQuantity
	jr z,.setMinimumQuantity
	ld [hl],a
	jr .handleNewQuantity
.setMinimumQuantity
	ld [hl],1
	jr .handleNewQuantity
.incrementQuantityBy10
; Match Crystal's Right-key behavior: add 10 and clamp at the current maximum.
	ld hl,wItemQuantity
	ld a,[hl]
	add 10
	ld b,a
	ld a,[wMaxItemQuantity]
	cp b
	jr nc,.storeIncreasedQuantity
	ld b,a
.storeIncreasedQuantity
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
	ret
.buttonBPressed ; the player chose to cancel the transaction
	xor a
	ld [wMenuItemToSwap],a ; 0 means no item is currently being swapped
	ld a,$ff
	ld e,a
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
	jp z,.printCancelMenuItem
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
	call GetMoveName
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

