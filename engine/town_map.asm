DisplayTownMap:
	ld a, [hTilesetType]
	push af
	xor a
	ld [hTilesetType], a
	call LoadTownMap
	ld hl, wUpdateSpritesEnabled
	ld a, [hl]
	push af
	ld [hl], $ff
	push hl
	ld a, $1
	ld [hJoy7], a
	callab GetFlyTownMapPlayerMap
	ld a, d
	push af
	ld b, $0
	call DrawPlayerOrBirdSprite ; player sprite
	coord hl, 0, 0
	ld a, $3f ; up/down arrow tile
	ld [hl], a
	coord hl, 1, 0
	ld de, wcd6d
	call PlaceString
	ld hl, wOAMBuffer
	ld de, wTileMapBackup
	ld bc, $10
	call CopyData
	ld hl, vSprites + $40
	ld de, TownMapCursor
	lb bc, BANK(TownMapCursor), (TownMapCursorEnd - TownMapCursor) / $8
	call CopyVideoDataDouble
	; wWhichTownMapLocation shares scratch WRAM at $cd3d, so initialize it only
	; after the Town Map/OAM setup above has finished using that scratch area.
	; Preserve the displayed player selector across the far call for .enterLoop.
	pop af
	push af
	ld e, a ; callab clobbers A, so pass the displayed selector through E
	callab InitTownMapLocationFromPlayerMap
	pop af
	jr .enterLoop

.townMapLoop
	coord hl, 1, 0
	lb bc, 2, 11
	call ClearScreenArea
	ld hl, TownMapOrder
	ld a, [wWhichTownMapLocation]
	ld c, a
	ld b, 0
	add hl, bc
	ld a, [hl]

.enterLoop:
	call LoadTownMapEntry
	push hl
	call TownMapCoordsToOAMCoords
	ld a, $4
	ld [wOAMBaseTile], a
	ld hl, wOAMBuffer + $10
	call WriteTownMapSpriteOAM ; town map cursor sprite
	pop hl
	ld de, wcd6d
.copyMapName
	ld a, [hli]
	ld [de], a
	inc de
	cp "@"
	jr nz, .copyMapName
	coord hl, 1, 0
	ld de, wcd6d
	call PlaceString
	ld hl, wOAMBuffer + $10
	ld de, wTileMapBackup + 16
	ld bc, $10
	call CopyData
.inputLoop
	call TownMapSpriteBlinkingAnimation
	call JoypadLowSensitivity
	ld a, [hJoy5]
	ld b, a
	and A_BUTTON | B_BUTTON | D_UP | D_DOWN
	jr z, .inputLoop
	ld a, SFX_TINK
	call PlaySound
	bit 6, b
	jr nz, .pressedUp
	bit 7, b
	jr nz, .pressedDown
	xor a
	ld [wTownMapSpriteBlinkingEnabled], a
	ld [hJoy7], a
	ld [wAnimCounter], a
	call ExitTownMap
	pop hl
	pop af
	ld [hl], a
	pop af
	ld [hTilesetType], a
	ret
.pressedUp
	ld a, [wWhichTownMapLocation]
	inc a
	cp TownMapOrderEnd - TownMapOrder ; number of list items + 1
	jr nz, .noOverflow
	xor a
.noOverflow
	ld [wWhichTownMapLocation], a
	jp .townMapLoop
.pressedDown
	ld a, [wWhichTownMapLocation]
	dec a
	cp -1
	jr nz, .noUnderflow
	ld a, TownMapOrderEnd - TownMapOrder - 1 ; number of list items
.noUnderflow
	ld [wWhichTownMapLocation], a
	jp .townMapLoop

INCLUDE "data/town_map_order.asm"

TownMapCursor:
	INCBIN "gfx/town_map_cursor.1bpp"
TownMapCursorEnd:

LoadTownMap_Nest:
	ld a, [hTilesetType]
	push af
	xor a
	ld [hTilesetType], a
	call LoadTownMap
	ld hl, wUpdateSpritesEnabled
	ld a, [hl]
	push af
	ld [hl], $ff
	push hl
	call DisplayWildLocations
	call GetMonName
	coord hl, 1, 0
	call PlaceString
	ld h, b
	ld l, c
	ld de, MonsText
	call PlaceString
	coord hl, 1, 1
	ld de, NestText
	call PlaceString
	call WaitForTextScrollButtonPress
	call ExitTownMap
	pop hl
	pop af
	ld [hl], a
	pop af
	ld [hTilesetType], a
	ret

MonsText:
	db "'s@"

NestText:
	db "Nest@"

LoadTownMap_Fly:
	ld a, [hTilesetType]
	push af
	xor a
	ld [hTilesetType], a
	call ClearSprites
	call LoadTownMap
	call LoadPlayerSpriteGraphics
	call LoadFontTilePatterns
	ld de, BirdSprite
	ld hl, vSprites + $40
	lb bc, BANK(BirdSprite), $c
	call CopyVideoData
	xor a
	ld [wFlyLocationsAxis], a ; 0 = city axis (Up/Down), 1 = special axis (Left/Right)
	call BuildFlyLocationsList
	ld hl, wUpdateSpritesEnabled
	ld a, [hl]
	push af
	ld [hl], $ff
	push hl
	coord hl, 0, 0
	ld a, $3f ; up/down arrow tile
	ld [hl], a
	callab GetFlyTownMapPlayerMap
	ld a, d
	ld b, $0
	call DrawPlayerOrBirdSprite
	ld hl, wBuffer + 1 ; expanded Fly list; wBuffer holds the leading $ff sentinel
;	coord de, 18, 0;No longer sets the destination address for the top‑right tile
.townMapFlyLoop
;	ld a, " ";No longer writes a blank tile to the top‑right corner
;	ld [de], a;So the map background there stays intact
	push hl
	push hl
	coord hl, 1, 0
	lb bc, 2, 11
	call ClearScreenArea
	pop hl
	ld a, [hl]
	ld b, $4
	call DrawPlayerOrBirdSprite ; draw bird sprite
	coord hl, 1, 0
	ld de, wcd6d
	call PlaceString
	ld c, 15
	call DelayFrames
	pop hl
.inputLoop
	push hl
	call DelayFrame
	call JoypadLowSensitivity
	ld a, [hJoy5]
	ld b, a
	pop hl
	and A_BUTTON | B_BUTTON | D_RIGHT | D_LEFT | D_UP | D_DOWN
	jr z, .inputLoop
	bit 0, b
	jr nz, .pressedA
	ld a, SFX_TINK
	call PlaySound
	bit 4, b
	jr nz, .pressedLeftOrRight
	bit 5, b
	jr nz, .pressedLeftOrRight
	bit 6, b
	jp nz, .pressedUp
	bit 7, b
	jp nz, .pressedDown
	jr .pressedB
.pressedA
	ld a, SFX_HEAL_AILMENT
	call PlaySound
	ld a, [hl]
	ld [wDestinationMap], a
	ld hl, wd732
	set 3, [hl]
	inc hl
	set 7, [hl]
.pressedB
	xor a
	ld [wTownMapSpriteBlinkingEnabled], a
	call GBPalWhiteOutWithDelay3
	pop hl
	pop af
	ld [hl], a
	pop af
	ld [hTilesetType], a
	ret
.pressedLeftOrRight
; Left/Right owns the special-destination axis. The first horizontal press
; enters that axis; further horizontal presses cycle only unlocked special
; destinations. Up/Down always returns to the original city axis.
	; Preserve B: it still holds hJoy5 and determines Left vs Right below.
	ld a, [wSpecialFlyVisitedFlag]
	ld c, a
	ld a, [wSpecialFlyVisitedFlag2]
	and %00011111 ; only bits 0-4 are currently defined
	or c
	jp z, .townMapFlyLoop ; no defined special destinations unlocked yet
	ld a, [wFlyLocationsAxis]
	and a
	jr nz, .alreadyOnSpecialAxis
	; Decide the horizontal direction before rebuilding the list: the list
	; builder uses B/BC internally, so hJoy5 must not be read from B afterwards.
	bit 4, b
	jr nz, .enterSpecialRight
