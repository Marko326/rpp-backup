; GBP-5.56.01: GB Player UI with flicker-free cursor/list refresh.
; Static screens are drawn only on screen transitions. Cursor moves update only
; reserved cursor tiles, while track scrolling redraws its list area atomically
; with automatic BG transfer paused, matching the Pokédex/MoveDex pattern.
; Track selection still stays separate from the map/battle soundtrack policy:
; selecting a track plays it immediately, while RESUME MAP BGM hands control
; back to the normal overworld music resolver.

GB_PLAYER_VISIBLE_TRACKS EQU 7
GB_PLAYER_MAIN_OPTIONS   EQU 5
GB_PLAYER_RBY_COUNT      EQU 45
GB_PLAYER_GSC_COUNT      EQU 102
GB_PLAYER_CUSTOM_COUNT   EQU 11

GBPlayerMenu::
	call GBPlayerWaitForRelease
	xor a
	ld [wGBPlayerCursorRow], a
	call GBPlayerDrawMainMenu

.mainLoop
	call GBPlayerWaitInput
	bit 1, a ; B
	ret nz
	bit 6, a ; Up
	jr nz, .up
	bit 7, a ; Down
	jr nz, .down
	bit 0, a ; A
	jr nz, .choose
	jr .mainLoop

.up
	ld hl, wGBPlayerCursorRow
	ld a, [hl]
	and a
	jr nz, .decrementMain
	ld [hl], GB_PLAYER_MAIN_OPTIONS - 1
	call GBPlayerDrawMainCursor
	jr .mainLoop
.decrementMain
	dec [hl]
	call GBPlayerDrawMainCursor
	jr .mainLoop

.down
	ld hl, wGBPlayerCursorRow
	ld a, [hl]
	inc a
	cp GB_PLAYER_MAIN_OPTIONS
	jr c, .storeMain
	xor a
.storeMain
	ld [hl], a
	call GBPlayerDrawMainCursor
	jr .mainLoop

.choose
	ld a, [wGBPlayerCursorRow]
	cp 3
	jr c, .openCategory
	jr z, .resumeMap
	ret ; EXIT

.openCategory
	ld [wGBPlayerCategory], a
	xor a
	ld [wGBPlayerTrackIndex], a
	call GBPlayerLoadCategoryTable
	call GBPlayerTrackMenu
	call GBPlayerWaitForRelease
	; Return to the category the player just browsed. The track screen replaced
	; the main screen, so this is a real screen transition and needs one redraw.
	ld a, [wGBPlayerCategory]
	ld [wGBPlayerCursorRow], a
	call GBPlayerDrawMainMenu
	jr .mainLoop

.resumeMap
	call PlayDefaultMusic
	call GBPlayerWaitForRelease
	jr .mainLoop

GBPlayerTrackMenu:
	call GBPlayerWaitForRelease
	call GBPlayerDrawTrackMenu
.loop
	call GBPlayerWaitInput
	bit 1, a ; B
	ret nz
	bit 6, a ; Up
	jr nz, .up
	bit 7, a ; Down
	jr nz, .down
	bit 0, a ; A
	jr nz, .play
	jr .loop

.up
	ld hl, wGBPlayerTrackIndex
	ld a, [hl]
	and a
	jr nz, .decrement
	ld a, [wGBPlayerTrackCount]
	dec a
	ld [hl], a
	call GBPlayerRefreshTrackSelection
	jr .loop
.decrement
	dec [hl]
	call GBPlayerRefreshTrackSelection
	jr .loop

.down
	ld hl, wGBPlayerTrackIndex
	ld a, [hl]
	inc a
	ld b, a
	ld a, [wGBPlayerTrackCount]
	cp b
	jr nz, .storeDown
	xor a
	ld b, a
.storeDown
	ld [hl], b
	call GBPlayerRefreshTrackSelection
	jr .loop

.play
	ld a, [wGBPlayerTrackIndex]
	call GBPlayerGetTrackEntry
	ld a, [hl] ; regular/extended Music ID
	call PlayMusic
	jr .loop

GBPlayerWaitForRelease:
	call Joypad
	ld a, [hJoyHeld]
	and A_BUTTON | B_BUTTON | D_UP | D_DOWN
	ret z
	call DelayFrame
	jr GBPlayerWaitForRelease

