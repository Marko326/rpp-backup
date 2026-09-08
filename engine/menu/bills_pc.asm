DisplayPCMainMenu::
	xor a
	ld [H_AUTOBGTRANSFERENABLED], a
	call SaveScreenTilesToBuffer2
	ld a, [wNumHoFTeams]
	and a
	jr nz, .leaguePCAvailable
	CheckEvent EVENT_GOT_POKEDEX
	jr z, .noOaksPC
	ld a, [wNumHoFTeams]
	and a
	jr nz, .leaguePCAvailable
	coord hl, 0, 0
	ld b, 8
	ld c, 14
	jr .next
.noOaksPC
	coord hl, 0, 0
	ld b, 6
	ld c, 14
	jr .next
.leaguePCAvailable
	coord hl, 0, 0
	ld b, 10
	ld c, 14
.next
	call TextBoxBorder
	call UpdateSprites
	ld a, 3
	ld [wMaxMenuItem], a
	CheckEvent EVENT_MET_BILL
	jr nz, .metBill
	coord hl, 2, 2
	ld de, SomeonesPCText
	jr .next2
.metBill
	coord hl, 2, 2
	ld de, BillsPCText
.next2
	call PlaceString
	coord hl, 2, 4
	ld de, wPlayerName
	call PlaceString
	ld l, c
	ld h, b
	ld de, PlayersPCText
	call PlaceString
	CheckEvent EVENT_GOT_POKEDEX
	jr z, .noOaksPC2
	coord hl, 2, 6
	ld de, OaksPCText
	call PlaceString
	ld a, [wNumHoFTeams]
	and a
	jr z, .noLeaguePC
	ld a, 4
	ld [wMaxMenuItem], a
	coord hl, 2, 8
	ld de, PKMNLeaguePCText
	call PlaceString
	coord hl, 2, 10
	ld de, LogOffPCText
	jr .next3
.noLeaguePC
	coord hl, 2, 8
	ld de, LogOffPCText
	jr .next3
.noOaksPC2
	ld a, $2
	ld [wMaxMenuItem], a
	coord hl, 2, 6
	ld de, LogOffPCText
.next3
	call PlaceString
	ld a, A_BUTTON | B_BUTTON
	ld [wMenuWatchedKeys], a
	ld a, 2
	ld [wTopMenuItemY], a
	ld a, 1
	ld [wTopMenuItemX], a
	xor a
	ld [wCurrentMenuItem], a
	ld [wLastMenuItem], a
	ld a, 1
	ld [H_AUTOBGTRANSFERENABLED], a
	ret

SomeonesPCText:   db "Someone's PC@"
BillsPCText:      db "Bill's PC@"
PlayersPCText:    db "'s PC@"
OaksPCText:       db "Prof. Oak's PC@"
PKMNLeaguePCText: db $4a, "League@"
LogOffPCText:     db "Log off@"

BillsPC_::
	ld hl, wd730
	set 6, [hl]
	xor a
	ld [wParentMenuItem], a
	inc a               ; MONSTER_NAME
	ld [wNameListType], a
	call LoadHpBarAndStatusTilePatterns
	ld a, [wListScrollOffset]
	push af
	ld a, [wFlags_0xcd60]
	bit 3, a ; accessing Bill's PC through another PC?
	jr nz, BillsPCMenu
; accessing it directly
	ld a, $99
	call PlaySound
	ld hl, SwitchOnText
	call PrintText

