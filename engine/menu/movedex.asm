; MoveDex
; Seen / Use v1：参考 Pokédex 的 Seen / Own 层级重新实现。
; Seen 表示任意一方在实战中真正执行过该技能；Use 表示玩家方执行过，且 Use 必然同时 Seen。
; 未 Seen 条目显示虚线，Use 条目显示 Poké Ball；列表上限由最高 Seen 技能动态决定。

ShowMoveDexMenu:
	call GBPalWhiteOut
	call ClearScreen
	call UpdateSprites
	; 旧存档中的这段空间过去是 unused。magic/version 不匹配时从 0 开始建立新的 Seen/Use。
	call MoveDexEnsureStateInitialized
	call MoveDexFindMaxSeenMove
	ld a,[wListScrollOffset]
	push af
	; 默认打开时直接定位到最低编号的 Seen 技能，并把它放在列表第一行。
	; 如果一个技能都没见过，则继续保留原来的 #001 虚线占位。
	call MoveDexFindMinSeenMove
	and a
	jr z,.openAtFirstMove
	ld [wd11e],a
	dec a
	ld [wListScrollOffset],a
	xor a
	ld [wCurrentMenuItem],a
	ld [wLastMenuItem],a
	inc a
	ld [hJoy7],a
	jp .setUpGraphics ; Info 返回后重新加载列表图块与静态界面
.openAtFirstMove
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
	; 末页不足 7 项时同步缩小菜单行数；完全没有 Seen 时保留 #001 虚线占位。
	call MoveDexGetVisibleListCount
	ld d,a
	dec a
	ld [wMaxMenuItem],a
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
	; Use 对应 Pokédex 的 Own：在技能名前显示同一枚 Poké Ball tile。
	push hl
	ld a,[wd11e]
	ld hl,wMoveDexUsed
	call MoveDexTestMoveFlag
	pop hl
	ld a," "
	jr z,.writeUseMarker
	ld a,$72
.writeUseMarker
	ld [hl],a

	; Seen 对应 Pokédex 的 Seen：未见技能只公开编号，名字显示 12 格虚线。
	push hl
	ld a,[wd11e]
	ld hl,wMoveDexSeen
	call MoveDexTestMoveFlag
	pop hl
	ld de,.dashedMoveName
	jr z,.placeMoveName
	call GetMoveName
.placeMoveName
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
	jr .listDrawDone

.dashedMoveName
	db "------------@"
.listDrawDone

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
	; Up: scroll one row. A fresh UP at the first entry wraps to the highest Seen move.
	ld a,[wMoveDexMaxSeenMove]
	and a
	jp z,.stopAtVerticalBoundary
	ld a,[wListScrollOffset]
	and a
	jr nz,.scrollUpOne
	ld a,[hJoyPressed]
	bit 6,a
	jp z,.stopAtVerticalBoundary
	ld a,[wMoveDexMaxSeenMove]
	cp 7
	jr c,.wrapUpOnFirstPage
	sub 7
	ld [wListScrollOffset],a
	ld a,6
	ld [wCurrentMenuItem],a
	jp .loopAfterBoundaryWrap
.wrapUpOnFirstPage
	xor a
	ld [wListScrollOffset],a
	ld a,[wMoveDexMaxSeenMove]
	dec a
	ld [wCurrentMenuItem],a
	jp .loopAfterBoundaryWrap
.scrollUpOne
	dec a
	ld [wListScrollOffset],a
	jp .loop

.checkDown
	bit 7,a
	jr z,.checkRight
	; Down: scroll one row. A fresh DOWN at the dynamic highest Seen entry wraps to move 001.
	ld a,[wMoveDexMaxSeenMove]
	and a
	jp z,.stopAtVerticalBoundary
	call MoveDexGetSelectedMove
	ld b,a
	ld a,[wMoveDexMaxSeenMove]
	cp b
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
	; Right 的语义仍是“当前选中技能 +7”，只是合法末端改成动态最高 Seen 技能。
	; 仍然通过 MoveDexSyncListSelection 同步，绝不退回直接修改 scroll offset。
	ld a,[wMoveDexMaxSeenMove]
	and a
	jp z,.loop
	call MoveDexGetSelectedMove
	ld b,a
	ld a,[wMoveDexMaxSeenMove]
	sub b
	cp 7
	jr c,.rightClampToLast
	ld a,b
	add 7
	jr .storeRightTarget
