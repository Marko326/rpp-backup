; GBP-5.57.01: GB Player v2 MoveDex/Pokédex menu infrastructure alignment.
; The list/sidebar layout, menu cursor lifecycle, Pokédex list tile patterns,
; BG-transfer discipline, and full-screen sprite hiding now follow MoveDex/
; Pokédex instead of maintaining a parallel hand-written cursor implementation.
; Play/Map remain live; Info stays visible as a reserved slot for later expansion.

GB_PLAYER_VISIBLE_TRACKS EQU 7
GB_PLAYER_LIBRARY_COUNT  EQU 3
GB_PLAYER_SIDE_OPTIONS   EQU 4
GB_PLAYER_RBY_COUNT      EQU 45
GB_PLAYER_GSC_COUNT      EQU 102
GB_PLAYER_CUSTOM_COUNT   EQU 11
GB_PLAYER_NAME_WIDTH     EQU 12

GBPlayerMenu::
	call GBPlayerWaitForRelease

	; Full-screen menus must own OAM while visible. Preserve the Bag/overworld
	; caller state, disable overworld sprite generation, and clear the current OAM
	; buffer before drawing the GB Player. This mirrors the Pokédex protection and
	; prevents player/NPC sprites from appearing over the list.
	ld hl,wUpdateSpritesEnabled
	ld a,[hl]
	push af
	ld [hl],$ff
	call ClearSprites
	call GBPalWhiteOut
	call ClearScreen
	call UpdateSprites

	; GB Player is opened from the Bag. HandleMenuInput has Bag-specific refresh
	; hooks, so temporarily leave Bag mode while this independent full-screen menu
	; owns input; restore it exactly on exit.
	ld a,[wBagPocketActive]
	push af
	xor a
	ld [wBagPocketActive],a

	; Force the same double-spaced cursor geometry used by MoveDex, but preserve
	; the caller's HRAM flags because the Bag will be redrawn after we return.
	ld a,[hFlags_0xFFF6]
	push af
	res 1,a
	ld [hFlags_0xFFF6],a

	ld a,[wListScrollOffset]
	push af
	xor a
	ld [wGBPlayerCategory],a
	ld [wListScrollOffset],a
	ld [wCurrentMenuItem],a
	ld [wLastMenuItem],a
	inc a
	ld [hJoy7],a
	call GBPlayerLoadCategoryTable

.setUpGraphics
	xor a
	ld [H_AUTOBGTRANSFERENABLED],a
	call ClearScreen
	ld b,SET_PAL_GENERIC
	call RunPaletteCommand
IF DEF(_BLUE)
	callab SetBlueMoveDexListPokeballPalettes
ENDC
IF DEF(_RED)
	; $70/$71/$72 and the sidebar connector graphics are Pokédex list tiles.
	; Loading normal text-box patterns here was the reason v2 showed broken
	; comma-like vertical separators instead of the MoveDex line/connector set.
	callab LoadPokedexTilePatterns
ENDC
	call GBPlayerDrawStaticUI

.doTrackListMenu
	call GBPlayerSetupListMenuParameters
	call HandleGBPlayerListMenu
	jr c,.goToSideMenu

.exitGBPlayer
	xor a
	ld [wMenuWatchMovingOutOfBounds],a
	ld [wCurrentMenuItem],a
	ld [wLastMenuItem],a
	ld [hJoy7],a
	pop af
	ld [wListScrollOffset],a
	pop af
	ld [hFlags_0xFFF6],a
	pop af
	ld [wBagPocketActive],a

	; GB Player temporarily loads the Pokédex list graphics. Restore the shared
	; text-box/font tiles while the screen is white before returning to the Bag.
	call GBPalWhiteOutWithDelay3
	call LoadTextBoxTilePatterns
	call RunDefaultPaletteCommand
	pop af
	ld [wUpdateSpritesEnabled],a
	ret

.goToSideMenu
	call HandleGBPlayerSideMenu
	dec b
	jr z,.exitGBPlayer ; Quit
	; B returns to the left list. The side-menu helper already restored the parent
	; selection; redraw the list cursor through the same menu system as MoveDex.
	jr .doTrackListMenu

; ---------------------------------------------------------------------------
; MoveDex-style left track list
; ---------------------------------------------------------------------------

GBPlayerSetupListMenuParameters:
	call GBPlayerGetVisibleListCount
	dec a
	ld b,a
	ld hl,wTopMenuItemY
	ld a,3
	ld [hli],a ; top menu item Y
	xor a
	ld [hli],a ; top menu item X
	inc a
	ld [wMenuWatchMovingOutOfBounds],a
	inc hl
	inc hl
	ld a,b
	ld [hli],a ; max menu item ID
	ld a,D_UP | D_DOWN | D_LEFT | D_RIGHT | B_BUTTON | A_BUTTON
	ld [hl],a
	ret

HandleGBPlayerListMenu:
	call GBPlayerRedrawList
.inputLoop
	; Keep the pre-input row so UP/DOWN can distinguish an ordinary cursor move
	; from an attempted move past the visible boundary.
	ld a,[wCurrentMenuItem]
	ld [wGBPlayerDrawRow],a
	call HandleMenuInput
	bit 1,a
	jp nz,.buttonBPressed
	bit 6,a
	jr nz,.up
	bit 7,a
	jr nz,.down
	bit 5,a
	jp nz,.previousLibrary
	bit 4,a
	jp nz,.nextLibrary
	bit 0,a
	jr z,.inputLoop
	scf
	ret