BillsPCMenu:
	ld a, [wParentMenuItem]
	ld [wCurrentMenuItem], a
	ld hl, vChars2 + $780
	ld de, PokeballTileGraphics
	lb bc, BANK(PokeballTileGraphics), $01
	call CopyVideoData
	call LoadScreenTilesFromBuffer2DisableBGTransfer
	coord hl, 0, 0
	ld b, 10
	ld c, 12
	call TextBoxBorder
	coord hl, 2, 2
	ld de, BillsPCMenuText
	call PlaceString
	ld hl, wTopMenuItemY
	ld a, 2
	ld [hli], a ; wTopMenuItemY
	dec a
	ld [hli], a ; wTopMenuItemX
	inc hl
	inc hl
	ld a, 4
	ld [hli], a ; wMaxMenuItem
	ld a, A_BUTTON | B_BUTTON
	ld [hli], a ; wMenuWatchedKeys
	xor a
	ld [hli], a ; wLastMenuItem
	ld [hli], a ; wPartyAndBillsPCSavedMenuItem
	ld hl, wListScrollOffset
	ld [hli], a ; wListScrollOffset
	ld [hl], a ; wMenuWatchMovingOutOfBounds
	ld [wPlayerMonNumber], a
	ld hl, WhatText
	call PrintText
	coord hl, 9, 14
	ld b, 2
	ld c, 9
	call TextBoxBorder
	ld a, [wCurrentBoxNum]
	and $7f
	cp 9
	jr c, .singleDigitBoxNum
; two digit box num
	sub 9
	coord hl, 17, 16
	ld [hl], "1"
	add "0"
	jr .next
.singleDigitBoxNum
	add "1"
.next
	Coorda 18, 16
	coord hl, 10, 16
	ld de, BoxNoPCText
	call PlaceString
	ld a, 1
	ld [H_AUTOBGTRANSFERENABLED], a
	call Delay3
	call HandleMenuInput
	bit 1, a
	jr nz, ExitBillsPC ; b button
	call PlaceUnfilledArrowMenuCursor
	ld a, [wCurrentMenuItem]
	ld [wParentMenuItem], a
	and a
	jp z, BillsPCWithdraw ; withdraw
	cp $1
	jr z, BillsPCDeposit ; deposit
	cp $2
	jp z, BillsPCRelease ; release
	cp $3
	jp z, BillsPCChangeBox ; change box

ExitBillsPC:
	ld a, [wFlags_0xcd60]
	bit 3, a ; accessing Bill's PC through another PC?
	jr nz, .next
; accessing it directly
	call LoadTextBoxTilePatterns
	ld a, $9a
	call PlaySound
	call WaitForSoundToFinish
.next
	ld hl, wFlags_0xcd60
	res 5, [hl]
	call LoadScreenTilesFromBuffer2
	pop af
	ld [wListScrollOffset], a
	ld hl, wd730
	res 6, [hl]
	ret

BillsPCDeposit:
	ld hl, wPartyCount
	call DisplayMonListMenu
	jp c, BillsPCMenu
	call DisplayDepositWithdrawMenu
	jr nc, BillsPCDeposit
	; Allow the Deposit list to open even with only one party mon or a full
	; box. Enforce those limits only when Deposit is actually confirmed.
	ld a, [wPartyCount]
	dec a
	jr nz, .partyLargeEnough
	ld hl, CantDepositLastMonText
	call PrintText
	jr BillsPCDeposit
.partyLargeEnough
	ld a, [wNumInBox]
	cp MONS_PER_BOX
	jr nz, .boxNotFull
	ld hl, BoxFullText
	call PrintText
	jr BillsPCDeposit
.boxNotFull
	call WaitForSoundToFinish
	ld a, [wcf91]
	call PlayCry
	ld a, PARTY_TO_BOX
	ld [wMoveMonType], a
	call MoveMon
	xor a
	ld [wRemoveMonFromBox], a
	call RemovePokemon
	call NormalizeBillsPCListCursorAfterRemoval
	call WaitForSoundToFinish
	ld hl, wBoxNumString
	ld a, [wCurrentBoxNum]
	and $7f
	cp 9
	jr c, .singleDigitBoxNum
	sub 9
	ld [hl], "1"
	inc hl
	add "0"
	jr .next
.singleDigitBoxNum
	add "1"
.next
	ld [hli], a
	ld [hl], "@"
	ld hl, MonWasStoredText
	call PrintText
	jr BillsPCDeposit

BillsPCWithdraw:
	ld a, [wNumInBox]
	and a
	jr nz, .boxNotEmpty
	ld hl, NoMonText
	call PrintText
	jp BillsPCMenu
