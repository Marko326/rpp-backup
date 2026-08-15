; MoveDex
; Lists every usable move ID and displays its current battle data.
; This intentionally has no seen/owned state: the first version is a complete
; reference for all moves defined by the project.

ShowMoveDexMenu:
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
	xor a
	ld [H_AUTOBGTRANSFERENABLED],a
	call ClearScreen
	ld b, SET_PAL_GENERIC
	call RunPaletteCommand
	callab LoadPokedexTilePatterns
	call MoveDexDrawStaticListUI

.doMoveListMenu
	; 与 Pokédex 一样，右侧子菜单负责在返回前清掉自己的光标，
	; 左侧这里只恢复列表参数并重新进入列表输入，不再额外重复扫描右栏。
	call MoveDexSetupListMenuParameters
	call HandleMoveDexListMenu
	jr c,.goToSideMenu

.exitMovedex
	xor a
	ld [wMenuWatchMovingOutOfBounds],a
	ld [wCurrentMenuItem],a
	ld [wLastMenuItem],a
	ld [hJoy7],a
	pop af
	ld [wListScrollOffset],a
	call GBPalWhiteOutWithDelay3
	; MoveDex 会加载 Pokédex 专用图块，其中一部分 VRAM 与户外屋顶/文本框共用。
	; 返回 START 前先恢复当前 World 模式对应的文本框/屋顶图块，避免屋顶一直乱码到关闭菜单。
	call LoadTextBoxTilePatterns
	call RunDefaultPaletteCommand
	ret

.goToSideMenu
	call HandleMoveDexSideMenu
	dec b
	jp z,.exitMovedex ; Quit
	dec b
	jp z,.doMoveListMenu ; B 返回左侧
	jp .setUpGraphics ; Info 返回后重新加载列表图块与静态界面

; 按 Pokédex 的结构把左侧列表做成独立处理函数。
; OUTPUT:
; carry set: A 选择当前技能
; carry clear: B 退出 MoveDex
HandleMoveDexListMenu:
.loopAfterBoundaryWrap
	ld a,1
	jr .drawList
.loop
	xor a
.drawList
	push af
	xor a
	ld [H_AUTOBGTRANSFERENABLED],a
	coord hl, 0, 2
	lb bc, 14, 14
	call ClearScreenArea

	coord hl, 1, 3
	ld a,[wListScrollOffset]
	ld [wd11e],a
	ld d,7
.printMoveLoop
	ld a,[wd11e]
	inc a
	ld [wd11e],a
	push af
	push de
	push hl

	; Number on the line above the move name, matching the Pokédex layout.
	ld de,-SCREEN_WIDTH
	add hl,de
	ld de,wd11e
	lb bc, LEADING_ZEROES | 1, 3
	call PrintNumber

	pop hl
	push hl
	call GetMoveName
	pop hl
	; x=1 留给未来的 Use 标记，技能名固定从 x=2 开始。
	; PlaceString 会推进 HL，因此额外保存行起点，避免每一项继续向右漂移。
	push hl
	inc hl
	call PlaceString
	pop hl

	ld bc,2 * SCREEN_WIDTH
	add hl,bc
	pop de
	pop af
	ld [wd11e],a
	dec d
	jr nz,.printMoveLoop

	call PlaceMenuCursor
	ld a,1
	ld [H_AUTOBGTRANSFERENABLED],a
	call Delay3
	call GBPalNormal
	pop af
	and a
	call nz,.waitForVerticalRelease
	call HandleMenuInput
	bit 1,a
	jp nz,.buttonBPressed

	bit 6,a
	jr z,.checkDown
	; Up: scroll one row. A fresh UP at the first entry wraps to the end.
	ld a,[wListScrollOffset]
	and a
	jr nz,.scrollUpOne
	ld a,[hJoyPressed]
	bit 6,a
	jp z,.stopAtVerticalBoundary
	ld a,NUM_ATTACKS - 1
	sub 7
	ld [wListScrollOffset],a
	ld a,6
	ld [wCurrentMenuItem],a
	jp .loopAfterBoundaryWrap
.scrollUpOne
	dec a
	ld [wListScrollOffset],a
	jp .loop

.checkDown
	bit 7,a
	jr z,.checkRight
	; Down: scroll one row. A fresh DOWN at the final entry wraps to move 001.
	call MoveDexGetSelectedMove
	cp NUM_ATTACKS - 1
	jr nz,.scrollDownOne
	ld a,[hJoyPressed]
	bit 7,a
	jp z,.stopAtVerticalBoundary
	xor a
	ld [wCurrentMenuItem],a
	ld [wListScrollOffset],a
	jp .loopAfterBoundaryWrap
.scrollDownOne
	ld hl,wListScrollOffset
	inc [hl]
	jp .loop

.checkRight
	bit 4,a
	jr z,.checkLeft
	; Right: advance seven absolute entries and clamp at the final move.
	ld a,NUM_ATTACKS - 1
	sub 7
	ld b,a
	ld a,[wListScrollOffset]
	add 7
	cp b
	jr c,.storeRightOffset
	ld a,b
	ld [wListScrollOffset],a
	ld a,6
	ld [wCurrentMenuItem],a
	jp .loop
.storeRightOffset
	ld [wListScrollOffset],a
	jp .loop

.checkLeft
	bit 5,a
	jr z,.checkA
	; Left: move back seven entries and clamp at move 001.
	ld a,[wListScrollOffset]
	sub 7
	jr nc,.storeLeftOffset
	xor a
	ld [wListScrollOffset],a
	ld [wCurrentMenuItem],a
	jp .loop
.storeLeftOffset
	ld [wListScrollOffset],a
	jp .loop

.checkA
	bit 0,a
	jp z,.loop
	scf
	ret

.buttonBPressed
	and a
	ret

.stopAtVerticalBoundary
	jp .loopAfterBoundaryWrap

.waitForVerticalRelease
	call DelayFrame
	call Joypad
	ld a,[hJoyHeld]
	and D_UP | D_DOWN
	jr nz,.waitForVerticalRelease
	ret

MoveDexGetSelectedMove:
	ld a,[wListScrollOffset]
	ld b,a
	ld a,[wCurrentMenuItem]
	add b
	inc a
	ret

MoveDexSetupListMenuParameters:
	; 左侧技能列表的通用菜单参数。进入右侧菜单后会被临时覆盖，
	; 因此首次进入以及从右侧菜单返回时都从这里统一恢复。
	ld hl,wTopMenuItemY
	ld a,3
	ld [hli],a
	xor a
	ld [hli],a
	inc a
	ld [wMenuWatchMovingOutOfBounds],a
	inc hl
	inc hl
	ld a,6
	ld [hli],a
	ld [hl],D_LEFT | D_RIGHT | B_BUTTON | A_BUTTON
	ret