.up
	ld a,[wCurrentMenuItem]
	ld b,a
	ld a,[wGBPlayerDrawRow]
	cp b
	jp nz,.cursorMoved

	; Cursor was already on the first visible row: scroll upward, or wrap from the
	; first track to the last track only on a fresh UP press (same boundary rule as MoveDex).
	ld a,[wListScrollOffset]
	and a
	jr nz,.scrollUpOne
	ld a,[hJoyPressed]
	bit 6,a
	jr z,.inputLoop
	ld a,[wGBPlayerTrackCount]
	cp GB_PLAYER_VISIBLE_TRACKS + 1
	jr c,.wrapUpFirstPage
	sub GB_PLAYER_VISIBLE_TRACKS
	ld [wListScrollOffset],a
	ld a,GB_PLAYER_VISIBLE_TRACKS - 1
	ld [wCurrentMenuItem],a
	ld [wLastMenuItem],a
	call GBPlayerRedrawList
	call GBPlayerWaitForVerticalRelease
	jr .inputLoop
.wrapUpFirstPage
	xor a
	ld [wListScrollOffset],a
	ld a,[wGBPlayerTrackCount]
	dec a
	ld [wCurrentMenuItem],a
	ld [wLastMenuItem],a
	call GBPlayerRedrawList
	call GBPlayerWaitForVerticalRelease
	jr .inputLoop
.scrollUpOne
	dec a
	ld [wListScrollOffset],a
	call GBPlayerRedrawList
	jr .inputLoop

.down
	ld a,[wCurrentMenuItem]
	ld b,a
	ld a,[wGBPlayerDrawRow]
	cp b
	jr nz,.cursorMoved

	; Cursor was already on the last visible row. Scroll until the final track;
	; a fresh DOWN at the true end wraps to the first track.
	call GBPlayerGetSelectedTrackIndex
	inc a
	ld b,a
	ld a,[wGBPlayerTrackCount]
	cp b
	jr nz,.scrollDownOne
	ld a,[hJoyPressed]
	bit 7,a
	jp z,.inputLoop
	xor a
	ld [wListScrollOffset],a
	ld [wCurrentMenuItem],a
	ld [wLastMenuItem],a
	call GBPlayerRedrawList
	call GBPlayerWaitForVerticalRelease
	jp .inputLoop
.scrollDownOne
	ld hl,wListScrollOffset
	inc [hl]
	call GBPlayerRedrawList
	jp .inputLoop

.cursorMoved
	; HandleMenuInput already changed the generic menu row. Let PlaceMenuCursor
	; atomically erase/place the arrow, then update only the dynamic track number.
	ld a,[H_AUTOBGTRANSFERENABLED]
	push af
	xor a
	ld [H_AUTOBGTRANSFERENABLED],a
	call PlaceMenuCursor
	call GBPlayerDrawTrackNumber
	pop af
	ld [H_AUTOBGTRANSFERENABLED],a
	jp .inputLoop

.previousLibrary
	ld a,[wGBPlayerCategory]
	and a
	jr nz,.previousLibraryInRange
	ld a,GB_PLAYER_LIBRARY_COUNT
.previousLibraryInRange
	dec a
	jr .storeLibrary

.nextLibrary
	ld a,[wGBPlayerCategory]
	inc a
	cp GB_PLAYER_LIBRARY_COUNT
	jr c,.storeLibrary
	xor a
.storeLibrary
	ld [wGBPlayerCategory],a
	xor a
	ld [wListScrollOffset],a
	ld [wCurrentMenuItem],a
	ld [wLastMenuItem],a
	call GBPlayerLoadCategoryTable
	call GBPlayerSetupListMenuParameters
	call GBPlayerRedrawLibrary
	call GBPlayerWaitForDirectionalRelease
	jp .inputLoop

.buttonBPressed
	and a
	ret

GBPlayerWaitForVerticalRelease:
	call DelayFrame
	call Joypad
	ld a,[hJoyHeld]
	and D_UP | D_DOWN
	jr nz,GBPlayerWaitForVerticalRelease
	ret

; ---------------------------------------------------------------------------
; MoveDex-style right function menu
; ---------------------------------------------------------------------------

HandleGBPlayerSideMenu:
	; Preserve the parent cursor as MoveDex does: turn the filled left arrow into
	; the outline marker, then let HandleMenuInput own the right-side arrow.
	call PlaceUnfilledArrowMenuCursor
	ld a,[wCurrentMenuItem]
	push af
	ld b,a
	ld a,[wLastMenuItem]
	push af
	ld a,[wListScrollOffset]
	push af
	add b
	ld [wGBPlayerTrackIndex],a ; zero-based absolute track index

	ld hl,wTopMenuItemY
	ld a,10
	ld [hli],a
	ld a,15
	ld [hli],a
	xor a
	ld [hli],a
	inc hl
	ld a,GB_PLAYER_SIDE_OPTIONS - 1
	ld [hli],a
	ld a,A_BUTTON | B_BUTTON
	ld [hli],a
	xor a
	ld [hli],a
	ld [wMenuWatchMovingOutOfBounds],a

.handleMenuInput
	call HandleMenuInput
	bit 1,a
	ld b,2
	jr nz,.buttonBPressed

	ld a,[wCurrentMenuItem]
	and a
	jr z,.play
	dec a
	jr z,.resumeMap
	dec a
	jr z,.placeholderInfo
	ld b,1 ; Quit
	jr .exitSideMenu

.play
	ld a,[wGBPlayerTrackIndex]
	call GBPlayerGetTrackEntry
	ld a,[hl]
	call PlayMusic
	call GBPlayerWaitForABRelease
	jr .handleMenuInput

.resumeMap
	call PlayDefaultMusic
	call GBPlayerWaitForABRelease
	jr .handleMenuInput

.placeholderInfo
	; Reserved for per-track information in a later GB Player version.
	call GBPlayerWaitForABRelease
	jr .handleMenuInput

.buttonBPressed
	; Erase the real right-side cursor location recorded by PlaceMenuCursor, then
	; clear the whole right cursor column as the same defensive cleanup MoveDex uses.
	call EraseMenuCursor
	push bc
	coord hl,15,10
	lb bc,7,1
	call ClearScreenArea
	pop bc

