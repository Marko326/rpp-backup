DisplayOptionMenu:
	xor a
	ld [wOptionsMenuPage], a ; options menu page: 0 = main, 1 = music
	call NormalizeBGMVolumeOption
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

; Page 2: Music, BGM Volume, World, and Page.
; Music and BGM Volume are intentionally independent. BGM Volume 0 uses the
; same effective mute path as Music Off without changing the Music option bit.
.checkPage2DirectionKeys
	ld a,[wTopMenuItemY]
	bit 7,b ; Down pressed?
	jp nz,.page2DownPressed
	bit 6,b ; Up pressed?
	jp nz,.page2UpPressed
	cp 16 ; cursor on Page?
	jp z,.cursorOnPage2Back
	cp 13 ; cursor on World?
	jp z,.cursorInWorld
	cp 8 ; cursor on BGM Volume?
	jp z,.cursorInBGMVolume
.cursorInMusic
	ld a,[wOptionsMusicCursorX]
	xor a,$0b ; toggle between 1 and 10
	ld [wOptionsMusicCursorX],a
	jp .eraseOldMenuCursor

.cursorInBGMVolume
	call GetBGMVolumeOptionLevel
	bit 5,b ; Left pressed?
	jr z,.increaseBGMVolume
	and a
	jr z,.bgmVolumeUnchanged
	dec a
	jr .storeBGMVolume
.increaseBGMVolume
	cp 10
	jr z,.bgmVolumeUnchanged
	inc a
.storeBGMVolume
	add $a0
	ld [wBGMVolume],a
	call DrawBGMVolumeValue
.bgmVolumeUnchanged
	jp .loop

.cursorInWorld
	ld hl,wOptions
	bit 5,b ; Left = Normal, Right = Snowy
	jr z,.setSnowyWorld
	res 4,[hl]
	ld a,1
	jp .eraseOldMenuCursor
.setSnowyWorld
	set 4,[hl]
	ld a,10
	jp .eraseOldMenuCursor

.page2DownPressed
	cp 3
	jr z,.page2SelectBGMVolume
	cp 8
	jr z,.page2SelectWorld
	cp 13
	jr z,.page2SelectBack
	jr .page2SelectMusic
.page2UpPressed
	cp 3
	jr z,.page2SelectBack
	cp 8
	jr z,.page2SelectMusic
	cp 13
	jr z,.page2SelectBGMVolume
	jr .page2SelectWorld
.page2SelectMusic
	ld a,3
	ld [wTopMenuItemY],a
	ld a,[wOptionsMusicCursorX]
	ld [wTopMenuItemX],a
	call PlaceUnfilledArrowMenuCursor
	jp .loop
.page2SelectBGMVolume
	ld a,8
	ld [wTopMenuItemY],a
	ld a,1
	ld [wTopMenuItemX],a
	call PlaceUnfilledArrowMenuCursor
	jp .loop
.page2SelectWorld
	ld a,13
	ld [wTopMenuItemY],a
	call GetWorldOptionCursorX
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
	coord hl, 1, 6
	ld de,BGMVolumeOptionText
	call PlaceString
	call DrawBGMVolumeValue
	coord hl, 1, 11
	ld de,WorldOptionText
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
	coord hl, 1, 8
	ld [hl],$ec
	coord hl, 0, 13
	call GetWorldOptionCursorX
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

BGMVolumeOptionText:
	db "Music Volume:@"

WorldOptionText:
	db   "World:"
	next " Normal   Snowy@"

OptionMenuPageText:
	db "Page@"

OptionMenuPage1Text:
	db "1/2@"

OptionMenuPage2Text:
	db "2/2@"

NormalizeBGMVolumeOption:
; $a0-$aa encode 0-10. Anything else is legacy data from the old unused d366
; byte and becomes the default level 10.
	ld a,[wBGMVolume]
	cp $a0
	jr c,.setDefault
	cp $ab
	ret c
.setDefault
	ld a,$aa
	ld [wBGMVolume],a
	ret

GetBGMVolumeOptionLevel:
	ld a,[wBGMVolume]
	cp $a0
	jr c,.defaultLevel
	cp $ab
	jr nc,.defaultLevel
	sub $a0
	ret
.defaultLevel
	ld a,10
	ret

DrawBGMVolumeValue:
; Draw a right-aligned two-character value in the second Page 2 box.
	call GetBGMVolumeOptionLevel
	coord hl, 2, 8
	cp 10
	jr z,.drawTen
	ld [hl]," "
	inc hl
	add "0"
	ld [hl],a
	ret
.drawTen
	ld a,"1"
	ld [hli],a
	ld a,"0"
	ld [hl],a
	ret

GetWorldOptionCursorX:
	ld a,[wOptions]
	bit 4,a
	ld a,1 ; Normal
	ret z
	ld a,10 ; Snowy
	ret

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
	jr .setWorldAppearance
.musicOn
	res 5,d
.setWorldAppearance
	; World 没有单独的 WRAM cursor 变量，直接保留当前 wOptions bit 4。
	ld a,[wOptions]
	bit 4,a
	jr z,.worldNormal
	set 4,d
	jr .storeOptions
.worldNormal
	res 4,d
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

StartMenuOptionWithWorldSwitch::
	; 记录进入 Options 前的 World 模式；只有实际切换时才重载地图。
	ld a,[wOptions]
	and 1 << 4
	push af
	xor a
	ld [H_AUTOBGTRANSFERENABLED],a
	call ClearScreen
	call UpdateSprites
	call DisplayOptionMenu
	pop af
	ld c,a
	ld a,[wOptions]
	and 1 << 4
	cp c
	jr z,.appearanceUnchanged

	; 不再通过 ReloadMapData 关闭 LCD。录像里的白闪就是 LCD 在 World 切换时
	; 被关掉数帧造成的。Options 此时仍用 Window 覆盖整屏，可以在它后面通过
	; VBlank 安全地替换发生变化的 tiles，再让 RedrawMapView 重画当前 BG。
	call .loadWorldTilesetDiffVBlank
	call .loadWorldTextBoxDiffVBlank
	callba RedrawMapView
	ret

.appearanceUnchanged
	call LoadScreenTilesFromBuffer2 ; restore saved screen
	call LoadTextBoxTilePatterns
	ret

.loadWorldTilesetDiffVBlank
; 只传 Normal/Snowy 真正不同的 tiles，不重传完整 $600 bytes tileset。
; 这样既避免关闭 LCD 的白闪，也缩短 World 切换时等待的 VBlank 数量。
	ld a,[wCurMapTileset]
	cp OVERWORLD
	ld hl,SnowOverworldGfxPatchTable
	jr z,.gotTable
	cp FOREST
	ld hl,SnowForestGfxPatchTable
	jr z,.gotTable
	cp SAFARI
	ld hl,SnowSafariGfxPatchTable
	jr z,.gotTable
	cp PLATEAU
	ld hl,SnowPlateauGfxPatchTable
	ret nz
.gotTable
	ld a,[wOptions]
	and 1 << 4
	ld [wBuffer + 2],a ; 0 = Normal, non-zero = Snowy
.loop
	ld a,[hli]
	cp $ff
	ret z
	ld [wBuffer],a ; tile ID
	ld a,[hli]
	ld [wBuffer + 1],a ; tile count
	ld a,[hli]
	ld e,a
	ld a,[hli]
	ld d,a ; Snowy source pointer
	push hl

	ld a,[wBuffer + 2]
	and a
	jr nz,.snowSource
	; 切回 Normal 时，用同一组差分范围从普通 tileset 取原图块。
	ld a,[wTilesetGfxPtr]
	ld e,a
	ld a,[wTilesetGfxPtr + 1]
	ld d,a
	ld a,[wBuffer]
	ld l,a
	ld h,0
	add hl,hl
	add hl,hl
	add hl,hl
	add hl,hl
	add hl,de
	ld d,h
	ld e,l
	ld a,[wTilesetBank]
	ld b,a
	jr .haveSource
.snowSource
	ld b,BANK(SnowOverworldGfxPatchTable)
.haveSource

	; destination = vTileset + tile ID * $10
	ld a,[wBuffer]
	and $0f
	swap a
	ld l,a
	ld a,[wBuffer]
	swap a
	and $0f
	add $90 ; HIGH(vTileset)
	ld h,a
	ld a,[wBuffer + 1]
	ld c,a
	call CopyVideoData
	pop hl
	jr .loop

.loadWorldTextBoxDiffVBlank
; TextBoxGraphics 中只有 0-2、4-7 号 tiles 在 Snowy 版本不同。
; 只恢复这 7 个共享屋顶 tiles，避免为了切 World 重传整套文本框图块。
	ld a,[wOptions]
	bit 4,a
	jr z,.normalTextBox
	ld de,SnowTextBoxTiles0
	ld hl,vChars2 + $600
	lb bc,BANK(SnowTextBoxTiles0),3
	call CopyVideoData
	ld de,SnowTextBoxTiles4
	ld hl,vChars2 + $640
	lb bc,BANK(SnowTextBoxTiles4),4
	jp CopyVideoData
.normalTextBox
	ld de,TextBoxGraphics
	ld hl,vChars2 + $600
	lb bc,BANK(TextBoxGraphics),3
	call CopyVideoData
	ld de,TextBoxGraphics + $40
	ld hl,vChars2 + $640
	lb bc,BANK(TextBoxGraphics),4
	jp CopyVideoData
