; Categorized player Bag runtime. This entire file lives in ROMX bank $35.
; The real inventory remains wNumBagItems/wBagItems. START Bag builds one
; real-slot index map per menu session and never reorders the physical Bag.

BAG_POCKET_TITLE_WIDTH_TILES EQU 8
BAG_POCKET_TITLE_HEIGHT_TILES EQU 2
BAG_POCKET_TITLE_VRAM_SET0 EQU $c0
BAG_POCKET_TITLE_VRAM_SET1 EQU $d0

; Battle titles use the already-resident font as 8x8 sprites. This keeps the exact
; BAGTITLE-011 pixel anchors/y-position without borrowing any battle BG tile VRAM.
BATTLE_BAG_TITLE_OAM_FIRST EQU 33
BATTLE_BAG_TITLE_OAM_COUNT EQU 7
BATTLE_BAG_TITLE_OAM_Y     EQU 11 + 16 ; OAM Y is screen Y + 16

PrepareBagPocketMenu::
	; Persistent state uses ten bytes that were already reserved as unused game
	; progress WRAM. Magic bytes make old saves initialize deterministically.
	ld a, [wBagPocketStateMagic1]
	cp $b6
	jr nz, .initializeState
	ld a, [wBagPocketStateMagic2]
	cp $48
	jr z, .stateReady
.initializeState
	xor a
	ld hl, wBagPocketCurrent
	ld b, 8 ; current + five saved positions + two legacy work bytes
.clearStateLoop
	ld [hli], a
	dec b
	jr nz, .clearStateLoop
	ld a, $b6
	ld [wBagPocketStateMagic1], a
	ld a, $48
	ld [wBagPocketStateMagic2], a
.stateReady
	ld a, [wBagPocketCurrent]
	cp NUM_BAG_POCKETS
	jr c, .validPocket
	xor a
	ld [wBagPocketCurrent], a
.validPocket
	ld a, BAG_POCKET_MODE_START
	ld [wBagPocketActive], a
	call BuildBagPocketMap
	call LoadBagPocketTitleTiles
	call LoadCurrentBagPocketCursor
	xor a
	ld [wFilteredBagItems + BAG_POCKET_LAYOUT_READY_OFFSET], a
	ld a, $fe
	ld [wFilteredBagItems + BAG_POCKET_DESCRIPTION_CACHE_OFFSET], a
	; Keep a conventional real-Bag pointer installed for code paths which are not
	; Pocket-aware. ITEMLISTMENU explicitly switches to the Slot Map while active.
	ld hl, wNumBagItems
	ld a, l
	ld [wListPointer], a
	ld a, h
	ld [wListPointer + 1], a
	ret

ClearBattleBagTransientState::
	; Called from MainMenu and safe to call at any session boundary. None of this
	; state is saved, so old .sav bytes can never be interpreted as Battle Bag flags.
	xor a
	ld [wBagPocketActive], a
	ld [wBattleBagPocket], a
	ld hl, wBattleBagSavedPositions
	ld b, 4
.clearSavedPositions
	ld [hli], a
	dec b
	jr nz, .clearSavedPositions
	ld a, $ff
	ld [wBattleBagCachedPocket], a
	ld [wBattleBagCachedScroll], a
	ld hl, wBattleBagVisibleSlots
	ld b, 4
.clearVisibleSlots
	ld [hli], a
	dec b
	jr nz, .clearVisibleSlots
	ld a, $fe
	ld [wBattleBagDescriptionCache], a
	ret

PrepareBattleBagPocketMenu::
	; Wild-battle Bag never touches the START Slot Map at $cc5b. Battle-only state
	; lives in unsaved WRAM, so Continue cannot inherit a stale Pocket/layout/VRAM
	; flag from an older save schema.
	ld a, BAG_POCKET_MODE_BATTLE
	ld [wBagPocketActive], a
	xor a
	ld [wMenuItemToSwap], a
	ld a, $fe
	ld [wBattleBagDescriptionCache], a
	call InvalidateBattleBagPageCache

	ld a, [wBattleBagPocket]
	cp BAG_POCKET_ITEMS
	jr z, .pocketValid
	cp BAG_POCKET_BALLS
	jr z, .pocketValid
	cp BAG_POCKET_BERRIES
	jr z, .pocketValid
	cp BAG_POCKET_KEY
	jr z, .pocketValid
	xor a
	ld [wBattleBagPocket], a
.pocketValid
	call EnsureBattleBagPocketHasItems
	call LoadBattleBagCursor
	; Leave a conventional real-Bag pointer installed for legacy code which only
	; needs the physical Bag after DisplayListMenuID returns.
	ld hl, wNumBagItems
	ld a, l
	ld [wListPointer], a
	ld a, h
	ld [wListPointer + 1], a
	ret

SwitchBagPocket::
	ld a, [wBagPocketActive]
	cp BAG_POCKET_MODE_BATTLE
	jp z, SwitchBattleBagPocket
	; A pending SELECT swap is local to one Pocket and never crosses Left/Right.
	xor a
	ld [wMenuItemToSwap], a
	call SaveCurrentBagPocketCursor
	ld a, [hJoy5]
	bit 5, a ; Left
	jr nz, .previousPocket
	ld a, [wBagPocketCurrent]
	inc a
	cp NUM_BAG_POCKETS
	jr c, .storePocket
	xor a
	jr .storePocket
.previousPocket
	ld a, [wBagPocketCurrent]
	and a
	jr nz, .decrementPocket
	ld a, NUM_BAG_POCKETS
.decrementPocket
	dec a
.storePocket
	ld [wBagPocketCurrent], a
	call LoadBagPocketTitleTiles
	call LoadCurrentBagPocketCursor
	call UpdateCurrentBagPocketMenuLimits
	ld a, $fe
	ld [wFilteredBagItems + BAG_POCKET_DESCRIPTION_CACHE_OFFSET], a
	ret

SwitchBattleBagPocket:
	; Battle is a use-only view. Remember this Pocket's absolute cursor before
	; cycling, skip empty Pockets, then restore the destination Pocket's cursor.
	xor a
	ld [wMenuItemToSwap], a
	call SaveCurrentBattleBagCursor
	ld a, [wBattleBagPocket]
	push af ; original Pocket ID
	ld d, 4 ; ITEM/BALL/BERRY/KEY
.search
	ld a, [wBattleBagPocket]
	call StepBattleBagPocket
	ld [wBattleBagPocket], a
	push de ; GetBattleBagPocketCount clobbers DE while resolving ItemUse handlers
	call GetBattleBagPocketCount
	pop de
	and a
	jr nz, .found
	dec d
	jr nz, .search
	pop af
	ld [wBattleBagPocket], a
	ret