MoveDexDrawStaticListUI:
	; 右侧统计/功能区完全沿用 Pokédex 的对齐方式。
	coord hl, 15, 8
	ld a,"─"
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld [hli],a
	coord hl, 14, 0
	ld [hl],$71
	coord hl, 14, 1
	call MoveDexDrawVerticalLine
	coord hl, 14, 9
	call MoveDexDrawVerticalLine

	coord hl, 1, 1
	ld de,MoveDexContentsText
	call PlaceString

	; Seen / Use 的记录系统留到下一阶段；这里先用最大技能数量占位，
	; 让版式、位数和未来真实统计完全一致。
	ld a,NUM_ATTACKS - 1
	ld [wBuffer],a
	coord hl, 16, 2
	ld de,MoveDexSeenText
	call PlaceString
	coord hl, 16, 3
	ld de,wBuffer
	lb bc, 1, 3
	call PrintNumber

	coord hl, 16, 5
	ld de,MoveDexUseText
	call PlaceString
	coord hl, 16, 6
	ld de,wBuffer
	lb bc, 1, 3
	call PrintNumber

	coord hl, 16, 10
	ld de,MoveDexMenuItemsText
	call PlaceString
	ret

HandleMoveDexSideMenu:
	; 按 Pokédex 的父列表/右侧子菜单结构处理光标。
	; RPP 的 PlaceMenuCursor 还会记录 wMenuCursorLocation/wTileBehindCursor，
	; 因此 B 返回时必须先按“当前真实光标地址”擦除右栏箭头，再恢复父列表。
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
	ld [hli],a ; A_BUTTON | B_BUTTON
	xor a
	ld [hli],a ; old menu item ID
	ld [wMenuWatchMovingOutOfBounds],a

.handleMenuInput
	call HandleMenuInput
	bit 1,a
	ld b,2
	jr nz,.buttonBPressed

	ld a,[wCurrentMenuItem]
	and a
	jr z,.choseInfo
	cp 3
	jr z,.choseQuit

	; Anim / Effe 暂时只是占位。等待本次 A 松开后再重新进入
	; HandleMenuInput，避免立即重复触发造成右侧光标状态异常。
	call MoveDexWaitForABRelease
	jr .handleMenuInput

.choseQuit
	ld b,1
.exitSideMenu
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
	ld de,SCREEN_WIDTH
	lb bc, " ", 13
	call DrawTileLine ; 与 Pokédex 一样清掉左侧列表旧光标
	pop bc
	ret

.buttonBPressed
	; 先使用菜单系统记录的真实位置擦掉当前右栏光标。
	; 这一步补齐 RPP 新版 PlaceMenuCursor 对 wMenuCursorLocation 的维护，
	; 避免只按固定坐标清 tilemap 时留下右侧箭头。
	call EraseMenuCursor
	; 再保留 Pokédex 原版的整列清理作为保险，四个菜单项全部覆盖。
	push bc
	coord hl, 15, 10
	ld de,SCREEN_WIDTH
	lb bc, " ", 7
	call DrawTileLine
	pop bc
	jr .exitSideMenu

.choseInfo
	; Info 会清屏。先恢复左侧列表状态，让详情页左右切换后的
	; MoveDexSyncListSelection 使用正确的列表行作为返回基准。
	pop af
	ld [wd11e],a
	pop af
	ld [wListScrollOffset],a
	pop af
	ld [wLastMenuItem],a
	pop af
	ld [wCurrentMenuItem],a
	call ShowMoveDexData
	ld b,0
	ret

MoveDexWaitForABRelease:
	call DelayFrame
	call Joypad
	ld a,[hJoyHeld]
	and A_BUTTON | B_BUTTON
	jr nz,MoveDexWaitForABRelease
	ret

MoveDexContentsText:
	db "MoveDex@"
MoveDexSeenText:
	db "Seen@"
MoveDexUseText:
	db "Use@"
MoveDexMenuItemsText:
	db   "Info"
	next "Anim"
	next "Effe"
	next "Quit@"

MoveDexDrawVerticalLine:
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

ShowMoveDexData:
	call GBPalWhiteOut
	xor a
	ld [H_AUTOBGTRANSFERENABLED],a
	call ClearScreen
	ld b,SET_PAL_GENERIC
	call RunPaletteCommand

	; 第一阶段移植 PureRGB 风格 MoveDex 详情页：
	; UI 图块只在进入详情页时加载一次，技能切换时只更新动态数据和类型图标。
	call MoveDexLoadDataUITiles
	call MoveDexDrawDataFrame
	call MoveDexSetupTypeIconAttributes
	; 每次进入技能详情都从说明第 1 页开始。
	xor a
	ld [wBuffer + 6],a ; MoveDex 专用说明页索引（0=第1页，可继续扩展）

	; MoveDex 说明页直接复用 Pokédex/普通文本的下箭头闪烁计时器。
	; 进入前先保存全局计时值，退出详情页时再完整恢复。
	ld a,[H_DOWNARROWBLINKCNT1]
	push af
	ld a,[H_DOWNARROWBLINKCNT2]
	push af
	call MoveDexDrawMoveData

	ld a,1
	ld [H_AUTOBGTRANSFERENABLED],a
	call Delay3
	call GBPalNormal

.inputLoop
	; 与 Pokédex 的文本翻页提示使用同一个闪烁函数和循环时序。
	; 最后一页会把箭头 tile 保持为空且 CNT1=0，因此这里可无条件调用。
	coord hl, 10, 16
	call HandleDownArrowBlinkTiming
	call JoypadLowSensitivity
	ld a,[hJoy5]
	bit 5,a
	jp nz,.previousMove
	bit 4,a
	jp nz,.nextMove
	bit 1,a ; B
	jp nz,.close
	bit 0,a ; A
	jr nz,.nextDescriptionPage
	jr .inputLoop

.nextDescriptionPage
	; PureRGB 风格分页：有下一页时 A 翻页；最后一页按 A 不退出。
	call MoveDexDescriptionHasNextPage
	jr nc,.inputLoop
	ld a,[wBuffer + 6]
	inc a
	ld [wBuffer + 6],a
	xor a
	ld [H_AUTOBGTRANSFERENABLED],a
	; 说明正文只占 y=11..15。y=16 同时放着 <PREV/NEXT> 的上半部分，
	; 不能整行清掉；中央下箭头由 MoveDexPrepareDescriptionArrow 单独处理。
	coord hl, 1, 11
	lb bc, 5, 18
	call ClearScreenArea
	call MoveDexDrawDescription
	ld a,1
	ld [H_AUTOBGTRANSFERENABLED],a
	call Delay3
	jr .inputLoop