GBPlayerWaitInput:
	call Delay3
.loop
	call JoypadLowSensitivity
	ld a, [hJoy5]
	and A_BUTTON | B_BUTTON | D_UP | D_DOWN
	jr z, .loop
	ret

GBPlayerDrawMainMenu:
	call ClearScreen
	call LoadTextBoxTilePatterns
	call RunDefaultPaletteCommand
	coord hl, 5, 0
	ld de, GBPlayerTitleText
	call PlaceString
	coord hl, 2, 2
	ld de, GBPlayerChooseText
	call PlaceString

	coord hl, 3, 4
	ld de, GBPlayerRBYText
	call PlaceString
	coord hl, 3, 6
	ld de, GBPlayerGSCText
	call PlaceString
	coord hl, 3, 8
	ld de, GBPlayerCustomText
	call PlaceString
	coord hl, 3, 10
	ld de, GBPlayerResumeText
	call PlaceString
	coord hl, 3, 12
	ld de, GBPlayerExitText
	call PlaceString

	coord hl, 2, 16
	ld de, GBPlayerMainFooterText
	call PlaceString

	call GBPlayerDrawMainCursor
	ret

GBPlayerDrawTrackMenu:
	call ClearScreen
	call LoadTextBoxTilePatterns
	call RunDefaultPaletteCommand
	coord hl, 5, 0
	ld de, GBPlayerTitleText
	call PlaceString
	call GBPlayerPlaceCategoryTitle
	coord hl, 2, 17
	ld de, GBPlayerTrackFooterText
	call PlaceString
	call GBPlayerComputeWindow
	call GBPlayerDrawVisibleTracks
	call GBPlayerDrawTrackCursor
	ret

GBPlayerPlaceCategoryTitle:
	ld a, [wGBPlayerCategory]
	add a
	ld c, a
	ld b, 0
	ld hl, GBPlayerCategoryTitlePointers
	add hl, bc
	ld e, [hl]
	inc hl
	ld d, [hl]
	coord hl, 7, 1
	jp PlaceString

GBPlayerComputeWindow:
	xor a
	ld [wGBPlayerScrollOffset], a
	ld a, [wGBPlayerTrackCount]
	cp GB_PLAYER_VISIBLE_TRACKS + 1
	jr c, .cursor

	ld a, [wGBPlayerTrackIndex]
	cp 3
	jr c, .cursor
	sub 3
	ld b, a ; candidate scroll

	ld a, [wGBPlayerTrackCount]
	sub GB_PLAYER_VISIBLE_TRACKS
	cp b
	jr nc, .storeCandidate
	ld b, a
.storeCandidate
	ld a, b
	ld [wGBPlayerScrollOffset], a

.cursor
	ld a, [wGBPlayerTrackIndex]
	ld b, a
	ld a, [wGBPlayerScrollOffset]
	ld c, a
	ld a, b
	sub c
	ld [wGBPlayerCursorRow], a
	ret

GBPlayerDrawVisibleTracks:
	ld a, [wGBPlayerScrollOffset]
	ld [wGBPlayerDrawIndex], a
	xor a
	ld [wGBPlayerDrawRow], a
.loop
	ld a, [wGBPlayerDrawRow]
	cp GB_PLAYER_VISIBLE_TRACKS
	ret z

	ld a, [wGBPlayerDrawIndex]
	ld b, a
	ld a, [wGBPlayerTrackCount]
	cp b
	ret z

	ld a, b
	call GBPlayerGetTrackEntry
	inc hl ; skip Music ID
	ld e, [hl]
	inc hl
	ld d, [hl]

	ld a, [wGBPlayerDrawRow]
	push de ; GBPlayerGetTrackRowCoord uses E as scratch.
	call GBPlayerGetTrackRowCoord
	pop de
	call PlaceString

	ld hl, wGBPlayerDrawIndex
	inc [hl]
	ld hl, wGBPlayerDrawRow
	inc [hl]
	jr .loop

GBPlayerDrawMainCursor:
	coord hl, 1, 4
	ld b, GB_PLAYER_MAIN_OPTIONS
	jr GBPlayerDrawCursorRows

GBPlayerDrawTrackCursor:
	coord hl, 0, 3
	ld b, GB_PLAYER_VISIBLE_TRACKS

