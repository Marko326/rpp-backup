ShowPokedexMenu:
	call GBPalWhiteOut
	call ClearScreen
	call UpdateSprites
	ld a,[wListScrollOffset]
	push af
	xor a
	ld [wCurrentMenuItem],a
	ld [wListScrollOffset],a
	ld [wLastMenuItem],a
	inc a
	ld [wd11e],a
	ld [hJoy7],a
.setUpGraphics
	ld b, SET_PAL_GENERIC
	call RunPaletteCommand
	callab LoadPokedexTilePatterns
.doPokemonListMenu
	ld hl,wTopMenuItemY
	ld a,3
	ld [hli],a ; top menu item Y
	xor a
	ld [hli],a ; top menu item X
	inc a
	ld [wMenuWatchMovingOutOfBounds],a
	inc hl
	inc hl
	ld a,6
	ld [hli],a ; max menu item ID
	; 图鉴列表额外监听 SELECT/START，仅用于当前宝可梦的叫声和地区快捷键。
	ld [hl],D_LEFT | D_RIGHT | B_BUTTON | A_BUTTON | SELECT | START
	call HandlePokedexListMenu
	jr c,.goToSideMenu ; if the player chose a pokemon from the list
	ld a,b
	and a
	jr nz,.setUpGraphics ; START 查看地区后重新初始化图鉴列表界面
.exitPokedex
	xor a
	ld [wMenuWatchMovingOutOfBounds],a
	ld [wCurrentMenuItem],a
	ld [wLastMenuItem],a
	ld [hJoy7],a
	ld [wWastedByteCD3A],a
	ld [wOverrideSimulatedJoypadStatesMask],a
	pop af
	ld [wListScrollOffset],a
	call GBPalWhiteOutWithDelay3
	call RunDefaultPaletteCommand
	jp ReloadMapData
.goToSideMenu
	call HandlePokedexSideMenu
	dec b
	jr z,.exitPokedex ; if the player chose Quit
	dec b
	jr z,.doPokemonListMenu ; if pokemon not seen or player pressed B button
	jp .setUpGraphics ; if pokemon data or area was shown

; handles the menu on the lower right in the pokedex screen
; OUTPUT:
; b = reason for exiting menu
; 00: showed pokemon data or area
; 01: the player chose Quit
; 02: the pokemon has not been seen yet or the player pressed the B button
HandlePokedexSideMenu:
	call PlaceUnfilledArrowMenuCursor
	ld a,[wCurrentMenuItem]
	push af
	ld b,a
	ld a,[wLastMenuItem]
	push af
	ld a,[wListScrollOffset]
	push af
	add b
	inc a
	ld [wd11e],a
	ld a,[wd11e]
	push af
	ld a,[wDexMaxSeenMon]
	push af ; this doesn't need to be preserved
	ld hl,wPokedexSeen
	call IsPokemonBitSet
	ld b,2
	jr z,.exitSideMenu
	call PokedexToIndex
	ld hl,wTopMenuItemY
	ld a,10
	ld [hli],a ; top menu item Y
	ld a,15
	ld [hli],a ; top menu item X
	xor a
	ld [hli],a ; current menu item ID
	inc hl
	ld a,3
	ld [hli],a ; max menu item ID
	;ld a, A_BUTTON | B_BUTTON
	ld [hli],a ; menu watched keys (A button and B button)
	xor a
	ld [hli],a ; old menu item ID
	ld [wMenuWatchMovingOutOfBounds],a
.handleMenuInput
	call HandleMenuInput
	bit 1,a ; was the B button pressed?
	ld b,2
	jr nz,.buttonBPressed
	ld a,[wCurrentMenuItem]
	and a
	jr z,.choseData
	dec a
	jr z,.choseCry
	dec a
	jr z,.choseArea
.choseQuit
	ld b,1
.exitSideMenu
	pop af
	ld [wDexMaxSeenMon],a
	pop af
	ld [wd11e],a
	pop af
	ld [wListScrollOffset],a
	pop af
	ld [wLastMenuItem],a
	pop af
	ld [wCurrentMenuItem],a
	push bc
	coord hl, 0, 3
	ld de,20
	lb bc, " ", 13
	call DrawTileLine ; cover up the menu cursor in the pokemon list
	pop bc
	ret

