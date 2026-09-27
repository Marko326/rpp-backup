DisplayOptionMenu:
	xor a
	ld [wOptionsMenuPage], a ; 0 = main, 1 = music, 2 = world
	call NormalizeBGMVolumeOption
	callba NormalizeMusicStyleOption
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
	jr z,.checkAButton
	; MUS-5.59.00: START on the Music Style row toggles only the Custom
	; preference for the currently selected RBY/GSC family. RND has no sub-mode.
	ld a,[wOptionsMenuPage]
	cp 1
	jr nz,.exitMenu
	ld a,[wTopMenuItemY]
	cp 13
	jr nz,.exitMenu
	callba ToggleCurrentMusicStyleCustom
	jp .loop
.checkAButton
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
	ld a,[wOptionsMenuPage]
	and a
	jr z,.checkPage1DirectionKeys
	dec a
	jp z,.checkPage2DirectionKeys
	jp .checkPage3DirectionKeys

; Page 1: Text Speed, Battle Effects, Battle Style, Page.
.checkPage1DirectionKeys
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
	jr .storeOptionMenuCursorX
.page1SelectBattleAnimation
	ld a,8
	ld [wTopMenuItemY],a
	ld a,[wOptionsBattleAnimCursorX]
	jr .storeOptionMenuCursorX
.page1SelectBattleStyle
	ld a,13
	ld [wTopMenuItemY],a
	ld a,1
	jr .storeOptionMenuCursorX
.page1SelectBack
	ld a,16
	ld [wTopMenuItemY],a
	ld a,1
.storeOptionMenuCursorX
	ld [wTopMenuItemX],a
	call PlaceUnfilledArrowMenuCursor
	jp .loop
.cursorInBattleAnimation
	ld hl,wOptionsBattleAnimCursorX
	jp .toggleBinaryCursorX
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

; Page 2: Music, BGM Volume, Music Style, and Page.
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
	cp 13 ; cursor on Music Style?
	jp z,.cursorInMusicStyle
	cp 8 ; cursor on BGM Volume?
	jp z,.cursorInBGMVolume
.cursorInMusic
	ld hl,wOptionsMusicCursorX
.toggleBinaryCursorX
	ld a,[hl]
	xor a,$0b ; toggle between 1 and 10
	ld [hl],a
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

.cursorInMusicStyle
	call GetMusicStyleOptionValue ; A = base family only (RBY/GSC/RND)
	bit 5,b ; Left pressed?
	jr z,.nextMusicStyle
	and a
	jr nz,.previousMusicStyle
	ld a,MUSIC_STYLE_BASE_COUNT
.previousMusicStyle
	dec a
	jr .storeMusicStyleBase
.nextMusicStyle
	inc a
	cp MUSIC_STYLE_BASE_COUNT
	jr c,.storeMusicStyleBase
	xor a
.storeMusicStyleBase
	ld e,a
	; Keep the nearly-full fixed Options bank small: packed-state update, signature
	; write, and live preview all live in the movable Music Style section.
	callba SetMusicStyleBaseAndPreview
	call GetMusicStyleOptionCursorX
	jp .eraseOldMenuCursor

.page2DownPressed
	cp 3
	jr z,.page2SelectBGMVolume
	cp 8
	jr z,.page2SelectMusicStyle
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
	jr .page2SelectMusicStyle
.page2SelectMusic
	ld a,3
	ld [wTopMenuItemY],a
	ld a,[wOptionsMusicCursorX]
	jp .storeOptionMenuCursorX
.page2SelectBGMVolume
	ld a,8
	ld [wTopMenuItemY],a
	ld a,1
	jp .storeOptionMenuCursorX
.page2SelectMusicStyle
	ld a,13
	ld [wTopMenuItemY],a
	call GetMusicStyleOptionCursorX
	jp .storeOptionMenuCursorX
.page2SelectBack
	ld a,16
	ld [wTopMenuItemY],a
	ld a,1
	jp .storeOptionMenuCursorX
.cursorOnPage2Back
	bit 5,b ; Left pressed?
	jp nz,.showPage1
	bit 4,b ; Right pressed?
	jp nz,.showPage3
	jp .loop

; Page 3: World appearance and Page.
.checkPage3DirectionKeys
	ld a,[wTopMenuItemY]
	bit 7,b ; Down pressed?
	jr nz,.page3MoveCursor
	bit 6,b ; Up pressed?
	jr nz,.page3MoveCursor
	cp 16 ; cursor on Page?
	jr z,.cursorOnPage3Back
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
.page3MoveCursor
	cp 3
	jr z,.page3SelectBack
