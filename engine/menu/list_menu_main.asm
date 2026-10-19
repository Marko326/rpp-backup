; ROM0 relief round 2: list-menu control flow stays in Bank $01.
; The HOME entry selects this bank BEFORE jumping here; restoring the
; caller bank MUST happen in ROM0, not inside this switchable code.
; See tools/rom0_list_menu_bank_audit.py and the phone-test matrix.

DisplayListMenuID_::
	xor a
	ld [H_AUTOBGTRANSFERENABLED],a ; disable auto-transfer
	ld a,1
	ld [hJoy7],a ; joypad state update flag
	; TUT-5.41.00: no Old Man pseudo-bag remains; all list menus use
	; the normal list-menu bank-switch path.
	ld hl,wd730
	set 6,[hl] ; turn off letter printing delay
	xor a
	ld [wMenuItemToSwap],a ; 0 means no item is currently being swapped
	ld [wListCount],a
	ld a,[wBagPocketActive]
	and a
	jr z,.loadConventionalListCount
	cp BAG_POCKET_MODE_BATTLE
	jr z,.loadBattleBagListCount
	ld a,[wBagPocketCurrent]
	ld e,a
	ld d,0
	ld hl,wFilteredBagItems + BAG_POCKET_COUNTS_OFFSET
	add hl,de
	ld a,[hl]
	jr .storeListCount
.loadBattleBagListCount
	callba StoreCurrentBattleBagPocketCount
	ld a,[wListCount]
	jr .storeListCount
.loadConventionalListCount
	ld a,[wListPointer]
	ld l,a
	ld a,[wListPointer + 1]
	ld h,a ; hl = address of the list
	ld a,[hl] ; the first byte is the number of entries in the list
.storeListCount
	ld [wListCount],a
	ld a,LIST_MENU_BOX
	ld [wTextBoxID],a
	ld a,[wBagPocketActive]
	cp BAG_POCKET_MODE_BATTLE
	jr nz,.drawStockListMenuBox
	; Battle Pocket mode owns its final frame from the first menu draw: title area
	; at y=1..2, four item rows at y=3/5/7/9, bottom border y=11, description y=12+.
	coord hl, 4, 0
	ld b,10
	ld c,14
	call TextBoxBorder
	ld a,MESSAGE_BOX
	ld [wTextBoxID],a
	call DisplayTextBoxID
	jr .listMenuBoxReady
.drawStockListMenuBox
	call DisplayTextBoxID ; draw the stock menu text box
.listMenuBoxReady
	call UpdateSprites ; disable sprites behind the text box
; the code up to .skipMovingSprites appears to be useless
	coord hl, 4, 2 ; coordinates of upper left corner of menu text box
	lb de, 9, 14 ; height and width of menu text box
	ld a,[wListMenuID]
	and a ; is it a PC pokemon list?
	jr nz,.skipMovingSprites
	call UpdateSprites
.skipMovingSprites
	ld a,1
	ld [wMenuWatchMovingOutOfBounds],a
	ld a,[wListCount]
	and a
	jr nz,.nonemptyList
	ld a,[wBagPocketActive]
	and a
	ld a,1 ; preserve the original empty-list value outside categorized Bag
	jr z,.setMenuVariables
	xor a ; empty Pocket has only Cancel at menu position 0
	jr .setMenuVariables
.nonemptyList
	; PC Pokémon lists can temporarily keep an older scroll offset after removing
	; entries from the end. Limit the selectable rows to what is actually visible
	; so Cancel remains the final selectable row without rewriting the saved cursor.
	ld b,a
	ld a,[wListMenuID]
	and a ; is it a PC Pokémon list?
	ld a,b
	jr nz,.setMenuLimitFromCount
	ld b,a
	ld a,[wListScrollOffset]
	cp b
	jr nc,.pcCancelOnly
	ld c,a
	ld a,b
	sub c ; remaining Pokémon entries from the current scroll offset
.setMenuLimitFromCount
	cp 2
	ld a,1
	jr c,.setMenuVariables
	inc a
	jr .setMenuVariables
.pcCancelOnly
	xor a
.setMenuVariables
	ld [wMaxMenuItem],a
	ld a,[wBagPocketActive]
	and a
	ld a,4
	jr z,.storeTopMenuItemY
	dec a ; categorized Bag list window is one row higher
.storeTopMenuItemY
	ld [wTopMenuItemY],a
	ld a,5
	ld [wTopMenuItemX],a
	ld a,A_BUTTON | B_BUTTON | SELECT
	ld b,a
	ld a,[wBagPocketActive]
	cp BAG_POCKET_MODE_BATTLE
	jr nz,.haveBaseWatchedKeys
	ld b,A_BUTTON | B_BUTTON ; Battle Bag is use-only; SELECT is ignored entirely
.haveBaseWatchedKeys
	ld a,[wListMenuID]
	cp ITEMLISTMENU
	ld a,b
	jr nz,.storeWatchedKeys
	or D_LEFT | D_RIGHT