.buttonBPressed
	push bc
	coord hl, 15, 10
	ld de,20
	lb bc, " ", 7
	call DrawTileLine ; cover up the menu cursor in the side menu
	pop bc
	jr .exitSideMenu

.choseData
	call ShowPokedexDataInternal
	ld b,0
	jr .exitSideMenu

; play pokemon cry
.choseCry
	ld a,[wd11e]
	push af
	call PlayCry
	pop af
	ld [wd11e], a
	jr .handleMenuInput

.choseArea
	predef LoadTownMap_Nest ; display pokemon areas
    call ClearScreen ; added
	ld b,0
	jr .exitSideMenu

; handles the list of pokemon on the left of the pokedex screen
; OUTPUT:
; carry set: player pressed A on the current pokemon
; carry clear, b = 0: player pressed B and exited the pokedex
; carry clear, b = 1: player used START to view the current pokemon's area
HandlePokedexListMenu:
	xor a
	ld [H_AUTOBGTRANSFERENABLED],a
; draw the horizontal line separating the seen and owned amounts from the menu
	coord hl, 15, 8
	ld a,"─"
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld [hli],a
	coord hl, 14, 0
	ld [hl],$71 ; vertical line tile
	coord hl, 14, 1
	call DrawPokedexVerticalLine
	coord hl, 14, 9
	call DrawPokedexVerticalLine
	ld hl,wPokedexSeen
	ld b,wPokedexSeenEnd - wPokedexSeen
	call CountSetBits
	ld de, wNumSetBits
	coord hl, 16, 3
	lb bc, 1, 3
	call PrintNumber ; print number of seen pokemon
	ld hl,wPokedexOwned
	ld b,wPokedexOwnedEnd - wPokedexOwned
	call CountSetBits
	ld de, wNumSetBits
	coord hl, 16, 6
	lb bc, 1, 3
	call PrintNumber ; print number of owned pokemon
	coord hl, 16, 2
	ld de,PokedexSeenText
	call PlaceString
	coord hl, 16, 5
	ld de,PokedexOwnText
	call PlaceString
	coord hl, 1, 1
	ld de,PokedexContentsText
	call PlaceString
	coord hl, 16, 10
	ld de,PokedexMenuItemsText
	call PlaceString
; find the highest pokedex number among the pokemon the player has seen
	ld hl,wPokedexSeenEnd - 1
	ld b,(wPokedexSeenEnd - wPokedexSeen) * 8 + 1
.maxSeenPokemonLoop
	ld a,[hld]
	ld c,8
.maxSeenPokemonInnerLoop
	dec b
	sla a
	jr c,.storeMaxSeenPokemon
	dec c
	jr nz,.maxSeenPokemonInnerLoop
	jr .maxSeenPokemonLoop

.storeMaxSeenPokemon
	ld a,b
	ld [wDexMaxSeenMon],a
.loop
	xor a ; 普通重绘保持原有方向键连发
	jr .drawList
.loopAfterBoundaryWrap
	ld a,1 ; 首尾跳转后先重绘目标位置，再等待上下键松开
.drawList
	push af
	xor a
	ld [H_AUTOBGTRANSFERENABLED],a
	coord hl, 4, 2
	lb bc, 14, 10
	call ClearScreenArea
	coord hl, 1, 3
	ld a,[wListScrollOffset]
	ld [wd11e],a
	ld d,7
	ld a,[wDexMaxSeenMon]
	cp a,7
	jr nc,.printPokemonLoop
	ld d,a
	dec a
	ld [wMaxMenuItem],a
; loop to print pokemon pokedex numbers and names
; if the player has owned the pokemon, it puts a pokeball beside the name
.printPokemonLoop
	ld a,[wd11e]
	inc a
	ld [wd11e],a
	push af
	push de
	push hl
	ld de,-SCREEN_WIDTH
	add hl,de
	ld de,wd11e
	lb bc, LEADING_ZEROES | 1, 3
	call PrintNumber ; print the pokedex number
	ld de,SCREEN_WIDTH
	add hl,de
	dec hl
	push hl
	ld hl,wPokedexOwned
	call IsPokemonBitSet
	pop hl
	ld a," "
	jr z,.writeTile
	ld a,$72 ; pokeball tile