.rightClampToLast
	ld a,[wMoveDexMaxSeenMove]
.storeRightTarget
	ld [wd11e],a
	call MoveDexSyncListSelection
	jp .loop

.checkLeft
	bit 5,a
	jr z,.checkA
	; Left 同样按“当前选中技能 -7”计算。小于 #008 时只 clamp 到 #001。
	ld a,[wMoveDexMaxSeenMove]
	and a
	jp z,.loop
	call MoveDexGetSelectedMove
	cp 8
	jr c,.leftClampToFirst
	sub 7
	jr .storeLeftTarget
.leftClampToFirst
	ld a,1
.storeLeftTarget
	ld [wd11e],a
	call MoveDexSyncListSelection
	jp .loop

.checkA
	bit 0,a
	jp z,.loop
	; 与 Pokédex 一样，未 Seen 的虚线条目不能进入右侧功能菜单。
	call MoveDexGetSelectedMove
	ld hl,wMoveDexSeen
	call MoveDexTestMoveFlag
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

; ---------------------------------------------------------------------------
; MoveDex Seen / Use v1 状态辅助
; ---------------------------------------------------------------------------

MoveDexEnsureStateInitialized:
	; "MDX" + version 1。旧存档原本把这片区域当 unused，因此只有 magic/version
	; 全部匹配时才信任 bitfield；否则清零后从当前游戏进度重新记录。
	ld a,[wMoveDexStateMagic0]
	cp $4d ; M
	jr nz,.reset
	ld a,[wMoveDexStateMagic1]
	cp $44 ; D
	jr nz,.reset
	ld a,[wMoveDexStateMagic2]
	cp $58 ; X
	jr nz,.reset
	ld a,[wMoveDexStateVersion]
	cp 1
	ret z
.reset
	ld hl,wMoveDexStateMagic0
	ld bc,wMoveDexStateEnd - wMoveDexStateMagic0
	xor a
	call FillMemory
	ld a,$4d
	ld [wMoveDexStateMagic0],a
	ld a,$44
	ld [wMoveDexStateMagic1],a
	ld a,$58
	ld [wMoveDexStateMagic2],a
	ld a,1
	ld [wMoveDexStateVersion],a
	ret

MoveDexFindMinSeenMove:
	; OUTPUT: A = 0（一个都没见过）或最低编号的 Seen 技能 ID。
	ld a,1
.loop
	ld b,a
	ld hl,wMoveDexSeen
	call MoveDexTestMoveFlag
	jr nz,.found
	ld a,b
	cp NUM_ATTACKS - 1
	jr z,.noneSeen
	inc a
	jr .loop
.found
	ld a,b
	ret
.noneSeen
	xor a
	ret

MoveDexFindMaxSeenMove:
	; OUTPUT: wMoveDexMaxSeenMove = 0（一个都没见过）或最高 Seen 技能 ID。
	ld a,NUM_ATTACKS - 1
.loop
	ld b,a
	ld hl,wMoveDexSeen
	call MoveDexTestMoveFlag
	jr nz,.found
	ld a,b
	dec a
	jr nz,.loop
	xor a
	ld [wMoveDexMaxSeenMove],a
	ret
.found
	ld a,b
	ld [wMoveDexMaxSeenMove],a
	ret

MoveDexGetVisibleListCount:
	; OUTPUT: A = 当前 scroll offset 下应绘制的行数（1..7）。
	; 完全没有 Seen 时仍保留 #001 虚线占位，因此返回 1。
	ld a,[wMoveDexMaxSeenMove]
	and a
	jr nz,.hasSeen
	inc a
	ret
.hasSeen
	ld b,a
	ld a,[wListScrollOffset]
	ld c,a
	ld a,b
	sub c
	cp 7
	ret c
	ld a,7
	ret

