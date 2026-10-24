DisplayStartMenu::
	ld a,BANK(StartMenu_Pokedex)
	ld [H_LOADEDROMBANK],a
	ld [MBC1RomBank],a
	ld a,[wWalkBikeSurfState] ; walking/biking/surfing
	ld [wWalkBikeSurfStateCopy],a
	ld a, SFX_START_MENU
	call PlaySound
RedisplayStartMenu::
	callba DrawStartMenu
	callba PrintSafariZoneSteps ; print Safari Zone info, if in Safari Zone
	call UpdateSprites
.loop
	call HandleMenuInput
	ld b,a
.checkIfUpPressed
	bit 6,a ; was Up pressed?
	jr z,.checkIfDownPressed
	ld a,[wCurrentMenuItem] ; menu selection
	and a
	jr nz,.loop
	ld a,[wLastMenuItem]
	and a
	jr nz,.loop
; if the player pressed tried to go past the top item, wrap around to the bottom
	CheckEvent EVENT_GOT_POKEDEX
	ld a,START_MENU_ITEM_COUNT_WITH_DEX - 1 ; max visible index with Pokédex + MoveDex
	jr nz,.wrapMenuItemId
	ld a,START_MENU_ITEM_COUNT_WITHOUT_DEX - 1 ; max visible index without either dex entry
.wrapMenuItemId
	ld [wCurrentMenuItem],a
	call EraseMenuCursor
	jr .loop
.checkIfDownPressed
	bit 7,a
	jr z,.buttonPressed
; if the player pressed tried to go past the bottom item, wrap around to the top
	CheckEvent EVENT_GOT_POKEDEX
	ld a,[wCurrentMenuItem]
	ld c,START_MENU_ITEM_COUNT_WITH_DEX
	jr nz,.checkIfPastBottom
	ld c,START_MENU_ITEM_COUNT_WITHOUT_DEX
.checkIfPastBottom
	cp c
	jr nz,.loop
; the player went past the bottom, so wrap to the top
	xor a
	ld [wCurrentMenuItem],a
	call EraseMenuCursor
	jr .loop
.buttonPressed ; A, B, or Start button pressed
	call PlaceUnfilledArrowMenuCursor
	ld a,[wCurrentMenuItem]
	ld c,a
	ld a,[wStartMenuSavedMenuItem]
	and 1 << START_MENU_FULL_RESTORE_F
	or c
	ld [wStartMenuSavedMenuItem],a ; remember cursor without losing restore state
	ld a,b
	and a,%00001010 ; was the Start button or B button pressed?
	jp nz,CloseStartMenu
	CheckEvent EVENT_GOT_POKEDEX
	ld a,[wCurrentMenuItem]
	jr nz,.displayMenuItem
	add START_MENU_HIDDEN_DEX_ITEM_COUNT ; Pokédex + MoveDex are hidden before the Pokédex is obtained
.displayMenuItem
	cp START_MENU_EXIT_ID
	jp z,CloseStartMenu ; EXIT never touched Bank 0 and keeps the fast close path
	push af
	; MENU-5.62.11: prepare the legacy Bank-0 text contract only when a real
	; submenu is selected; the helper also snapshots START and marks full restore.
	callba StartMenuPrepareSubmenuText
	pop af
	cp 0
	jp z,StartMenu_Pokedex
	cp 1
	jr nz,.notMoveDex
	callba ShowMoveDexMenu
	call LoadScreenTilesFromBuffer2
	; Keep BG/Window white until the real CGB OBJ palette commit is complete.
	callba StartMenuFinishWhiteReturn
	jp RedisplayStartMenu
.notMoveDex
	cp 2
	jp z,StartMenu_Pokemon
	cp 3
	jp z,StartMenu_Item
	cp 4
	jp z,StartMenu_TrainerInfo
	cp 5
	jp z,StartMenu_SaveReset
	cp 6
	jp z,StartMenu_Option

CloseStartMenu::
	call Joypad
	ld a,[hJoyPressed]
	bit 0,a ; was A button newly pressed?
	jr nz,CloseStartMenu
	; MENU-5.62.11: the ROMX helper selects lightweight direct close or the proven
	; full map/sprite restore path. Carry = full restore.
	callba StartMenuPrepareClose
	jr c,StartMenuFullRestoreClose
	pop af
	ld [H_LOADEDROMBANK],a
	ld [MBC1RomBank],a
	jp UpdateSprites

StartMenuFullRestoreClose::
	ld a,[wCurMap]
	call SwitchToMapRomBank
	jp CloseTextDisplayAfterWindowHide
