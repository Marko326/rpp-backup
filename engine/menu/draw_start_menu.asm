; function that displays the start menu
DrawStartMenu:
	; MENU-5.62.11: prepare START text-bank/tilemap state in a floating ROMX helper.
	callba StartMenuPrepareRedisplay
	coord hl, START_MENU_X, 0
	CheckEvent EVENT_GOT_POKEDEX
; menu with pokedex
	ld b,START_MENU_TEXTBOX_HEIGHT_WITH_DEX
	ld c,START_MENU_TEXTBOX_WIDTH
	jr nz,.drawTextBoxBorder
; shorter menu if the player doesn't have the pokedex
	ld b,START_MENU_TEXTBOX_HEIGHT_NO_DEX
	ld c,START_MENU_TEXTBOX_WIDTH
.drawTextBoxBorder
	call TextBoxBorder
	ld a,D_DOWN | D_UP | START | B_BUTTON | A_BUTTON
	ld [wMenuWatchedKeys],a
	ld a,$02
	ld [wTopMenuItemY],a ; Y position of first menu choice
	ld a,START_MENU_X + 1
	ld [wTopMenuItemX],a ; X position of first menu choice
	ld a,[wStartMenuSavedMenuItem] ; low 7 bits are the remembered START selection
	and $7f ; bit 7 is the full-restore state flag
	ld [wCurrentMenuItem],a
	ld [wLastMenuItem],a
	xor a
	ld [wMenuWatchMovingOutOfBounds],a
	ld hl,wd730
	set 6,[hl] ; no pauses between printing each letter
	coord hl, START_MENU_X + 2, 2
	CheckEvent EVENT_GOT_POKEDEX
; case for not having pokedex
	ld a,START_MENU_ITEM_COUNT_WITHOUT_DEX
	jr z,.storeMenuItemCount
; case for having pokedex
	ld de,StartMenuPokedexText
	call PrintStartMenuItem
	ld de,StartMenuMoveDexText
	call PrintStartMenuItem
	ld a,START_MENU_ITEM_COUNT_WITH_DEX
.storeMenuItemCount
	ld [wMaxMenuItem],a ; number of menu items
	ld de,StartMenuPokemonText
	call PrintStartMenuItem
	ld de,StartMenuItemText
	call PrintStartMenuItem
	ld de,wPlayerName ; player's name
	call PrintStartMenuItem
	ld a,[wd72e]
	bit 6,a ; is the player using the link feature?
; case for not using link feature
	ld de,StartMenuSaveText
	jr z,.printSaveOrResetText
; case for using link feature
	ld de,StartMenuResetText
.printSaveOrResetText
	call PrintStartMenuItem
	ld de,StartMenuOptionText
	call PrintStartMenuItem
	ld de,StartMenuExitText
	call PlaceString
	ld hl,wd730
	res 6,[hl] ; turn pauses between printing letters back on
	ret

StartMenuPokedexText:
	db "Pokédex@"

StartMenuMoveDexText:
	db "MoveDex@"

StartMenuPokemonText:
	db "Pokémon@"

StartMenuItemText:
	db "Pack@"

StartMenuSaveText:
	db "Save@"

StartMenuResetText:
	db "Reset@"

StartMenuExitText:
	db "Quit@"

StartMenuOptionText:
	db "Options@"

PrintStartMenuItem:
	push hl
	call PlaceString
	pop hl
	ld de,SCREEN_WIDTH * 2
	add hl,de
	ret