.enterSpecialLeft
	inc a
	ld [wFlyLocationsAxis], a
	call BuildFlyLocationsList
	jr .selectLastAvailable ; Left enters from the opposite end
.enterSpecialRight
	inc a
	ld [wFlyLocationsAxis], a
	call BuildFlyLocationsList
	jr .selectFirstAvailable ; Right enters at the first unlocked destination
.alreadyOnSpecialAxis
	bit 4, b
	jr nz, .moveSpecialRight
	jr .moveSpecialLeft

.selectFirstAvailable
	ld hl, wBuffer + 1
.findFirstAvailable
	ld a, [hl]
	cp $ff
	jr z, .noSpecialAvailable
	cp $fe
	jp nz, .townMapFlyLoop
	inc hl
	jr .findFirstAvailable
.noSpecialAvailable
	; Defensive fallback: never let the end sentinel become a map selector.
	; A valid save with any defined special bit cannot reach this branch.
	xor a
	ld [wFlyLocationsAxis], a
	call BuildFlyLocationsList
	ld hl, wBuffer ; .moveCityUp increments before examining the first city entry
	jr .moveCityUp

.selectLastAvailable
	call FindFlyListEnd
	jr .moveSpecialLeft

.moveSpecialRight
	inc hl
	ld a, [hl]
	cp $ff
	jr z, .wrapSpecialRight
	cp $fe
	jr z, .moveSpecialRight
	jp .townMapFlyLoop
.wrapSpecialRight
	ld hl, wBuffer + 1
	jr .findFirstAvailable

.moveSpecialLeft
	dec hl
	ld a, [hl]
	cp $ff
	jr z, .wrapSpecialLeft
	cp $fe
	jr z, .moveSpecialLeft
	jp .townMapFlyLoop
.wrapSpecialLeft
	call FindFlyListEnd
	jr .moveSpecialLeft

.pressedUp
	ld a, [wFlyLocationsAxis]
	and a
	jr z, .moveCityUp
	; Vertical input always returns to the normal city axis. Up starts from the
	; first visited city; Down starts from the opposite end.
	xor a
	ld [wFlyLocationsAxis], a
	call BuildFlyLocationsList
	jr .selectFirstAvailable
.moveCityUp
;	coord de, 18, 0;Prevents an extra blank write when the cursor moves upward, avoiding unnecessary overwrites
	inc hl
	ld a, [hl]
	cp $ff
	jr z, .wrapCityUp
	cp $fe
	jr z, .moveCityUp ; skip past unvisited towns
	jp .townMapFlyLoop
.wrapCityUp
	ld hl, wBuffer
	jr .moveCityUp

.pressedDown
	ld a, [wFlyLocationsAxis]
	and a
	jr z, .moveCityDown
	xor a
	ld [wFlyLocationsAxis], a
	call BuildFlyLocationsList
	call FindFlyListEnd
	jr .moveCityDown
.moveCityDown
;	coord de, 19, 0;Prevents an extra blank write one column further right when the cursor moves downward
	dec hl
	ld a, [hl]
	cp $ff
	jr z, .wrapCityDown
	cp $fe
	jr z, .moveCityDown ; skip past unvisited towns
	jp .townMapFlyLoop
.wrapCityDown
	call FindFlyListEnd
	jr .moveCityDown

FindFlyListEnd:
; Return HL pointing at the $ff end sentinel of the currently built Fly list.
	ld hl, wBuffer + 1
