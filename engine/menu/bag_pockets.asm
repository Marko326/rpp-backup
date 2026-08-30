; Categorized player Bag runtime. This entire file lives in ROMX bank $35.
; The real inventory remains wNumBagItems/wBagItems. The visible Pocket list is
; a conventional ITEMLISTMENU list, so Home only needs tiny input/header hooks.

BAG_POCKET_TITLE_TILE_COUNT EQU 6
BAG_POCKET_TITLE_BYTES EQU BAG_POCKET_TITLE_TILE_COUNT * 8
BAG_POCKET_TITLE_VRAM_TILE EQU $c0

PrepareBagPocketMenu::
	; Persistent state uses ten bytes that were already reserved as unused game
	; progress WRAM. Magic bytes make old saves initialize deterministically.
	ld a, [wBagPocketStateMagic1]
	cp $b6
	jr nz, .initializeState
	ld a, [wBagPocketStateMagic2]
	cp $47
	jr z, .stateReady
.initializeState
	xor a
	ld hl, wBagPocketCurrent
	ld b, 8 ; current + five saved positions + two work bytes
.clearStateLoop
	ld [hli], a
	dec b
	jr nz, .clearStateLoop
	ld a, $b6
	ld [wBagPocketStateMagic1], a
	ld a, $47
	ld [wBagPocketStateMagic2], a
.stateReady
	ld a, [wBagPocketCurrent]
	cp NUM_BAG_POCKETS
	jr c, .validPocket
	xor a
	ld [wBagPocketCurrent], a
.validPocket
	ld a, 1
	ld [wBagPocketActive], a
	; Load only the current 6-tile MoveDex-style Pocket title. This costs one
	; VBlank on Bag entry, while vertical list movement does no title VRAM work.
	call LoadBagPocketTitleTiles
	call BuildCurrentBagPocket
	call LoadCurrentBagPocketCursor
	; Work byte 1 doubles as a one-session layout-initialized flag after the
	; filtered list has been built. Work byte 2 caches the item whose short
	; description is currently displayed.
	xor a
	ld [wBagPocketWorkByte1], a
	ld a, $fe
	ld [wBagPocketWorkByte2], a
	ld hl, wFilteredBagItems
	ld a, l
	ld [wListPointer], a
	ld a, h
	ld [wListPointer + 1], a
	ret

SwitchBagPocket::
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
	; Left/Right changes the title graphics once; Up/Down never reloads them.
	call LoadBagPocketTitleTiles
	call BuildCurrentBagPocket
	call LoadCurrentBagPocketCursor
	ld hl, wFilteredBagItems
	ld a, l
	ld [wListPointer], a
	ld a, h
	ld [wListPointer + 1], a
	ld a, [wFilteredBagItems]
	ld [wListCount], a
	cp 2
	ld a, 1
	jr c, .storeMaxMenuItem
	inc a
.storeMaxMenuItem
	ld [wMaxMenuItem], a
	xor a
	ld [wMenuItemToSwap], a
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

LoadCurrentBagPocketCursor:
	ld a, [wFilteredBagItems]
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
	; Convert the filtered-list selection back to a real wBagItems slot before
	; any item-use/toss code sees wWhichPokemon. Also reproduce the original
	; DisplayListMenuID carry result for the caller.
	ld a, [wBagPocketActive]
	and a
	jr z, .returnMenuResult
	call SaveCurrentBagPocketCursor
	ld a, [wMenuExitMethod]
	cp CHOSE_MENU_ITEM
	jr nz, .cancelled
	call ResolveBagPocketSelection
	xor a
	ld [wBagPocketActive], a
	and a
	ret
.cancelled
	xor a
	ld [wBagPocketActive], a
	scf
	ret
.returnMenuResult
	ld a, [wMenuExitMethod]
	cp CHOSE_MENU_ITEM
	jr z, .chosen
	scf
	ret
.chosen
	and a
	ret

ResolveBagPocketSelection:
	; The visible Pocket list contains normal item/quantity pairs. To recover the
	; physical Bag slot robustly when duplicate item IDs occupy multiple slots,
	; count how many copies of this same item precede the selected Pocket entry,
	; then select the matching occurrence in the real Bag.
	ld a, [wWhichPokemon]
	ld [wBagPocketWorkByte1], a ; selected Pocket index
	xor a
	ld [wBagPocketWorkByte2], a ; preceding occurrence count
	ld hl, wFilteredBagItems + 1
	ld a, [wBagPocketWorkByte1]
	ld b, a
