MainMenu:
; Check save file
	call InitOptions
	xor a
	ld [wOptionsInitialized],a
	inc a
	ld [wSaveFileStatus],a
	call CheckForPlayerNameInSRAM
	jr nc,.mainMenuLoop

	predef LoadSAV

.mainMenuLoop
	ld c,20
	call DelayFrames
	xor a ; LINK_STATE_NONE
	ld [wLinkState],a
	ld hl,wPartyAndBillsPCSavedMenuItem
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld [hl],a
	ld [wDefaultMap],a
	ld hl,wd72e
	res 6,[hl]
	call ClearScreen
	call RunDefaultPaletteCommand
	call LoadTextBoxTilePatterns
	call LoadFontTilePatterns
	ld hl,wd730
	set 6,[hl]
	ld a,[wSaveFileStatus]
	cp a,1
	jr z,.noSaveFile
; there's a save file
	coord hl, 0, 0
	ld b,6
	ld c,13
	call TextBoxBorder
	coord hl, 2, 2
	ld de,ContinueText
	call PlaceString
	jr .next2
.noSaveFile
	coord hl, 0, 0
	ld b,4
	ld c,13
	call TextBoxBorder
	coord hl, 2, 2
	ld de,NewGameText
	call PlaceString
.next2
	ld hl,wd730
	res 6,[hl]
	call UpdateSprites
	xor a
	ld [wCurrentMenuItem],a
	ld [wLastMenuItem],a
	ld [wMenuJoypadPollCount],a
	inc a
	ld [wTopMenuItemX],a
	inc a
	ld [wTopMenuItemY],a
	ld a,A_BUTTON | B_BUTTON | START
	ld [wMenuWatchedKeys],a
	ld a,[wSaveFileStatus]
	ld [wMaxMenuItem],a
	call HandleMenuInput
	bit 1,a ; pressed B?
	jp nz,DisplayTitleScreen ; if so, go back to the title screen
	ld c,20
	call DelayFrames
	ld a,[wCurrentMenuItem]
	ld b,a
	ld a,[wSaveFileStatus]
	cp a,2
	jp z,.skipInc
; If there's no save file, increment the current menu item so that the numbers
; are the same whether or not there's a save file.
	inc b
.skipInc
	ld a,b
	and a
	jr z,.choseContinue
	cp a,1
	jp z,StartNewGame
	call DisplayOptionMenu
	ld a,1
	ld [wOptionsInitialized],a
	jp .mainMenuLoop
.choseContinue
	call DisplayContinueGameInfo
	ld hl,wCurrentMapScriptFlags
	set 5,[hl]
.inputLoop
	xor a
	ld [hJoyPressed],a
	ld [hJoyReleased],a
	ld [hJoyHeld],a
	call Joypad
	ld a,[hJoyHeld]
	bit 0,a
	jr nz,.pressedA
	bit 1,a
	jp nz,.mainMenuLoop ; pressed B
	jr .inputLoop
.pressedA
	call GBPalWhiteOutWithDelay3
	call ClearScreen
	ld a,PLAYER_DIR_DOWN
	ld [wPlayerDirection],a
	ld c,10
	call DelayFrames
	ld a,[wNumHoFTeams]
	and a
	jp z,SpecialEnterMap
	ld a,[wCurMap] ; map ID
	cp a,HALL_OF_FAME
	jp nz,SpecialEnterMap
	xor a
	ld [wDestinationMap],a
	ld hl,wd732
	set 2,[hl] ; fly warp or dungeon warp
	call SpecialWarpIn
	jp SpecialEnterMap

InitOptions:
	ld a,1 ; no delay
	ld [wLetterPrintingDelayFlags],a
	; Keep the startup-loaded Music Off bit while resetting the other options.
	; MainMenu runs before LoadSAV, so clearing bit 5 here would briefly let the
	; title music leak out between the title screen and the Continue menu.
	ld a,[wOptions]
	and 1 << 5
	or 1 ; fast speed
	ld [wOptions],a
	ret