.loop
	ld a, [hli]
	cp $ff
	jr nz, .loop
	dec hl
	ret

BuildFlyLocationsList:
; wBuffer is a 30-byte temporary area. Byte 0 is the leading sentinel and the
; actual list starts at byte 1, leaving enough room for the expanded special list.
	ld hl, wBuffer
	ld [hl], $ff
	inc hl
	ld a, [wFlyLocationsAxis]
	and a
	jr nz, .specialLocations

	; Original city page: the 11 town flags/map IDs are unchanged.
	ld a, [wKantoTownVisitedFlag]
	ld e, a
	ld a, [wKantoTownVisitedFlag + 1]
	ld d, a
	ld bc, SAFFRON_CITY + 1
.cityLoop
	srl d
	rr e
	ld a, $fe ; store $fe if the town hasn't been visited
	jr nc, .storeCity
	ld a, b ; store the map number of the town if it has been visited
.storeCity
	ld [hl], a
	inc hl
	inc b
	dec c
	jr nz, .cityLoop
	ld [hl], $ff
	ret

.specialLocations
	; The special list and its second saved flag byte live in expansion bank $35.
	callab BuildSpecialFlyLocationsList
	ret


LoadTownMap:
	call GBPalWhiteOutWithDelay3
	call ClearScreen
	call UpdateSprites
	coord hl, 0, 0
	ld b, $12
	ld c, $12
	call TextBoxBorder
	call DisableLCD
	ld hl, WorldMapTileGraphics
    ld de, vChars2
	ld bc, WorldMapTileGraphicsEnd - WorldMapTileGraphics
	ld a, BANK(WorldMapTileGraphics)
	call FarCopyData2
	ld hl, MonNestIcon
	ld de, vSprites + $40
	ld bc, MonNestIconEnd - MonNestIcon
	ld a, BANK(MonNestIcon)
	call FarCopyData2
	
	ld hl, UncompressedMap
	ld de, wTileMap
	ld bc, UncompressedMapEnd - UncompressedMap
	call CopyData

	call EnableLCD
	ld b, SET_PAL_TOWN_MAP
	call RunPaletteCommand
	call Delay3
	call GBPalNormal
	xor a
	ld [wAnimCounter], a
	inc a
	ld [wTownMapSpriteBlinkingEnabled], a
	ret

UncompressedMap: ; Uses the Gen 2 format
    INCBIN "gfx/tilemaps/kanto_map.kmp"
UncompressedMapEnd:
; TODO: Add the map for Johto and Shamouti later

ExitTownMap:
; clear town map graphics data and load usual graphics data
	xor a
	ld [wTownMapSpriteBlinkingEnabled], a
	call GBPalWhiteOut
	call ClearScreen
	call ClearSprites
	call LoadPlayerSpriteGraphics
	call LoadFontTilePatterns
    call ReloadMapData ; added
	call UpdateSprites
	jp RunDefaultPaletteCommand

DrawPlayerOrBirdSprite:
; a = map number
; b = OAM base tile
	push af
	ld a, b
	ld [wOAMBaseTile], a
	pop af
	call LoadTownMapEntry
	push hl
	call TownMapCoordsToOAMCoords
	call WritePlayerOrBirdSpriteOAM
	pop hl
	ld de, wcd6d
.loop
	ld a, [hli]
	ld [de], a
	inc de
	cp "@"
	jr nz, .loop
	ld hl, wOAMBuffer
	ld de, wTileMapBackup
	ld bc, $a0
	jp CopyData

DisplayWildLocations:
	callba FindWildLocationsOfMon
	call ZeroOutDuplicatesInList
	ld hl, wOAMBuffer
	ld de, wBuffer
.loop
	ld a, [de]
	cp $ff
	jr z, .exitLoop
	and a
	jr z, .nextEntry
	push hl
	call LoadTownMapEntry
	lb hl, -5, -4
	add hl, bc
	ld b, h
	ld c, l
	pop hl
	call TownMapCoordsToOAMCoords
	ld a, $4 ; nest icon tile no.
	ld [hli], a
	xor a
	ld [hli], a