MoveDexRecordPlayerMove:
	; 与 Pokédex 一致：Link Battle / Test Battle 不写入正式收集数据。
	ld a,[wLinkState]
	cp LINK_STATE_BATTLING
	ret z
	ld a,[wFlags_D733]
	bit BIT_TEST_BATTLE,a
	ret nz
	; 玩家真正进入技能执行流程：Use + Seen。
	call MoveDexEnsureStateInitialized
	; wPlayerMoveNum 是 Moves 表第 1 byte 的兼容动画 ID；
	; 扩展技能必须按真实 selected move ID 记录。
	ld a,[wPlayerSelectedMove]
	push af
	ld hl,wMoveDexSeen
	call MoveDexSetMoveFlag
	pop af
	ld hl,wMoveDexUsed
	jp MoveDexSetMoveFlag

MoveDexRecordEnemyMove:
	; Link Battle / Test Battle 同样不记录敌方技能。
	ld a,[wLinkState]
	cp LINK_STATE_BATTLING
	ret z
	ld a,[wFlags_D733]
	bit BIT_TEST_BATTLE,a
	ret nz
	; 敌方真正进入技能执行流程：只 Seen。
	call MoveDexEnsureStateInitialized
	; 敌方同样使用真实技能 ID，避免 Gunk Shot 等被记成兼容动画技能。
	ld a,[wEnemySelectedMove]
	ld hl,wMoveDexSeen
	jp MoveDexSetMoveFlag

MoveDexIsCurrentMoveUsed:
	ld a,[wd11e]
	ld hl,wMoveDexUsed
	jp MoveDexTestMoveFlag

MoveDexFindPreviousSeenMove:
	; INPUT: A = 当前技能 ID
	; OUTPUT: carry set + A = 前一个 Seen；没有则 carry clear。
	cp 1
	jr z,.none
.loop
	dec a
	ld b,a
	ld hl,wMoveDexSeen
	call MoveDexTestMoveFlag
	ld a,b
	jr nz,.found
	cp 1
	jr nz,.loop
.none
	and a
	ret
.found
	scf
	ret

MoveDexFindNextSeenMove:
	; INPUT: A = 当前技能 ID
	; OUTPUT: carry set + A = 后一个 Seen；没有则 carry clear。
.loop
	inc a
	ld b,a
	ld a,[wMoveDexMaxSeenMove]
	cp b
	jr c,.none
	ld a,b
	ld hl,wMoveDexSeen
	call MoveDexTestMoveFlag
	ld a,b
	jr z,.loop
	scf
	ret
.none
	ld a,b
	and a
	ret

MoveDexSetMoveFlag:
	; INPUT: A = move ID (1..253), HL = 32-byte bitfield。
	; 非法/0 move（例如某些战斗内部占位）直接忽略。
	and a
	ret z
	cp NUM_ATTACKS
	ret nc
	push bc
	push de
	push hl
	dec a
	ld c,a
	and 7
	ld e,a
	ld a,c
	srl a
	srl a
	srl a
	ld c,a
	ld b,0
	add hl,bc
	ld a,e
	and a
	ld a,1
	jr z,.shifted
.shift
	sla a
	dec e
	jr nz,.shift
.shifted
	or [hl]
	ld [hl],a
	pop hl
	pop de
	pop bc
	ret

MoveDexTestMoveFlag:
	; INPUT: A = move ID (1..253), HL = bitfield。
	; OUTPUT: Z set = 未记录，Z clear = 已记录。BC/DE/HL 保持。
	and a
	jr z,.notSet
	cp NUM_ATTACKS
	jr nc,.notSet
	push bc
	push de
	push hl
	dec a
	ld c,a
	and 7
	ld e,a
	ld a,c
	srl a
	srl a
	srl a
	ld c,a
	ld b,0
	add hl,bc
	ld a,e
	and a
	ld a,1
	jr z,.shifted
.shift
	sla a
	dec e
	jr nz,.shift
.shifted
	and [hl]
	pop hl
	pop de
	pop bc
	and a
	ret
