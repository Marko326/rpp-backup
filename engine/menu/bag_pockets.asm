; Categorized player Bag runtime. This entire file lives in ROMX bank $35.
; The real inventory remains wNumBagItems/wBagItems. The visible Pocket list is
; a conventional ITEMLISTMENU list, so Home only needs tiny input/header hooks.

BAG_POCKET_TITLE_WIDTH_TILES EQU 8
BAG_POCKET_TITLE_HEIGHT_TILES EQU 2
BAG_POCKET_TITLE_TILE_COUNT EQU BAG_POCKET_TITLE_WIDTH_TILES * BAG_POCKET_TITLE_HEIGHT_TILES
BAG_POCKET_TITLE_BUFFER_BYTES EQU BAG_POCKET_TITLE_TILE_COUNT * 8
BAG_POCKET_TITLE_VRAM_SET0 EQU $c0
BAG_POCKET_TITLE_VRAM_SET1 EQU $d0

; The top border occupies screen y=0..7 and the first item text begins at
; y=24. That leaves a 16-pixel title area (y=8..23). The stock uppercase
; FontGraphics glyphs are 7 pixels high, so BASE_Y=4 is the upper of the two
; possible centered positions. BAGTITLE-004 keeps that result nudged up one pixel,
; placing title ink at screen y=11..17. Change only Y_NUDGE for later tuning.
BAG_POCKET_TITLE_BASE_Y EQU 4
BAG_POCKET_TITLE_Y_NUDGE EQU -1
BAG_POCKET_TITLE_Y EQU BAG_POCKET_TITLE_BASE_Y + BAG_POCKET_TITLE_Y_NUDGE

BAG_POCKET_TITLE_END EQU $00

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
	; Load only the current Pocket title graphics. BAGTITLE-011 keeps wide and
	; short titles in separate safe VRAM ranges; vertical list movement still does
	; no title VRAM work.
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
	; BAGTITLE-011 keeps BAGTITLE-004's centered 64x16 presentation, but short
	; singular titles use only the tile columns they actually
	; occupy. Clear the whole canvas first so switching from a wide title cannot
	; leave stale tile IDs at either side.
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
	ld c, a ; bottom row starts immediately after the packed top row

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

LoadBagPocketTitleTiles:
	; Singular titles are rendered directly into a packed two-row buffer. ITEM and
	; BALL use 4 columns (8 tiles total), BERRY uses 6 columns (12 tiles), while
	; MACHINE and KEY ITEM retain the full 8 columns (16 tiles). This preserves
	; BAGTITLE-004's pixel placement without uploading guaranteed-empty side tiles.
	call LoadBagPocketTitleSpan
	call ClearBagPocketTitleBuffer
	ld a, [wBagPocketCurrent]
	add a
	ld e, a
	ld d, 0
	ld hl, BagPocketTitleLayouts
	add hl, de
	ld a, [hli]
	ld h, [hl]
	ld l, a
.drawGlyph
	ld a, [hli]
	cp BAG_POCKET_TITLE_END
	jr z, .upload
	ld c, [hl]
	inc hl
	push hl
	call BlitBagPocketTitleGlyph
	pop hl
	jr .drawGlyph

.upload
	; Keep the full-width titles in $C0-$CF and all short titles in $D0-$DB.
	; This deliberately never touches $DF, the project's [SHINY] font tile.
	; MACHINE and KEY ITEM are not adjacent Pockets, so the 16-tile wide buffer is
	; never rewritten while it is visible. ITEM and BALL can switch directly while
	; sharing the short buffer, but all eight referenced tiles are replaced within
	; one VBlank; BERRY also fits the copier's 12-tile single-VBlank budget.
	ld a, [wBagPocketTitleSpanWidth]
	cp BAG_POCKET_TITLE_WIDTH_TILES
	jr z, .uploadWide
	ld a, 1
	push af
	ld hl, vChars1 + $500 ; short set: tiles $D0-$DB maximum
	jr .haveUploadDestination
.uploadWide
	xor a
	push af
	ld hl, vChars1 + $400 ; wide set: tiles $C0-$CF
.haveUploadDestination
	ld de, wFilteredBagItems
	ld b, BANK(FontGraphics)
	ld a, [wBagPocketTitleSpanWidth]
	add a ; top row + bottom row
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
	add a
	add a
	add a
	ld [wBagPocketTitleRowBytes], a
	ret

ClearBagPocketTitleBuffer:
	ld hl, wFilteredBagItems
	ld a, [wBagPocketTitleRowBytes]
	add a ; two packed tile rows
	ld b, a
	xor a
.loop
	ld [hli], a
	dec b
	jr nz, .loop
	ret

; INPUT: A = normal font character code ($80="A" .. $99="Z")
; Copies the corresponding project-owned gfx/font.png tile to eight scratch bytes
; directly after the 128-byte temporary title canvas. Both areas live inside
; wFilteredBagItems and are overwritten by BuildCurrentBagPocket immediately after
; the title upload, so they consume no additional persistent WRAM.
LoadBagPocketTitleGlyph:
	sub "A"
	ld hl, FontGraphics
	ld bc, 8
	call AddNTimes
	ld de, wFilteredBagItems + BAG_POCKET_TITLE_BUFFER_BYTES
	ld bc, 8
	ld a, BANK(FontGraphics)
	jp FarCopyData