.close
	; 恢复进入 MoveDex 详情页之前的全局下箭头闪烁计时值。
	pop af
	ld [H_DOWNARROWBLINKCNT2],a
	pop af
	ld [H_DOWNARROWBLINKCNT1],a

	; 如果在详情页用左右切换过技能，返回列表时同步选中位置。
	call MoveDexSyncListSelection
	call GBPalWhiteOut
	; 详情页临时占用了字体区 $C0-$D9，白屏期间恢复这些字体图块，
	; 避免离开 MoveDex 后留下潜在的共享 VRAM 图块污染。
	call MoveDexRestoreFontTiles
	call ClearScreen
	ret

.previousMove
	ld a,[wd11e]
	cp 1
	jp z,.inputLoop
	dec a
	ld [wd11e],a
	jr .redrawMove

.nextMove
	ld a,[wd11e]
	cp NUM_ATTACKS - 1
	jp z,.inputLoop
	inc a
	ld [wd11e],a

.redrawMove
	; 左右切换技能时回到说明第 1 页。
	xor a
	ld [wBuffer + 6],a
	ld [H_AUTOBGTRANSFERENABLED],a
	call MoveDexClearDynamicData
	call MoveDexDrawMoveData
	ld a,1
	ld [H_AUTOBGTRANSFERENABLED],a
	call Delay3
	jp .inputLoop

MoveDexLoadDataUITiles:
	; PureRGB 的 <PREV/NEXT>、分类标识与百分号图块。
	; 三种伤害分类统一使用 PureRGB PHYSICAL 的完整宽底框和同一套字模。
	; 1bpp 图块复制到 $C4-$D9，不覆盖当前 MoveDex/Pokédex 边框图块。
	ld de,MoveDexUI
	ld hl,vChars1 + $440
	lb bc, BANK(MoveDexUI), (MoveDexUIEnd - MoveDexUI) / $8
	jp CopyVideoDataDouble

MoveDexRestoreFontTiles:
	; $C0-$D9 共 26 个 tile，对应 FontGraphics 中从第 $40 个字符开始的区域。
	ld de,FontGraphics + $200
	ld hl,vChars1 + $400
	lb bc, BANK(FontGraphics), $1a
	jp CopyVideoDataDouble

MoveDexLoadMoveData:
	ld a,[wd11e]
	dec a
	ld hl,Moves
	ld bc,MoveEnd - Moves
	call AddNTimes
	ld de,wBuffer
	ld bc,MoveEnd - Moves
	ld a,BANK(Moves)
	jp FarCopyData

MoveDexDrawDataFrame:
	coord hl, 0, 0
	ld de,1
	lb bc, $64, SCREEN_WIDTH
	call MoveDexDrawTileLine
	coord hl, 0, 17
	ld b,$6f
	call MoveDexDrawTileLine
	coord hl, 0, 1
	ld de,SCREEN_WIDTH
	lb bc, $66, $10
	call MoveDexDrawTileLine
	coord hl, 19, 1
	ld b,$67
	call MoveDexDrawTileLine
	ld a,$63
	Coorda 0, 0
	ld a,$65
	Coorda 19, 0
	ld a,$6c
	Coorda 0, 17
	ld a,$6e
	Coorda 19, 17

	; PureRGB 风格的上下分区。
	coord hl, 0, 2
	ld de,MoveDexDividerLine
	call PlaceString
	coord hl, 0, 9
	ld de,MoveDexDividerLine
	call PlaceString

	; PureRGB 把编号固定在最右侧：最长 12 字符技能名占 x=1..12，
	; x=13 永远留一格，再从 x=14 显示 №. 和三位编号。
	coord hl, 14, 1
	ld de,MoveDexNumberPrefixText
	call PlaceString

	coord hl, 4, 3
	ld de,MoveDexTypeLabel
	call PlaceString
	coord hl, 1, 6
	ld de,MoveDexPowerLabel
	call PlaceString
	coord hl, 13, 6
	ld de,MoveDexPPLabel
	call PlaceString
	coord hl, 1, 8
	ld de,MoveDexAccuracyLabel
	call PlaceString

	; 类型图标固定使用 $C0-$C3，切技能时只替换 VRAM 中的四个图块。
	coord hl, 1, 3
	ld a,$c0
	ld [hli],a
	inc a
	ld [hl],a
	inc a
	coord hl, 1, 4
	ld [hli],a
	inc a
	ld [hl],a

	; RPP charmap 没有 % 字符；$D9 是这页专用的百分号 UI tile。
	; 百分比个位与 Power 个位同列（x=9），% 紧跟在 x=10。
	ld a,$d9
	Coorda 10, 8
	ret

MoveDexDrawMoveData:
	call MoveDexLoadMoveData

	; 技能名称与编号。当前最长技能名为 12 字符，因此 x=13 保证为空格。
	call GetMoveName
	coord hl, 1, 1
	call PlaceString
	coord hl, 16, 1
	ld de,wd11e
	lb bc, LEADING_ZEROES | 1, 3
	call PrintNumber

	; 类型图标、类型名和 Physical/Special/Status 分类。
	ld a,[wBuffer + 3]
	push af
	call MoveDexLoadTypeIcon
	pop af
	push af
	call MoveDexLoadTypePalette
	pop af
	call MoveDexGetTypeText
	coord hl, 4, 4
	call PlaceString
	call MoveDexDrawDamageClass

	; Power。
	coord hl, 7, 6
	ld de,wBuffer + 2
	lb bc, 1, 3
	call PrintNumber

	; PP。
	coord hl, 16, 6
	ld de,wBuffer + 5
	lb bc, 1, 2
	call PrintNumber

	; Accuracy：0-255 直接换算为百分比。
	; 数字使用与 Power 相同的 x=7..9 三格右对齐，% 固定在 x=10。
	ld a,[wBuffer + 4]
	call MoveDexAccuracyToPercent
	ld [wBuffer],a
	coord hl, 7, 8
	ld de,wBuffer
	lb bc, 1, 3
	call PrintNumber

	; HiCrit 只在高暴击技能显示；H 与 PP 的第一个 P 同列（x=13）。
	ld a,[wd11e]
	call MoveDexIsHighCrit
	jr nc,.skipHighCrit
	coord hl, 13, 8
	ld de,MoveDexHighCritText
	call PlaceString
.skipHighCrit

	; 技能说明区参考 PureRGB：上半部分描述招式本身，
	; 最后明确写当前 RPP 实际使用的战斗效果。
	call MoveDexDrawDescription

	jp MoveDexDrawBottomNavigation