.writeTile
	ld [hl],a ; put a pokeball next to pokemon that the player has owned
	push hl
	ld hl,wPokedexSeen
	call IsPokemonBitSet
	jr nz,.getPokemonName ; if the player has seen the pokemon
	ld de,.dashedLine ; print a dashed line in place of the name if the player hasn't seen the pokemon
	jr .skipGettingName
.dashedLine ; for unseen pokemon in the list
	db "----------@"
.getPokemonName
	call PokedexToIndex
	call GetMonName
.skipGettingName
	pop hl
	inc hl
	call PlaceString
	pop hl
	ld bc,2 * SCREEN_WIDTH
	add hl,bc
	pop de
	pop af
	ld [wd11e],a
	dec d
	jr nz,.printPokemonLoop
	; 在打开自动传输前同步箭头位置，避免首尾换页时旧光标残留一帧。
	call PlaceMenuCursor
	ld a,01
	ld [H_AUTOBGTRANSFERENABLED],a
	call Delay3
	call GBPalNormal
	pop af
	and a
	call nz,.waitForVerticalRelease ; 按住上下键时，首尾跳转只执行一次
	call HandleMenuInput
	bit 1,a ; was the B button pressed?
	jp nz,.buttonBPressed
.checkIfUpPressed
	bit 6,a ; was Up pressed?
	jr z,.checkIfDownPressed
.upPressed ; 上移一行，或从图鉴第一项跳到当前最后一只已见宝可梦
	ld a,[wListScrollOffset]
	and a
	jr nz,.scrollUpOneRow
	; 只有按键开始时已经位于第一项，才允许执行首尾跳转。
	; 从中间按住上键移动到第一项时，HandleMenuInput 返回的是连发输入，
	; 此时 hJoyPressed 没有 UP，等待松键并停在第一项，避免继续跳到末项。
	ld a,[hJoyPressed]
	bit 6,a
	jp z,.stopAtVerticalBoundary
	jr .wrapToLastSeenMon
.scrollUpOneRow
	dec a
	ld [wListScrollOffset],a
	jp .loop
.wrapToLastSeenMon
	; wDexMaxSeenMon 是本次打开图鉴时动态扫描出的最高已见编号。
	; 不写死宝可梦数量，扩充图鉴或已见状态变化后仍会跳到正确末项。
	ld a,[wDexMaxSeenMon]
	cp a,7
	jr c,.lastSeenFitsOnFirstPage
	sub a,7
	ld [wListScrollOffset],a
	ld a,6
	ld [wCurrentMenuItem],a
	jp .loopAfterBoundaryWrap
.lastSeenFitsOnFirstPage
	xor a
	ld [wListScrollOffset],a
	ld a,[wDexMaxSeenMon]
	dec a
	ld [wCurrentMenuItem],a
	jp .loopAfterBoundaryWrap
.checkIfDownPressed
	bit 7,a ; was Down pressed?
	jr z,.checkIfRightPressed
.downPressed ; 下移一行，或从当前最后一只已见宝可梦跳回图鉴第一项
	ld a,[wCurrentMenuItem]
	ld b,a
	ld a,[wListScrollOffset]
	add b
	inc a ; 当前绝对图鉴编号 = 滚动位置 + 屏幕光标 + 1
	ld b,a
	ld a,[wDexMaxSeenMon]
	cp b
	jr nz,.scrollDownOneRow
	; 与上键相同，只有在末项重新按下 DOWN 才跳回第一项。
	; 从中间按住下键到达末项时先等待松键，让光标稳定停在末项。
	ld a,[hJoyPressed]
	bit 7,a
	jp z,.stopAtVerticalBoundary
	jr .wrapToFirstEntry
.scrollDownOneRow
	ld hl,wListScrollOffset
	inc [hl]
	jp .loop
.wrapToFirstEntry
	; 同时重置屏幕光标和滚动位置，确保回到真正的第一项。
	xor a
	ld [wCurrentMenuItem],a
	ld [wListScrollOffset],a
	jp .loopAfterBoundaryWrap