.nextEntry
	inc de
	jr .loop
.exitLoop
	ld a, l
	and a ; were any OAM entries written?
	jr nz, .drawPlayerSprite
; if no OAM entries were written, print area unknown text
	coord hl, 1, 7
	ld b, 2
	ld c, 15
	call TextBoxBorder
	coord hl, 2, 9
	ld de, AreaUnknownText
	call PlaceString
	jr .done
.drawPlayerSprite
	ld a, [wCurMap]
	ld b, $0
	call DrawPlayerOrBirdSprite
.done
	ld hl, wOAMBuffer
	ld de, wTileMapBackup
	ld bc, $a0
	jp CopyData

AreaUnknownText:
	db " Area unknown@"

TownMapCoordsToOAMCoords:
; in: b = y, c = x
; out: [hl] = y, [hl + 1] = x
	ld a, b
	ld [hli], a
	ld a, c
	ld [hli], a
	ret

WritePlayerOrBirdSpriteOAM:
	ld a, [wOAMBaseTile]
	and a
	ld hl, wOAMBuffer + $90 ; for player sprite
	jr z, WriteTownMapSpriteOAM
	ld hl, wOAMBuffer + $80 ; for bird sprite

WriteTownMapSpriteOAM:
	push hl

; Adjust the coords so the sprite is lined up properly
	lb hl, -9, -8
	add hl, bc

	ld b, h
	ld c, l
	pop hl
	lb de, 2, 2
.loop
	push de
	push bc
.innerLoop
	ld a, b
	ld [hli], a
	ld a, c
	ld [hli], a
	ld a, [wOAMBaseTile]
	ld [hli], a
	inc a
	ld [wOAMBaseTile], a
	ld a, [wPlayerGender]
	and a ; Are you a boy? Or a girl?
	ld a, PAL_OW_GREEN
	jr nz, .gotPal
	xor a ; ld a, PAL_OW_RED
.gotPal
	ld [hli], a
	inc d
	ld a, 8
	add c
	ld c, a
	dec e
	jr nz, .innerLoop
	pop bc
	pop de
	ld a, 8
	add b
	ld b, a
	dec d
	jr nz, .loop
	ret

WriteAsymmetricMonPartySpriteOAM:
; Writes 4 OAM blocks for a helix mon party sprite, since it does not have
; a vertical line of symmetry.
	lb de, 2, 2
.loop
	push de
	push bc
.innerLoop
	ld a, b
	ld [hli], a
	ld a, c
	ld [hli], a
	ld a, [wOAMBaseTile]
	ld [hli], a
	inc a
	ld [wOAMBaseTile], a
	xor a
	ld [hli], a
	inc d
	ld a, 8
	add c
	ld c, a
	dec e
	jr nz, .innerLoop
	pop bc
	pop de
	ld a, 8
	add b
	ld b, a
	dec d
	jr nz, .loop
	ret

WriteSymmetricMonPartySpriteOAM:
; Writes 4 OAM blocks for a mon party sprite other than a helix. All the
; sprites other than the helix one have a vertical line of symmetry which allows
; the X-flip OAM bit to be used so that only 2 rather than 4 tile patterns are
; needed.
	xor a
	ld [wSymmetricSpriteOAMAttributes], a
	lb de, 2, 2
.loop
	push de
	push bc
.innerLoop
	ld a, b
	ld [hli], a ; Y
	ld a, c
	ld [hli], a ; X
	ld a, [wOAMBaseTile]
	ld [hli], a ; tile
	ld a, [wSymmetricSpriteOAMAttributes]
	ld [hli], a ; attributes
	xor (1 << OAM_X_FLIP)
	ld [wSymmetricSpriteOAMAttributes], a
	inc d
	ld a, 8
	add c
	ld c, a
	dec e
	jr nz, .innerLoop
	pop bc
	pop de
	push hl
	ld hl, wOAMBaseTile
	inc [hl]
	inc [hl]
	pop hl
	ld a, 8
	add b
	ld b, a
	dec d
	jr nz, .loop
	ret