.found
	pop bc ; B = original Pocket ID
	ld a, [wBattleBagPocket]
	cp b
	ret z ; only the current Pocket was non-empty
	call LoadBattleBagCursor
	call UpdateBattleBagMenuLimitsFromCount
	call InvalidateBattleBagPageCache
	ld a, $fe
	ld [wBattleBagDescriptionCache], a
	ret

UpdateBattleBagMenuLimitsFromCount:
	ld a, [wListCount]
	and a
	jr z, .empty
	cp 2
	ld a, 1
	jr c, .store
	inc a
.store
	ld [wMaxMenuItem], a
	ret
.empty
	xor a
	ld [wMaxMenuItem], a
	ret

StepBattleBagPocket:
	; INPUT/OUTPUT: A = actual BAG_POCKET_* ID. hJoy5 selects direction.
	ld c, a
	ld a, [hJoy5]
	bit 5, a ; Left
	ld a, c
	jr nz, .left
.right
	cp BAG_POCKET_ITEMS
	jr z, .toBalls
	cp BAG_POCKET_BALLS
	jr z, .toBerries
	cp BAG_POCKET_BERRIES
	jr z, .toKey
	xor a ; KEY -> ITEM
	ret
.toBalls
	ld a, BAG_POCKET_BALLS
	ret
.toBerries
	ld a, BAG_POCKET_BERRIES
	ret
.toKey
	ld a, BAG_POCKET_KEY
	ret
.left
	cp BAG_POCKET_ITEMS
	jr z, .toKey
	cp BAG_POCKET_BALLS
	jr z, .toItems
	cp BAG_POCKET_BERRIES
	jr z, .toBalls
	ld a, BAG_POCKET_BERRIES ; KEY -> BERRY
	ret
.toItems
	xor a
	ret

EnsureBattleBagPocketHasItems:
	call GetBattleBagPocketCount
	and a
	ret nz
	; Search forward independent of the current joypad state.
	ld d, 4
.search
	ld a, [wBattleBagPocket]
	cp BAG_POCKET_ITEMS
	jr z, .balls
	cp BAG_POCKET_BALLS
	jr z, .berries
	cp BAG_POCKET_BERRIES
	jr z, .key
	xor a
	jr .store
.balls
	ld a, BAG_POCKET_BALLS
	jr .store
.berries
	ld a, BAG_POCKET_BERRIES
	jr .store
.key
	ld a, BAG_POCKET_KEY
.store
	ld [wBattleBagPocket], a
	push de ; preserve the four-Pocket search counter across the counting call
	call GetBattleBagPocketCount
	pop de
	and a
	ret nz
	dec d
	jr nz, .search
	xor a
	ld [wBattleBagPocket], a
	ret

StoreCurrentBattleBagPocketCount::
	callab CountBattleBagPocketItems
	ret

GetBattleBagPocketCount:
	callab CountBattleBagPocketItems
	ld a, [wListCount]
	ret

InvalidateBattleBagPageCache:
	ld a, $ff
	ld [wBattleBagCachedPocket], a
	ld [wBattleBagCachedScroll], a
	ret

EnsureBattleBagPageCache:
	ld a, [wBattleBagCachedPocket]
	ld b, a
	ld a, [wBattleBagPocket]
	cp b
	jr nz, .rebuild
	ld a, [wBattleBagCachedScroll]
	ld b, a
	ld a, [wListScrollOffset]
	cp b
	ret z
.rebuild
	callab BuildBattleBagVisiblePage
	ret

SaveCurrentBattleBagCursor::
	; Store one absolute filtered index for each Battle Pocket. The array is
	; unsaved battle-runtime state, so positions live only for this battle.
	ld a, [wListScrollOffset]
	ld b, a
	ld a, [wCurrentMenuItem]
	add b
	ld b, a
	ld a, [wBattleBagPocket]
	call GetBattleBagSavedCursorAddress
	ld [hl], b
	ret

GetBattleBagSavedCursorAddress:
	; INPUT: A = actual BAG_POCKET_* ID. OUTPUT: HL = ITEM/BALL/BERRY/KEY slot.
	cp BAG_POCKET_BERRIES
	jr z, .berries
	cp BAG_POCKET_KEY
	jr z, .key
	; ITEM=0 and BALL=1 already match their compact cursor indices.
	ld e, a
	jr .haveIndex
.berries
	ld e, 2
	jr .haveIndex
.key
	ld e, 3
.haveIndex
	ld d, 0
	ld hl, wBattleBagSavedPositions
	add hl, de
	ret

LoadBattleBagCursor:
	; Restore this Pocket's absolute cursor and clamp it to the current filtered
	; count. Reconstruct scroll+row using the same three-row selectable window.
	call GetBattleBagPocketCount
	ld a, [wListCount]
	and a
	jr z, .empty
	ld b, a
	ld a, [wBattleBagPocket]
	call GetBattleBagSavedCursorAddress
	ld a, [hl]
	cp b
	jr c, .positionValid
	ld a, b
	dec a
.positionValid
	ld c, a
	cp 3
	jr c, .topRows
	sub 2
	ld [wListScrollOffset], a
	ld a, 2
	jr .storeRow
.topRows
	xor a
	ld [wListScrollOffset], a
	ld a, c
.storeRow
	ld [wCurrentMenuItem], a
	ld [wBagSavedMenuItem], a
	ret
.empty
	xor a
	ld [wListScrollOffset], a
	ld [wCurrentMenuItem], a
	ld [wBagSavedMenuItem], a
	ret

ResolveCurrentBattleBagEntry:
	; Current selection always lives inside the four-slot visible-page cache.
	call EnsureBattleBagPageCache
	ld a, [wCurrentMenuItem]
	ld e, a
	ld d, 0
	ld hl, wBattleBagVisibleSlots
	add hl, de
	ld a, [hl]
	cp $ff
	jr z, .invalid
	ld [wWhichPokemon], a
	call GetBagItemPointerFromRealSlot
	ld a, [hli]
	ld [wcf91], a
	ld a, [hl]
	ld [wMaxItemQuantity], a
	ret
.invalid
	ld a, $ff
	ld [wWhichPokemon], a
	ld [wcf91], a
	xor a
	ld [wMaxItemQuantity], a
	ret

SaveCurrentBagPocketCursor::
	; Remember one absolute item index per Pocket. This needs only five bytes and
	; can be reconstructed into scroll+row whenever the Pocket is reopened.
	ld a, [wListScrollOffset]
	ld b, a
	ld a, [wCurrentMenuItem]
	add b
	ld b, a
	ld a, [wBagPocketCurrent]
	ld e, a
	ld d, 0
	ld hl, wBagPocketSavedPositions
	add hl, de
	ld [hl], b
	ret

StoreCurrentBagPocketSavedPosition:
	; INPUT: A = Pocket-local absolute item index.
	ld b, a
	ld a, [wBagPocketCurrent]
	ld e, a
	ld d, 0
	ld hl, wBagPocketSavedPositions
	add hl, de
	ld [hl], b
	ret