LinkMenu:
	xor a
	ld [wLetterPrintingDelayFlags], a
	ld hl, wd72e
	set 6, [hl]
	ld hl, TextTerminator_6b20
	call PrintText
	call SaveScreenTilesToBuffer1
	ld hl, WhereWouldYouLikeText
	call PrintText
	coord hl, 5, 5
	ld b, $6
	ld c, $d
	call TextBoxBorder
	call UpdateSprites
	coord hl, 7, 7
	ld de, CableClubOptionsText
	call PlaceString
	xor a
	ld [wUnusedCD37], a
	ld [wd72d], a
	ld hl, wTopMenuItemY
	ld a, $7
	ld [hli], a
	ld a, $6
	ld [hli], a
	xor a
	ld [hli], a
	inc hl
	ld a, $2
	ld [hli], a
	inc a
	; ld a, A_BUTTON | B_BUTTON
	ld [hli], a ; wMenuWatchedKeys
	xor a
	ld [hl], a
.waitForInputLoop
	call HandleMenuInput
	and A_BUTTON | B_BUTTON
	add a
	add a
	ld b, a
	ld a, [wCurrentMenuItem]
	add b
	add $d0
	ld [wLinkMenuSelectionSendBuffer], a
	ld [wLinkMenuSelectionSendBuffer + 1], a
.exchangeMenuSelectionLoop
	call Serial_ExchangeLinkMenuSelection
	ld a, [wLinkMenuSelectionReceiveBuffer]
	ld b, a
	and $f0
	cp $d0
	jr z, .asm_5c7d
	ld a, [wLinkMenuSelectionReceiveBuffer + 1]
	ld b, a
	and $f0
	cp $d0
	jr nz, .exchangeMenuSelectionLoop
.asm_5c7d
	ld a, b
	and $c ; did the enemy press A or B?
	jr nz, .enemyPressedAOrB
; the enemy didn't press A or B
	ld a, [wLinkMenuSelectionSendBuffer]
	and $c ; did the player press A or B?
	jr z, .waitForInputLoop ; if neither the player nor the enemy pressed A or B, try again
	jr .doneChoosingMenuSelection ; if the player pressed A or B but the enemy didn't, use the player's selection
.enemyPressedAOrB
	ld a, [wLinkMenuSelectionSendBuffer]
	and $c ; did the player press A or B?
	jr z, .useEnemyMenuSelection ; if the enemy pressed A or B but the player didn't, use the enemy's selection
; the enemy and the player both pressed A or B
; The gameboy that is clocking the connection wins.
	ld a, [hSerialConnectionStatus]
	cp USING_INTERNAL_CLOCK
	jr z, .doneChoosingMenuSelection
.useEnemyMenuSelection
	ld a, b
	ld [wLinkMenuSelectionSendBuffer], a
	and $3
	ld [wCurrentMenuItem], a
.doneChoosingMenuSelection
	ld a, [hSerialConnectionStatus]
	cp USING_INTERNAL_CLOCK
	jr nz, .skipStartingTransfer
	call DelayFrame
	call DelayFrame
	ld a, START_TRANSFER_INTERNAL_CLOCK
	ld [rSC], a
.skipStartingTransfer
	ld b, $7f
	ld c, $7f
	ld d, $ec
	ld a, [wLinkMenuSelectionSendBuffer]
	and (B_BUTTON << 2) ; was B button pressed?
	jr nz, .updateCursorPosition
; A button was pressed
	ld a, [wCurrentMenuItem]
	cp $2
	jr z, .updateCursorPosition
	ld c, d
	ld d, b
	dec a
	jr z, .updateCursorPosition
	ld b, c
	ld c, d