.checkIfRightPressed
	bit 4,a ; was Right pressed?
	jr z,.checkIfLeftPressed
.rightPressed ; 按住右键时每次向后移动 7 项，最终停在动态最后一项
	ld a,[wDexMaxSeenMon]
	cp a,7
	jr c,.rightToLastSeenOnFirstPage
	sub a,7 ; 最后一页的滚动位置 = 最高已见编号 - 7
	ld b,a
	ld a,[wListScrollOffset]
	add a,7
	cp b
	jr c,.storeRightPageOffset
	; 到达或越过最后一页时，同时把光标移到最后一行。
	; 这样按住右键会真正停在最后一只已见宝可梦，而不是保留原屏幕行。
	ld a,b
	ld [wListScrollOffset],a
	ld a,6
	ld [wCurrentMenuItem],a
	jp .loop
.storeRightPageOffset
	ld [wListScrollOffset],a
	jp .loop
.rightToLastSeenOnFirstPage
	; 已见宝可梦不足 7 只时没有滚动页，右键直接落到动态末项。
	xor a
	ld [wListScrollOffset],a
	ld a,[wDexMaxSeenMon]
	dec a
	ld [wCurrentMenuItem],a
	jp .loop
.checkIfLeftPressed ; 按住左键时每次向前移动 7 项，最终停在第一项
	bit 5,a ; was Left pressed?
	jr z,.checkIfAButtonPressed
.leftPressed
	ld a,[wListScrollOffset]
	sub a,7
	jr nc,.storeLeftPageOffset
	; 已经无法再退完整一页时，同时清零滚动位置和屏幕光标。
	; 例如第 18 项按住左键依次为 18 → 11 → 4 → 1。
	xor a
	ld [wListScrollOffset],a
	ld [wCurrentMenuItem],a
	jp .loop
.storeLeftPageOffset
	ld [wListScrollOffset],a
	jp .loop
.checkIfAButtonPressed
	; A/B 优先于快捷键，避免组合按键改变进入四项菜单或退出图鉴的原行为。
	bit 0,a ; was A pressed?
	jr nz,.buttonAPressed
.checkIfSelectPressed
	bit 2,a ; was SELECT pressed?
	jr z,.checkIfStartPressed
	call .getSelectedSeenMonIndex
	jp z,.loop ; 未见的虚线条目没有可播放的对应叫声
	ld a,[wd11e]
	call PlayCry
	jp .loop
.checkIfStartPressed
	bit 3,a ; was START pressed?
	jp z,.loop
	call .getSelectedSeenMonIndex
	jp z,.loop ; 未见的虚线条目不能查看地区
	predef LoadTownMap_Nest
	call ClearScreen
	ld b,1 ; 告诉上层重新载入图鉴图块并初始化列表菜单
	and a
	ret
.buttonAPressed
	scf
	ret
.buttonBPressed
	ld b,0
	and a
	ret

.stopAtVerticalBoundary
	; 从列表中间按住方向键到达首尾时，只停在边界并等待松键。
	; 重新按一次对应方向键后，才会执行首尾跳转。
	jp .loopAfterBoundaryWrap

.waitForVerticalRelease
	; 首尾跳转或按住到达边界后必须先松开上下键，防止继续移动。
	call DelayFrame
	call Joypad
	ld a,[hJoyHeld]
	and D_UP | D_DOWN
	jr nz,.waitForVerticalRelease
	ret

.getSelectedSeenMonIndex
	; 将当前列表光标换算成图鉴编号，并沿用四项菜单的“仅已见有效”规则。
	ld a,[wListScrollOffset]
	ld b,a
	ld a,[wCurrentMenuItem]
	add b
	inc a
	ld [wd11e],a
	ld hl,wPokedexSeen
	call IsPokemonBitSet
	ret z
	call PokedexToIndex ; wd11e 转换为叫声和地区功能使用的内部编号
	ld a,[wd11e]
	and a ; 显式返回非零状态，供快捷键分支判断条目有效
	ret

DrawPokedexVerticalLine:
	ld c,9 ; height of line
	ld de,SCREEN_WIDTH
	ld a,$71 ; vertical line tile