GetCurrentBagPocketCount:
	ld a, [wBagPocketCurrent]
	ld e, a
	ld d, 0
	ld hl, wFilteredBagItems + BAG_POCKET_COUNTS_OFFSET
	add hl, de
	ld a, [hl]
	ret

GetCurrentBagPocketStart:
	ld a, [wBagPocketCurrent]
	ld e, a
	ld d, 0
	ld hl, wFilteredBagItems + BAG_POCKET_STARTS_OFFSET
	add hl, de
	ld a, [hl]
	ret

UpdateCurrentBagPocketMenuLimits:
	call GetCurrentBagPocketCount
	ld [wListCount], a
	and a
	jr z, .empty
	cp 2
	ld a, 1
	jr c, .store
	inc a
.store
	ld [wMaxMenuItem], a
	ret
.empty
	xor a
	ld [wMaxMenuItem], a
	ret

LoadCurrentBagPocketCursor:
	call GetCurrentBagPocketCount
	and a
	jr z, .emptyPocket
	ld b, a ; number of real items in this Pocket
	ld a, [wBagPocketCurrent]
	ld e, a
	ld d, 0
	ld hl, wBagPocketSavedPositions
	add hl, de
	ld a, [hl]
	cp b
	jr c, .positionValid
	ld a, b
	dec a ; old position became Cancel/out of range: use new last real item
.positionValid
	ld c, a
	cp 3
	jr c, .topRows
	sub 2
	ld [wListScrollOffset], a
	ld a, 2
	ld [wCurrentMenuItem], a
	ld [wBagSavedMenuItem], a
	ret
.topRows
	xor a
	ld [wListScrollOffset], a
	ld a, c
	ld [wCurrentMenuItem], a
	ld [wBagSavedMenuItem], a
	ret
.emptyPocket
	xor a
	ld [wListScrollOffset], a
	ld [wCurrentMenuItem], a
	ld [wBagSavedMenuItem], a
	ret

FinalizeBagPocketMenuResult::
	; A-button handling already resolves the Pocket entry to a physical Bag slot.
	; This routine only saves the Pocket-local cursor and reproduces the original
	; DisplayListMenuID carry result for START-menu callers.
	ld a, [wBagPocketActive]
	and a
	jr z, .returnMenuResult
	call SaveCurrentBagPocketCursor
	xor a
	ld [wBagPocketActive], a
.returnMenuResult
	ld a, [wMenuExitMethod]
	cp CHOSE_MENU_ITEM
	jr z, .chosen
	scf
	ret
.chosen
	and a
	ret

ResolveCurrentBagPocketEntry::
	; Cross-bank-safe resolver interface. The caller writes the Pocket-local
	; absolute index to wFilteredBagItems + BAG_POCKET_RESOLVER_INDEX_OFFSET and reads all results from WRAM.
	; No A/BC/flags return convention is required across callba.
	call GetCurrentBagPocketCount
	ld c, a
	ld a, [wFilteredBagItems + BAG_POCKET_RESOLVER_INDEX_OFFSET]
	cp c
	jr nc, .invalid
	ld b, a
	call GetCurrentBagPocketStart
	add b
	ld e, a
	ld d, 0
	ld hl, wFilteredBagItems + BAG_POCKET_SLOT_MAP_OFFSET
	add hl, de
	ld a, [hl]
	ld [wFilteredBagItems + BAG_POCKET_RESOLVED_SLOT_OFFSET], a
	call GetBagItemPointerFromRealSlot
	ld a, [hli]
	ld [wFilteredBagItems + BAG_POCKET_RESOLVED_ITEM_OFFSET], a
	ld a, [hl]
	ld [wFilteredBagItems + BAG_POCKET_RESOLVED_QUANTITY_OFFSET], a
	ret
.invalid
	ld a, $ff
	ld [wFilteredBagItems + BAG_POCKET_RESOLVED_SLOT_OFFSET], a
	ld [wFilteredBagItems + BAG_POCKET_RESOLVED_ITEM_OFFSET], a
	xor a
	ld [wFilteredBagItems + BAG_POCKET_RESOLVED_QUANTITY_OFFSET], a
	ret

ChooseCurrentBagPocketEntry::
	ld a, [wBagPocketActive]
	cp BAG_POCKET_MODE_BATTLE
	jp z, ChooseCurrentBattleBagEntry
	; START-menu A-button wrapper. Input is wFilteredBagItems + BAG_POCKET_RESOLVER_INDEX_OFFSET; all selection
	; state is written to the same globals used by the legacy ITEMLISTMENU path.
	call ResolveCurrentBagPocketEntry
	ld a, [wFilteredBagItems + BAG_POCKET_RESOLVED_SLOT_OFFSET]
	ld [wWhichPokemon], a
	ld a, [wFilteredBagItems + BAG_POCKET_RESOLVED_ITEM_OFFSET]
	ld [wcf91], a
	ld a, [wFilteredBagItems + BAG_POCKET_RESOLVED_QUANTITY_OFFSET]
	ld [wMaxItemQuantity], a
	call GetItemPrice
	ld a, [wcf91]
	ld [wd0b5], a
	ld a, BANK(ItemNames)
	ld [wPredefBank], a
	ld a, ITEM_NAME
	ld [wNameListType], a
	call GetName
	ret

ChooseCurrentBattleBagEntry:
	call ResolveCurrentBattleBagEntry
	ld a, [wcf91]
	cp $ff
	ret z
	call GetItemPrice
	ld a, [wcf91]
	ld [wd0b5], a
	ld a, BANK(ItemNames)
	ld [wPredefBank], a
	ld a, ITEM_NAME
	ld [wNameListType], a
	call GetName
	ret

BuildBagPocketMap:
	; First pass counts each Pocket. Second pass writes each real Bag slot into
	; its pre-sized segment. This costs at most two 100-slot scans per START Bag
	; opening; Left/Right switches never scan the Bag again.
	xor a
	ld hl, wFilteredBagItems + BAG_POCKET_COUNTS_OFFSET
	ld b, NUM_BAG_POCKETS
.clearCounts
	ld [hli], a
	dec b
	jr nz, .clearCounts

	ld hl, wBagItems
	ld a, [wNumBagItems]
	ld b, a
.countLoop
	ld a, b
	and a
	jr z, .countsReady
	ld a, [hli]
	push hl
	push bc
	call GetBagPocketForItem
	ld e, a
	ld d, 0
	ld hl, wFilteredBagItems + BAG_POCKET_COUNTS_OFFSET
	add hl, de
	inc [hl]
	pop bc
	pop hl
	inc hl ; quantity -> next item
	dec b
	jr .countLoop