.exitSideMenu
	pop af
	ld [wListScrollOffset],a
	pop af
	ld [wLastMenuItem],a
	pop af
	ld [wCurrentMenuItem],a
	push bc
	coord hl,0,3
	lb bc,13,1
	call ClearScreenArea
	pop bc
	ret

GBPlayerWaitForRelease:
	call Joypad
	ld a,[hJoyHeld]
	and A_BUTTON | B_BUTTON | D_UP | D_DOWN | D_LEFT | D_RIGHT
	ret z
	call DelayFrame
	jr GBPlayerWaitForRelease

GBPlayerWaitForABRelease:
	call DelayFrame
	call Joypad
	ld a,[hJoyHeld]
	and A_BUTTON | B_BUTTON
	jr nz,GBPlayerWaitForABRelease
	ret

GBPlayerWaitForDirectionalRelease:
	call DelayFrame
	call Joypad
	ld a,[hJoyHeld]
	and D_LEFT | D_RIGHT
	jr nz,GBPlayerWaitForDirectionalRelease
	ret

; ---------------------------------------------------------------------------
; Drawing helpers
; ---------------------------------------------------------------------------

GBPlayerDrawStaticUI:
	; Exact MoveDex/Pokédex list geometry. These $70/$71 connector tiles require
	; the Pokédex list tile patterns loaded in GBPlayerMenu.setUpGraphics.
	coord hl,15,8
	ld a,"─"
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld [hli],a
	coord hl,14,0
	ld [hl],$71
	coord hl,14,1
	call GBPlayerDrawVerticalLine
	coord hl,14,9
	call GBPlayerDrawVerticalLine

	coord hl,1,1
	ld de,GBPlayerContentsText
	call PlaceString
	coord hl,16,2
	ld de,GBPlayerLibraryLabelText
	call PlaceString
	coord hl,16,5
	ld de,GBPlayerNumberLabelText
	call PlaceString
	coord hl,16,10
	ld de,GBPlayerMenuItemsText
	call PlaceString
	call GBPlayerDrawLibraryStatus
	jp GBPlayerDrawTrackNumber

GBPlayerDrawVerticalLine:
	ld c,9
	ld de,SCREEN_WIDTH
	ld a,$71
.loop
	ld [hl],a
	add hl,de
	xor 1
	dec c
	jr nz,.loop
	ret

GBPlayerRedrawList:
	xor a
	ld [H_AUTOBGTRANSFERENABLED],a
	coord hl,0,2
	lb bc,14,14
	call ClearScreenArea
	call GBPlayerSetupListMenuParameters
	call GBPlayerDrawVisibleTracks
	call PlaceMenuCursor
	call GBPlayerDrawTrackNumber
	ld a,1
	ld [H_AUTOBGTRANSFERENABLED],a
	call Delay3
	call GBPalNormal
	ret

GBPlayerRedrawLibrary:
	xor a
	ld [H_AUTOBGTRANSFERENABLED],a
	coord hl,0,2
	lb bc,14,14
	call ClearScreenArea
	call GBPlayerDrawVisibleTracks
	call PlaceMenuCursor
	call GBPlayerDrawLibraryStatus
	call GBPlayerDrawTrackNumber
	ld a,1
	ld [H_AUTOBGTRANSFERENABLED],a
	call Delay3
	ret

GBPlayerDrawLibraryStatus:
	coord hl,16,3
	lb bc,1,4
	call ClearScreenArea
	ld a,[wGBPlayerCategory]
	add a
	ld c,a
	ld b,0
	ld hl,GBPlayerCategoryStatusPointers
	add hl,bc
	ld e,[hl]
	inc hl
	ld d,[hl]
	coord hl,16,3
	jp PlaceString

GBPlayerDrawTrackNumber:
	call GBPlayerGetSelectedTrackIndex
	inc a
	ld [wGBPlayerTrackIndex],a
	coord hl,16,6
	lb bc,1,3
	call ClearScreenArea
	coord hl,16,6
	ld de,wGBPlayerTrackIndex
	lb bc,LEADING_ZEROES | 1,3
	jp PrintNumber

GBPlayerGetSelectedTrackIndex:
	ld a,[wListScrollOffset]
	ld b,a
	ld a,[wCurrentMenuItem]
	add b
	ret

GBPlayerGetVisibleListCount:
	; OUTPUT: A = number of visible rows from current scroll offset (1..7).
	ld a,[wGBPlayerTrackCount]
	ld b,a
	ld a,[wListScrollOffset]
	ld c,a
	ld a,b
	sub c
	cp GB_PLAYER_VISIBLE_TRACKS
	ret c
	ld a,GB_PLAYER_VISIBLE_TRACKS
	ret

GBPlayerDrawVisibleTracks:
	ld a,[wListScrollOffset]
	ld [wGBPlayerDrawIndex],a
	xor a
	ld [wGBPlayerDrawRow],a
.loop
	ld a,[wGBPlayerDrawRow]
	cp GB_PLAYER_VISIBLE_TRACKS
	ret z
	ld a,[wGBPlayerDrawIndex]
	ld b,a
	ld a,[wGBPlayerTrackCount]
	cp b
	ret z

	; Number on the line above the track name, matching the MoveDex list layout.
	ld a,b
	inc a
	ld [wGBPlayerTrackIndex],a
	push bc
	ld a,[wGBPlayerDrawRow]
	call GBPlayerGetTrackRowCoord
	ld de,-SCREEN_WIDTH
	add hl,de
	inc hl
	ld de,wGBPlayerTrackIndex
	lb bc,LEADING_ZEROES | 1,3
	call PrintNumber
	pop bc

	ld a,b
	call GBPlayerGetTrackEntry
	inc hl
	ld e,[hl]
	inc hl
	ld d,[hl]
	ld a,[wGBPlayerDrawRow]
	push de
	call GBPlayerGetTrackRowCoord
	inc hl
	ld [hl]," " ; reserve MoveDex's marker column even though GB Player has no Own marker
	inc hl
	pop de
	call GBPlayerPlaceTrackName

	ld hl,wGBPlayerDrawIndex
	inc [hl]
	ld hl,wGBPlayerDrawRow
	inc [hl]
	jr .loop