.boxNotEmpty
	ld hl, wNumInBox
	call DisplayMonListMenu
	jp c, BillsPCMenu
	call DisplayDepositWithdrawMenu
	jr nc, BillsPCWithdraw
	; A full party may still browse the Withdraw list. Reject only the
	; confirmed Withdraw action, then redraw the same Withdraw list.
	ld a, [wPartyCount]
	cp PARTY_LENGTH
	jr nz, .partyNotFull
	ld hl, CantTakeMonText
	call PrintText
	jr BillsPCWithdraw
.partyNotFull
	ld a, [wWhichPokemon]
	ld hl, wBoxMonNicks
	call GetPartyMonName
	call WaitForSoundToFinish
	ld a, [wcf91]
	call PlayCry
	xor a ; BOX_TO_PARTY
	ld [wMoveMonType], a
	call MoveMon
	ld a, 1
	ld [wRemoveMonFromBox], a
	call RemovePokemon
	call NormalizeBillsPCListCursorAfterRemoval
	call WaitForSoundToFinish
	ld hl, MonIsTakenOutText
	call PrintText
	; If that was the last mon in the box, leave Withdraw directly instead of
	; re-entering it and triggering NoMonText from the empty-box entry check.
	ld a, [wNumInBox]
	and a
	jp z, BillsPCMenu
	jr BillsPCWithdraw

; If the removed mon was the final entry in the old list, the saved
; scroll offset + menu row now points at Cancel. Move the saved cursor
; back by one entry while preserving the current page whenever possible.
NormalizeBillsPCListCursorAfterRemoval:
	ld hl, wPartyCount
	ld a, [wRemoveMonFromBox]
	and a
	jr z, .gotCount
	ld hl, wNumInBox
.gotCount
	ld a, [wWhichPokemon]
	cp [hl]
	ret c
	ld hl, wPartyAndBillsPCSavedMenuItem
	ld a, [hl]
	and a
	jr z, .moveScrollUp
	dec [hl]
	ret
.moveScrollUp
	ld hl, wListScrollOffset
	ld a, [hl]
	and a
	ret z
	dec [hl]
	ret

BillsPCRelease:
	ld a, [wNumInBox]
	and a
	jr nz, .loop
	ld hl, NoMonText
	call PrintText
	jp BillsPCMenu
.loop
	ld hl, wNumInBox
	call DisplayMonListMenu
	jp c, BillsPCMenu
	ld hl, OnceReleasedText
	call PrintText
	call YesNoChoice
	ld a, [wCurrentMenuItem]
	and a
	jr nz, .loop
	inc a
	ld [wRemoveMonFromBox], a
	call RemovePokemon
	call WaitForSoundToFinish
	ld a, [wcf91]
	call PlayCry
	ld hl, MonWasReleasedText
	call PrintText
	jp BillsPCMenu

BillsPCChangeBox:
	callba ChangeBox
	jp BillsPCMenu

DisplayMonListMenu:
	ld a, l
	ld [wListPointer], a
	ld a, h
	ld [wListPointer + 1], a
	xor a
	ld [wPrintItemPrices], a
	ld [wListMenuID], a
	inc a                ; MONSTER_NAME
	ld [wNameListType], a
	ld a, [wPartyAndBillsPCSavedMenuItem]
	ld [wCurrentMenuItem], a
	call DisplayListMenuID
	ld a, [wCurrentMenuItem]
	ld [wPartyAndBillsPCSavedMenuItem], a
	ret

BillsPCMenuText:
	db   "Withdraw ", $4a
	next "Deposit ",  $4a
	next "Release ",  $4a
	next "Change Box"
	next "Back"
	db "@"

BoxNoPCText:
	db "Box No.@"

KnowsHMMove::
; returns whether mon with party index [wWhichPokemon] knows an HM move
	ld hl, wPartyMon1Moves
	ld bc, wPartyMon2 - wPartyMon1
	jr .next
; unreachable
	ld hl, wBoxMon1Moves
	ld bc, wBoxMon2 - wBoxMon1
.next
	ld a, [wWhichPokemon]
	call AddNTimes
	ld b, NUM_MOVES