.countsReady
	; Convert counts to starts and initialize one write cursor per Pocket.
	ld hl, wFilteredBagItems + BAG_POCKET_COUNTS_OFFSET
	ld de, wFilteredBagItems + BAG_POCKET_STARTS_OFFSET
	ld b, 0 ; running total
	ld c, NUM_BAG_POCKETS
.startLoop
	ld a, b
	ld [de], a
	inc de
	add [hl]
	ld b, a
	inc hl
	dec c
	jr nz, .startLoop

	ld hl, wFilteredBagItems + BAG_POCKET_STARTS_OFFSET
	ld de, wFilteredBagItems + BAG_POCKET_BUILD_CURSORS_OFFSET
	ld bc, NUM_BAG_POCKETS
	call CopyData

	ld hl, wBagItems
	ld a, [wNumBagItems]
	ld b, a
	xor a
	ld [wFilteredBagItems + BAG_POCKET_BUILD_SLOT_OFFSET], a
.fillLoop
	ld a, b
	and a
	jr z, .filled
	ld a, [hli]
	push hl
	push bc
	call GetBagPocketForItem
	ld e, a
	ld d, 0
	ld hl, wFilteredBagItems + BAG_POCKET_BUILD_CURSORS_OFFSET
	add hl, de
	ld a, [hl]
	ld c, a ; map index
	inc [hl]
	ld b, 0
	ld hl, wFilteredBagItems + BAG_POCKET_SLOT_MAP_OFFSET
	add hl, bc
	ld a, [wFilteredBagItems + BAG_POCKET_BUILD_SLOT_OFFSET]
	ld [hl], a
	inc a
	ld [wFilteredBagItems + BAG_POCKET_BUILD_SLOT_OFFSET], a
	pop bc
	pop hl
	inc hl ; quantity -> next item
	dec b
	jr .fillLoop
.filled
	call SortBagPocketMachines
	ret

GetBagPocketForItem:
	; INPUT: A = item ID. OUTPUT: A = BAG_POCKET_*.
	ld [wcf91], a
	call IsBagPocketMachine
	jr c, .machine
	ld a, [wcf91]
	call IsBagPocketBall
	jr c, .balls
	ld a, [wcf91]
	call IsBagPocketBerry
	jr c, .berries
	call IsKeyItem
	ld a, [wIsKeyItem]
	and a
	jr nz, .key
	ld a, BAG_POCKET_ITEMS
	ret
.balls
	ld a, BAG_POCKET_BALLS
	ret
.machine
	ld a, BAG_POCKET_TM_HM
	ret
.berries
	ld a, BAG_POCKET_BERRIES
	ret
.key
	ld a, BAG_POCKET_KEY
	ret

SortBagPocketMachines:
	; Stable insertion sort of only the MACHINE Slot Map segment. The physical
	; Bag is never reordered. Equal ranks stop the left shift, so duplicate TM/HM
	; slots preserve their original relative order.
	ld a, [wFilteredBagItems + BAG_POCKET_COUNTS_OFFSET + BAG_POCKET_TM_HM]
	cp 2
	ret c
	ld a, 1
	ld [wFilteredBagItems + BAG_POCKET_SORT_INDEX_OFFSET], a
.outer
	ld a, [wFilteredBagItems + BAG_POCKET_SORT_INDEX_OFFSET]
	ld b, a
	ld a, [wFilteredBagItems + BAG_POCKET_COUNTS_OFFSET + BAG_POCKET_TM_HM]
	cp b
	ret z
	ret c ; defensive if metadata is ever stale

	; Capture the current key slot and its TM/HM display rank.
	ld a, [wFilteredBagItems + BAG_POCKET_STARTS_OFFSET + BAG_POCKET_TM_HM]
	add b
	ld e, a
	ld d, 0
	ld hl, wFilteredBagItems + BAG_POCKET_SLOT_MAP_OFFSET
	add hl, de
	ld a, [hl]
	ld [wFilteredBagItems + BAG_POCKET_SORT_KEY_SLOT_OFFSET], a
	call GetMachineRankForRealSlot
	ld [wFilteredBagItems + BAG_POCKET_SORT_KEY_RANK_OFFSET], a
	ld a, b
	ld [wFilteredBagItems + BAG_POCKET_SORT_SCAN_OFFSET], a

.inner
	ld a, [wFilteredBagItems + BAG_POCKET_SORT_SCAN_OFFSET]
	and a
	jp z, .placeKey
	dec a
	ld c, a ; previous Pocket-local index
	ld a, [wFilteredBagItems + BAG_POCKET_STARTS_OFFSET + BAG_POCKET_TM_HM]
	add c
	ld e, a
	ld d, 0
	ld hl, wFilteredBagItems + BAG_POCKET_SLOT_MAP_OFFSET
	add hl, de
	ld a, [hl]
	ld [wFilteredBagItems + BAG_POCKET_BUILD_SLOT_OFFSET], a ; previous real slot; map construction is finished
	call GetMachineRankForRealSlot
	ld b, a ; previous rank
	ld a, [wFilteredBagItems + BAG_POCKET_SORT_KEY_RANK_OFFSET]
	cp b
	jr nc, .placeKey ; key >= previous gives a stable insertion point

	; Shift the previous real-slot index one map position to the right.
	ld a, [wFilteredBagItems + BAG_POCKET_SORT_SCAN_OFFSET]
	ld c, a
	ld a, [wFilteredBagItems + BAG_POCKET_STARTS_OFFSET + BAG_POCKET_TM_HM]
	add c
	ld e, a
	ld d, 0
	ld hl, wFilteredBagItems + BAG_POCKET_SLOT_MAP_OFFSET
	add hl, de
	ld a, [wFilteredBagItems + BAG_POCKET_BUILD_SLOT_OFFSET]
	ld [hl], a
	ld a, [wFilteredBagItems + BAG_POCKET_SORT_SCAN_OFFSET]
	dec a
	ld [wFilteredBagItems + BAG_POCKET_SORT_SCAN_OFFSET], a
	jr .inner

.placeKey
	ld a, [wFilteredBagItems + BAG_POCKET_SORT_SCAN_OFFSET]
	ld c, a
	ld a, [wFilteredBagItems + BAG_POCKET_STARTS_OFFSET + BAG_POCKET_TM_HM]
	add c
	ld e, a
	ld d, 0
	ld hl, wFilteredBagItems + BAG_POCKET_SLOT_MAP_OFFSET
	add hl, de
	ld a, [wFilteredBagItems + BAG_POCKET_SORT_KEY_SLOT_OFFSET]
	ld [hl], a
	ld hl, wFilteredBagItems + BAG_POCKET_SORT_INDEX_OFFSET
	inc [hl]
	jp .outer