GBPlayerDrawCursorRows:
; INPUT: HL = first reserved cursor tile, B = number of double-spaced rows.
; Clear every reserved cursor cell and place the current arrow while automatic
; BG transfer is paused, so VBlank can never expose the erase/place midpoint.
	ld a, [H_AUTOBGTRANSFERENABLED]
	push af
	xor a
	ld [H_AUTOBGTRANSFERENABLED], a
	push hl
	ld de, 2 * SCREEN_WIDTH
.clearLoop
	ld [hl], " "
	add hl, de
	dec b
	jr nz, .clearLoop
	pop hl
	ld a, [wGBPlayerCursorRow]
	and a
	jr z, .place
	ld bc, 2 * SCREEN_WIDTH
.seekLoop
	add hl, bc
	dec a
	jr nz, .seekLoop
.place
	ld [hl], "▶"
	pop af
	ld [H_AUTOBGTRANSFERENABLED], a
	ret

GBPlayerRefreshTrackSelection:
; Recompute the centered seven-row window after Up/Down. If the window did not
; move, only refresh the cursor. If it scrolled, redraw only the track rows and
; keep that redraw hidden until the shadow tilemap is complete.
	ld a, [wGBPlayerScrollOffset]
	ld [wGBPlayerDrawIndex], a ; temporary old scroll offset
	call GBPlayerComputeWindow
	ld a, [wGBPlayerScrollOffset]
	ld b, a
	ld a, [wGBPlayerDrawIndex]
	cp b
	jr z, .cursorOnly

	ld a, [H_AUTOBGTRANSFERENABLED]
	push af
	xor a
	ld [H_AUTOBGTRANSFERENABLED], a
	coord hl, 0, 3
	lb bc, 13, SCREEN_WIDTH
	call ClearScreenArea
	call GBPlayerDrawVisibleTracks
	call GBPlayerDrawTrackCursor
	pop af
	ld [H_AUTOBGTRANSFERENABLED], a
	ret

.cursorOnly
	jp GBPlayerDrawTrackCursor

GBPlayerGetTrackRowCoord:
; INPUT: A = visible row 0..6. OUTPUT: HL = x2, y(3 + 2*A).
	ld e, a
	coord hl, 2, 3
	ld a, e
	and a
	ret z
	ld bc, 2 * SCREEN_WIDTH
.loop
	add hl, bc
	dec a
	jr nz, .loop
	ret

GBPlayerGetTrackEntry:
; INPUT: A = absolute index within current category.
; OUTPUT: HL = 3-byte entry: db MusicID, dw name.
	push af
	call GBPlayerLoadCategoryTable
	pop af
	ld c, a
	ld b, 0
	add hl, bc
	add hl, bc
	add hl, bc
	ret

GBPlayerLoadCategoryTable:
; OUTPUT: HL = category table; wGBPlayerTrackCount updated.
	ld a, [wGBPlayerCategory]
	ld e, a
	add a
	add e ; A = category * 3
	ld c, a
	ld b, 0
	ld hl, GBPlayerCategoryTables
	add hl, bc
	ld e, [hl]
	inc hl
	ld d, [hl]
	inc hl
	ld a, [hl]
	ld [wGBPlayerTrackCount], a
	ld h, d
	ld l, e
	ret

GBPlayerCategoryTables:
	dw GBPlayerRBYTracks
	db GB_PLAYER_RBY_COUNT
	dw GBPlayerGSCTracks
	db GB_PLAYER_GSC_COUNT
	dw GBPlayerCustomTracks
	db GB_PLAYER_CUSTOM_COUNT

GBPlayerCategoryTitlePointers:
	dw GBPlayerRBYText
	dw GBPlayerGSCText
	dw GBPlayerCustomText

GBPlayerTitleText:
	db "GB PLAYER@"
GBPlayerChooseText:
	db "SELECT LIBRARY@"
GBPlayerRBYText:
	db "RBY@"
GBPlayerGSCText:
	db "GSC@"
GBPlayerCustomText:
	db "CUSTOM@"
GBPlayerResumeText:
	db "RESUME MAP BGM@"
GBPlayerExitText:
	db "EXIT@"
GBPlayerMainFooterText:
	db "A:SELECT B:EXIT@"
GBPlayerTrackFooterText:
	db "A:PLAY B:BACK@"

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

; Display names are capped at 18 characters to fit beside the cursor.
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