.updateCursorPosition
	ld a, b
	Coorda 6, 7
	ld a, c
	Coorda 6, 9
	ld a, d
	Coorda 6, 11
	ld c, 40
	call DelayFrames
	call LoadScreenTilesFromBuffer1
	ld a, [wLinkMenuSelectionSendBuffer]
	and (B_BUTTON << 2) ; was B button pressed?
	jr nz, .choseCancel ; all three visible rows are real functions; B cancels
	xor a
	ld [wWalkBikeSurfState], a ; start walking

	; Keep the synchronized menu index as the link mode. Both Colosseum modes
	; warp to the original Colosseum map, while only mode 2 enables Lv50 rules.
	ld a, [wCurrentMenuItem]
	ld [wLinkBattleMode], a

	; Colosseum50 must refresh the temporary party before entering the room so
	; the player can inspect the level-50 stats and choose the lead Pokemon.
	; Preserve the synchronized menu index because the banked call changes A.
	push af
	cp LINK_MODE_COLOSSEUM_50
	jr nz, .skipLevel50Normalization
	callba NormalizePartyForLevel50LinkBattle
.skipLevel50Normalization
	pop af

	and a
	ld a, COLOSSEUM
	jr nz, .next
	ld a, TRADE_CENTER
.next
	ld [wd72d], a
	ld hl, PleaseWaitText
	call PrintText
	ld c, 50
	call DelayFrames
	ld hl, wd732
	res 1, [hl]
	ld a, [wDefaultMap]
	ld [wDestinationMap], a
	call SpecialWarpIn
	ld c, 20
	call DelayFrames
	xor a
	ld [wMenuJoypadPollCount], a
	ld [wSerialExchangeNybbleSendData], a
	inc a ; LINK_STATE_IN_CABLE_CLUB
	ld [wLinkState], a
	ld [wEnteringCableClub], a
	jr SpecialEnterMap
.choseCancel
	xor a
	ld [wMenuJoypadPollCount], a
	call Delay3
	call CloseLinkConnection
	ld hl, LinkCanceledText
	call PrintText
	ld hl, wd72e
	res 6, [hl]
	ret

WhereWouldYouLikeText:
	TX_FAR _WhereWouldYouLikeText
	db "@"

PleaseWaitText:
	TX_FAR _PleaseWaitText
	db "@"

LinkCanceledText:
	TX_FAR _LinkCanceledText
	db "@"

StartNewGame:
	ld hl, wd732
	res 1, [hl]
	call OakSpeech
	ld c, 20
	call DelayFrames

; enter map after using a special warp or loading the game from the main menu
SpecialEnterMap:
	xor a
	ld [hJoyPressed], a
	ld [hJoyHeld], a
	ld [hJoy5], a
	ld [wd72d], a
	ld hl, wd732
	set 0, [hl] ; count play time
	call ResetPlayerSpriteData
	ld c, 20
	call DelayFrames
	ld a, [wEnteringCableClub]
	and a
	ret nz
	jp EnterMap

ContinueText:
	db "Continue", $4e

NewGameText:
	db   "New Game"
	next "Options@"

CableClubOptionsText:
	db   "Trade Center"
	next "Colosseum"
	next "Colosseum50@" ; third function; press B to cancel the Link Menu

DisplayContinueGameInfo:
	xor a
	ld [H_AUTOBGTRANSFERENABLED], a
	coord hl, 2, 6
	ld b, 10
	ld c, 16
	call TextBoxBorder

; Display the current Town Map legend on one line.
; GetMapNameForSaveScreen reads wCurMap after the bank switch.
	callba GetMapNameForSaveScreen
	coord hl, 3, 8
	ld de, wBuffer
	call PlaceString

; Display the normal save information below the map legend.
	coord hl, 3, 10
	ld de, SaveScreenInfoText
	call PlaceString
	coord hl, 12, 10
	ld de, wPlayerName
	call PlaceString
	coord hl, 17, 12
	call PrintNumBadges
	coord hl, 16, 14
	call PrintNumOwnedMons
	coord hl, 13, 16
	call PrintPlayTime
	ld a, 1
	ld [H_AUTOBGTRANSFERENABLED], a
	ld c, 30
	jp DelayFrames