.notSet
	xor a
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

	; Seen / Use 直接统计两个 32-byte bitfield，显示方式与 Pokédex Seen / Own 一致。
	ld hl,wMoveDexSeen
	ld b,wMoveDexSeenEnd - wMoveDexSeen
	call CountSetBits
	coord hl, 16, 2
	ld de,MoveDexSeenText
	call PlaceString
	coord hl, 16, 3
	ld de,wNumSetBits
	lb bc, 1, 3
	call PrintNumber

	ld hl,wMoveDexUsed
	ld b,wMoveDexUsedEnd - wMoveDexUsed
	call CountSetBits
	coord hl, 16, 5
	ld de,MoveDexUseText
	call PlaceString
	coord hl, 16, 6
	ld de,wNumSetBits
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
	; 保险检查：即使未来别的入口直接调用右侧菜单，未 Seen 条目仍不能公开资料。
	ld hl,wMoveDexSeen
	call MoveDexTestMoveFlag
	ld b,2
	jr z,.exitSideMenu

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
	ld a,[hDownArrowBlinkActive]
	push af
	ld a,[hDownArrowBlinkTimer]
	push af
	call MoveDexDrawMoveData

	ld a,1
	ld [H_AUTOBGTRANSFERENABLED],a
	call Delay3
	call GBPalNormal

.inputLoop
	; 闪烁计时由 HandleDownArrowBlinkTiming 按 VBlank 统一推进。
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
	ld [hDownArrowBlinkTimer],a
	pop af
	ld [hDownArrowBlinkActive],a

	; 如果在详情页用左右切换过技能，返回列表时同步选中位置。
	call MoveDexSyncListSelection
	call GBPalWhiteOut
	; 详情页临时占用了字体区 $C0-$D9，白屏期间恢复这些字体图块，
	; 避免离开 MoveDex 后留下潜在的共享 VRAM 图块污染。
	call MoveDexRestoreFontTiles
	call ClearScreen
	ret

.previousMove
	; 详情页只在 Seen 技能之间移动，避免左右键泄露虚线条目的名字/资料。
	ld a,[wd11e]
	call MoveDexFindPreviousSeenMove
	jp nc,.inputLoop
	ld [wd11e],a
	jr .redrawMove

.nextMove
	ld a,[wd11e]
	call MoveDexFindNextSeenMove
	jp nc,.inputLoop
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

	; 数值和单位都属于动态资料。Seen-only 时先显示与字段实际宽度一致的 ? 占位，
	; Use 解锁后再直接绘制真实数值；Accuracy 的 % 也只在解锁后出现。
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

	; Use 对应 Pokédex 的 Own：Seen-only 只公开身份层（名字/编号/类型/分类），
	; Power / PP / Accuracy / HiCrit / 完整说明在玩家实际使用过后解锁。
	call MoveDexIsCurrentMoveUsed
	jr nz,.drawUnlockedData
	; 参考 Pokédex 的未 Own 资料：标签继续显示，但未知数值按各字段
	; 实际占用宽度显示 ?。Power / Accuracy 为 3 格，PP 为 2 格。
	coord hl, 7, 6
	ld de,MoveDexUnknown3Text
	call PlaceString
	coord hl, 16, 6
	ld de,MoveDexUnknown2Text
	call PlaceString
	coord hl, 7, 8
	ld de,MoveDexUnknown3Text
	call PlaceString

	; Seen-only 不绘制说明，因此必须显式关闭说明页下箭头。
	; 否则输入循环会继续调用 HandleDownArrowBlinkTiming，可能继承进入详情前
	; 的全局闪烁状态，在隐藏资料时错误显示“还有下一页”的光标。
	call MoveDexPrepareDescriptionArrow
	jp .drawNavigationOnly

.drawUnlockedData
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
	; RPP charmap 没有普通 % 字符；$D9 是 MoveDex 专用百分号 tile。
	; 百分号属于已解锁资料，避免 Seen-only 时单独留下一个 %。
	ld a,$d9
	Coorda 10, 8

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

.drawNavigationOnly
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
	; Accuracy 数字占 x=7..9，解锁后 % 位于 x=10；切到 Seen-only
	; 条目时四格必须一起清掉，不能留下上一招的百分号。
	lb bc, 1, 4
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
	call MoveDexFindPreviousSeenMove
	jr nc,.noPrevious
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
	call MoveDexFindNextSeenMove
	jr nc,.noNext
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
	; a = type ID。专用表按 type ID 直接索引，只保存中间两色；
	; LoadMoveDexTypePalette 会像 Pokémon palette 一样自动补白色/黑色。
	ld d,a
	ld e,2
	callba LoadMoveDexTypePalette

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
MoveDexUnknown2Text:
	db "??@"