.storeWatchedKeys
	ld [wMenuWatchedKeys],a
	; MENU-5.61.17: only the categorized START Bag may opt into START.
	; Other ITEMLISTMENU callers keep their historical input behavior.
	ld a,[wListMenuID]
	cp ITEMLISTMENU
	jr nz,.watchedKeysReady
	callba UpdateBagPocketStartShortcutWatchedKey
.watchedKeysReady
	ld c,10
	call DelayFrames

DisplayListMenuIDLoop::
	xor a ; normal redraw: accept repeated directions immediately
	jr .drawList
.redrawAndWaitForDPadRelease
	ld a,1 ; boundary wrap: show the new position, then require release
.drawList
	push af
	xor a
	ld [H_AUTOBGTRANSFERENABLED],a ; disable transfer
	call PrintListMenuEntries
	; Categorized Bag redraw updates its description in the same far call.
	; Draw the cursor into the same hidden tilemap update as the list.
	; This prevents a frame where the refreshed list is visible without a cursor.
	call PlaceMenuCursor
	ld a,1
	ld [H_AUTOBGTRANSFERENABLED],a ; enable transfer
	call Delay3
	pop af
	and a
	call nz,checkOtherKeys.waitForDPadRelease
.input
	call LoadGBPal
	call HandleMenuInput
	push af
	call PlaceMenuCursor
	pop af
	bit 0,a ; was the A button pressed?
	jp z, checkOtherKeys
.buttonAPressed
	ld a,[wCurrentMenuItem]
	call PlaceUnfilledArrowMenuCursor

; pointless because both values are overwritten before they are read
	ld a,$01
	ld [wMenuExitMethod],a
	ld [wChosenMenuItem],a

	xor a
	ld [wMenuWatchMovingOutOfBounds],a
	ld a,[wCurrentMenuItem]
	ld c,a
	ld a,[wListScrollOffset]
	add c
	ld c,a
	ld a,[wListCount]
	and a ; is the list empty?
	jp z,ExitListMenu ; if so, exit the menu
	dec a
	cp c ; did the player select Cancel?
	jp c,ExitListMenu ; if so, exit the menu
	ld a,[wBagPocketActive]
	and a
	jr z,.resolveConventionalSelection
	ld a,[wListMenuID]
	cp ITEMLISTMENU
	jr nz,.resolveConventionalSelection
	ld a,[wBagPocketActive]
	cp BAG_POCKET_MODE_BATTLE
	jr z,.resolveBattleBagSelection
	; START Pocket-local list index -> real Bag slot/item/quantity.
	ld a,c
	ld [wFilteredBagItems + BAG_POCKET_RESOLVER_INDEX_OFFSET],a
	callba ChooseCurrentBagPocketEntry
	jp storeChosenEntry
.resolveBattleBagSelection
	; Battle resolves the highlighted row through its current-page real-slot cache.
	callba ChooseCurrentBagPocketEntry
	jp storeChosenEntry

.resolveConventionalSelection
	ld a,c
	ld [wWhichPokemon],a
	ld a,[wListMenuID]
	cp ITEMLISTMENU
	jr nz,.skipMultiplying
; if it's an item menu
	sla c ; item entries are 2 bytes long, so multiply by 2
.skipMultiplying
	ld a,[wListPointer]
	ld l,a
	ld a,[wListPointer + 1]
	ld h,a
	inc hl ; hl = beginning of list entries
	ld b,0
	add hl,bc
	ld a,[hl]
	ld [wcf91],a
	ld a,[wListMenuID]
	and a ; is it a PC pokemon list?
	jr z, pokemonList
	push hl
	call GetItemPrice
	pop hl
	jp DisplayListMenuIDLoop_Hack
checkIfItemListMenu:
	cp ITEMLISTMENU
	jr nz,.skipGettingQuantity
; if it's an item menu
	inc hl
	ld a,[hl] ; a = item quantity
	ld [wMaxItemQuantity],a
.skipGettingQuantity
	ld a,[wcf91]
	ld [wd0b5],a
	ld a,BANK(ItemNames)
	ld [wPredefBank],a
	ld a,ITEM_NAME
	ld [wNameListType],a
	call GetName
	jr storeChosenEntry
pokemonList:
	ld hl,wPartyCount
	ld a,[wListPointer]
	cp l ; is it a list of party pokemon or box pokemon?
	ld hl,wPartyMonNicks
	jr z,.getPokemonName
	ld hl, wBoxMonNicks ; box pokemon names
.getPokemonName
	ld a,[wWhichPokemon]
	call GetPartyMonName
storeChosenEntry: ; store the menu entry that the player chose and return
	ld de,wcd6d
	call CopyStringToCF4B ; copy name to wcf4b
skipStoringItemName:
	ld a,CHOSE_MENU_ITEM
	ld [wMenuExitMethod],a
	ld a,[wCurrentMenuItem]
	ld [wChosenMenuItem],a
	xor a
	ld [hJoy7],a ; joypad state update flag
	ld hl,wd730
	res 6,[hl] ; turn on letter printing delay
	jp BankswitchBack
