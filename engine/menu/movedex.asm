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
	ld [hli],a ; seven visible entries
	ld [hl],D_LEFT | D_RIGHT | B_BUTTON | A_BUTTON

.redrawScreen
	xor a
	ld [H_AUTOBGTRANSFERENABLED],a
	call ClearScreen
	ld b, SET_PAL_GENERIC
	call RunPaletteCommand
	callab LoadPokedexTilePatterns
	call MoveDexDrawStaticListUI
	jr .loop

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
	call PlaceString

	ld bc,2 * SCREEN_WIDTH
	add hl,bc
	pop de
	pop af
	ld [wd11e],a
	dec d
	jr nz,.printMoveLoop

	; Refresh the selected absolute move number on the right panel.
	call MoveDexGetSelectedMove
	ld [wd11e],a
	coord hl, 16, 6
	ld de,wd11e
	lb bc, LEADING_ZEROES | 1, 3
	call PrintNumber

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
	call MoveDexGetSelectedMove
	ld [wd11e],a
	call ShowMoveDexData
	jp .redrawScreen

.buttonBPressed
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

MoveDexDrawStaticListUI:
	; Same split-panel construction used by the Pokédex list.
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
	coord hl, 15, 2
	ld de,MoveDexMovesText
	call PlaceString
	ld a,NUM_ATTACKS - 1
	ld [wBuffer],a
	coord hl, 16, 3
	ld de,wBuffer
	lb bc, 1, 3
	call PrintNumber
	coord hl, 16, 5
	ld de,MoveDexNumberText
	call PlaceString
	coord hl, 15, 10
	ld de,MoveDexInfoText
	call PlaceString
	coord hl, 15, 12
	ld de,MoveDexQuitText
	call PlaceString
	ret

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

MoveDexContentsText:
	db "MoveDex@"
MoveDexMovesText:
	db "Moves@"
MoveDexNumberText:
	db "No.@"
MoveDexInfoText:
	db "Info@"
MoveDexQuitText:
	db "Quit@"

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
	call MoveDexDrawMoveData

	ld a,1
	ld [H_AUTOBGTRANSFERENABLED],a
	call Delay3
	call GBPalNormal

.inputLoop
	call JoypadLowSensitivity
	ld a,[hJoy5]
	bit 5,a
	jr nz,.previousMove
	bit 4,a
	jr nz,.nextMove
	and A_BUTTON | B_BUTTON
	jr z,.inputLoop

.close
	; 如果在详情页用左右切换过技能，返回列表时同步选中位置。
	call MoveDexSyncListSelection
	call GBPalWhiteOut
	; 详情页临时占用了字体区 $C0-$D8，白屏期间恢复这些字体图块，
	; 避免离开 MoveDex 后留下潜在的共享 VRAM 图块污染。
	call MoveDexRestoreFontTiles
	call ClearScreen
	ret

.previousMove
	ld a,[wd11e]
	cp 1
	jr z,.inputLoop
	dec a
	ld [wd11e],a
	jr .redrawMove

.nextMove
	ld a,[wd11e]
	cp NUM_ATTACKS - 1
	jr z,.inputLoop
	inc a
	ld [wd11e],a

.redrawMove
	xor a
	ld [H_AUTOBGTRANSFERENABLED],a
	call MoveDexClearDynamicData
	call MoveDexDrawMoveData
	ld a,1
	ld [H_AUTOBGTRANSFERENABLED],a
	call Delay3
	jr .inputLoop

MoveDexLoadDataUITiles:
	; PureRGB 的 <PREV/NEXT> 与分类标识图块。
	; 1bpp 图块复制到 $C4-$D8，不覆盖当前 MoveDex/Pokédex 边框图块。
	ld de,MoveDexUI
	ld hl,vChars1 + $440
	lb bc, BANK(MoveDexUI), (MoveDexUIEnd - MoveDexUI) / $8
	jp CopyVideoDataDouble

MoveDexRestoreFontTiles:
	; $C0-$D8 共 25 个 tile，对应 FontGraphics 中从第 $40 个字符开始的区域。
	ld de,FontGraphics + $200
	ld hl,vChars1 + $400
	lb bc, BANK(FontGraphics), $19
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

	coord hl, 13, 1
	ld de,MoveDexNoText
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
	coord hl, 13, 8
	ld de,MoveDexPercentText
	call PlaceString
	coord hl, 1, 11
	ld de,MoveDexEffectLabel
	call PlaceString
	coord hl, 1, 14
	ld de,MoveDexCritLabel
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
	ret

MoveDexDrawMoveData:
	call MoveDexLoadMoveData

	; 技能名称与编号。
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

	; Accuracy：不再依赖固定查表，直接把 0-255 精度换算为百分比。
	ld a,[wBuffer + 4]
	call MoveDexAccuracyToPercent
	ld [wBuffer],a
	coord hl, 10, 8
	ld de,wBuffer
	lb bc, 1, 3
	call PrintNumber

	; 保留 RPP 当前 MoveDex 的 Effect 与 High Crit 信息。
	ld a,[wBuffer + 1]
	call MoveDexGetEffectText
	coord hl, 1, 12
	call PlaceString

	ld a,[wd11e]
	call MoveDexIsHighCrit
	ld de,MoveDexNoValue
	jr nc,.critTextReady
	ld de,MoveDexYesValue
.critTextReady
	coord hl, 12, 14
	call PlaceString

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
	coord hl, 10, 8
	lb bc, 1, 3
	call ClearScreenArea
	coord hl, 1, 12
	lb bc, 1, 17
	call ClearScreenArea
	coord hl, 12, 14
	lb bc, 1, 3
	call ClearScreenArea
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

MoveDexNoText:
	db "No.@"
MoveDexTypeLabel:
	db "Type@"
MoveDexPowerLabel:
	db "Power@"
MoveDexAccuracyLabel:
	db "Accuracy@"
MoveDexPPLabel:
	db "PP@"
MoveDexEffectLabel:
	db "Effect@"
MoveDexCritLabel:
	db "High Crit@"
MoveDexPercentText:
	db "%@"
MoveDexYesValue:
	db "Yes@"
MoveDexNoValue:
	db "No@"

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