.loop
	ld a, [hli]
	push hl
	push bc
	ld hl, HMMoveArray
	ld de, 1
	call IsInArray
	pop bc
	pop hl
	ret c
	dec b
	jr nz, .loop
	and a
	ret

HMMoveArray:
	db CUT
	db FLY
	db SURF
	db STRENGTH
	db DIVE
	db -1

DisplayDepositWithdrawMenu:
	; Preserve the exact mon-list screen underneath the action menu, including
	; the current bottom message text. B/Cancel can then restore it verbatim.
	call PrepareBillsPCActionMenu
.redrawActionMenu
	coord hl, 9, 10
	ld b, 6
	ld c, 9
	call TextBoxBorder
	ld a, [wParentMenuItem]
	and a ; was the Deposit or Withdraw item selected in the parent menu?
	ld de, DepositPCText
	jr nz, .next
	ld de, WithdrawPCText
.next
	coord hl, 11, 12
	call PlaceString
	coord hl, 11, 14
	ld de, StatsCancelPCText
	call PlaceString
	ld hl, wTopMenuItemY
	ld a, 12
	ld [hli], a ; wTopMenuItemY
	ld a, 10
	ld [hli], a ; wTopMenuItemX
	inc hl ; keep the action-menu selection chosen by the setup helper
	inc hl
	ld a, 2
	ld [hli], a ; wMaxMenuItem
	ld a, A_BUTTON | B_BUTTON
	ld [hli], a ; wMenuWatchedKeys
	xor a
	ld [hl], a ; wLastMenuItem
	; Keep the mon list cursor/scroll state while this action menu is open so
	; returning to Deposit/Withdraw can redraw the same list page.
	ld [wMenuWatchMovingOutOfBounds], a
	ld [wPlayerMonNumber], a
.loop
	call HandleMenuInput
	bit 1, a ; pressed B?
	jr nz, .exit
	ld a, [wCurrentMenuItem]
	and a
	jr z, .choseDepositWithdraw
	dec a
	jr z, .viewStats
.exit
	; Restore the exact list screen that was present before this action menu.
	; Tail-call the ROM0 helper so Carry is cleared before returning.
	jp RestoreBillsPCActionMenuAndCancel
.choseDepositWithdraw
	scf
	ret
.viewStats
	ld a, [wParentMenuItem]
	and a
	jr z, .viewWithdrawStats

	; Deposit is backed by PLAYER_PARTY_DATA, so it can reuse the mature party
	; Summary UP/DOWN switch pipeline. Require the action-menu direction to be
	; released before entry so a held DOWN used to reach Stats cannot become the
	; first Summary navigation input.
	call BillsPC_WaitForVerticalRelease
	ld a, PLAYER_PARTY_DATA
	ld [wMonDataLocation], a
	ld a, 1 << STATUS_SCREEN_MON_SWITCH_F
	ld [wStatusScreenPage], a
	predef StatusScreen

	; Unlike the START Party caller, Bill's PC should not keep the action menu open.
	; Follow the last Pokémon actually viewed, rebuild the complete underlying PC list
	; while the StatusScreen whiteout still hides it, then reveal that final page in
	; one transaction. The normal list initializer may still run afterwards, but its
	; 10-frame setup now happens behind an already-correct visible page.
	call BillsPC_SelectViewedMonInList
	call BillsPC_RebuildMonListAfterStats
	and a
	ret

.viewWithdrawStats
	; BOX_DATA keeps the existing single-Pokémon Stats behavior for this first PC
	; stage. Explicitly clear the switch flag so a previous Deposit browse cannot
	; leak navigation permission into Withdraw.
	ld a, BOX_DATA
	ld [wMonDataLocation], a
	xor a
	ld [wStatusScreenPage], a
	predef StatusScreen

.restoreAfterStats
	; Withdraw keeps its original single-entry behavior: restore the saved list and
	; redraw the same action menu with Stats selected.
	call RestoreBillsPCActionMenuAfterStats
	jp .redrawActionMenu