.loop
	ld [hl],a
	add hl,de
	xor a,1 ; toggle between vertical line tile and box tile
	dec c
	jr nz,.loop
	ret

PokedexSeenText:
	db "Seen@"

PokedexOwnText:
	db "Own@"

PokedexContentsText:
	db "Kanto Pokédex@"

PokedexMenuItemsText:
	db   "Info"
	next "Cry"
	next "Area"
	next "Quit@"

; tests if a pokemon's bit is set in the seen or owned pokemon bit fields
; INPUT:
; [wd11e] = pokedex number
; hl = address of bit field
IsPokemonBitSet:
	ld a,[wd11e]
	dec a
	ld c,a
	ld b,FLAG_TEST
	predef FlagActionPredef
	ld a,c
	and a
	ret

; function to display pokedex data from outside the pokedex
ShowPokedexData:
	call GBPalWhiteOutWithDelay3
	call ClearScreen
	call UpdateSprites
	callab LoadPokedexTilePatterns ; load pokedex tiles

; function to display pokedex data from inside the pokedex
ShowPokedexDataInternal:
	ld hl,wd72c
	set 1,[hl]
	ld a,$33 ; 3/7 volume
	ld [rNR50],a
	call GBPalWhiteOut ; zero all palettes
	call ClearScreen
	ld a,[wd11e] ; pokemon ID
	ld [wcf91],a
	push af
	ld b, SET_PAL_POKEDEX
	call RunPaletteCommand
	pop af
	ld [wd11e],a
	ld a,[hTilesetType]
	push af
	xor a
	ld [hTilesetType],a

	coord hl, 0, 0
	ld de,1
	lb bc, $64, SCREEN_WIDTH
	call DrawTileLine ; draw top border

	coord hl, 0, 17
	ld b, $6f
	call DrawTileLine ; draw bottom border

	coord hl, 0, 1
	ld de,20
	lb bc, $66, $10
	call DrawTileLine ; draw left border

	coord hl, 19, 1
	ld b,$67
	call DrawTileLine ; draw right border

	ld a,$63 ; upper left corner tile
	Coorda 0, 0
	ld a,$65 ; upper right corner tile
	Coorda 19, 0
	ld a,$6c ; lower left corner tile
	Coorda 0, 17
	ld a,$6e ; lower right corner tile
	Coorda 19, 17

	coord hl, 0, 9
	ld de,PokedexDataDividerLine
	call PlaceString ; draw horizontal divider line

	coord hl, 9, 6
	ld de,HeightWeightText
	call PlaceString

	call GetMonName
	coord hl, 9, 2
	call PlaceString

	ld hl,PokedexEntryPointers
	ld a,[wd11e]
	dec a
	ld e,a
	ld d,0
	add hl,de
	add hl,de
	ld a,[hli]
	ld e,a
	ld d,[hl] ; de = address of pokedex entry

	coord hl, 9, 4
	call PlaceString ; print species name

	ld h,b
	ld l,c
	push de
	ld a,[wd11e]
	push af
	call IndexToPokedex

	coord hl, 2, 8
	ld a, "№"
	ld [hli],a
	ld a,"⠄"
	ld [hli],a
	ld de,wd11e
	lb bc, LEADING_ZEROES | 1, 3
	call PrintNumber ; print pokedex number

	ld hl,wPokedexOwned
	call IsPokemonBitSet
	pop af
	ld [wd11e],a
	ld a,[wcf91]
	ld [wd0b5],a
	pop de

	push af
	push bc
	push de
	push hl

	call Delay3
	call GBPalNormal
	call GetMonHeader ; load pokemon picture location
	coord hl, 1, 1
	call LoadFlippedFrontSpriteByMonIndex ; draw pokemon picture
	ld a,[wcf91]
	call PlayCry ; play pokemon cry

	pop hl
	pop de
	pop bc
	pop af

	ld a,c
	and a
	jp z,.waitForButtonPress ; if the pokemon has not been owned, don't print the height, weight, or description
	inc de ; de = address of feet (height)
	ld a,[de] ; reads feet, but a is overwritten without being used
	coord hl, 12, 6
	lb bc, 1, 2
	call PrintNumber ; print feet (height)
	ld a,$60 ; feet symbol tile (one tick)
	ld [hl],a
	inc de
	inc de ; de = address of inches (height)
	coord hl, 15, 6
	lb bc, LEADING_ZEROES | 1, 2
	call PrintNumber ; print inches (height)
	ld a,$61 ; inches symbol tile (two ticks)
	ld [hl],a