GBPlayerPlaceTrackName:
	; The MoveDex left pane reserves x0 for the cursor and x1 for its marker. Keep
	; track names inside x2..x13 so they can never overwrite the x14 divider.
	ld b,GB_PLAYER_NAME_WIDTH
.loop
	ld a,[de]
	cp "@"
	ret z
	ld [hli],a
	inc de
	dec b
	jr nz,.loop
	ret

GBPlayerGetTrackRowCoord:
	; INPUT: A = visible row 0..6. OUTPUT: HL = x0, y(3 + 2*A).
	ld e,a
	coord hl,0,3
	ld a,e
	and a
	ret z
	ld bc,2 * SCREEN_WIDTH
.loop
	add hl,bc
	dec a
	jr nz,.loop
	ret

GBPlayerGetTrackEntry:
	; INPUT: A = zero-based absolute index within current category.
	; OUTPUT: HL = 3-byte entry: db MusicID, dw name.
	push af
	call GBPlayerLoadCategoryTable
	pop af
	ld c,a
	ld b,0
	add hl,bc
	add hl,bc
	add hl,bc
	ret

GBPlayerLoadCategoryTable:
	; OUTPUT: HL = category table; wGBPlayerTrackCount updated.
	ld a,[wGBPlayerCategory]
	ld e,a
	add a
	add e
	ld c,a
	ld b,0
	ld hl,GBPlayerCategoryTables
	add hl,bc
	ld e,[hl]
	inc hl
	ld d,[hl]
	inc hl
	ld a,[hl]
	ld [wGBPlayerTrackCount],a
	ld h,d
	ld l,e
	ret

GBPlayerCategoryTables:
	dw GBPlayerRBYTracks
	db GB_PLAYER_RBY_COUNT
	dw GBPlayerGSCTracks
	db GB_PLAYER_GSC_COUNT
	dw GBPlayerCustomTracks
	db GB_PLAYER_CUSTOM_COUNT

GBPlayerCategoryStatusPointers:
	dw GBPlayerRBYStatusText
	dw GBPlayerGSCStatusText
	dw GBPlayerCustomStatusText

GBPlayerContentsText:
	db "GB Player@"
GBPlayerLibraryLabelText:
	db "Lib@"
GBPlayerNumberLabelText:
	db "No.@"
GBPlayerRBYStatusText:
	db "RBY@"
GBPlayerGSCStatusText:
	db "GSC@"
GBPlayerCustomStatusText:
	db "CSTM@"
GBPlayerMenuItemsText:
	db   "Play"
	next "Map"
	next "Info"
	next "Quit@"

gbplayer_track: MACRO
	db \1
	dw \2
ENDM

GBPlayerRBYTracks:
	gbplayer_track MUSIC_PALLET_TOWN, GBPlayerRBYName00
	gbplayer_track MUSIC_POKECENTER, GBPlayerRBYName01
	gbplayer_track MUSIC_GYM, GBPlayerRBYName02
	gbplayer_track MUSIC_CITIES1, GBPlayerRBYName03
	gbplayer_track MUSIC_CITIES2, GBPlayerRBYName04
	gbplayer_track MUSIC_CELADON, GBPlayerRBYName05
	gbplayer_track MUSIC_CINNABAR, GBPlayerRBYName06
	gbplayer_track MUSIC_VERMILION, GBPlayerRBYName07
	gbplayer_track MUSIC_LAVENDER, GBPlayerRBYName08
	gbplayer_track MUSIC_SS_ANNE, GBPlayerRBYName09
	gbplayer_track MUSIC_MEET_PROF_OAK, GBPlayerRBYName10
	gbplayer_track MUSIC_MEET_RIVAL, GBPlayerRBYName11
	gbplayer_track MUSIC_MUSEUM_GUY, GBPlayerRBYName12
	gbplayer_track MUSIC_SAFARI_ZONE, GBPlayerRBYName13
	gbplayer_track MUSIC_PKMN_HEALED, GBPlayerRBYName14
	gbplayer_track MUSIC_ROUTES1, GBPlayerRBYName15
	gbplayer_track MUSIC_ROUTES2, GBPlayerRBYName16
	gbplayer_track MUSIC_ROUTES3, GBPlayerRBYName17
	gbplayer_track MUSIC_ROUTES4, GBPlayerRBYName18
	gbplayer_track MUSIC_INDIGO_PLATEAU, GBPlayerRBYName19
	gbplayer_track MUSIC_GYM_LEADER_BATTLE, GBPlayerRBYName20
	gbplayer_track MUSIC_TRAINER_BATTLE, GBPlayerRBYName21
	gbplayer_track MUSIC_WILD_BATTLE, GBPlayerRBYName22
	gbplayer_track MUSIC_FINAL_BATTLE, GBPlayerRBYName23
	gbplayer_track MUSIC_DEFEATED_TRAINER, GBPlayerRBYName24
	gbplayer_track MUSIC_DEFEATED_WILD_MON, GBPlayerRBYName25
	gbplayer_track MUSIC_DEFEATED_GYM_LEADER, GBPlayerRBYName26
	gbplayer_track MUSIC_TITLE_SCREEN, GBPlayerRBYName27
	gbplayer_track MUSIC_CREDITS, GBPlayerRBYName28
	gbplayer_track MUSIC_HALL_OF_FAME, GBPlayerRBYName29
	gbplayer_track MUSIC_OAKS_LAB, GBPlayerRBYName30
	gbplayer_track MUSIC_JIGGLYPUFF_SONG, GBPlayerRBYName31
	gbplayer_track MUSIC_BIKE_RIDING, GBPlayerRBYName32
	gbplayer_track MUSIC_SURFING, GBPlayerRBYName33
	gbplayer_track MUSIC_GAME_CORNER, GBPlayerRBYName34
	gbplayer_track MUSIC_INTRO_BATTLE, GBPlayerRBYName35
	gbplayer_track MUSIC_DUNGEON1, GBPlayerRBYName36
	gbplayer_track MUSIC_DUNGEON2, GBPlayerRBYName37
	gbplayer_track MUSIC_DUNGEON3, GBPlayerRBYName38
	gbplayer_track MUSIC_CINNABAR_MANSION, GBPlayerRBYName39
	gbplayer_track MUSIC_POKEMON_TOWER, GBPlayerRBYName40
	gbplayer_track MUSIC_SILPH_CO, GBPlayerRBYName41
	gbplayer_track MUSIC_MEET_EVIL_TRAINER, GBPlayerRBYName42
	gbplayer_track MUSIC_MEET_FEMALE_TRAINER, GBPlayerRBYName43
	gbplayer_track MUSIC_MEET_MALE_TRAINER, GBPlayerRBYName44