BillsPC_WaitForVerticalRelease:
	call Joypad
	ldh a, [hJoyHeld]
	and D_UP | D_DOWN
	ret z
.wait
	call DelayFrame
	call Joypad
	ldh a, [hJoyHeld]
	and D_UP | D_DOWN
	jr nz, .wait
	ret

; StatusScreen leaves an absolute selected index in wWhichPokemon. Bill's PC list
; always displays three selectable Pokémon rows at a time, whether the backing list
; is the six-mon party or a larger Box. Keep the existing viewport when possible and
; shift it only far enough to make the final viewed entry selectable.
BillsPC_SelectViewedMonInList:
	ld a, [wListScrollOffset]
	ld c, a
	ld a, [wWhichPokemon]
	cp c
	jr c, .aboveWindow
	sub c
	cp 3
	jr c, .storeRow
	ld a, [wWhichPokemon]
	sub 2
	ld [wListScrollOffset], a
	ld a, 2
	jr .storeRow
.aboveWindow
	ld a, [wWhichPokemon]
	ld [wListScrollOffset], a
	xor a
.storeRow
	ld [wPartyAndBillsPCSavedMenuItem], a
	ret

BillsPC_RebuildMonListAfterStats:
	; Buffer 1 is the complete Bill's PC page from immediately before the action menu.
	; Restore it only to wTileMap while the StatusScreen whiteout is still active; the
	; stale list/cursor therefore never reaches the LCD.
	xor a
	ld [H_AUTOBGTRANSFERENABLED], a
	ld hl, wTileMapBackup
	coord de, 0, 0
	ld bc, SCREEN_WIDTH * SCREEN_HEIGHT
	call CopyData

	; Rebuild the Pokémon-list portion in the same hidden wTileMap using the final
	; scroll offset and row. Keep this generic over wListPointer so the same resume
	; transaction can later serve the larger Withdraw/Box list as well.
	ld a, [wListPointer]
	ld l, a
	ld a, [wListPointer + 1]
	ld h, a
	ld a, [hl]
	ld [wListCount], a
	xor a
	ld [wPrintItemPrices], a
	ld [wListMenuID], a
	ld [wMenuItemToSwap], a
	ld [wLastMenuItem], a
	inc a
	ld [wNameListType], a
	ld a, [wPartyAndBillsPCSavedMenuItem]
	ld [wCurrentMenuItem], a
	ld a, 4
	ld [wTopMenuItemY], a
	ld a, 5
	ld [wTopMenuItemX], a

	; The stock list renderer uses wWhichPokemon/wcf91 as scratch while printing.
	; Preserve StatusScreen's final absolute selection so the logical target remains
	; synchronized with the page that is about to be revealed.
	ld a, [wWhichPokemon]
	push af
	ld a, [wcf91]
	push af
	call PrintListMenuEntries
	call PlaceMenuCursor
	pop af
	ld [wcf91], a
	pop af
	ld [wWhichPokemon], a

	; Finish every visual dependency before revealing anything. RunDefaultPaletteCommand
	; prepares the generic PC palette/map while rBGP is still white, so CGB hardware
	; remains hidden. Transfer all three BG thirds and explicitly wait for the palette
	; map producer/consumer before restoring normal colors.
	call ReloadTilesetTilePatterns
	call RunDefaultPaletteCommand
	ld a, 1
	ld [H_AUTOBGTRANSFERENABLED], a
	call Delay3
	call BillsPC_WaitForHiddenListCommit

	; Make the final color restore a real completion boundary as well. Forcing the BGP
	; conversion guarantees the CGB palette buffer is produced after LoadGBPal changes
	; rBGP; the local waiter does not return until hardware consumed it.
	ld a, [rSVBK]
	ld b, a
	ld a, 2
	ld [rSVBK], a
	ld a, 1
	ld [W2_ForceBGPUpdate], a
	ld a, b
	ld [rSVBK], a
	call LoadGBPal
	call BillsPC_WaitForBgPaletteCommit
	ret