ZeroOutDuplicatesInList:
; replace duplicate bytes in the list of wild pokemon locations with 0
	ld de, wBuffer
.loop
	ld a, [de]
	inc de
	cp $ff
	ret z
	ld c, a
	ld l, e
	ld h, d
.zeroDuplicatesLoop
	ld a, [hl]
	cp $ff
	jr z, .loop
	cp c
	jr nz, .skipZeroing
	xor a
	ld [hl], a
.skipZeroing
	inc hl
	jr .zeroDuplicatesLoop

LoadTownMapEntryFromE::
; Far-call trampoline for callers that need to pass a map selector across Bankswitch.
; callab/callba overwrite A/BC/HL while DE survives the switch, so return the
; Town Map coordinates in D/E instead of relying on LoadTownMapEntry's B/C.
	ld a, e
	call LoadTownMapEntry
	ld d, b ; y
	ld e, c ; x
	ret

LoadTownMapEntry:
; in: a = map number
; out: b = y, c = x, hl = address of name
; Selector-only/entrance points are exact-matched in expansion bank $35 so they
; do not alter InternalMapEntries' interval semantics.
	push af
	push de
	ld e, a
	callab TryLoadSpecialTownMapEntry
	jr c, .specialEntry
	pop de
	pop af
	cp REDS_HOUSE_1F
	jr c, .external
	ld bc, 5
	ld hl, InternalMapEntries
.loop
	cp [hl]
	jr c, .foundEntry
	jr z, .foundEntry ; works on exact entry too
	add hl, bc
	jr .loop
.foundEntry
	inc hl
	jr .readEntry
.external
	ld hl, ExternalMapEntries
	ld c, a
	ld b, 0
	add hl, bc
	add hl, bc
	add hl, bc
	add hl, bc
.readEntry
	ld a, [hli]
	ld b, a
	ld a, [hli]
	ld c, a
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ret
.specialEntry
	ld b, d
	ld c, e
	pop de ; preserve LoadTownMapEntry's original DE behavior
	pop af ; discard saved selector
	ret

GetMapNameForSaveScreen:
; Copies the current Town Map legend to wBuffer for the Continue/Save info box.
; callba overwrites register a with the destination ROM bank before entering
; this function, so read wCurMap here instead of accepting the map number in a.
; The Town Map-only line break character is changed to a normal space, while
; the original map name remains unchanged for the Town Map's two-line display.
	ld a, [wCurMap]
	call LoadTownMapEntry
	ld de, wBuffer
.copyName
	ld a, [hli]
	cp "_"
	jr nz, .storeCharacter
	ld a, " "
.storeCharacter
	ld [de], a
	inc de
	cp "@"
	jr nz, .copyName
	ret

INCLUDE "data/town_map_entries.asm"

INCLUDE "text/map_names.asm"

MonNestIcon:
	INCBIN "gfx/mon_nest_icon.2bpp"
MonNestIconEnd:

TownMapSpriteBlinkingAnimation:
	ld a, [wAnimCounter]
	inc a
	cp 25
	jr z, .hideSprites
	cp 50
	jr nz, .done
; show sprites when the counter reaches 50
	ld hl, wTileMapBackup
	ld de, wOAMBuffer
	ld bc, $90
	call CopyData
	xor a
	jr .done
.hideSprites
	ld hl, wOAMBuffer
	ld b, $24
	ld de, $4
.hideSpritesLoop
	ld [hl], $a0
	add hl, de
	dec b
	jr nz, .hideSpritesLoop
	ld a, 25
.done
	ld [wAnimCounter], a
	jp DelayFrame