PrintSaveScreenText:
	xor a
	ld [H_AUTOBGTRANSFERENABLED], a
	coord hl, 2, 0
	ld b, 10
	ld c, 16
	call TextBoxBorder
	call LoadTextBoxTilePatterns
	call UpdateSprites

; Display the current Town Map legend on one line.
; GetMapNameForSaveScreen reads wCurMap after the bank switch.
	callba GetMapNameForSaveScreen
	coord hl, 3, 2
	ld de, wBuffer
	call PlaceString

; Display the normal save information below the map legend.
	coord hl, 3, 4
	ld de, SaveScreenInfoText
	call PlaceString
	coord hl, 12, 4
	ld de, wPlayerName
	call PlaceString
	coord hl, 17, 6
	call PrintNumBadges
	coord hl, 16, 8
	call PrintNumOwnedMons
	coord hl, 13, 10
	call PrintPlayTime
	ld a, $1
	ld [H_AUTOBGTRANSFERENABLED], a
	ld c, 30
	jp DelayFrames

PrintNumBadges:
	push hl
	ld hl, wObtainedKantoBadges
	ld b, $2
	call CountSetBits
	pop hl
	ld de, wNumSetBits
	lb bc, 1, 2
	jp PrintNumber

PrintNumOwnedMons:
	push hl
	ld hl, wPokedexOwned
	ld b, wPokedexOwnedEnd - wPokedexOwned
	call CountSetBits
	pop hl
	ld de, wNumSetBits
	lb bc, 1, 3
	jp PrintNumber

PrintPlayTime:
	ld de, wPlayTimeHours
	lb bc, 1, 3
	call PrintNumber
	ld [hl], $6d
	inc hl
	ld de, wPlayTimeMinutes
	lb bc, LEADING_ZEROES | 1, 2
	jp PrintNumber

SaveScreenInfoText:
	db   "Player"
	next "Badges    "
	next "#dex    "
	next "Time@"

DisplayOptionMenu:
	xor a
	ld [wOptionsMenuPage], a ; options menu page: 0 = main, 1 = music
	call .drawPage1
	xor a
	ld [wCurrentMenuItem],a
	ld [wLastMenuItem],a
	inc a
	ld [wLetterPrintingDelayFlags],a
	call SetCursorPositionsFromOptions
	; Open the options menu with the active cursor on the page selector.
	ld a,16
	ld [wTopMenuItemY],a
	ld a,1
	ld [wTopMenuItemX],a
	ld a,$01
	ld [H_AUTOBGTRANSFERENABLED],a ; enable auto background transfer
	call Delay3
.loop
	call PlaceMenuCursor
	call SetOptionsFromCursorPositions
.getJoypadStateLoop
	call JoypadLowSensitivity
	ld a,[hJoy5]
	ld b,a
	and a,A_BUTTON | B_BUTTON | START | D_RIGHT | D_LEFT | D_UP | D_DOWN ; any key besides select pressed?
	jr z,.getJoypadStateLoop
	bit 1,b ; B button pressed?
	jr nz,.exitMenu
	bit 3,b ; Start button pressed?
	jr nz,.exitMenu
	bit 0,b ; A button pressed?
	jr z,.checkDirectionKeys
	; The page selector is navigated with Left/Right only.
	jp .loop
.exitMenu
	ld a,SFX_PRESS_AB
	call PlaySound
	ret
.eraseOldMenuCursor
	ld [wTopMenuItemX],a
	call EraseMenuCursor
	jp .loop
.checkDirectionKeys
	ld a, [wOptionsMenuPage]
	and a
	jp nz, .checkPage2DirectionKeys

; Page 1: Text Speed, Battle Effects, Battle Style, Back.
	ld a,[wTopMenuItemY]
	bit 7,b ; Down pressed?
	jr nz,.downPressed
	bit 6,b ; Up pressed?
	jr nz,.upPressed
	cp a,8 ; cursor in Battle Animation section?
	jr z,.cursorInBattleAnimation
	cp a,13 ; cursor in Battle Style section?
	jr z,.cursorInBattleStyle
	cp a,16 ; cursor on Back?
	jr z,.cursorOnPage1Back