GetMachineRankForRealSlot:
	; INPUT: A = real Bag slot. OUTPUT: A = TM01..TM50 -> 0..49,
	; HM01..HM05 -> 50..54. All callers pass MACHINE entries only.
	call GetBagItemAtRealSlot
	cp TM_01
	jr c, .hm
	sub TM_01
	ret
.hm
	sub HM_01
	add 50
	ret

GetBagItemPointerFromRealSlot:
	; INPUT: A = real Bag slot. OUTPUT: HL = address of its (item, quantity) pair.
	add a
	ld e, a
	ld d, 0
	ld hl, wBagItems
	add hl, de
	ret

GetBagItemAtRealSlot:
	; INPUT: A = real Bag slot. OUTPUT: A = item ID.
	call GetBagItemPointerFromRealSlot
	ld a, [hl]
	ret

HandleBagPocketSwapping::
	ld a, [wBagPocketActive]
	cp BAG_POCKET_MODE_BATTLE
	ret z
	ld a, [wBagPocketCurrent]
	cp BAG_POCKET_TM_HM
	ret z
	ld a, [wCurrentMenuItem]
	ld b, a
	ld a, [wListScrollOffset]
	add b
	ld [wFilteredBagItems + BAG_POCKET_SWAP_SECOND_INDEX_OFFSET], a
	ld b, a
	call GetCurrentBagPocketCount
	cp b
	ret z
	ret c ; Cancel or defensive out-of-range position

	ld a, [wMenuItemToSwap]
	and a
	jr nz, .haveFirst
	ld a, [wFilteredBagItems + BAG_POCKET_SWAP_SECOND_INDEX_OFFSET]
	inc a
	ld [wMenuItemToSwap], a
	ld c, 20
	call DelayFrames
	ret
.haveFirst
	dec a
	ld [wFilteredBagItems + BAG_POCKET_SWAP_FIRST_INDEX_OFFSET], a
	ld b, a
	ld a, [wFilteredBagItems + BAG_POCKET_SWAP_SECOND_INDEX_OFFSET]
	cp b
	ret z
	ld c, 20
	call DelayFrames

	ld a, [wFilteredBagItems + BAG_POCKET_SWAP_FIRST_INDEX_OFFSET]
	ld [wFilteredBagItems + BAG_POCKET_RESOLVER_INDEX_OFFSET], a
	call ResolveCurrentBagPocketEntry
	ld a, [wFilteredBagItems + BAG_POCKET_RESOLVED_SLOT_OFFSET]
	ld [wFilteredBagItems + BAG_POCKET_SWAP_FIRST_SLOT_OFFSET], a

	ld a, [wFilteredBagItems + BAG_POCKET_SWAP_SECOND_INDEX_OFFSET]
	ld [wFilteredBagItems + BAG_POCKET_RESOLVER_INDEX_OFFSET], a
	call ResolveCurrentBagPocketEntry
	ld a, [wFilteredBagItems + BAG_POCKET_RESOLVED_SLOT_OFFSET]
	ld [wFilteredBagItems + BAG_POCKET_SWAP_SECOND_SLOT_OFFSET], a

	call GetBagPocketSwapAddresses
	ld a, [de]
	ld b, a
	ld a, [hl]
	cp b
	jr z, .sameItem

	; Different item IDs: exchange the two physical item/quantity pairs. Both
	; positions belong to this same Pocket, so the Slot Map itself stays valid.
	ld c, a ; second item ID
	ld a, c
	ld [de], a
	ld a, b
	ld [hl], a
	inc de
	inc hl
	ld a, [de]
	ld b, a
	ld a, [hl]
	ld c, a
	ld a, c
	ld [de], a
	ld a, b
	ld [hl], a
	jr .done

.sameItem
	inc de ; first quantity
	inc hl ; second quantity
	ld a, [hl]
	ld b, a
	ld a, [de]
	add b
	cp 100
	jr c, .combineSlots
	; Keep the original item-list semantics: fill the second selected slot to 99
	; and leave the remainder in the first selected slot.
	sub 99
	ld [de], a
	ld a, 99
	ld [hl], a
	jr .done

.combineSlots
	ld [hl], a ; merged quantity remains in the second selected slot
	; Let the project's inventory primitive erase the first physical slot. This
	; keeps slot compaction, item count, and legacy menu side effects in one place.
	ld a, [de]
	ld [wItemQuantity], a
	ld a, [wFilteredBagItems + BAG_POCKET_SWAP_FIRST_SLOT_OFFSET]
	ld [wWhichPokemon], a
	ld hl, wNumBagItems
	call RemoveItemFromInventory
	; Removing a physical slot invalidates every later real-slot index.
	call BuildBagPocketMap
	ld a, [wFilteredBagItems + BAG_POCKET_SWAP_SECOND_INDEX_OFFSET]
	ld b, a
	ld a, [wFilteredBagItems + BAG_POCKET_SWAP_FIRST_INDEX_OFFSET]
	cp b
	jr nc, .cursorIndexReady
	dec b
.cursorIndexReady
	ld a, b
	call GetCurrentBagPocketCount
	ld c, a
	ld a, b
	cp c
	jr c, .storeMergedCursor
	ld a, c
	and a
	jr z, .storeMergedCursor
	dec a
.storeMergedCursor
	call StoreCurrentBagPocketSavedPosition
	call LoadCurrentBagPocketCursor
	call UpdateCurrentBagPocketMenuLimits
.done
	xor a
	ld [wMenuItemToSwap], a
	ld a, $fe
	ld [wFilteredBagItems + BAG_POCKET_DESCRIPTION_CACHE_OFFSET], a
	ret

GetBagPocketSwapAddresses:
	; OUTPUT: DE = first item pair, HL = second item pair.
	ld a, [wFilteredBagItems + BAG_POCKET_SWAP_FIRST_SLOT_OFFSET]
	call GetBagItemPointerFromRealSlot
	push hl
	ld a, [wFilteredBagItems + BAG_POCKET_SWAP_SECOND_SLOT_OFFSET]
	call GetBagItemPointerFromRealSlot
	pop de
	ret

IsBagPocketMachine:
	cp HM_01
	jr c, .no
	cp TM_50 + 1
	ret c
.no
	and a
	ret

IsBagPocketBerry:
	cp ORAN_BERRY
	jr c, .no
	cp ACAI_BERRY + 1
	ret c
.no
	and a
	ret

IsBagPocketBall:
	cp MASTER_BALL
	jr z, .yes
	cp ULTRA_BALL
	jr z, .yes
	cp GREAT_BALL
	jr z, .yes
	cp POKE_BALL
	jr z, .yes
	cp SAFARI_BALL
	jr z, .yes
	cp THIEF_BALL
	jr z, .yes
	and a
	ret
.yes
	scf
	ret