MoveDexUnknown3Text:
	db "???@"

MoveDexDrawDescription:
	; MoveDex 本地说明分页，不修改全局文本引擎。
	; RPP 的 next 默认下移两行，因此说明区 y=11/13/15 天然形成
	; 三行等间距布局；每页最多三行，不再把第 4 行挤到底框上。
	call MoveDexGetDescriptionPagePointer
	jr nc,.fallback
	coord hl, 1, 11
	call MoveDexPlaceStringFar
	jp MoveDexDrawDescriptionPageArrow

.fallback
	; 253 项当前都有正式说明；保留单行兜底，方便未来新增技能时显式暴露缺项。
	coord hl, 1, 11
	ld de,MoveDexDescriptionPendingText
	call PlaceString
	jp MoveDexDrawDescriptionPageArrow

MoveDexFindDescriptionEntry:
	; 253 项固定索引表，每项为 bank + page-list 指针，共 3 bytes。
	; 表和说明正文都放在扩展 bank，避免继续占用接近满载的 $35。
	; 输出：carry=1、A=page-list bank、HL=page-list；无说明则 carry=0。
	ld a,[wd11e]
	dec a
	ld e,a
	ld d,0
	ld hl,MoveDexDescriptionPointerTable
	add hl,de
	add hl,de
	add hl,de
	ld de,wBuffer + 7
	ld bc,3
	ld a,BANK(MoveDexDescriptionPointerTable)
	call FarCopyData
	ld a,[wBuffer + 7]
	and a
	jr z,.notFound
	ld b,a
	ld a,[wBuffer + 8]
	ld l,a
	ld a,[wBuffer + 9]
	ld h,a
	ld a,b
	scf
	ret
.notFound
	and a
	ret

MoveDexGetDescriptionPagePointer:
	; 输出：carry=1、A=当前说明 bank、DE=当前页字符串。
	call MoveDexFindDescriptionEntry
	ret nc
	ld a,[wBuffer + 6]
	add a
	ld e,a
	ld d,0
	add hl,de
	ld de,wBuffer + 10
	ld bc,2
	ld a,[wBuffer + 7]
	call FarCopyData
	ld a,[wBuffer + 10]
	ld e,a
	ld a,[wBuffer + 11]
	ld d,a
	or e
	jr z,.none
	ld a,[wBuffer + 7]
	scf
	ret
.none
	and a
	ret

MoveDexDescriptionHasNextPage:
	; Seen-only 条目不显示说明页，也不显示/推进分页箭头。
	call MoveDexIsCurrentMoveUsed
	jr nz,.used
	and a ; carry clear
	ret
.used
	; 下一页指针也从对应说明 bank 读取；0 指针仍表示 page-list 结束。
	call MoveDexFindDescriptionEntry
	ret nc
	ld a,[wBuffer + 6]
	inc a
	add a
	ld e,a
	ld d,0
	add hl,de
	ld de,wBuffer + 10
	ld bc,2
	ld a,[wBuffer + 7]
	call FarCopyData
	ld a,[wBuffer + 10]
	ld e,a
	ld a,[wBuffer + 11]
	or e
	jr z,.no
	scf
	ret
.no
	and a
	ret

MoveDexDrawDescriptionPageArrow:
MoveDexPrepareDescriptionArrow:
	; PureRGB/Pokédex 的翻页箭头位于 (10,16)。
	; 使用全局帧间隔初始化闪烁计时；所有下箭头界面共用同一频率。
	xor a
	ld [hDownArrowBlinkActive],a
	ld a,DOWN_ARROW_BLINK_INTERVAL_FRAMES
	ld [hDownArrowBlinkTimer],a

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
; 正式说明数据已移到 data/movedex_descriptions.asm。
; $35 只保留 UI/控制代码，说明表通过 FarCopyData 从扩展 bank 读取。

MoveDexDescriptionPendingText:
	db "Info pending.@"

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
	; 与战斗核心共用宏定义：普通高暴击 + 必定暴击都显示 HiCrit。
	db_high_critical_moves
	db_always_critical_moves
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