MoveDexClearDynamicData:
	coord hl, 1, 1
	lb bc, 1, 12
	call ClearScreenArea
	coord hl, 16, 1
	lb bc, 1, 3
	call ClearScreenArea
	coord hl, 4, 4
	lb bc, 1, 8
	call ClearScreenArea
	coord hl, 15, 3
	lb bc, 1, 4
	call ClearScreenArea
	coord hl, 7, 6
	lb bc, 1, 3
	call ClearScreenArea
	coord hl, 16, 6
	lb bc, 1, 2
	call ClearScreenArea
	coord hl, 7, 8
	lb bc, 1, 3
	call ClearScreenArea
	coord hl, 13, 8
	lb bc, 1, 6
	call ClearScreenArea
	coord hl, 1, 11
	lb bc, 5, 18
	call ClearScreenArea
	coord hl, 10, 16
	ld a," "
	ld [hl],a
	coord hl, 1, 16
	lb bc, 1, 3
	call ClearScreenArea
	coord hl, 16, 16
	lb bc, 1, 3
	call ClearScreenArea
	ret

MoveDexDrawDamageClass:
	ld a,[wd11e]
	ld [wTempMoveID],a
	callba _PhysicalSpecialSplit
	ld a,[wTempMoveID]
	cp PHYSICAL
	ld a,$d1 ; PHYSICAL
	jr z,.draw
	ld a,[wTempMoveID]
	cp SPECIAL
	ld a,$cd ; SPECIAL
	jr z,.draw
	ld a,$d5 ; STATUS
.draw
	coord hl, 15, 3
	ld c,4
.loop
	ld [hli],a
	inc a
	dec c
	jr nz,.loop
	ret

MoveDexDrawBottomNavigation:
	; 先恢复中央底边，再根据当前技能是否有前/后项绘制按钮。
	coord hl, 4, 17
	ld de,1
	lb bc, $6f, 12
	call MoveDexDrawTileLine

	ld a,[wd11e]
	cp 1
	jr z,.noPrevious
	coord hl, 1, 17
	ld a,$c4
	ld [hli],a
	inc a
	ld [hli],a
	inc a
	ld [hl],a
	coord hl, 1, 16
	ld a,$ca
	ld [hli],a
	inc a
	ld [hli],a
	inc a
	ld [hl],a
	jr .nextButton
.noPrevious
	coord hl, 1, 17
	ld de,1
	lb bc, $6f, 3
	call MoveDexDrawTileLine

.nextButton
	ld a,[wd11e]
	cp NUM_ATTACKS - 1
	jr z,.noNext
	coord hl, 16, 17
	ld a,$c7
	ld [hli],a
	inc a
	ld [hli],a
	inc a
	ld [hl],a
	coord hl, 16, 16
	ld a,$ca
	ld [hli],a
	inc a
	ld [hli],a
	inc a
	ld [hl],a
	ret
.noNext
	coord hl, 16, 17
	ld de,1
	lb bc, $6f, 3
	jp MoveDexDrawTileLine

MoveDexSetupTypeIconAttributes:
	; 给 2x2 类型图标单独使用 BG palette 2，其余 MoveDex UI 保持原菜单配色。
	; 切 WRAM bank 时不使用栈，恢复原 bank 后再 ret，避免破坏主栈。
	ld a,[rSVBK]
	ld b,a
	ld a,2
	ld [rSVBK],a
	ld hl,W2_TilesetPaletteMap + 3 * SCREEN_WIDTH + 1
	ld a,2
	ld [hli],a
	ld [hl],a
	ld de,SCREEN_WIDTH - 1
	add hl,de
	ld [hli],a
	ld [hl],a
	ld a,3
	ld [W2_StaticPaletteMapChanged],a
	ld a,1
	ld [W2_ForceBGPUpdate],a
	ld a,b
	ld [rSVBK],a
	ret

MoveDexLoadTypePalette:
	ld e,a
	ld d,0
	ld hl,MoveDexTypePaletteMap
	add hl,de
	ld d,[hl]
	ld e,2
	callba LoadSGBPalette

	; 新的类型颜色写入 palette 2 后请求下一次 VBlank 更新 BG palette。
	ld a,[rSVBK]
	ld b,a
	ld a,2
	ld [rSVBK],a
	ld a,1
	ld [W2_ForceBGPUpdate],a
	ld a,b
	ld [rSVBK],a
	ret

MoveDexTypePaletteMap:
	db PAL_GREYMON    ; NORMAL
	db PAL_BROWNMON   ; FIGHTING
	db PAL_MEWMON     ; FLYING
	db PAL_PURPLEMON  ; POISON
	db PAL_BROWNMON   ; GROUND
	db PAL_GREYMON    ; ROCK
	db PAL_GREYMON    ; unused $06
	db PAL_GREENMON   ; BUG
	db PAL_PURPLEMON  ; GHOST
	db PAL_GREYMON    ; STEEL
	db PAL_GREYMON    ; UNK_TYPE
	rept 9
		db PAL_GREYMON ; unused $0b-$13
	endr
	db PAL_REDMON     ; FIRE
	db PAL_BLUEMON    ; WATER
	db PAL_GREENMON   ; GRASS
	db PAL_YELLOWMON  ; ELECTRIC
	db PAL_PINKMON    ; PSYCHIC
	db PAL_CYANMON    ; ICE
	db PAL_PURPLEMON  ; DRAGON
	db PAL_BLACK      ; DARK
	db PAL_PINKMON    ; FAIRY

MoveDexLoadTypeIcon:
	add a
	ld e,a
	ld d,0
	ld hl,MoveDexTypeIconPointers
	add hl,de
	ld a,[hli]
	ld e,a
	ld d,[hl]
	ld hl,vChars1 + $400
	lb bc, BANK(MoveDexNormalTypeIcon), 4
	jp CopyVideoData

MoveDexTypeIconPointers:
	dw MoveDexNormalTypeIcon
	dw MoveDexFightingTypeIcon
	dw MoveDexFlyingTypeIcon
	dw MoveDexPoisonTypeIcon
	dw MoveDexGroundTypeIcon
	dw MoveDexRockTypeIcon
	dw MoveDexTypelessIcon ; unused $06
	dw MoveDexBugTypeIcon
	dw MoveDexGhostTypeIcon
	dw MoveDexSteelTypeIcon
	dw MoveDexTypelessIcon ; UNK_TYPE
	rept 9
		dw MoveDexTypelessIcon ; unused $0b-$13
	endr
	dw MoveDexFireTypeIcon
	dw MoveDexWaterTypeIcon
	dw MoveDexGrassTypeIcon
	dw MoveDexElectricTypeIcon
	dw MoveDexPsychicTypeIcon
	dw MoveDexIceTypeIcon
	dw MoveDexDragonTypeIcon
	dw MoveDexDarkTypeIcon
	dw MoveDexFairyTypeIcon