PrintBagPocketName::
	ld a, [wBagPocketActive]
	cp BAG_POCKET_MODE_BATTLE
	jr z, .battleTitle

	; START keeps its existing custom frame, drawn once per Bag session.
	ld hl, wFilteredBagItems + BAG_POCKET_LAYOUT_READY_OFFSET
	ld a, [hl]
	and a
	jr nz, .startLayoutReady
	inc a
	ld [hl], a
	coord hl, 4, 0
	ld b, 10
	ld c, 14
	call TextBoxBorder
	ld a, MESSAGE_BOX
	ld [wTextBoxID], a
	call DisplayTextBoxID
	; DisplayListMenuID already clipped map sprites against the upper list box,
	; but this description box is created later during the first categorized redraw.
	; Re-run clipping once now so sprites covered by y=12..17 are hidden too.
	call UpdateSprites
.startLayoutReady
	coord hl, 8, 1
	ld b, BAG_POCKET_TITLE_HEIGHT_TILES
	ld c, BAG_POCKET_TITLE_WIDTH_TILES
	call ClearScreenArea

	ld a, [wBagPocketTitleSpanLeft]
	ld e, a
	ld d, 0
	coord hl, 8, 1
	add hl, de
	ld a, [wBagPocketTitleVRAMSet]
	and 1
	jr z, .useSet0
	ld c, BAG_POCKET_TITLE_VRAM_SET1
	jr .haveTitleBase
.useSet0
	ld c, BAG_POCKET_TITLE_VRAM_SET0
.haveTitleBase
	ld a, [wBagPocketTitleSpanWidth]
	ld b, a
	ld a, c
.drawTopTitleTiles
	ld [hli], a
	inc a
	dec b
	jr nz, .drawTopTitleTiles
	ld c, a

	ld a, [wBagPocketTitleSpanLeft]
	ld e, a
	ld d, 0
	coord hl, 8, 2
	add hl, de
	ld a, [wBagPocketTitleSpanWidth]
	ld b, a
	ld a, c
.drawBottomTitleTiles
	ld [hli], a
	inc a
	dec b
	jr nz, .drawBottomTitleTiles
	ret

.battleTitle
	; Battle uses font sprites at BAGTITLE-011's exact pixel anchors. The BG title
	; canvas stays blank, so switching Pockets never mutates battle BG tile graphics.
	coord hl, 8, 1
	ld b, BAG_POCKET_TITLE_HEIGHT_TILES
	ld c, BAG_POCKET_TITLE_WIDTH_TILES
	call ClearScreenArea
	jp DrawBattleBagTitleSprites

HideBattleBagTitleSprites::
	ld hl, wOAMBuffer + BATTLE_BAG_TITLE_OAM_FIRST * 4
	ld de, 4
	ld b, BATTLE_BAG_TITLE_OAM_COUNT
	ld a, 160 ; hidden below the visible OBJ range
.loop
	ld [hl], a
	add hl, de
	dec b
	jr nz, .loop
	ret

DrawBattleBagTitleSprites:
	call HideBattleBagTitleSprites
	ld a, [wBattleBagPocket]
	cp BAG_POCKET_BALLS
	jr z, .ball
	cp BAG_POCKET_BERRIES
	jr z, .berry
	cp BAG_POCKET_KEY
	jr z, .key
	ld de, BattleBagTitleItemLayout
	jr .draw
.ball
	ld de, BattleBagTitleBallLayout
	jr .draw
.berry
	ld de, BattleBagTitleBerryLayout
	jr .draw
.key
	ld de, BattleBagTitleKeyLayout
.draw
	ld hl, wOAMBuffer + BATTLE_BAG_TITLE_OAM_FIRST * 4
.nextGlyph
	ld a, [de]
	inc de
	and a
	ret z
	ld b, a
	ld a, BATTLE_BAG_TITLE_OAM_Y
	ld [hli], a
	ld a, [de]
	inc de
	ld [hli], a
	ld a, b ; sprite tile ID equals the resident font character code ($80-$ff)
	ld [hli], a
	xor a ; palette 0, no flip, above BG
	ld [hli], a
	jr .nextGlyph

; Pairs are font tile ID and OAM X (screen X + 8). These are BAGTITLE-011's
; exact anchors, including I's seven-pixel spacing and KEY ITEM's four-pixel gap.
BattleBagTitleItemLayout:
	db "I", 88, "T", 95, "E", 103, "M", 111, 0
BattleBagTitleBallLayout:
	db "B", 88, "A", 96, "L", 104, "L", 112, 0
BattleBagTitleBerryLayout:
	db "B", 84, "E", 92, "R", 100, "R", 108, "Y", 116, 0
BattleBagTitleKeyLayout:
	db "K", 76, "E", 84, "Y", 92, "I", 102, "T", 109, "E", 117, "M", 125, 0

PrintBagPocketListEntries::
	ld a, [wBagPocketActive]
	cp BAG_POCKET_MODE_BATTLE
	jp z, PrintBattleBagListEntries
	; Keep the categorized redraw in one ROM bank so Home only Bankswitches once.
	coord hl, 5, 2
	ld b, 9
	ld c, 14
	call ClearScreenArea
	call PrintBagPocketName
	call PrintBagPocketEntries
	jp UpdateBagPocketDescription

PrintBagPocketEntries::
	; Pocket-active ITEMLISTMENU entries are not a conventional pair list. Resolve
	; each visible local index through the Slot Map before printing item/quantity.
	coord hl, 6, 3
	ld b, 4
	ld c, 0 ; visible row offset
.loop
	ld a, [wListScrollOffset]
	add c
	ld [wFilteredBagItems + BAG_POCKET_RESOLVER_INDEX_OFFSET], a
	ld e, a
	ld a, [wListCount]
	cp e
	jr z, .printCancel
	jr c, .printCancel

	push bc
	push hl
	call ResolveCurrentBagPocketEntry
	pop hl
	ld a, [wFilteredBagItems + BAG_POCKET_RESOLVED_ITEM_OFFSET]
	ld [wd11e], a
	ld [wcf91], a
	push hl
	call GetItemName
	call PlaceString
	pop hl

	call IsKeyItem
	ld a, [wIsKeyItem]
	and a
	jr nz, .skipQuantity
	push hl
	ld de, SCREEN_WIDTH + 8
	add hl, de
	ld a, "×"
	ld [hli], a
	ld a, [wFilteredBagItems + BAG_POCKET_RESOLVED_QUANTITY_OFFSET]
	ld [wMaxItemQuantity], a
	ld [wd11e], a
	ld de, wd11e
	lb bc, 1, 2
	call PrintNumber
	pop hl
.skipQuantity
	ld a, [wMenuItemToSwap]
	and a
	jr z, .rowDone
	dec a
	ld e, a
	ld a, [wFilteredBagItems + BAG_POCKET_RESOLVER_INDEX_OFFSET]
	cp e
	jr nz, .rowDone
	dec hl
	ld a, $ec
	ld [hli], a