.countPreceding
	ld a, b
	and a
	jr z, .scanRealBag
	ld a, [hli]
	ld c, a
	inc hl ; skip quantity
	ld a, [wcf91]
	cp c
	jr nz, .nextPocketEntry
	ld a, [wBagPocketWorkByte2]
	inc a
	ld [wBagPocketWorkByte2], a
.nextPocketEntry
	dec b
	jr .countPreceding

.scanRealBag
	ld a, [wBagPocketWorkByte2]
	ld c, a
	ld hl, wBagItems
	ld a, [wNumBagItems]
	ld b, a
	xor a
	ld [wBagPocketWorkByte1], a ; real Bag slot index
.realLoop
	ld a, b
	and a
	ret z ; defensive fallback: leave the filtered index unchanged
	ld a, [hli]
	ld d, a
	ld a, [wcf91]
	cp d
	jr nz, .nextRealEntry
	ld a, c
	and a
	jr z, .foundRealEntry
	dec c
.nextRealEntry
	inc hl ; skip quantity
	ld a, [wBagPocketWorkByte1]
	inc a
	ld [wBagPocketWorkByte1], a
	dec b
	jr .realLoop
.foundRealEntry
	ld a, [wBagPocketWorkByte1]
	ld [wWhichPokemon], a
	ret

BuildCurrentBagPocket:
	xor a
	ld [wFilteredBagItems], a
	ld a, [wBagPocketCurrent]
	cp BAG_POCKET_TM_HM
	jr z, BuildTMHMPocket

	ld hl, wBagItems
	ld a, [wNumBagItems]
	ld b, a
.scanBag
	ld a, b
	and a
	jr z, FinishBagPocketList
	ld a, [hli]
	ld [wcf91], a
	call DoesItemBelongInCurrentPocket
	jr nc, .skipItem
	call AppendCurrentBagEntry
.skipItem
	inc hl ; quantity -> next item
	dec b
	jr .scanBag

BuildTMHMPocket:
	; Fixed display order regardless of acquisition/physical Bag order.
	ld a, TM_01
.tmLoop
	push af
	call AppendAllBagSlotsMatchingItem
	pop af
	inc a
	cp TM_50 + 1
	jr c, .tmLoop
	ld a, HM_01
.hmLoop
	push af
	call AppendAllBagSlotsMatchingItem
	pop af
	inc a
	cp HM_05 + 1
	jr c, .hmLoop
	jr FinishBagPocketList

AppendAllBagSlotsMatchingItem:
	ld [wBagPocketWorkByte1], a ; target item ID
	ld hl, wBagItems
	ld a, [wNumBagItems]
	ld b, a
.loop
	ld a, b
	and a
	ret z
	ld a, [hli]
	ld c, a
	ld a, [wBagPocketWorkByte1]
	cp c
	jr nz, .next
	ld a, c
	ld [wcf91], a
	call AppendCurrentBagEntry
.next
	inc hl ; quantity -> next item
	dec b
	jr .loop

AppendCurrentBagEntry:
	; INPUT: [wcf91] = item ID, hl = source quantity byte in wBagItems.
	ld a, [hl]
	ld e, a
	push bc
	push hl
	ld a, [wFilteredBagItems]
	ld c, a
	ld b, 0
	sla c
	rl b
	ld hl, wFilteredBagItems + 1
	add hl, bc
	ld a, [wcf91]
	ld [hli], a
	ld a, e
	ld [hl], a
	ld hl, wFilteredBagItems
	inc [hl]
	pop hl
	pop bc
	ret

FinishBagPocketList:
	ld a, [wFilteredBagItems]
	ld c, a
	ld b, 0
	sla c
	rl b
	ld hl, wFilteredBagItems + 1
	add hl, bc
	ld [hl], $ff
	ret

DoesItemBelongInCurrentPocket:
	ld a, [wBagPocketCurrent]
	cp BAG_POCKET_ITEMS
	jr z, .items
	cp BAG_POCKET_BALLS
	jr z, .balls
	cp BAG_POCKET_BERRIES
	jr z, .berries
	; KEY ITEMS: use the project's existing definition after higher-priority
	; categories have been excluded.