GBPlayerGSCTracks:
	gbplayer_track MUSIC_GBP_GSC_ROUTE36, GBPlayerGSCName000
	gbplayer_track MUSIC_GBP_GSC_RIVAL_BATTLE, GBPlayerGSCName001
	gbplayer_track MUSIC_GBP_GSC_ROCKET_BATTLE, GBPlayerGSCName002
	gbplayer_track MUSIC_GBP_GSC_ELMS_LAB, GBPlayerGSCName003
	gbplayer_track MUSIC_GBP_GSC_DARK_CAVE, GBPlayerGSCName004
	gbplayer_track MUSIC_GBP_GSC_JOHTO_GYM_BATTLE, GBPlayerGSCName005
	gbplayer_track MUSIC_GBP_GSC_CHAMPION_BATTLE, GBPlayerGSCName006
	gbplayer_track MUSIC_GBP_GSC_SS_AQUA, GBPlayerGSCName007
	gbplayer_track MUSIC_GBP_GSC_NEW_BARK_TOWN, GBPlayerGSCName008
	gbplayer_track MUSIC_GBP_GSC_GOLDENROD_CITY, GBPlayerGSCName009
	gbplayer_track MUSIC_GBP_GSC_VERMILION_CITY, GBPlayerGSCName010
	gbplayer_track MUSIC_GBP_GSC_TITLE_SCREEN, GBPlayerGSCName011
	gbplayer_track MUSIC_GBP_GSC_RUINS_OF_ALPH_INTERIOR, GBPlayerGSCName012
	gbplayer_track MUSIC_GBP_GSC_LOOK_POKEMANIAC, GBPlayerGSCName013
	gbplayer_track MUSIC_GBP_GSC_TRAINER_VICTORY, GBPlayerGSCName014
	gbplayer_track MUSIC_GBP_GSC_ROUTE1, GBPlayerGSCName015
	gbplayer_track MUSIC_GBP_GSC_ROUTE3, GBPlayerGSCName016
	gbplayer_track MUSIC_GBP_GSC_ROUTE12, GBPlayerGSCName017
	gbplayer_track MUSIC_GBP_GSC_KANTO_GYM_BATTLE, GBPlayerGSCName018
	gbplayer_track MUSIC_GBP_GSC_KANTO_WILD_BATTLE, GBPlayerGSCName019
	gbplayer_track MUSIC_GBP_GSC_POKEMON_CENTER, GBPlayerGSCName020
	gbplayer_track MUSIC_GBP_GSC_LOOK_LASS, GBPlayerGSCName021
	gbplayer_track MUSIC_GBP_GSC_LOOK_OFFICER, GBPlayerGSCName022
	gbplayer_track MUSIC_GBP_GSC_ROUTE2, GBPlayerGSCName023
	gbplayer_track MUSIC_GBP_GSC_MT_MOON, GBPlayerGSCName024
	gbplayer_track MUSIC_GBP_GSC_SHOW_ME_AROUND, GBPlayerGSCName025
	gbplayer_track MUSIC_GBP_GSC_GAME_CORNER, GBPlayerGSCName026
	gbplayer_track MUSIC_GBP_GSC_BICYCLE, GBPlayerGSCName027
	gbplayer_track MUSIC_GBP_GSC_LOOK_SAGE, GBPlayerGSCName028
	gbplayer_track MUSIC_GBP_GSC_POKEMON_CHANNEL, GBPlayerGSCName029
	gbplayer_track MUSIC_GBP_GSC_LIGHTHOUSE, GBPlayerGSCName030
	gbplayer_track MUSIC_GBP_GSC_LAKE_OF_RAGE, GBPlayerGSCName031
	gbplayer_track MUSIC_GBP_GSC_INDIGO_PLATEAU, GBPlayerGSCName032
	gbplayer_track MUSIC_GBP_GSC_ROUTE37, GBPlayerGSCName033
	gbplayer_track MUSIC_GBP_GSC_ROCKET_HIDEOUT, GBPlayerGSCName034
	gbplayer_track MUSIC_GBP_GSC_DRAGONS_DEN, GBPlayerGSCName035
	gbplayer_track MUSIC_GBP_GSC_RUINS_OF_ALPH_RADIO, GBPlayerGSCName036
	gbplayer_track MUSIC_GBP_GSC_LOOK_BEAUTY, GBPlayerGSCName037
	gbplayer_track MUSIC_GBP_GSC_ROUTE26, GBPlayerGSCName038
	gbplayer_track MUSIC_GBP_GSC_ECRUTEAK_CITY, GBPlayerGSCName039
	gbplayer_track MUSIC_GBP_GSC_LAKE_OF_RAGE_ROCKET_RADIO, GBPlayerGSCName040
	gbplayer_track MUSIC_GBP_GSC_MAGNET_TRAIN, GBPlayerGSCName041
	gbplayer_track MUSIC_GBP_GSC_LAVENDER_TOWN, GBPlayerGSCName042
	gbplayer_track MUSIC_GBP_GSC_DANCING_HALL, GBPlayerGSCName043
	gbplayer_track MUSIC_GBP_GSC_CONTEST_RESULTS, GBPlayerGSCName044
	gbplayer_track MUSIC_GBP_GSC_ROUTE30, GBPlayerGSCName045
	gbplayer_track MUSIC_GBP_GSC_VIOLET_CITY, GBPlayerGSCName046
	gbplayer_track MUSIC_GBP_GSC_ROUTE29, GBPlayerGSCName047
	gbplayer_track MUSIC_GBP_GSC_HALL_OF_FAME, GBPlayerGSCName048
	gbplayer_track MUSIC_GBP_GSC_HEAL_POKEMON, GBPlayerGSCName049
	gbplayer_track MUSIC_GBP_GSC_EVOLUTION, GBPlayerGSCName050
	gbplayer_track MUSIC_GBP_GSC_PRINTER, GBPlayerGSCName051
	gbplayer_track MUSIC_GBP_GSC_VIRIDIAN_CITY, GBPlayerGSCName052
	gbplayer_track MUSIC_GBP_GSC_CELADON_CITY, GBPlayerGSCName053
	gbplayer_track MUSIC_GBP_GSC_WILD_POKEMON_VICTORY, GBPlayerGSCName054
	gbplayer_track MUSIC_GBP_GSC_SUCCESSFUL_CAPTURE, GBPlayerGSCName055
	gbplayer_track MUSIC_GBP_GSC_GYM_LEADER_VICTORY, GBPlayerGSCName056
	gbplayer_track MUSIC_GBP_GSC_MT_MOON_SQUARE, GBPlayerGSCName057
	gbplayer_track MUSIC_GBP_GSC_GYM, GBPlayerGSCName058
	gbplayer_track MUSIC_GBP_GSC_PALLET_TOWN, GBPlayerGSCName059
	gbplayer_track MUSIC_GBP_GSC_PROF_OAKS_POKEMON_TALK, GBPlayerGSCName060
	gbplayer_track MUSIC_GBP_GSC_PROF_OAK, GBPlayerGSCName061
	gbplayer_track MUSIC_GBP_GSC_LOOK_RIVAL, GBPlayerGSCName062
	gbplayer_track MUSIC_GBP_GSC_AFTER_THE_RIVAL_FIGHT, GBPlayerGSCName063
	gbplayer_track MUSIC_GBP_GSC_SURF, GBPlayerGSCName064
	gbplayer_track MUSIC_GBP_GSC_NATIONAL_PARK, GBPlayerGSCName065
	gbplayer_track MUSIC_GBP_GSC_AZALEA_TOWN, GBPlayerGSCName066
	gbplayer_track MUSIC_GBP_GSC_CHERRYGROVE_CITY, GBPlayerGSCName067
	gbplayer_track MUSIC_GBP_GSC_UNION_CAVE, GBPlayerGSCName068
	gbplayer_track MUSIC_GBP_GSC_JOHTO_WILD_BATTLE, GBPlayerGSCName069
	gbplayer_track MUSIC_GBP_GSC_JOHTO_WILD_BATTLE_NIGHT, GBPlayerGSCName070
	gbplayer_track MUSIC_GBP_GSC_JOHTO_TRAINER_BATTLE, GBPlayerGSCName071
	gbplayer_track MUSIC_GBP_GSC_LOOK_YOUNGSTER, GBPlayerGSCName072
	gbplayer_track MUSIC_GBP_GSC_TIN_TOWER, GBPlayerGSCName073
	gbplayer_track MUSIC_GBP_GSC_SPROUT_TOWER, GBPlayerGSCName074
	gbplayer_track MUSIC_GBP_GSC_BURNED_TOWER, GBPlayerGSCName075
	gbplayer_track MUSIC_GBP_GSC_MOM, GBPlayerGSCName076
	gbplayer_track MUSIC_GBP_GSC_VICTORY_ROAD, GBPlayerGSCName077
	gbplayer_track MUSIC_GBP_GSC_POKEMON_LULLABY, GBPlayerGSCName078
	gbplayer_track MUSIC_GBP_GSC_POKEMON_MARCH, GBPlayerGSCName079
	gbplayer_track MUSIC_GBP_GSC_GOLD_SILVER_OPENING, GBPlayerGSCName080
	gbplayer_track MUSIC_GBP_GSC_GOLD_SILVER_OPENING2, GBPlayerGSCName081
	gbplayer_track MUSIC_GBP_GSC_LOOK_HIKER, GBPlayerGSCName082
	gbplayer_track MUSIC_GBP_GSC_LOOK_ROCKET, GBPlayerGSCName083
	gbplayer_track MUSIC_GBP_GSC_ROCKET_THEME, GBPlayerGSCName084
	gbplayer_track MUSIC_GBP_GSC_MAIN_MENU, GBPlayerGSCName085
	gbplayer_track MUSIC_GBP_GSC_LOOK_KIMONO_GIRL, GBPlayerGSCName086
	gbplayer_track MUSIC_GBP_GSC_POKE_FLUTE_CHANNEL, GBPlayerGSCName087
	gbplayer_track MUSIC_GBP_GSC_BUG_CATCHING_CONTEST, GBPlayerGSCName088
	gbplayer_track MUSIC_GBP_GSC_KANTO_TRAINER_BATTLE, GBPlayerGSCName089
	gbplayer_track MUSIC_GBP_GSC_CREDITS, GBPlayerGSCName090
	gbplayer_track MUSIC_GBP_GSC_POST_CREDITS, GBPlayerGSCName091
	gbplayer_track MUSIC_GBP_GSC_CLAIR, GBPlayerGSCName092
	gbplayer_track MUSIC_GBP_GSC_MOBILE_ADAPTER_MENU, GBPlayerGSCName093
	gbplayer_track MUSIC_GBP_GSC_MOBILE_ADAPTER, GBPlayerGSCName094
	gbplayer_track MUSIC_GBP_GSC_BUENAS_PASSWORD, GBPlayerGSCName095
	gbplayer_track MUSIC_GBP_GSC_LOOK_MYSTICAL_MAN, GBPlayerGSCName096
	gbplayer_track MUSIC_GBP_GSC_CRYSTAL_OPENING, GBPlayerGSCName097
	gbplayer_track MUSIC_GBP_GSC_BATTLE_TOWER_THEME, GBPlayerGSCName098
	gbplayer_track MUSIC_GBP_GSC_SUICUNE_BATTLE, GBPlayerGSCName099
	gbplayer_track MUSIC_GBP_GSC_BATTLE_TOWER_LOBBY, GBPlayerGSCName100
	gbplayer_track MUSIC_GBP_GSC_MOBILE_CENTER, GBPlayerGSCName101