.cursorInTextSpeed
	bit 5,b ; Left pressed?
	jp nz,.pressedLeftInTextSpeed
	jp .pressedRightInTextSpeed
.downPressed
	cp a,3
	jr z,.page1SelectBattleAnimation
	cp a,8
	jr z,.page1SelectBattleStyle
	cp a,13
	jr z,.page1SelectBack
	jr .page1SelectTextSpeed
.upPressed
	cp a,3
	jr z,.page1SelectBack
	cp a,8
	jr z,.page1SelectTextSpeed
	cp a,13
	jr z,.page1SelectBattleAnimation
	jr .page1SelectBattleStyle
.page1SelectTextSpeed
	ld a,3
	ld [wTopMenuItemY],a
	ld a,[wOptionsTextSpeedCursorX]
	jr .storePage1CursorX
.page1SelectBattleAnimation
	ld a,8
	ld [wTopMenuItemY],a
	ld a,[wOptionsBattleAnimCursorX]
	jr .storePage1CursorX
.page1SelectBattleStyle
	ld a,13
	ld [wTopMenuItemY],a
	ld a,1
	jr .storePage1CursorX
.page1SelectBack
	ld a,16
	ld [wTopMenuItemY],a
	ld a,1
.storePage1CursorX
	ld [wTopMenuItemX],a
	call PlaceUnfilledArrowMenuCursor
	jp .loop
.cursorInBattleAnimation
	ld a,[wOptionsBattleAnimCursorX] ; battle animation cursor X coordinate
	xor a,$0b ; toggle between 1 and 10
	ld [wOptionsBattleAnimCursorX],a
	jp .eraseOldMenuCursor
.cursorInBattleStyle
	; Battle Style remains fixed to Set.
	jp .loop
.cursorOnPage1Back
	bit 4,b ; Right pressed?
	jp nz,.showPage2
	jp .loop
.pressedLeftInTextSpeed
	ld a,[wOptionsTextSpeedCursorX] ; text speed cursor X coordinate
	cp a,1
	jr z,.updateTextSpeedXCoord
	cp a,7
	jr nz,.fromSlowToMedium
	sub a,6
	jr .updateTextSpeedXCoord
.fromSlowToMedium
	sub a,7
	jr .updateTextSpeedXCoord
.pressedRightInTextSpeed
	ld a,[wOptionsTextSpeedCursorX] ; text speed cursor X coordinate
	cp a,14
	jr z,.updateTextSpeedXCoord
	cp a,7
	jr nz,.fromFastToMedium
	add a,7
	jr .updateTextSpeedXCoord
.fromFastToMedium
	add a,6
.updateTextSpeedXCoord
	ld [wOptionsTextSpeedCursorX],a ; text speed cursor X coordinate
	jp .eraseOldMenuCursor

; Page 2: Music and Back. Left/right on Music toggles the option.
; Left on Back returns to page 1.
.checkPage2DirectionKeys
	ld a,[wTopMenuItemY]
	bit 7,b ; Down pressed?
	jr nz,.page2DownPressed
	bit 6,b ; Up pressed?
	jr nz,.page2UpPressed
	cp a,16 ; cursor on Back?
	jr z,.cursorOnPage2Back
.cursorInMusic
	ld a,[wOptionsMusicCursorX]
	xor a,$0b ; toggle between 1 and 10
	ld [wOptionsMusicCursorX],a
	jp .eraseOldMenuCursor
.page2DownPressed
	cp a,3
	jr nz,.page2SelectMusic
	ld a,16
	ld [wTopMenuItemY],a
	ld a,1
	ld [wTopMenuItemX],a
	call PlaceUnfilledArrowMenuCursor
	jp .loop