MoveDexSyncListSelection:
	; 详情页左右切换后，返回列表时仍定位到当前技能。
	ld a,[wd11e]
	dec a
	ld b,a ; b = 0-based move index
	ld a,[wCurrentMenuItem]
	ld c,a ; c = preferred visible row
	ld a,b
	sub c
	jr c,.useTop

	ld e,a ; candidate scroll offset
	ld a,NUM_ATTACKS - 1
	sub 7
	cp e
	jr nc,.storeCandidate

	; 靠近列表末尾时把 scroll 固定在最大值，再计算实际光标行。
	ld [wListScrollOffset],a
	ld c,a
	ld a,b
	sub c
	ld [wCurrentMenuItem],a
	ret

.storeCandidate
	ld a,e
	ld [wListScrollOffset],a
	ret

.useTop
	xor a
	ld [wListScrollOffset],a
	ld a,b
	ld [wCurrentMenuItem],a
	ret

MoveDexDrawTileLine:
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

MoveDexDividerLine:
	db $68,$69,$6b,$69,$6b,$69,$6b,$69,$6b,$6b
	db $6b,$6b,$69,$6b,$69,$6b,$69,$6b,$69,$6a,"@"

MoveDexNumberPrefixText:
	db "№.@"
MoveDexTypeLabel:
	db "Type@"
MoveDexPowerLabel:
	db "Power@"
MoveDexAccuracyLabel:
	db "Accu@"
MoveDexPPLabel:
	db "PP@"
MoveDexHighCritText:
	db "HiCrit@"

MoveDexDrawDescription:
	; MoveDex 本地说明分页，不修改全局文本引擎。
	; RPP 的 next 默认下移两行，因此说明区 y=11/13/15 天然形成
	; 三行等间距布局；每页最多三行，不再把第 4 行挤到底框上。
	call MoveDexGetDescriptionPagePointer
	jr nc,.fallback
	coord hl, 1, 11
	call PlaceString
	jp MoveDexDrawDescriptionPageArrow

.fallback
	; 尚未补正式说明的技能保持三行以内。
	coord hl, 1, 11
	ld de,MoveDexDescriptionPendingText
	call PlaceString
	ld a,[wBuffer + 1]
	call MoveDexGetEffectText
	coord hl, 1, 15
	call PlaceString
	jp MoveDexDrawDescriptionPageArrow

MoveDexFindDescriptionEntry:
	; 表格式：move ID + page-list 指针。
	; page-list 可以包含任意数量的 dw 页面指针，最后用 dw 0 结束。
	; 输出：carry=1 且 HL=page-list；不存在则 carry=0。
	ld a,[wd11e]
	ld b,a
	ld hl,MoveDexDescriptionPreviewTable
.search
	ld a,[hli]
	and a
	jr z,.notFound
	cp b
	jr z,.found
	inc hl
	inc hl
	jr .search
.found
	ld a,[hli]
	ld e,a
	ld a,[hl]
	ld h,a
	ld l,e
	scf
	ret
.notFound
	and a
	ret

MoveDexGetDescriptionPagePointer:
	; 输出：carry=1 且 DE=当前页字符串。
	call MoveDexFindDescriptionEntry
	ret nc
	ld a,[wBuffer + 6]
	add a
	ld e,a
	ld d,0
	add hl,de
	ld a,[hli]
	ld d,[hl]
	ld e,a
	ld a,d
	or e
	jr z,.none
	scf
	ret
.none
	and a
	ret

MoveDexDescriptionHasNextPage:
	; 检查 page-list 中当前页之后的指针。
	; 0 指针结尾，所以第 3、4 页以后无需额外改代码。
	call MoveDexFindDescriptionEntry
	ret nc
	ld a,[wBuffer + 6]
	inc a
	add a
	ld e,a
	ld d,0
	add hl,de
	ld a,[hli]
	or [hl]
	jr z,.no
	scf
	ret
.no
	and a
	ret

MoveDexDrawDescriptionPageArrow:
MoveDexPrepareDescriptionArrow:
	; PureRGB/Pokédex 的翻页箭头位于 (10,16)。
	; 先按 WaitForTextScrollButtonPress 的原版数值初始化闪烁计时：
	; CNT1=0、CNT2=$06。HandleDownArrowBlinkTiming 会按相同频率闪烁。
	xor a
	ld [H_DOWNARROWBLINKCNT1],a
	ld a,$06
	ld [H_DOWNARROWBLINKCNT2],a

	; 无论当前页是否为最后一页，先清掉旧箭头。
	coord hl, 10, 16
	ld a," "
	ld [hl],a

	call MoveDexDescriptionHasNextPage
	ret nc

	; 上面的查表会改写 HL，因此必须重新取得 tilemap 坐标。
	; 上一版漏掉这一步，导致 $EE 没有真正写到屏幕上。
	coord hl, 10, 16
	ld a,"▼"
	ld [hl],a
	ret

; 说明页规则：
; - 每页最多 3 行，对应 y=11/13/15，中间自然空一行。
; - 每行最多 18 字符；能放一行的内容不人为拆成两行。
; - page-list 以 dw 0 结束，可自然扩展到三页或更多。
; - RPP charmap 没有 "%"，所有概率统一使用 MoveDex 专用 $D9 百分号 tile。
MoveDexDescriptionPreviewTable:
	db POUND
	dw MoveDexDescPoundPages
	db DOUBLESLAP
	dw MoveDexDescDoubleSlapPages
	db FIRE_PUNCH
	dw MoveDexDescFirePunchPages
	db SWORDS_DANCE
	dw MoveDexDescSwordsDancePages
	db FLY
	dw MoveDexDescFlyPages
	db DRAGON_RAGE
	dw MoveDexDescDragonRagePages
	db RECOVER
	dw MoveDexDescRecoverPages
	db METRONOME
	dw MoveDexDescMetronomePages
	db METAL_CLAW
	dw MoveDexDescMetalClawPages
	db CRUNCH
	dw MoveDexDescCrunchPages
	db DARK_PULSE
	dw MoveDexDescDarkPulsePages
	db MOONBLAST
	dw MoveDexDescMoonblastPages
	db ACROBATICS
	dw MoveDexDescAcrobaticsPages
	db ICY_WIND
	dw MoveDexDescIcyWindPages
	db ELECTRO_BALL
	dw MoveDexDescElectroBallPages
	db DYNAMICPUNCH
	dw MoveDexDescDynamicPunchPages
	db HURRICANE
	dw MoveDexDescHurricanePages
	db AEROBLAST
	dw MoveDexDescAeroblastPages
	db ANCIENTPOWER
	dw MoveDexDescAncientPowerPages
	db LUSTER_PURGE
	dw MoveDexDescLusterPurgePages
	db MIND_BLAST
	dw MoveDexDescMindBlastPages
	db 0