.page3SelectWorld
	ld a,3
	ld [wTopMenuItemY],a
	call GetWorldOptionCursorX
	jp .storeOptionMenuCursorX
.page3SelectBack
	ld a,16
	ld [wTopMenuItemY],a
	ld a,1
	jp .storeOptionMenuCursorX
.cursorOnPage3Back
	bit 5,b ; Left pressed?
	jp nz,.showPage2
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
	jp .finishPageSwitch

.showPage3
	ld a,2
	ld [wOptionsMenuPage],a
	xor a
	ld [H_AUTOBGTRANSFERENABLED],a
	call ClearScreen
	call .drawPage3
	call .placePage3Arrows
	jp .finishPageSwitch

.showPage1
	xor a
	ld [wOptionsMenuPage],a
	; Keep the old page visible until the new page is fully drawn.
	ld [H_AUTOBGTRANSFERENABLED],a
	call ClearScreen
	call .drawPage1
	call SetCursorPositionsFromOptions
.finishPageSwitch
	; Always enter a different options page with the active cursor on Page.
	ld a,16
	ld [wTopMenuItemY],a
	ld a,1
	ld [wTopMenuItemX],a
	ld a,1
	ld [H_AUTOBGTRANSFERENABLED],a
	call Delay3
	jp .loop

.drawPageFrame
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
	jp TextBoxBorder

.drawPage1
	call .drawPageFrame
	coord hl, 1, 1
	ld de,TextSpeedOptionText
	call PlaceString
	coord hl, 1, 6
	ld de,BattleAnimationOptionText
	call PlaceString
	coord hl, 1, 11
	ld de,BattleStyleOptionText
	call PlaceString
	; Keep the build version visible in-game without consuming the spare bottom row.
	; The Battle Style value occupies x=2-4, so x=6 leaves one blank column
	; and leaves enough room for the shared build-version string inside the frame.
	coord hl, 6, 13
	ld de,GameVersionText
	call PlaceString
	ld de,OptionMenuPage1Text
	jp .drawPageSelector

.drawPage2
	call .drawPageFrame
	coord hl, 1, 1
	ld de,MusicOptionText
	call PlaceString
	coord hl, 1, 6
	ld de,BGMVolumeOptionText
	call PlaceString
	call DrawBGMVolumeValue
	coord hl, 1, 11
	ld de,MusicStyleOptionText
	call PlaceString
	callba DrawMusicStyleCustomMarkers
	ld de,OptionMenuPage2Text
	jp .drawPageSelector

.drawPage3
	; MUS-5.59.00: World moved intact from Page 2 to the first row of Page 3.
	; Keep the normal three-row frame so the remaining two rows stay available for later options.
	call .drawPageFrame
	coord hl,1,1
	ld de,WorldOptionText
	call PlaceString
	ld de,OptionMenuPage3Text
	jp .drawPageSelector

.drawPageSelector
	push de
	coord hl, 2, 16
	ld de,OptionMenuPageText
	call PlaceString
	pop de
	coord hl, 16, 16
	jp PlaceString

.placePage2Arrows
	coord hl,0,3
	ld a,[wOptionsMusicCursorX]
	ld e,a
	ld d,0
	add hl,de
	ld [hl],$ec
	coord hl,1,8
	ld [hl],$ec
	coord hl,0,13
	call GetMusicStyleOptionCursorX
	ld e,a
	ld d,0
	add hl,de
	ld [hl],$ec
	coord hl,1,16
	ld [hl],$ec
	ret

.placePage3Arrows
	coord hl,0,3
	call GetWorldOptionCursorX
	ld e,a
	ld d,0
	add hl,de
	ld [hl],$ec
	coord hl,1,16
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

MusicStyleOptionText:
	db   "Music Style:"
	; x1/x8/x15 are the three cursor cells. x5/x12 are dynamic C markers.
	next " RBY    GSC    RND@"

WorldOptionText:
	db   "World:"
	next " Normal   Snowy@"

OptionMenuPageText:
	db "Page@"

OptionMenuPage1Text:
	db "1/3@"

OptionMenuPage2Text:
	db "2/3@"

OptionMenuPage3Text:
	db "3/3@"

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

GetMusicStyleOptionValue:
; Return only the selected main family. NormalizeMusicStyleOption has already
; migrated/validated the packed byte before the page is shown.
	ld a,[wMusicStyle]
	and MUSIC_STYLE_BASE_MASK
	ret

GetMusicStyleOptionCursorX:
	call GetMusicStyleOptionValue
	and a
	jr z,.rby
	cp MUSIC_STYLE_GSC
	jr z,.gsc
	ld a,15 ; RND
	ret
.rby
	ld a,1
	ret
.gsc
	ld a,8
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
	; World 在 Page 3 直接修改 wOptions bit 4；这里保留当前值。
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

OptionsLoadWorldTilesetDiffVBlank::
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

OptionsLoadWorldTextBoxDiffVBlank::
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

SECTION "Music Style Resolver", ROMX
SetMusicStyleBaseAndPreview:
; INPUT: E = RBY/GSC/RND base. Preserve both independent Custom preference bits.
	ld a,[wMusicStyle]
	and a,$fc
	or e
	ld [wMusicStyle],a
	call StoreMusicStyleSignature
	jp PlayDefaultMusic

ToggleCurrentMusicStyleCustom:
; START affects only the selected family. RBYC and GSCC are remembered
; independently; RND deliberately ignores START and never consumes either bit.
	ld a,[wMusicStyle]
	ld b,a
	and MUSIC_STYLE_BASE_MASK
	jr z,.toggleRBY
	cp MUSIC_STYLE_GSC
	ret nz
	ld a,b
	xor 1 << MUSIC_STYLE_GSC_CUSTOM_BIT
	jr .store
.toggleRBY
	ld a,b
	xor 1 << MUSIC_STYLE_RBY_CUSTOM_BIT
.store
	ld [wMusicStyle],a
	call StoreMusicStyleSignature
	call DrawMusicStyleCustomMarkers
	jp PlayDefaultMusic

DrawMusicStyleCustomMarkers:
; The static row owns RBY/GSC/RND. Only x5/x12 change between blank and C.
	coord hl,5,13
	ld a,[wMusicStyle]
	bit MUSIC_STYLE_RBY_CUSTOM_BIT,a
	ld a," "
	jr z,.drawRBY
	ld a,"C"
.drawRBY
	ld [hl],a
	coord hl,12,13
	ld a,[wMusicStyle]
	bit MUSIC_STYLE_GSC_CUSTOM_BIT,a
	ld a," "
	jr z,.drawGSC
	ld a,"C"
.drawGSC
	ld [hl],a
	ret

StoreMusicStyleSignature:
	ld a,MUSIC_STYLE_MAGIC0
	ld [wMusicStyleMagic0],a
	ld a,MUSIC_STYLE_MAGIC1
	ld [wMusicStyleMagic1],a
	ret

ReadMusicStyleState:
; MUS-5.59.00: return the packed runtime state in A. The previous three-value
; "MS" format is accepted in-place so old saves work before Options is opened:
; 0=RBY, 1=GSC, 2=old CSTM -> RBYC. Invalid/pre-feature data becomes RBY.
	ld a,[wMusicStyleMagic0]
	cp MUSIC_STYLE_MAGIC0
	jr nz,.rby
	ld a,[wMusicStyleMagic1]
	cp MUSIC_STYLE_MAGIC1
	jr z,.packed
	cp MUSIC_STYLE_LEGACY_MAGIC1
	jr nz,.rby
	ld a,[wMusicStyle]
	cp MUSIC_STYLE_LEGACY_CSTM
	jr z,.legacyCustom
	cp MUSIC_STYLE_LEGACY_CSTM
	ret c ; legacy 0=RBY / 1=GSC keep the same base values
	jr .rby
.legacyCustom
	ld a,1 << MUSIC_STYLE_RBY_CUSTOM_BIT ; old CSTM = RBY family + Custom
	ret
.packed
	ld a,[wMusicStyle]
	ld b,a
	and %11110000
	jr nz,.rby
	ld a,b
	and MUSIC_STYLE_BASE_MASK
	cp MUSIC_STYLE_BASE_COUNT
	jr nc,.rby
	ld a,b
	ret
.rby
	xor a
	ret

NormalizeMusicStyleOption:
; Rewrite any accepted legacy value into the packed independent-CSTM format.
	call ReadMusicStyleState
	ld [wMusicStyle],a
	ld a,MUSIC_STYLE_MAGIC0
	ld [wMusicStyleMagic0],a
	ld a,MUSIC_STYLE_MAGIC1
	ld [wMusicStyleMagic1],a
	ret

ResolveMusicStyle::
; DE is the requested Music ID. Only legacy IDs 1..48 are style candidates;
; GB Player direct-select IDs and stop ID 0 pass through unchanged.
;
; RBY  : original RBY only.
; RBYC : CSTM counterpart when present, otherwise RBY.
; GSC  : GSC counterpart when present, otherwise RBY.
; GSCC : CSTM first, then GSC, then RBY.
; RND  : independent of both Custom flags; choose uniformly from the counterparts
;        that actually exist for this request (RBY is always one candidate).
	ld a,d
	and a
	ret nz
	ld a,e
	and a
	ret z
	cp MUSIC_LAKE_OF_RAGE + 1
	ret nc
	call ReadMusicStyleState
	ld b,a
	and MUSIC_STYLE_BASE_MASK
	cp MUSIC_STYLE_RND
	jr z,.random
	cp MUSIC_STYLE_GSC
	jr z,.gsc

	; RBY family. Custom is an independent preference bit remembered only here.
	bit MUSIC_STYLE_RBY_CUSTOM_BIT,b
	ret z
	ld hl,MusicStyleCSTMMap
	call LookupMusicStyleMap
	and a
	ret z
	ld e,a
	ret

.gsc
	; GSCC prefers a real CSTM counterpart, then falls back through GSC to RBY.
	bit MUSIC_STYLE_GSC_CUSTOM_BIT,b
	jr z,.gscOnly
	ld hl,MusicStyleCSTMMap
	call LookupMusicStyleMap
	and a
	jr nz,.replace
.gscOnly
	ld hl,MusicStyleGSCMap
	call LookupMusicStyleMap
	and a
	ret z
.replace
	ld e,a
	ret

.random
	; RND ignores the remembered RBYC/GSCC bits. Build candidates only from
	; mappings that exist for this requested legacy track. B=GSC, C=CSTM.
	ld hl,MusicStyleGSCMap
	call LookupMusicStyleMap
	ld b,a
	ld hl,MusicStyleCSTMMap
	call LookupMusicStyleMap
	ld c,a
	ld a,b
	or c
	ret z ; only RBY exists
	ld a,b
	and a
	jr z,.randomRBYCSTM
	ld a,c
	and a
	jr z,.randomRBYGSC

.randomThree
	; Use two random low bits and reject 3: 0/1/2 are exactly equiprobable.
	call Random
	and 3
	cp 3
	jr z,.randomThree
	and a
	ret z ; 0 = RBY
	dec a
	jr z,.pickGSC ; 1 = GSC
	ld e,c ; 2 = CSTM
	ret
.randomRBYGSC
	call Random
	and 1
	ret z
.pickGSC
	ld e,b
	ret
.randomRBYCSTM
	call Random
	and 1
	ret z
	ld e,c
	ret

LookupMusicStyleMap:
; INPUT: HL = pair table, E = legacy RBY ID. OUTPUT: A = mapped ID or 0.
.loop
	ld a,[hli]
	and a
	ret z
	cp e
	jr z,.found
	inc hl
	jr .loop
.found
	ld a,[hl]
	ret

; Legacy RBY ID -> corresponding GSC direct-select ID.
; Shared RBY tracks without one clean GSC counterpart are deliberately omitted.
MusicStyleGSCMap:
	db MUSIC_PALLET_TOWN,          MUSIC_GBP_GSC_PALLET_TOWN
	db MUSIC_POKECENTER,           MUSIC_GBP_GSC_POKEMON_CENTER
	db MUSIC_GYM,                  MUSIC_GBP_GSC_GYM
	db MUSIC_CITIES1,              MUSIC_GBP_GSC_VIRIDIAN_CITY
	db MUSIC_CELADON,              MUSIC_GBP_GSC_CELADON_CITY
	db MUSIC_VERMILION,            MUSIC_GBP_GSC_VERMILION_CITY
	db MUSIC_LAVENDER,             MUSIC_GBP_GSC_LAVENDER_TOWN
	db MUSIC_SS_ANNE,              MUSIC_GBP_GSC_SS_AQUA
	db MUSIC_MEET_PROF_OAK,        MUSIC_GBP_GSC_PROF_OAK
	db MUSIC_MEET_RIVAL,           MUSIC_GBP_GSC_LOOK_RIVAL
	db MUSIC_PKMN_HEALED,          MUSIC_GBP_GSC_HEAL_POKEMON
	db MUSIC_ROUTES1,              MUSIC_GBP_GSC_ROUTE1
	db MUSIC_ROUTES2,              MUSIC_GBP_GSC_ROUTE2
	db MUSIC_ROUTES3,              MUSIC_GBP_GSC_ROUTE3
	db MUSIC_ROUTES4,              MUSIC_GBP_GSC_ROUTE12
	db MUSIC_INDIGO_PLATEAU,       MUSIC_GBP_GSC_INDIGO_PLATEAU
	db MUSIC_GYM_LEADER_BATTLE,    MUSIC_GBP_GSC_KANTO_GYM_BATTLE
	db MUSIC_TRAINER_BATTLE,       MUSIC_GBP_GSC_KANTO_TRAINER_BATTLE
	db MUSIC_WILD_BATTLE,          MUSIC_GBP_GSC_KANTO_WILD_BATTLE
	db MUSIC_FINAL_BATTLE,         MUSIC_GBP_GSC_CHAMPION_BATTLE
	db MUSIC_DEFEATED_TRAINER,     MUSIC_GBP_GSC_TRAINER_VICTORY
	db MUSIC_DEFEATED_WILD_MON,    MUSIC_GBP_GSC_WILD_POKEMON_VICTORY
	db MUSIC_DEFEATED_GYM_LEADER,  MUSIC_GBP_GSC_GYM_LEADER_VICTORY
	db MUSIC_TITLE_SCREEN,         MUSIC_GBP_GSC_TITLE_SCREEN
	db MUSIC_CREDITS,              MUSIC_GBP_GSC_CREDITS
	db MUSIC_HALL_OF_FAME,         MUSIC_GBP_GSC_HALL_OF_FAME
	db MUSIC_OAKS_LAB,             MUSIC_GBP_GSC_ELMS_LAB
	db MUSIC_BIKE_RIDING,          MUSIC_GBP_GSC_BICYCLE
	db MUSIC_SURFING,              MUSIC_GBP_GSC_SURF
	db MUSIC_GAME_CORNER,          MUSIC_GBP_GSC_GAME_CORNER
	db MUSIC_INTRO_BATTLE,         MUSIC_GBP_GSC_GOLD_SILVER_OPENING2
	db MUSIC_MEET_EVIL_TRAINER,    MUSIC_GBP_GSC_LOOK_ROCKET
	db MUSIC_MEET_FEMALE_TRAINER,  MUSIC_GBP_GSC_LOOK_LASS
	db MUSIC_MEET_MALE_TRAINER,    MUSIC_GBP_GSC_LOOK_YOUNGSTER
	db MUSIC_MT_MOON_SQUARE,       MUSIC_GBP_GSC_MT_MOON_SQUARE
	db MUSIC_LAKE_OF_RAGE,         MUSIC_GBP_GSC_LAKE_OF_RAGE
	db 0

; Legacy RBY ID -> corresponding track from the CSTM library.
; CSTM is intentionally sparse: no match means keep the original RBY track.
MusicStyleCSTMMap:
	db MUSIC_CITIES2,              MUSIC_GBP_CUSTOM_CERULEAN_GSC
	db MUSIC_CINNABAR,             MUSIC_GBP_CUSTOM_CINNABAR_GSC
	db MUSIC_ROUTES2,              MUSIC_GBP_CUSTOM_NUGGET_BRIDGE
	db MUSIC_GYM_LEADER_BATTLE,    MUSIC_GBP_CUSTOM_KANTO_GYM_LEADER_REMIX
	db MUSIC_WILD_BATTLE,          MUSIC_GBP_CUSTOM_NALJO_WILD_BATTLE
	db 0

SECTION "Runtime Options Wrapper", ROMX
StartMenuOptionWithWorldSwitch::
	; MUS-5.59.00: World still owns the no-LCD-disable tile refresh. Music Style
	; previews immediately inside DisplayOptionMenu, so exiting Options must not replay it.
	ld a,[wOptions]
	and 1 << 4
	push af
	xor a
	ld [H_AUTOBGTRANSFERENABLED],a
	call ClearScreen
	call UpdateSprites
	callba DisplayOptionMenu

	pop af ; old World
	ld c,a
	ld a,[wOptions]
	and 1 << 4
	cp c
	jr z,.appearanceUnchanged

	; Keep the no-white-flash World path in bank $35, beside the Snowy patch
	; tables it reads directly. This movable wrapper reaches those helpers with callba.
	callba OptionsLoadWorldTilesetDiffVBlank
	callba OptionsLoadWorldTextBoxDiffVBlank
	callba RedrawMapView
	ret

.appearanceUnchanged
	call LoadScreenTilesFromBuffer2 ; restore saved screen
	call LoadTextBoxTilePatterns
	ret