GBPlayerCustomTracks:
	gbplayer_track MUSIC_GBP_CUSTOM_JOHTO_GSC, GBPlayerCustomName00
	gbplayer_track MUSIC_GBP_CUSTOM_CERULEAN_GSC, GBPlayerCustomName01
	gbplayer_track MUSIC_GBP_CUSTOM_CINNABAR_GSC, GBPlayerCustomName02
	gbplayer_track MUSIC_GBP_CUSTOM_NUGGET_BRIDGE, GBPlayerCustomName03
	gbplayer_track MUSIC_GBP_CUSTOM_SHOP, GBPlayerCustomName04
	gbplayer_track MUSIC_GBP_CUSTOM_POKEATHELON_FINAL, GBPlayerCustomName05
	gbplayer_track MUSIC_GBP_CUSTOM_NALJO_WILD_BATTLE, GBPlayerCustomName06
	gbplayer_track MUSIC_GBP_CUSTOM_NALJO_GYM_BATTLE, GBPlayerCustomName07
	gbplayer_track MUSIC_GBP_CUSTOM_PALLET_BATTLE, GBPlayerCustomName08
	gbplayer_track MUSIC_GBP_CUSTOM_CINNABAR_REMIX, GBPlayerCustomName09
	gbplayer_track MUSIC_GBP_CUSTOM_KANTO_GYM_LEADER_REMIX, GBPlayerCustomName10