MoveDexDescriptionPendingText:
	db   "Info pending."
	next "Battle effect:@"

; #001 Pound
MoveDexDescPoundPages:
	dw MoveDexDescPound1, MoveDexDescPound2, 0
MoveDexDescPound1:
	db   "Pounds with limbs"
	next "or a sturdy tail.@"
MoveDexDescPound2:
	db   "No added effect.@"

; #003 DoubleSlap
MoveDexDescDoubleSlapPages:
	dw MoveDexDescDoubleSlap1, MoveDexDescDoubleSlap2, 0
MoveDexDescDoubleSlap1:
	db   "Repeatedly slaps"
	next "the target.@"
MoveDexDescDoubleSlap2:
	db   "Hits 2-5 times.@"

; #007 Fire Punch
MoveDexDescFirePunchPages:
	dw MoveDexDescFirePunch1, MoveDexDescFirePunch2, 0
MoveDexDescFirePunch1:
	db   "Strikes with a"
	next "blazing fist.@"
MoveDexDescFirePunch2:
	db   "10", $d9, " chance to burn"
	next "the target.@"

MoveDexDescSwordsDancePages:
	dw MoveDexDescSwordsDance1, MoveDexDescSwordsDance2, 0
MoveDexDescSwordsDance1:
	db   "A battle dance"
	next "raises fighting"
	next "spirit.@"
MoveDexDescSwordsDance2:
	db   "Raises Attack by"
	next "2 stages.@"

MoveDexDescFlyPages:
	dw MoveDexDescFly1, MoveDexDescFly2, 0
MoveDexDescFly1:
	db   "Flies up high on"
	next "the first turn,"
	next "then attacks.@"
MoveDexDescFly2:
	db   "Attacks on turn 2."
	next "Most attacks miss"
	next "while airborne.@"

MoveDexDescDragonRagePages:
	dw MoveDexDescDragonRage1, MoveDexDescDragonRage2, 0
MoveDexDescDragonRage1:
	db   "Blasts the foe"
	next "with dragon rage.@"
MoveDexDescDragonRage2:
	db   "Always deals"
	next "40 HP damage.@"

MoveDexDescRecoverPages:
	dw MoveDexDescRecover1, MoveDexDescRecover2, 0
MoveDexDescRecover1:
	db   "Restores vitality.@"
MoveDexDescRecover2:
	db   "Restores half of"
	next "maximum HP.@"

MoveDexDescMetronomePages:
	dw MoveDexDescMetronome1, MoveDexDescMetronome2, 0
MoveDexDescMetronome1:
	db   "Waggles a finger"
	next "to trigger a move.@"
MoveDexDescMetronome2:
	db   "Uses a random"
	next "battle move.@"

MoveDexDescMetalClawPages:
	dw MoveDexDescMetalClaw1, MoveDexDescMetalClaw2, 0
MoveDexDescMetalClaw1:
	db   "Rakes with steel"
	next "claws.@"
MoveDexDescMetalClaw2:
	db   "10", $d9, " chance to"
	next "raise Attack by 1.@"

MoveDexDescCrunchPages:
	dw MoveDexDescCrunch1, MoveDexDescCrunch2, 0
MoveDexDescCrunch1:
	db   "Crunches with"
	next "sharp fangs.@"
MoveDexDescCrunch2:
	db   "33", $d9, " chance to"
	next "lower Defense by"
	next "1 stage.@"

MoveDexDescDarkPulsePages:
	dw MoveDexDescDarkPulse1, MoveDexDescDarkPulse2, 0
MoveDexDescDarkPulse1:
	db   "Releases a wave"
	next "of dark energy.@"
MoveDexDescDarkPulse2:
	db   "10", $d9, " chance to"
	next "make foe flinch.@"

MoveDexDescMoonblastPages:
	dw MoveDexDescMoonblast1, MoveDexDescMoonblast2, 0
MoveDexDescMoonblast1:
	db   "Borrows the moon's"
	next "power to attack.@"
MoveDexDescMoonblast2:
	db   "33", $d9, " chance to"
	next "lower Special by"
	next "1 stage.@"

MoveDexDescAcrobaticsPages:
	dw MoveDexDescAcrobatics1, MoveDexDescAcrobatics2, 0
MoveDexDescAcrobatics1:
	db   "A nimble aerial"
	next "strike.@"
MoveDexDescAcrobatics2:
	db   "No added effect.@"

; #207 Icy Wind
MoveDexDescIcyWindPages:
	dw MoveDexDescIcyWind1, MoveDexDescIcyWind2, 0
MoveDexDescIcyWind1:
	db   "Blasts icy wind.@"
MoveDexDescIcyWind2:
	db   "33", $d9, " chance to"
	next "lower Speed by 1.@"

; #210 Electro Ball
MoveDexDescElectroBallPages:
	dw MoveDexDescElectroBall1, MoveDexDescElectroBall2, 0
MoveDexDescElectroBall1:
	db   "Hurls an electric"
	next "orb at the foe.@"
MoveDexDescElectroBall2:
	db   "Power: 60 if slow,"
	next "80 if tied, 120"
	next "if faster.@"

; #242 DynamicPunch：三页测试，验证非最后页始终显示静态 ▼。
MoveDexDescDynamicPunchPages:
	dw MoveDexDescDynamicPunch1, MoveDexDescDynamicPunch2, MoveDexDescDynamicPunch3, 0
MoveDexDescDynamicPunch1:
	db   "Throws a powerful"
	next "spinning punch.@"
MoveDexDescDynamicPunch2:
	db   "Always confuses if"
	next "the move hits.@"
MoveDexDescDynamicPunch3:
	db   "Confusion lasts"
	next "2-5 turns.@"

MoveDexDescHurricanePages:
	dw MoveDexDescHurricane1, MoveDexDescHurricane2, 0
MoveDexDescHurricane1:
	db   "Wraps the target"
	next "in fierce wind.@"
MoveDexDescHurricane2:
	db   "10", $d9, " chance to"
	next "confuse target.@"

MoveDexDescAeroblastPages:
	dw MoveDexDescAeroblast1, MoveDexDescAeroblast2, 0
MoveDexDescAeroblast1:
	db   "Fires a focused"
	next "blast of air.@"
MoveDexDescAeroblast2:
	db   "High critical-hit"
	next "rate.@"

; #250 AncientPower
MoveDexDescAncientPowerPages:
	dw MoveDexDescAncientPower1, MoveDexDescAncientPower2, 0
MoveDexDescAncientPower1:
	db   "Attacks with an"
	next "ancient power.@"
MoveDexDescAncientPower2:
	db   "10", $d9, " chance to"
	next "raise all stats by"
	next "1 stage.@"