.rowDone
	pop bc
	ld de, 2 * SCREEN_WIDTH
	add hl, de
	inc c
	dec b
	jr nz, .loop
	ld bc, -8
	add hl, bc
	ld a, "▼"
	ld [hl], a
	ret
.printCancel
	ld de, ListMenuCancelText
	jp PlaceString

PrintBattleBagListEntries:
	; Current-page real slots are cached in unsaved WRAM. Up/Down inside the same
	; page reuses these four slots; only a scroll/Pocket change rescans wBagItems.
	coord hl, 5, 2
	ld b, 9
	ld c, 14
	call ClearScreenArea
	call PrintBagPocketName
	call EnsureBattleBagPageCache

	coord hl, 6, 3
	ld b, 4
	ld c, 0
.rowLoop
	push hl
	ld a, c
	ld e, a
	ld d, 0
	ld hl, wBattleBagVisibleSlots
	add hl, de
	ld a, [hl]
	pop hl
	cp $ff
	jr z, .printCancel
	ld [wWhichPokemon], a

	push bc
	push hl
	call GetBagItemPointerFromRealSlot
	ld a, [hli]
	ld [wd11e], a
	ld [wcf91], a
	ld a, [hl]
	ld [wMaxItemQuantity], a
	pop hl
	push hl
	call GetItemName
	call PlaceString
	pop hl

	ld a, [wBattleBagPocket]
	cp BAG_POCKET_KEY
	jr z, .rowDone
	push hl
	ld de, SCREEN_WIDTH + 8
	add hl, de
	ld a, "×"
	ld [hli], a
	ld a, [wMaxItemQuantity]
	ld [wd11e], a
	ld de, wd11e
	lb bc, 1, 2
	call PrintNumber
	pop hl
.rowDone
	pop bc
	ld de, 2 * SCREEN_WIDTH
	add hl, de
	inc c
	dec b
	jr nz, .rowLoop
	call PrintBattleBagCancelOrDownArrow
	jp UpdateBattleBagDescription
.printCancel
	ld de, ListMenuCancelText
	call PlaceString
	jp UpdateBattleBagDescription

PrintBattleBagCancelOrDownArrow:
	ld a, [wListCount]
	ld b, a
	ld a, [wListScrollOffset]
	ld c, a
	ld a, b
	sub c
	cp 4
	jr nc, .downArrow
	; A = visible Cancel row.
	ld bc, 2 * SCREEN_WIDTH
	coord hl, 6, 3
	call AddNTimes
	ld de, ListMenuCancelText
	jp PlaceString
.downArrow
	coord hl, 18, 10
	ld a, "▼"
	ld [hl], a
	ret

LoadBagPocketTitleTiles:
	; START Bag alone owns the pre-rendered BG title graphics. Battle titles are
	; font sprites and therefore never borrow EXP/font tile VRAM.
	call LoadBagPocketTitleSpan
	ld a, [wBagPocketCurrent]
	add a
	ld e, a
	ld d, 0
	ld hl, BagPocketTitleGfxPointers
	add hl, de
	ld a, [hli]
	ld e, a
	ld d, [hl]

	ld a, [wBagPocketTitleSpanWidth]
	cp BAG_POCKET_TITLE_WIDTH_TILES
	jr z, .uploadWide
	ld a, 1
	push af
	ld hl, vChars1 + $500 ; short set: tiles $D0-$DB maximum
	jr .haveDestination
.uploadWide
	xor a
	push af
	ld hl, vChars1 + $400 ; wide set: tiles $C0-$CF
.haveDestination
	ld b, BANK(BagPocketTitleItemGfx)
	ld a, [wBagPocketTitleSpanWidth]
	add a
	ld c, a
	call CopyVideoDataDoubleStartMenu
	pop af
	ld [wBagPocketTitleVRAMSet], a
	ret

LoadBagPocketTitleSpan:
	ld a, [wBagPocketCurrent]
	add a
	ld e, a
	ld d, 0
	ld hl, BagPocketTitleSpans
	add hl, de
	ld a, [hli]
	ld [wBagPocketTitleSpanLeft], a
	ld a, [hl]
	ld [wBagPocketTitleSpanWidth], a
	ret

UpdateBagPocketDescription::
	ld a, [wBagPocketActive]
	cp BAG_POCKET_MODE_BATTLE
	jp z, UpdateBattleBagDescription
	; Resolve the item under the Pocket-local cursor. Cancel and empty Pockets use
	; $ff so the existing empty two-line description remains unchanged.
	ld a, [wCurrentMenuItem]
	ld c, a
	ld a, [wListScrollOffset]
	add c
	ld [wFilteredBagItems + BAG_POCKET_RESOLVER_INDEX_OFFSET], a
	ld b, a
	call GetCurrentBagPocketCount
	cp b
	jr z, .cancel
	jr c, .cancel
	call ResolveCurrentBagPocketEntry
	ld a, [wFilteredBagItems + BAG_POCKET_RESOLVED_ITEM_OFFSET]
	jr .haveItem
.cancel
	ld a, $ff
.haveItem
	ld hl, wFilteredBagItems + BAG_POCKET_DESCRIPTION_CACHE_OFFSET
	cp [hl]
	ret z
	ld [hl], a

	; Keep the old description hidden while replacing it. The Mart short
	; descriptions only use the two dialogue text rows (y=14 and y=16), so clear
	; only those 36 tiles instead of rebuilding the whole MESSAGE_BOX.
	ld a, [H_AUTOBGTRANSFERENABLED]
	push af
	xor a
	ld [H_AUTOBGTRANSFERENABLED], a
	coord hl, 1, 14
	ld b, 1
	ld c, 18
	call ClearScreenArea
	coord hl, 1, 16
	ld b, 1
	ld c, 18
	call ClearScreenArea

	; Reuse the Pokemart's compact two-line description pointer table. Pointer
	; arithmetic itself is bank-independent; the tiny bank-$15 helper switches
	; to the table's bank before PrintText_NoCreatingTextBox reads it.
	ld a, [wFilteredBagItems + BAG_POCKET_DESCRIPTION_CACHE_OFFSET]
	cp $ff
	ld de, EmptyDescription
	jr z, .printDescription
	dec a
	cp HM_01 - 1
	jr c, .descriptionIndexReady
	sub ((HM_01 - GO_HOME) - 1)
.descriptionIndexReady
	ld hl, ItemDescriptionPointers_Mart
	ld bc, 5
.findDescriptionPointer
	and a
	jr z, .descriptionPointerReady
	dec a
	add hl, bc
	jr .findDescriptionPointer
.descriptionPointerReady
	ld d, h
	ld e, l
.printDescription
	callab PrintBagItemDescriptionText
	pop af
	ld [H_AUTOBGTRANSFERENABLED], a
	ret