.page2UpPressed
	cp a,16
	jr nz,.page2SelectBack
.page2SelectMusic
	ld a,3
	ld [wTopMenuItemY],a
	ld a,[wOptionsMusicCursorX]
	ld [wTopMenuItemX],a
	call PlaceUnfilledArrowMenuCursor
	jp .loop
.page2SelectBack
	ld a,16
	ld [wTopMenuItemY],a
	ld a,1
	ld [wTopMenuItemX],a
	call PlaceUnfilledArrowMenuCursor
	jp .loop
.cursorOnPage2Back
	bit 5,b ; Left pressed?
	jp nz,.showPage1
	jp .loop

.showPage2
	ld a,1
	ld [wOptionsMenuPage],a
	; Build the next page completely in wTileMap before transferring it to VRAM.
	; ClearScreen waits for three frames, so leaving auto-transfer enabled here
	; would briefly display the cleared tilemap and make the page flash.
	xor a
	ld [H_AUTOBGTRANSFERENABLED],a
	call ClearScreen
	call .drawPage2
	call .placePage2Arrows
	; Always enter a different options page with the active cursor on Page.
	ld a,16
	ld [wTopMenuItemY],a
	ld a,1
	ld [wTopMenuItemX],a
	ld a,1
	ld [H_AUTOBGTRANSFERENABLED],a
	call Delay3
	jp .loop

.showPage1
	xor a
	ld [wOptionsMenuPage],a
	; Keep the old page visible until the new page is fully drawn.
	ld [H_AUTOBGTRANSFERENABLED],a
	call ClearScreen
	call .drawPage1
	call SetCursorPositionsFromOptions
	ld a,16
	ld [wTopMenuItemY],a
	ld a,1
	ld [wTopMenuItemX],a
	ld a,1
	ld [H_AUTOBGTRANSFERENABLED],a
	call Delay3
	jp .loop

.drawPage1
	coord hl, 0, 0
	ld b,3
	ld c,18
	call TextBoxBorder
	coord hl, 0, 5
	ld b,3
	ld c,18
	call TextBoxBorder
	coord hl, 0, 10
	ld b,3
	ld c,18
	call TextBoxBorder
	coord hl, 1, 1
	ld de,TextSpeedOptionText
	call PlaceString
	coord hl, 1, 6
	ld de,BattleAnimationOptionText
	call PlaceString
	coord hl, 1, 11
	ld de,BattleStyleOptionText
	call PlaceString
	coord hl, 2, 16
	ld de,OptionMenuPageText
	call PlaceString
	coord hl, 16, 16
	ld de,OptionMenuPage1Text
	jp PlaceString

.drawPage2
	coord hl, 0, 0
	ld b,3
	ld c,18
	call TextBoxBorder
	coord hl, 0, 5
	ld b,3
	ld c,18
	call TextBoxBorder
	coord hl, 0, 10
	ld b,3
	ld c,18
	call TextBoxBorder
	coord hl, 1, 1
	ld de,MusicOptionText
	call PlaceString
	coord hl, 2, 16
	ld de,OptionMenuPageText
	call PlaceString
	coord hl, 16, 16
	ld de,OptionMenuPage2Text
	jp PlaceString

.placePage2Arrows
	coord hl, 0, 3
	ld a,[wOptionsMusicCursorX]
	ld e,a
	ld d,0
	add hl,de
	ld [hl],$ec
	coord hl, 1, 16
	ld [hl],$ec
	ret

TextSpeedOptionText:
	db   "Text Speed:"
	next " Fast  Normal Slow@"

BattleAnimationOptionText:
	db   "Battle Effects:"
	next " On       Off@"

BattleStyleOptionText:
	db   "Battle Style:"
	next " Set@"

MusicOptionText:
	db   "Music:"
	next " On       Off@"

OptionMenuPageText:
	db "Page@"

OptionMenuPage1Text:
	db "1/2@"

OptionMenuPage2Text:
	db "2/2@"