MoveDexDescLusterPurgePages:
	dw MoveDexDescLusterPurge1, MoveDexDescLusterPurge2, 0
MoveDexDescLusterPurge1:
	db   "Attacks with a"
	next "burst of light.@"
MoveDexDescLusterPurge2:
	db   "33", $d9, " chance to"
	next "lower Special by"
	next "1 stage.@"

MoveDexDescMindBlastPages:
	dw MoveDexDescMindBlast1, MoveDexDescMindBlast2, 0
MoveDexDescMindBlast1:
	db   "Strikes with raw"
	next "psychic force.@"
MoveDexDescMindBlast2:
	db   "Always critical."
	next "10", $d9, " chance: raise"
	next "all stats by 1.@"

MoveDexAccuracyToPercent:
	; accuracy 字段是 0-255，按 100/255 换算并按余数四舍五入。
	ld [H_MULTIPLICAND + 2],a
	xor a
	ld [H_MULTIPLICAND],a
	ld [H_MULTIPLICAND + 1],a
	ld a,100
	ld [H_MULTIPLIER],a
	call Multiply
	ld a,255
	ld [H_DIVISOR],a
	ld b,4
	call Divide
	ld a,[H_REMAINDER]
	cp 128
	ld a,[H_QUOTIENT + 3]
	ret c
	inc a
	ret

MoveDexIsHighCrit:
	ld hl,MoveDexHighCritMoves
.loop
	cp [hl]
	jr z,.yes
	inc hl
	ld b,a
	ld a,[hl]
	cp $ff
	ld a,b
	jr nz,.loop
	and a
	ret
.yes
	scf
	ret

MoveDexHighCritMoves:
	db KARATE_CHOP, RAZOR_LEAF, CRABHAMMER, SLASH, NIGHT_SLASH
	db CROSS_CHOP, PSYCHO_CUT, LEAF_BLADE, AIR_CUTTER, AEROBLAST
	; RPP 战斗核心把 Storm Throw / Mind Blast 设为必定暴击，
	; MoveDex 也显示 HiCrit，避免资料页与实际机制不一致。
	db STORM_THROW, MIND_BLAST
	db $ff

MoveDexGetTypeText:
	add a
	ld e,a
	ld d,0
	ld hl,MoveDexTypePointers
	add hl,de
	ld a,[hli]
	ld e,a
	ld d,[hl]
	ret

MoveDexTypePointers:
	dw .Normal, .Fighting, .Flying, .Poison, .Ground, .Rock, .Bird, .Bug, .Ghost, .Steel
	dw .Unknown, .Normal, .Normal, .Normal, .Normal, .Normal, .Normal, .Normal, .Normal, .Normal
	dw .Fire, .Water, .Grass, .Electric, .Psychic, .Ice, .Dragon, .Dark, .Fairy
.Normal:   db "Normal@"
.Fighting: db "Fighting@"
.Flying:   db "Flying@"
.Poison:   db "Poison@"
.Ground:   db "Ground@"
.Rock:     db "Rock@"
.Bird:     db "Bird@"
.Bug:      db "Bug@"
.Ghost:    db "Ghost@"
.Steel:    db "Steel@"
.Fire:     db "Fire@"
.Water:    db "Water@"
.Grass:    db "Grass@"
.Electric: db "Electric@"
.Psychic:  db "Psychic@"
.Ice:      db "Ice@"
.Dragon:   db "Dragon@"
.Dark:     db "Dark@"
.Fairy:    db "Fairy@"
.Unknown:  db "???@"

MoveDexGetEffectText:
	add a
	ld e,a
	ld d,0
	ld hl,MoveDexEffectPointers
	add hl,de
	ld a,[hli]
	ld e,a
	ld d,[hl]
	ret

; Compact one-line names for every effect currently defined by the engine.
; These are labels for the mechanics, not separate gameplay data.
MoveDexEffectPointers:
	dw .NoAdditional
	dw .Unused
	dw .PoisonChance
	dw .DrainHP
	dw .BurnChance
	dw .FreezeChance
	dw .ParalyzeChance
	dw .Explode
	dw .DreamEater
	dw .MirrorMove
	dw .AttackUp1
	dw .DefenseUp1
	dw .SpeedUp1
	dw .SpecialUp1
	dw .AccuracyUp1
	dw .EvasionUp1
	dw .PayDay
	dw .NeverMiss
	dw .AttackDown1
	dw .DefenseDown1
	dw .SpeedDown1
	dw .SpecialDown1
	dw .AccuracyDown1
	dw .EvasionDown1
	dw .Conversion
	dw .Haze
	dw .Bide
	dw .Thrash
	dw .SwitchTarget
	dw .MultiHit
	dw .Unused
	dw .FlinchChance
	dw .Sleep
	dw .PoisonChance
	dw .BurnChance
	dw .FreezeChance
	dw .ParalyzeChance
	dw .FlinchChance
	dw .OHKO
	dw .ChargeTurn
	dw .HalfHP
	dw .FixedDamage
	dw .TrapTarget
	dw .Fly
	dw .HitTwice
	dw .JumpKick
	dw .Mist
	dw .FocusEnergy
	dw .Recoil
	dw .Confuse
	dw .AttackUp2
	dw .DefenseUp2
	dw .SpeedUp2
	dw .SpecialUp2
	dw .AccuracyUp2
	dw .EvasionUp2
	dw .Heal
	dw .Transform
	dw .AttackDown2
	dw .DefenseDown2
	dw .SpeedDown2
	dw .SpecialDown2
	dw .AccuracyDown2
	dw .EvasionDown2
	dw .LightScreen
	dw .Reflect
	dw .Poison
	dw .Paralyze
	dw .AttackDownChance
	dw .DefenseDownChance
	dw .SpeedDownChance
	dw .SpecialDownChance
	dw .AccuracyDownChance
	dw .EvasionDownChance
	dw .Unused
	dw .Unused
	dw .ConfuseChance
	dw .Twineedle
	dw .Nuzzle
	dw .Substitute
	dw .Recharge
	dw .Rage
	dw .Mimic
	dw .Metronome
	dw .LeechSeed
	dw .Splash
	dw .Disable
	dw .FireFang
	dw .IceFang
	dw .ThunderFang
	dw .VoltTackle
	dw .PoisonFang
	dw .Growth
	dw .HoneClaws
	dw .DynamicPunch
	dw .SilverWind
	dw .AttackUpChance
	dw .AttackUpChance20
	dw .DefenseUpChance
	dw .TriAttack

.NoAdditional:      db "No Additional@"
.Unused:            db "Unused@"
.PoisonChance:      db "Poison Chance@"
.DrainHP:           db "Drain HP@"
.BurnChance:        db "Burn Chance@"
.FreezeChance:      db "Freeze Chance@"
.ParalyzeChance:    db "Paralyze Chance@"
.Explode:           db "Explode@"
.DreamEater:        db "Dream Eater@"
.MirrorMove:        db "Mirror Move@"
.AttackUp1:         db "Attack +1@"
.DefenseUp1:        db "Defense +1@"
.SpeedUp1:          db "Speed +1@"
.SpecialUp1:        db "Special +1@"
.AccuracyUp1:       db "Accuracy +1@"
.EvasionUp1:        db "Evasion +1@"
.PayDay:            db "Pay Day@"
.NeverMiss:         db "Never Miss@"
.AttackDown1:       db "Attack -1@"
.DefenseDown1:      db "Defense -1@"
.SpeedDown1:        db "Speed -1@"
.SpecialDown1:      db "Special -1@"
.AccuracyDown1:     db "Accuracy -1@"
.EvasionDown1:      db "Evasion -1@"
.Conversion:        db "Conversion@"
.Haze:              db "Haze@"
.Bide:              db "Bide@"
.Thrash:            db "Rampage@"
.SwitchTarget:      db "Switch Target@"
.MultiHit:          db "2-5 Hits@"
.FlinchChance:      db "Flinch Chance@"
.Sleep:             db "Sleep@"
.OHKO:              db "One-Hit KO@"
.ChargeTurn:        db "Charge Turn@"
.HalfHP:            db "Halve HP@"
.FixedDamage:       db "Fixed Damage@"
.TrapTarget:        db "Trap Target@"
.Fly:               db "Fly Turn@"
.HitTwice:          db "Hit Twice@"
.JumpKick:          db "Crash Recoil@"
.Mist:              db "Mist@"
.FocusEnergy:       db "Focus Energy@"
.Recoil:            db "Recoil@"
.Confuse:           db "Confuse@"
.AttackUp2:         db "Attack +2@"
.DefenseUp2:        db "Defense +2@"
.SpeedUp2:          db "Speed +2@"
.SpecialUp2:        db "Special +2@"
.AccuracyUp2:       db "Accuracy +2@"
.EvasionUp2:        db "Evasion +2@"
.Heal:              db "Heal@"
.Transform:         db "Transform@"
.AttackDown2:       db "Attack -2@"
.DefenseDown2:      db "Defense -2@"
.SpeedDown2:        db "Speed -2@"
.SpecialDown2:      db "Special -2@"
.AccuracyDown2:     db "Accuracy -2@"
.EvasionDown2:      db "Evasion -2@"
.LightScreen:       db "Light Screen@"
.Reflect:           db "Reflect@"
.Poison:            db "Poison@"
.Paralyze:          db "Paralyze@"
.AttackDownChance:  db "Atk Down Chance@"
.DefenseDownChance: db "Def Down Chance@"
.SpeedDownChance:   db "Speed Down Chance@"
.SpecialDownChance: db "Spcl Down Chance@"
.AccuracyDownChance: db "Acc Down Chance@"
.EvasionDownChance: db "Eva Down Chance@"
.ConfuseChance:     db "Confuse Chance@"
.Twineedle:         db "2 Hits + Poison@"
.Nuzzle:            db "Paralyze Target@"
.Substitute:        db "Substitute@"
.Recharge:          db "Recharge Next@"
.Rage:              db "Rage@"
.Mimic:             db "Mimic@"
.Metronome:         db "Metronome@"
.LeechSeed:         db "Leech Seed@"
.Splash:            db "No Effect@"
.Disable:           db "Disable@"
.FireFang:          db "Fire Fang Effect@"
.IceFang:           db "Ice Fang Effect@"
.ThunderFang:       db "Thunder Fang Eff.@"
.VoltTackle:        db "Volt Tackle Eff.@"
.PoisonFang:        db "Poison Fang Eff.@"
.Growth:            db "Growth@"
.HoneClaws:         db "Hone Claws@"
.DynamicPunch:      db "DynamicPunch Eff.@"
.SilverWind:        db "Silver Wind Eff.@"
.AttackUpChance:    db "Attack Up Chance@"
.AttackUpChance20:  db "Attack Up 20 pct@"
.DefenseUpChance:   db "Defense Up Chance@"
.TriAttack:         db "Tri Attack Effect@"
; MoveDex 第一阶段 UI 图形。
; 基础 UI 与初代类型图标来自 PureRGB 的 MoveDex 设计；Steel/Dark/Fairy 为 RPP 扩展类型补充图标。
MoveDexUI:
	INCBIN "gfx/movedex/movedex_ui.1bpp"
MoveDexUIEnd:

MoveDexNormalTypeIcon:   INCBIN "gfx/movedex/type_icons/normal.2bpp"
MoveDexFightingTypeIcon: INCBIN "gfx/movedex/type_icons/fighting.2bpp"
MoveDexFlyingTypeIcon:   INCBIN "gfx/movedex/type_icons/flying.2bpp"
MoveDexPoisonTypeIcon:   INCBIN "gfx/movedex/type_icons/poison.2bpp"
MoveDexGroundTypeIcon:   INCBIN "gfx/movedex/type_icons/ground.2bpp"
MoveDexRockTypeIcon:     INCBIN "gfx/movedex/type_icons/rock.2bpp"
MoveDexTypelessIcon:     INCBIN "gfx/movedex/type_icons/typeless.2bpp"
MoveDexBugTypeIcon:      INCBIN "gfx/movedex/type_icons/bug.2bpp"
MoveDexGhostTypeIcon:    INCBIN "gfx/movedex/type_icons/ghost.2bpp"
MoveDexSteelTypeIcon:    INCBIN "gfx/movedex/type_icons/steel.2bpp"
MoveDexFireTypeIcon:     INCBIN "gfx/movedex/type_icons/fire.2bpp"
MoveDexWaterTypeIcon:    INCBIN "gfx/movedex/type_icons/water.2bpp"
MoveDexGrassTypeIcon:    INCBIN "gfx/movedex/type_icons/grass.2bpp"
MoveDexElectricTypeIcon: INCBIN "gfx/movedex/type_icons/electric.2bpp"
MoveDexPsychicTypeIcon:  INCBIN "gfx/movedex/type_icons/psychic_gbc.2bpp"
MoveDexIceTypeIcon:      INCBIN "gfx/movedex/type_icons/ice.2bpp"
MoveDexDragonTypeIcon:   INCBIN "gfx/movedex/type_icons/dragon.2bpp"
MoveDexDarkTypeIcon:     INCBIN "gfx/movedex/type_icons/dark.2bpp"
MoveDexFairyTypeIcon:    INCBIN "gfx/movedex/type_icons/fairy.2bpp"