; Display names are capped at 12 characters to fit beside the cursor.
GBPlayerRBYName00: db "Pallet Town@"
GBPlayerRBYName01: db "Pokémon Center@"
GBPlayerRBYName02: db "Gym@"
GBPlayerRBYName03: db "Cities 1@"
GBPlayerRBYName04: db "Cities 2@"
GBPlayerRBYName05: db "Celadon City@"
GBPlayerRBYName06: db "Cinnabar Island@"
GBPlayerRBYName07: db "Vermilion City@"
GBPlayerRBYName08: db "Lavender Town@"
GBPlayerRBYName09: db "S.S. Anne@"
GBPlayerRBYName10: db "Meet Prof. Oak@"
GBPlayerRBYName11: db "Meet Rival@"
GBPlayerRBYName12: db "Museum Guy@"
GBPlayerRBYName13: db "Safari Zone@"
GBPlayerRBYName14: db "Pokémon Healed@"
GBPlayerRBYName15: db "Routes 1@"
GBPlayerRBYName16: db "Routes 2@"
GBPlayerRBYName17: db "Routes 3@"
GBPlayerRBYName18: db "Routes 4@"
GBPlayerRBYName19: db "Indigo Plateau@"
GBPlayerRBYName20: db "Gym Leader Battle@"
GBPlayerRBYName21: db "Trainer Battle@"
GBPlayerRBYName22: db "Wild Battle@"
GBPlayerRBYName23: db "Final Battle@"
GBPlayerRBYName24: db "Trainer Victory@"
GBPlayerRBYName25: db "Wild Victory@"
GBPlayerRBYName26: db "Gym Leader Victory@"
GBPlayerRBYName27: db "Title Screen@"
GBPlayerRBYName28: db "Credits@"
GBPlayerRBYName29: db "Hall of Fame@"
GBPlayerRBYName30: db "Oak's Lab@"
GBPlayerRBYName31: db "Jigglypuff Song@"
GBPlayerRBYName32: db "Bike Riding@"
GBPlayerRBYName33: db "Surfing@"
GBPlayerRBYName34: db "Game Corner@"
GBPlayerRBYName35: db "Intro Battle@"
GBPlayerRBYName36: db "Dungeon 1@"
GBPlayerRBYName37: db "Dungeon 2@"
GBPlayerRBYName38: db "Dungeon 3@"
GBPlayerRBYName39: db "Cinnabar Mansion@"
GBPlayerRBYName40: db "Pokémon Tower@"
GBPlayerRBYName41: db "Silph Co.@"
GBPlayerRBYName42: db "Meet Evil Trainer@"
GBPlayerRBYName43: db "Meet Female@"
GBPlayerRBYName44: db "Meet Male@"
GBPlayerGSCName000: db "Route 36@"
GBPlayerGSCName001: db "Rival Battle@"
GBPlayerGSCName002: db "Rocket Battle@"
GBPlayerGSCName003: db "Elm's Lab@"
GBPlayerGSCName004: db "Dark Cave@"
GBPlayerGSCName005: db "Johto Gym Battle@"
GBPlayerGSCName006: db "Champion Battle@"
GBPlayerGSCName007: db "S.S. Aqua@"
GBPlayerGSCName008: db "New Bark Town@"
GBPlayerGSCName009: db "Goldenrod City@"
GBPlayerGSCName010: db "Vermilion City@"
GBPlayerGSCName011: db "Title Screen@"
GBPlayerGSCName012: db "Ruins Alph Inside@"
GBPlayerGSCName013: db "Look Pokemaniac@"
GBPlayerGSCName014: db "Trainer Victory@"
GBPlayerGSCName015: db "Route 1@"
GBPlayerGSCName016: db "Route 3@"
GBPlayerGSCName017: db "Route 12@"
GBPlayerGSCName018: db "Kanto Gym Battle@"
GBPlayerGSCName019: db "Kanto Wild Battle@"
GBPlayerGSCName020: db "Pokémon Center@"
GBPlayerGSCName021: db "Look Lass@"
GBPlayerGSCName022: db "Look Officer@"
GBPlayerGSCName023: db "Route 2@"
GBPlayerGSCName024: db "Mt Moon@"
GBPlayerGSCName025: db "Show Me Around@"
GBPlayerGSCName026: db "Game Corner@"
GBPlayerGSCName027: db "Bicycle@"
GBPlayerGSCName028: db "Look Sage@"
GBPlayerGSCName029: db "Pokémon Channel@"
GBPlayerGSCName030: db "Lighthouse@"
GBPlayerGSCName031: db "Lake Of Rage@"
GBPlayerGSCName032: db "Indigo Plateau@"
GBPlayerGSCName033: db "Route 37@"
GBPlayerGSCName034: db "Rocket Hideout@"
GBPlayerGSCName035: db "Dragons Den@"
GBPlayerGSCName036: db "Ruins Alph Radio@"
GBPlayerGSCName037: db "Look Beauty@"
GBPlayerGSCName038: db "Route 26@"
GBPlayerGSCName039: db "Ecruteak City@"
GBPlayerGSCName040: db "Rage Rocket Radio@"
GBPlayerGSCName041: db "Magnet Train@"
GBPlayerGSCName042: db "Lavender Town@"
GBPlayerGSCName043: db "Dancing Hall@"
GBPlayerGSCName044: db "Contest Results@"
GBPlayerGSCName045: db "Route 30@"
GBPlayerGSCName046: db "Violet City@"
GBPlayerGSCName047: db "Route 29@"
GBPlayerGSCName048: db "Hall Of Fame@"
GBPlayerGSCName049: db "Heal Pokémon@"
GBPlayerGSCName050: db "Evolution@"
GBPlayerGSCName051: db "Printer@"
GBPlayerGSCName052: db "Viridian City@"
GBPlayerGSCName053: db "Celadon City@"
GBPlayerGSCName054: db "Wild Victory@"
GBPlayerGSCName055: db "Successful Capture@"
GBPlayerGSCName056: db "Gym Leader Victory@"
GBPlayerGSCName057: db "Mt Moon Square@"
GBPlayerGSCName058: db "Gym@"
GBPlayerGSCName059: db "Pallet Town@"
GBPlayerGSCName060: db "Oak's Poké Talk@"
GBPlayerGSCName061: db "Prof Oak@"
GBPlayerGSCName062: db "Look Rival@"
GBPlayerGSCName063: db "After Rival Fight@"
GBPlayerGSCName064: db "Surf@"
GBPlayerGSCName065: db "National Park@"
GBPlayerGSCName066: db "Azalea Town@"
GBPlayerGSCName067: db "Cherrygrove City@"
GBPlayerGSCName068: db "Union Cave@"
GBPlayerGSCName069: db "Johto Wild Battle@"
GBPlayerGSCName070: db "Johto Wild Night@"
GBPlayerGSCName071: db "Johto Trainer@"
GBPlayerGSCName072: db "Look Youngster@"
GBPlayerGSCName073: db "Tin Tower@"
GBPlayerGSCName074: db "Sprout Tower@"
GBPlayerGSCName075: db "Burned Tower@"
GBPlayerGSCName076: db "Mom@"
GBPlayerGSCName077: db "Victory Road@"
GBPlayerGSCName078: db "Pokémon Lullaby@"
GBPlayerGSCName079: db "Pokémon March@"
GBPlayerGSCName080: db "G/S Opening@"
GBPlayerGSCName081: db "G/S Opening 2@"
GBPlayerGSCName082: db "Look Hiker@"
GBPlayerGSCName083: db "Look Rocket@"
GBPlayerGSCName084: db "Rocket Theme@"
GBPlayerGSCName085: db "Main Menu@"
GBPlayerGSCName086: db "Look Kimono Girl@"
GBPlayerGSCName087: db "Poké Flute Channel@"
GBPlayerGSCName088: db "Bug Contest@"
GBPlayerGSCName089: db "Kanto Trainer@"
GBPlayerGSCName090: db "Credits@"
GBPlayerGSCName091: db "Post Credits@"
GBPlayerGSCName092: db "Clair@"
GBPlayerGSCName093: db "Mobile Menu@"
GBPlayerGSCName094: db "Mobile Adapter@"
GBPlayerGSCName095: db "Buenas Password@"
GBPlayerGSCName096: db "Look Mystical Man@"
GBPlayerGSCName097: db "Crystal Opening@"
GBPlayerGSCName098: db "Battle Tower Theme@"
GBPlayerGSCName099: db "Suicune Battle@"
GBPlayerGSCName100: db "Battle Tower Lobby@"
GBPlayerGSCName101: db "Mobile Center@"
GBPlayerCustomName00: db "Johto GSC@"
GBPlayerCustomName01: db "Cerulean GSC@"
GBPlayerCustomName02: db "Cinnabar GSC@"
GBPlayerCustomName03: db "Nugget Bridge@"
GBPlayerCustomName04: db "Shop@"
GBPlayerCustomName05: db "Pokeathelon Final@"
GBPlayerCustomName06: db "Naljo Wild Battle@"
GBPlayerCustomName07: db "Naljo Gym Battle@"
GBPlayerCustomName08: db "Pallet Battle@"
GBPlayerCustomName09: db "Cinnabar Remix@"
GBPlayerCustomName10: db "Kanto Gym Remix@"