; INPUT: A = normal font character code, C = x-pixel anchor in the 64px canvas.
; The source is the original 8x8 FontGraphics tile. Its seven ink rows are placed
; at BAG_POCKET_TITLE_Y in one complete 64x16 tile buffer. Rendering once instead
; of four separate segments removes both repeated FarCopyData work and the old
; left/right carry reconstruction.
BlitBagPocketTitleGlyph:
	ld b, a ; preserve font character while calculating x destination

	ld a, c
	and 7
	ld [wMoveDexSmallFontShift], a
	ld d, a
	ld a, 8
	sub d
	ld [wMoveDexSmallFontLeftShift], a

	; x & $38 selects one of the eight top-row destination tiles.
	ld a, c
	and $38
	ld hl, wFilteredBagItems
	add l
	ld l, a
	jr nc, .destTileReady
	inc h
.destTileReady
	push hl
	ld a, b
	call LoadBagPocketTitleGlyph
	pop hl

	ld de, wFilteredBagItems + BAG_POCKET_TITLE_BUFFER_BYTES
	ld b, 7
	ld c, BAG_POCKET_TITLE_Y
.rowLoop
	ld a, [de]
	push bc
	push de
	push hl
	push af

	; Convert absolute title y to a byte in the top or bottom packed tile row.
	ld a, c
	cp 8
	jr c, .topTileRow
	ld a, [wBagPocketTitleRowBytes]
	add l
	ld l, a
	jr nc, .verticalTileRowReady
	inc h
.verticalTileRowReady
	ld a, c
	and 7
	jr .addScanline
.topTileRow
	and 7
.addScanline
	add l
	ld l, a
	jr nc, .destRowReady
	inc h
.destRowReady

	pop af
	ld b, a
	ld a, [wMoveDexSmallFontShift]
	and a
	jr z, .aligned

	; Current tile = glyph >> shift.
	push bc
	ld c, a
	ld a, b
.rightShift
	srl a
	dec c
	jr nz, .rightShift
	or [hl]
	ld [hl], a
	pop bc

	; Next tile = glyph << (8-shift). Uppercase FontGraphics keeps column 7
	; blank, so each packed layout can end safely at its declared tile span.
	push bc
	ld a, [wMoveDexSmallFontLeftShift]
	ld c, a
	ld a, b
.leftShift
	sla a
	dec c
	jr nz, .leftShift
	pop bc
	and a
	jr z, .rowDrawn
	push hl
	push de
	ld de, 8
	add hl, de
	pop de
	or [hl]
	ld [hl], a
	pop hl
	jr .rowDrawn

.aligned
	ld a, b
	or [hl]
	ld [hl], a
.rowDrawn
	pop hl
	pop de
	pop bc
	inc de
	inc c
	dec b
	jr nz, .rowLoop
	ret

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

; Per-Pocket layout data. Every pair is: project font character, local x anchor.
; BAGTITLE-011 keeps BAGTITLE-004's project FontGraphics and one visible blank
; pixel between letters, but removes the plural endings requested for the Bag.
BagPocketTitleLayouts:
	dw BagPocketTitleItem
	dw BagPocketTitleBall
	dw BagPocketTitleMachine
	dw BagPocketTitleBerry
	dw BagPocketTitleKeyItem

; Tilemap left column (inside the 64px canvas), followed by packed row width.
; The layouts below subtract left*8 from their old absolute x anchors, so their
; on-screen pixel positions remain centered while short titles upload fewer tiles.
BagPocketTitleSpans:
	db 2, 4 ; ITEM:    canvas x=16..47, visible ink x=17..45
	db 2, 4 ; BALL:    canvas x=16..47, visible ink x=16..46
	db 0, 8 ; MACHINE: full natural-width title
	db 1, 6 ; BERRY:   canvas x=8..55,  visible ink x=12..50
	db 0, 8 ; KEY ITEM: centered with the original four-pixel word gap

; Ordinary -> ordinary: +8 anchor pixels = 7px ink + 1px blank.
; I -> ordinary: +7 because I ink is five pixels wide at anchor+1..+5.
; Ordinary -> I: +7 because I itself begins one pixel to the right of its anchor.
BagPocketTitleItem:
	db "I", 0
	db "T", 7
	db "E", 15
	db "M", 23
	db BAG_POCKET_TITLE_END

BagPocketTitleBall:
	db "B", 0
	db "A", 8
	db "L", 16
	db "L", 24
	db BAG_POCKET_TITLE_END

BagPocketTitleMachine:
	db "M", 5
	db "A", 13
	db "C", 21
	db "H", 29
	db "I", 36
	db "N", 43
	db "E", 51
	db BAG_POCKET_TITLE_END

BagPocketTitleBerry:
	db "B", 4
	db "E", 12
	db "R", 20
	db "R", 28
	db "Y", 36
	db BAG_POCKET_TITLE_END

; KEY ITEM is 56 visible pixels wide when BAGTITLE-004's spacing is preserved.
; Centering it in 64px leaves four blank pixels on each side; the visible gap
; between Y and I remains four pixels.
BagPocketTitleKeyItem:
	db "K", 4
	db "E", 12
	db "Y", 20
	db "I", 30
	db "T", 37
	db "E", 45
	db "M", 53
	db BAG_POCKET_TITLE_END