.keyItems
	ld a, [wcf91]
	call IsBagPocketMachine
	jr c, .no
	ld a, [wcf91]
	call IsBagPocketBall
	jr c, .no
	ld a, [wcf91]
	call IsBagPocketBerry
	jr c, .no
	call IsKeyItem
	ld a, [wIsKeyItem]
	and a
	jr z, .no
	scf
	ret
.balls
	ld a, [wcf91]
	jp IsBagPocketBall
.berries
	ld a, [wcf91]
	jp IsBagPocketBerry
.items
	ld a, [wcf91]
	call IsBagPocketMachine
	jr c, .no
	ld a, [wcf91]
	call IsBagPocketBall
	jr c, .no
	ld a, [wcf91]
	call IsBagPocketBerry
	jr c, .no
	call IsKeyItem
	ld a, [wIsKeyItem]
	and a
	jr nz, .no
	scf
	ret
.no
	and a
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
	; The stock LIST_MENU_BOX is 4,2 -> 19,12. The categorized Bag keeps its
	; taller 12-row layout but moves that whole custom window up one more row,
	; giving 4,0 -> 19,11. Row 12 is therefore free for the unmodified global
	; MESSAGE_BOX (0,12 -> 19,17), so the two borders no longer overlap.
	; The layout is drawn once per Bag session, not on cursor movement.
	ld a, [wBagPocketWorkByte1]
	and a
	jr nz, .layoutReady
	inc a
	ld [wBagPocketWorkByte1], a
	coord hl, 4, 0
	ld b, 10
	ld c, 14
	call TextBoxBorder
	ld a, MESSAGE_BOX
	ld [wTextBoxID], a
	call DisplayTextBoxID
.layoutReady
	; The larger proportional title is a centered 48x8 strip occupying six tiles.
	; Its pixels are loaded only on Bag entry / Left / Right; redraws merely put
	; the same six tile IDs back into the title row, so Up/Down stays lightweight.
	coord hl, 9, 1
	ld a, BAG_POCKET_TITLE_VRAM_TILE
	ld b, BAG_POCKET_TITLE_TILE_COUNT
.drawTitleTiles
	ld [hli], a
	inc a
	dec b
	jr nz, .drawTitleTiles
	ret

LoadBagPocketTitleTiles:
	; Each Pocket owns one 48x8 row (6 consecutive 1bpp tiles) in the source
	; graphic. Copy only the selected row into the unused English-font VRAM slots
	; $C0-$C5. Those tile IDs are Japanese glyph slots and do not collide with
	; normal English item names or the compact item descriptions.
	ld a, [wBagPocketCurrent]
	ld hl, BagPocketTitleGraphics
	ld bc, BAG_POCKET_TITLE_BYTES
	call AddNTimes
	ld d, h
	ld e, l
	ld hl, vChars1 + $400 ; tile $C0
	lb bc, BANK(BagPocketTitleGraphics), BAG_POCKET_TITLE_TILE_COUNT
	jp CopyVideoDataDouble

UpdateBagPocketDescription::
	; Determine the item under the cursor in the filtered pair list. Cancel (or
	; an empty Pocket) uses $ff and therefore the existing empty description.
	ld a, [wCurrentMenuItem]
	ld c, a
	ld a, [wListScrollOffset]
	add c
	ld c, a
	ld a, [wFilteredBagItems]
	cp c
	jr z, .cancel
	jr c, .cancel
	ld a, c
	add a
	ld c, a
	ld b, 0
	ld hl, wFilteredBagItems + 1
	add hl, bc
	ld a, [hl]
	jr .haveItem
.cancel
	ld a, $ff
.haveItem
	; Do no tile work at all if the newly selected entry has the same
	; description as the one already displayed. This also makes duplicate item
	; slots essentially free to move between.
	ld hl, wBagPocketWorkByte2
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
	ld a, [wBagPocketWorkByte2]
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

; Five 48x8 title strips use a larger 5x7 proportional uppercase style.
; They keep the existing six-tile title loader, so only the graphics change;
; vertical Bag movement still performs no title VRAM upload.
BagPocketTitleGraphics:
	INCBIN "gfx/movedex/bag_pocket_titles.1bpp"
BagPocketTitleGraphicsEnd:
