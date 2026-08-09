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
	ld a,7 ; Pokédex + MoveDex add two entries, so the max visible index is 7
	jr nz,.wrapMenuItemId
	ld a,5 ; there are 6 menu items without either dex entry
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
	ld c,8 ; there are 8 menu items with Pokédex + MoveDex
	jr nz,.checkIfPastBottom
	ld c,6 ; there are 6 menu items without either dex entry
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
	ld [wBattleAndStartSavedMenuItem],a ; save current menu selection
	ld a,b
	and a,%00001010 ; was the Start button or B button pressed?
	jp nz,CloseStartMenu
	call SaveScreenTilesToBuffer2 ; copy background from wTileMap to wTileMapBackup2
	CheckEvent EVENT_GOT_POKEDEX
	ld a,[wCurrentMenuItem]
	jr nz,.displayMenuItem
	add 2 ; both Pokédex and MoveDex are hidden before the Pokédex is obtained
.displayMenuItem
	cp 0
	jp z,StartMenu_Pokedex
	cp 1
	jr nz,.notMoveDex
	callba ShowMoveDexMenu
	call LoadScreenTilesFromBuffer2
	call Delay3
	call LoadGBPal
	call UpdateSprites
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

; EXIT falls through to here
CloseStartMenu::
	call Joypad
	ld a,[hJoyPressed]
	bit 0,a ; was A button newly pressed?
	jr nz,CloseStartMenu
	call LoadTextBoxTilePatterns
	jp CloseTextDisplay