checkOtherKeys: ; check B, START, SELECT, directions
	bit 1,a ; was the B button pressed?
	jp nz,ExitListMenu ; if so, exit the menu
	bit 3,a ; was START pressed?
	jr z,.notStart
	; MENU-5.61.17: consume the Bag shortcut only on the physical press edge.
	; JoypadLowSensitivity may repeat a held START; repeated states are masked below
	; so holding the key never jumps again and direction combos still work normally.
	ld b,a
	ld a,[hJoyPressed]
	bit BIT_START,a
	ld a,b
	jr nz,.freshBagStart
	; A repeated START is not a command. Remove it before continuing so a held
	; START cannot be mistaken for UP by the direction fallback below.
	res BIT_START,a
	and a
	jp z,DisplayListMenuIDLoop.input
	jr .notStart
.freshBagStart
	; HandleMenuInput returns the complete hJoy5 state once any watched key fires.
	; Only consume START when this menu explicitly watches it; otherwise combos such
	; as START+RIGHT must continue through the normal direction/SELECT handling.
	ld hl,wMenuWatchedKeys
	bit BIT_START,[hl]
	jr z,.notStart
	callba HandleBagStartShortcut
	jp DisplayListMenuIDLoop
.notStart
	bit 2,a ; was the select button pressed?
	jr z,.notSelect
	ld b,a
	ld a,[wBagPocketActive]
	and a
	ld a,b
	jp z,HandleItemListSwapping ; non-Bag item lists keep the original swap behavior
	ld a,[wBagPocketActive]
	cp BAG_POCKET_MODE_BATTLE
	jp z,DisplayListMenuIDLoop ; Battle Bag is a filtered use-only view; SELECT never reorders wBagItems
	callba HandleBagPocketSwapping
	jp DisplayListMenuIDLoop
.notSelect
	ld b,a
	and D_LEFT | D_RIGHT
	jr nz,.leftOrRightPressed
	bit 7,b ; was Down pressed?
	ld hl,wListScrollOffset
	jr z,.upPressed
.downPressed
; A held Down stops on Cancel. A fresh Down press on Cancel wraps once.
	ld a,[wListMenuID]
	and a ; PC Pokémon lists use the same first <-> Cancel boundary wrap as item lists
	jr z,.checkDownBoundaryWrap
	cp ITEMLISTMENU
	jr nz,.tryScrollingDown
.checkDownBoundaryWrap
	ld a,[wCurrentMenuItem]
	ld c,a
	ld a,[hl]
	add c
	ld c,a
	ld a,[wListCount]
	cp c
	jr nz,.tryScrollingDown
	ld a,[hJoyPressed]
	and D_DOWN
	jr z,.waitForDPadReleaseAndInput
	call ItemListJumpToFirst
	jp DisplayListMenuIDLoop.redrawAndWaitForDPadRelease
.tryScrollingDown
	ld a,[hl]
	add 3
	ld b,a
	ld a,[wListCount]
	cp b ; will going down scroll past the Cancel button?
	jr c,.waitForDPadReleaseAndInput
	inc [hl] ; if not, go down
	jp DisplayListMenuIDLoop
.upPressed
	ld a,[hl]
	and a
	jr nz,.scrollUp
; A held Up stops on the first item. A fresh Up press wraps once.
	ld a,[wListMenuID]
	and a ; PC Pokémon lists wrap from the first entry to Cancel too
	jr z,.checkUpBoundaryWrap
	cp ITEMLISTMENU
	jr nz,.waitForDPadReleaseAndInput
.checkUpBoundaryWrap
	ld a,[hJoyPressed]
	and D_UP
	jr z,.waitForDPadReleaseAndInput
	call ItemListJumpToCancel
	jp DisplayListMenuIDLoop.redrawAndWaitForDPadRelease
.scrollUp
	dec [hl]
	jp DisplayListMenuIDLoop
.leftOrRightPressed
; Categorized player Bag uses Left/Right for pockets. Other ITEMLISTMENU
; callers keep the project's existing four-entry vertical paging.
	ld a,[wListMenuID]
	cp ITEMLISTMENU
	jr nz,.waitForDPadReleaseAndInput
	ld a,[wBagPocketActive]
	and a
	jr z,.pageRegularItemList
	callba SwitchBagPocket
	jp DisplayListMenuIDLoop.redrawAndWaitForDPadRelease
.pageRegularItemList
	call PageItemListByFour
	jp c,DisplayListMenuIDLoop
.waitForDPadReleaseAndInput
	call .waitForDPadRelease
	jp DisplayListMenuIDLoop.input
.waitForDPadRelease
	call DelayFrame
	call Joypad
	ld a,[hJoyHeld]
	and D_UP | D_DOWN | D_LEFT | D_RIGHT
	jr nz,.waitForDPadRelease
	ret


ExitListMenu::
	ld a,[wCurrentMenuItem]
	ld [wChosenMenuItem],a
	ld a,CANCELLED_MENU
	ld [wMenuExitMethod],a
	ld [wMenuWatchMovingOutOfBounds],a
	xor a
	ld [hJoy7],a
	ld hl,wd730
	res 6,[hl]
	jp ExitListMenuReturnHome