; now print the weight (note that weight is stored in tenths of pounds internally)
	inc de
	inc de
	inc de ; de = address of upper byte of weight
	push de
; put weight in big-endian order at hDexWeight
	ld hl,hDexWeight
	ld a,[hl] ; save existing value of [hDexWeight]
	push af
	ld a,[de] ; a = upper byte of weight
	ld [hli],a ; store upper byte of weight in [hDexWeight]
	ld a,[hl] ; save existing value of [hDexWeight + 1]
	push af
	dec de
	ld a,[de] ; a = lower byte of weight
	ld [hl],a ; store lower byte of weight in [hDexWeight + 1]
	ld de,hDexWeight
	coord hl, 11, 8
	lb bc, 2, 5 ; 2 bytes, 5 digits
	call PrintNumber ; print weight
	coord hl, 14, 8
	ld a,[hDexWeight + 1]
	sub a,10
	ld a,[hDexWeight]
	sbc a,0
	jr nc,.next
	ld [hl],"0" ; if the weight is less than 10, put a 0 before the decimal point
.next
	inc hl
	ld a,[hli]
	ld [hld],a ; make space for the decimal point by moving the last digit forward one tile
	ld [hl],"⠄" ; decimal point tile
	pop af
	ld [hDexWeight + 1],a ; restore original value of [hDexWeight + 1]
	pop af
	ld [hDexWeight],a ; restore original value of [hDexWeight]
	pop hl
	inc hl ; hl = address of pokedex description text
	coord bc, 1, 11
	ld a,2
	ld [$fff4],a
	call TextCommandProcessor ; print pokedex description text
	xor a
	ld [$fff4],a
.waitForButtonPress
	call JoypadLowSensitivity
	ld a,[hJoy5]
	and a,A_BUTTON | B_BUTTON
	jr z,.waitForButtonPress
	pop af
	ld [hTilesetType],a
	call GBPalWhiteOut
	call ClearScreen
	call RunDefaultPaletteCommand
	call LoadTextBoxTilePatterns
	call GBPalNormal
	ld hl,wd72c
	res 1,[hl]
	ld a,$77 ; max volume
	ld [rNR50],a
	ret

HeightWeightText:
	db   "Ht  ?",$60,"??",$61
	next "Wt   ???lb@"

; XXX does anything point to this?
PokeText:
	db "#@"

; horizontal line that divides the pokedex text description from the rest of the data
PokedexDataDividerLine:
	db $68,$69,$6B,$69,$6B
	db $69,$6B,$69,$6B,$6B
	db $6B,$6B,$69,$6B,$69
	db $6B,$69,$6B,$69,$6A
	db "@"

; draws a line of tiles
; INPUT:
; b = tile ID
; c = number of tile ID's to write
; de = amount to destination address after each tile (1 for horizontal, 20 for vertical)
; hl = destination address
DrawTileLine:
	push bc
	push de
.loop
	ld [hl],b
	add hl,de
	dec c
	jr nz,.loop
	pop de
	pop bc
	ret

INCLUDE "data/pokedex_entries.asm"

PokedexToIndex:
	; converts the Pokédex number at wd11e to an index
	push bc
	push hl
	ld a,[wd11e]
	ld b,a
	ld c,0
	ld hl,PokedexOrder

.loop ; go through the list until we find an entry with a matching dex number
	inc c
	ld a,[hli]
	cp b
	jr nz,.loop

	ld a,c
	ld [wd11e],a
	pop hl
	pop bc
	ret

IndexToPokedex:
	; converts the index number at wd11e to a Pokédex number
	push bc
	push hl
	ld a,[wd11e]
	dec a
	ld hl,PokedexOrder
	ld b,0
	ld c,a
	add hl,bc
	ld a,[hl]
	ld [wd11e],a
	pop hl
	pop bc
	ret

INCLUDE "data/pokedex_order.asm"