UpdateBattleBagDescription:
	call EnsureBattleBagPageCache
	ld a, [wCurrentMenuItem]
	ld c, a
	ld a, [wListScrollOffset]
	add c
	ld c, a
	ld a, [wListCount]
	cp c
	jr z, .cancel
	jr c, .cancel

	ld a, [wCurrentMenuItem]
	ld e, a
	ld d, 0
	ld hl, wBattleBagVisibleSlots
	add hl, de
	ld a, [hl]
	cp $ff
	jr z, .cancel
	call GetBagItemAtRealSlot
	jr .haveItem
.cancel
	ld a, $ff
.haveItem
	ld hl, wBattleBagDescriptionCache
	cp [hl]
	ret z
	ld [hl], a
	push af
	ld a, [H_AUTOBGTRANSFERENABLED]
	push af
	xor a
	ld [H_AUTOBGTRANSFERENABLED], a
	coord hl, 1, 14
	ld b, 1
	ld c, 18
	call ClearScreenArea
	coord hl, 1, 16
	ld b, 1
	ld c, 18
	call ClearScreenArea
	pop bc
	pop af
	cp $ff
	ld de, EmptyDescription
	jr z, .printDescription
	dec a
	cp HM_01 - 1
	jr c, .descriptionIndexReady
	sub ((HM_01 - GO_HOME) - 1)
.descriptionIndexReady
	ld hl, ItemDescriptionPointers_Mart
	ld de, 5
.findDescriptionPointer
	and a
	jr z, .descriptionPointerReady
	dec a
	add hl, de
	jr .findDescriptionPointer
.descriptionPointerReady
	ld d, h
	ld e, l
.printDescription
	push bc
	callab PrintBagItemDescriptionText
	pop bc
	ld a, b
	ld [H_AUTOBGTRANSFERENABLED], a
	ret

; Tilemap left column (inside the centered 64px canvas), followed by the packed
; row width. These values are unchanged from BAGTITLE-011.
BagPocketTitleSpans:
	db 2, 4 ; ITEM
	db 2, 4 ; BALL
	db 0, 8 ; MACHINE
	db 1, 6 ; BERRY
	db 0, 8 ; KEY ITEM

BagPocketTitleGfxPointers:
	dw BagPocketTitleItemGfx
	dw BagPocketTitleBallGfx
	dw BagPocketTitleMachineGfx
	dw BagPocketTitleBerryGfx
	dw BagPocketTitleKeyItemGfx

; Pre-rendered 1bpp title tiles generated from the project's existing
; gfx/font.png glyphs using BAGTITLE-011's exact anchors and y placement.
; CopyVideoDataDoubleStartMenu expands these to 2bpp while uploading to VRAM.
BagPocketTitleItemGfx:
	db $00, $00, $00, $7d, $10, $10, $10, $10
	db $00, $00, $00, $fd, $21, $21, $21, $21
	db $00, $00, $00, $fd, $01, $01, $f9, $01
	db $00, $00, $00, $04, $8c, $54, $24, $04
	db $10, $7c, $00, $00, $00, $00, $00, $00
	db $21, $21, $00, $00, $00, $00, $00, $00
	db $01, $fd, $00, $00, $00, $00, $00, $00
	db $04, $04, $00, $00, $00, $00, $00, $00

BagPocketTitleBallGfx:
	db $00, $00, $00, $f8, $84, $84, $fc, $82
	db $00, $00, $00, $10, $28, $28, $44, $7c
	db $00, $00, $00, $80, $80, $80, $80, $80
	db $00, $00, $00, $80, $80, $80, $80, $80
	db $82, $fc, $00, $00, $00, $00, $00, $00
	db $82, $82, $00, $00, $00, $00, $00, $00
	db $80, $fe, $00, $00, $00, $00, $00, $00
	db $80, $fe, $00, $00, $00, $00, $00, $00

BagPocketTitleMachineGfx:
	db $00, $00, $00, $04, $06, $05, $04, $04
	db $00, $00, $00, $10, $31, $51, $92, $13
	db $00, $00, $00, $81, $42, $44, $24, $e4
	db $00, $00, $00, $e4, $14, $04, $07, $04
	db $00, $00, $00, $17, $11, $11, $f1, $11
	db $00, $00, $00, $d0, $18, $14, $12, $11
	db $00, $00, $00, $5f, $50, $50, $5f, $50
	db $00, $00, $00, $c0, $00, $00, $80, $00
	db $04, $04, $00, $00, $00, $00, $00, $00
	db $14, $14, $00, $00, $00, $00, $00, $00
	db $12, $11, $00, $00, $00, $00, $00, $00
	db $14, $e4, $00, $00, $00, $00, $00, $00
	db $11, $17, $00, $00, $00, $00, $00, $00
	db $10, $d0, $00, $00, $00, $00, $00, $00
	db $d0, $5f, $00, $00, $00, $00, $00, $00
	db $00, $c0, $00, $00, $00, $00, $00, $00

BagPocketTitleBerryGfx:
	db $00, $00, $00, $0f, $08, $08, $0f, $08
	db $00, $00, $00, $8f, $48, $48, $cf, $28
	db $00, $00, $00, $ef, $08, $08, $cf, $08
	db $00, $00, $00, $cf, $28, $28, $cf, $88
	db $00, $00, $00, $c8, $24, $22, $c1, $81
	db $00, $00, $00, $20, $40, $80, $00, $00
	db $08, $0f, $00, $00, $00, $00, $00, $00
	db $28, $cf, $00, $00, $00, $00, $00, $00
	db $08, $e8, $00, $00, $00, $00, $00, $00
	db $48, $28, $00, $00, $00, $00, $00, $00
	db $41, $21, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00

BagPocketTitleKeyItemGfx:
	db $00, $00, $00, $08, $08, $09, $0b, $0c
	db $00, $00, $00, $4f, $88, $08, $0f, $88
	db $00, $00, $00, $e8, $04, $02, $c1, $01
	db $00, $00, $00, $21, $40, $80, $00, $00
	db $00, $00, $00, $f7, $40, $40, $40, $40
	db $00, $00, $00, $f7, $84, $84, $87, $84
	db $00, $00, $00, $f4, $06, $05, $e4, $04
	db $00, $00, $00, $10, $30, $50, $90, $10
	db $08, $08, $00, $00, $00, $00, $00, $00
	db $48, $2f, $00, $00, $00, $00, $00, $00
	db $01, $e1, $00, $00, $00, $00, $00, $00
	db $00, $01, $00, $00, $00, $00, $00, $00
	db $40, $f0, $00, $00, $00, $00, $00, $00
	db $84, $87, $00, $00, $00, $00, $00, $00
	db $04, $f4, $00, $00, $00, $00, $00, $00
	db $10, $10, $00, $00, $00, $00, $00, $00