; sets the options variable according to the current placement of the menu cursors in the options menu
SetOptionsFromCursorPositions:
	ld hl,TextSpeedOptionData
	ld a,[wOptionsTextSpeedCursorX] ; text speed cursor X coordinate
	ld c,a
.loop
	ld a,[hli]
	cp c
	jr z,.textSpeedMatchFound
	inc hl
	jr .loop
.textSpeedMatchFound
	ld a,[hl]
	ld d,a
	ld a,[wOptionsBattleAnimCursorX] ; battle animation cursor X coordinate
	dec a
	jr z,.battleAnimationOn
.battleAnimationOff
	set 7,d
	jr .setBattleStyle
.battleAnimationOn
	res 7,d
.setBattleStyle
	; Battle Style is displayed as Set and remains fixed to Set.
	set 6,d
	ld a,[wOptionsMusicCursorX]
	dec a
	jr z,.musicOn
.musicOff
	set 5,d
	jr .storeOptions
.musicOn
	res 5,d
.storeOptions
	ld a,d
	ld [wOptions],a
	ld a,1
	ld [wLetterPrintingDelayFlags],a ; Fast=1(整句瞬出)，其余=0(逐字)
	ret

; reads the options variable and places menu cursors in the correct positions within the options menu
SetCursorPositionsFromOptions:
	ld hl,TextSpeedOptionData + 1
	ld a,[wOptions]
	and a,$0f
	ld c,a
	ld de,2
	call IsInArray
	dec hl
	ld a,[hl]
	ld [wOptionsTextSpeedCursorX],a ; text speed cursor X coordinate
	coord hl, 0, 3
	call .placeUnfilledRightArrow

	ld a,[wOptions]
	bit 7,a
	ld a,1 ; On
	jr z,.storeBattleAnimationCursorX
	ld a,10 ; Off
.storeBattleAnimationCursorX
	ld [wOptionsBattleAnimCursorX],a ; battle animation cursor X coordinate
	coord hl, 0, 8
	call .placeUnfilledRightArrow

	; Battle Style is fixed to Set and does not need a cursor variable.
	coord hl, 1, 13
	ld [hl],$ec

	ld a,[wOptions]
	bit 5,a
	ld a,1 ; On
	jr z,.storeMusicCursorX
	ld a,10 ; Off
.storeMusicCursorX
	ld [wOptionsMusicCursorX],a ; music cursor X coordinate

; cursor in front of Back
	coord hl, 1, 16
	ld [hl],$ec
	ret
.placeUnfilledRightArrow
	ld e,a
	ld d,0
	add hl,de
	ld [hl],$ec ; unfilled right arrow menu cursor
	ret

; table that indicates how the 3 text speed options affect frame delays
; Format:
; 00: X coordinate of menu cursor
; 01: delay after printing a letter (in frames)
TextSpeedOptionData:
	db 14,3 ; Slow  -> 3 帧，原 Normal
	db  7,1 ; Normal-> 1 帧，原 Fast
	db  1,0 ; Fast  -> 0 帧（配合标志=1，整句瞬出）
	db 7 ; default X coordinate (Medium)
	db $ff ; terminator

CheckForPlayerNameInSRAM:
; Check if the player name data in SRAM has a string terminator character
; (indicating that a name may have been saved there) and return whether it does
; in carry.
	ld a, SRAM_ENABLE
	ld [MBC1SRamEnable], a
	ld a, $1
	ld [MBC1SRamBankingMode], a
	ld [MBC1SRamBank], a
	ld b, NAME_LENGTH
	ld hl, sPlayerName
.loop
	ld a, [hli]
	cp "@"
	jr z, .found
	dec b
	jr nz, .loop
; not found
	xor a
	ld [MBC1SRamEnable], a
	ld [MBC1SRamBankingMode], a
	and a
	ret
.found
	xor a
	ld [MBC1SRamEnable], a
	ld [MBC1SRamBankingMode], a
	scf
	ret