BillsPC_WaitForHiddenListCommit:
	; Delay3 covers the three tilemap thirds, but CGB attribute-map preparation and
	; VBlank consumption can trail them. Keep the page white until both queues and
	; the last Window portion are completely drained.
.wait
	ld a, [rSVBK]
	ld b, a
	ld a, 2
	ld [rSVBK], a
	ld a, [W2_StaticPaletteMapChanged]
	ld c, a
	ld a, [W2_StaticPaletteMapChanged_vbl]
	or c
	ld c, a
	ld a, [W2_UpdatedWindowPortion]
	or c
	ld c, a
	ld a, b
	ld [rSVBK], a
	ld a, c
	and a
	ret z
	call DelayFrame
	jr .wait

BillsPC_WaitForBgPaletteCommit:
	; Bill's PC is assembled from audio.asm while StatusScreen is assembled from
	; main.asm. Keep this waiter bank-local: callba cannot resolve BANK() for the
	; StatusScreen-private symbol while audio.asm is being assembled.
.check
	ld a, [rSVBK]
	ld b, a
	ld a, 2
	ld [rSVBK], a
	ld a, [W2_ForceBGPUpdate]
	ld c, a
	ld a, [W2_BgPaletteDataModified]
	or c
	ld c, a
	ld a, b
	ld [rSVBK], a
	ld a, c
	and a
	ret z
	call DelayFrame
	jr .check

DepositPCText:  db "Deposit@"
WithdrawPCText: db "Withdraw@"
StatsCancelPCText:
	db   "Stats"
	next "Cancel@"

SwitchOnText:
	TX_FAR _SwitchOnText
	db "@"

WhatText:
	TX_FAR _WhatText
	db "@"

DepositWhichMonText:
	TX_FAR _DepositWhichMonText
	db "@"

MonWasStoredText:
	TX_FAR _MonWasStoredText
	db "@"

CantDepositLastMonText:
	TX_FAR _CantDepositLastMonText
	db "@"

BoxFullText:
	TX_FAR _BoxFullText
	db "@"

MonIsTakenOutText:
	TX_FAR _MonIsTakenOutText
	db "@"

NoMonText:
	TX_FAR _NoMonText
	db "@"

CantTakeMonText:
	TX_FAR _CantTakeMonText
	db "@"

ReleaseWhichMonText:
	TX_FAR _ReleaseWhichMonText
	db "@"

OnceReleasedText:
	TX_FAR _OnceReleasedText
	db "@"

MonWasReleasedText:
	TX_FAR _MonWasReleasedText
	db "@"

CableClubLeftGameboy::
	ld a, [hSerialConnectionStatus]
	cp USING_EXTERNAL_CLOCK
	ret z
	ld a, [wSpriteStateData1 + 9] ; player's sprite facing direction
	cp SPRITE_FACING_RIGHT
	ret nz
	ld a, [wCurMap]
	cp TRADE_CENTER
	ld a, LINK_STATE_START_TRADE
	jr z, .next
	inc a ; LINK_STATE_START_BATTLE
.next
	ld [wLinkState], a
	call EnableAutoTextBoxDrawing
	tx_pre_jump JustAMomentText

CableClubRightGameboy::
	ld a, [hSerialConnectionStatus]
	cp USING_INTERNAL_CLOCK
	ret z
	ld a, [wSpriteStateData1 + 9] ; player's sprite facing direction
	cp SPRITE_FACING_LEFT
	ret nz
	ld a, [wCurMap]
	cp TRADE_CENTER
	ld a, LINK_STATE_START_TRADE
	jr z, .next
	inc a ; LINK_STATE_START_BATTLE
.next
	ld [wLinkState], a
	call EnableAutoTextBoxDrawing
	tx_pre_jump JustAMomentText

JustAMomentText::
	TX_FAR _JustAMomentText
	db "@"

	ld a, [wSpriteStateData1 + 9] ; player's sprite facing direction
	cp SPRITE_FACING_UP
	ret nz
	call EnableAutoTextBoxDrawing
	tx_pre_jump OpenBillsPCText

OpenBillsPCText::
	db $FD ; FuncTX_BillsPC
