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
	ld b, SET_PAL_GENERIC
	call RunPaletteCommand
	call MoveDexDrawDataFrame

	coord hl, 2, 1
	ld de,MoveDexTitleText
	call PlaceString
	coord hl, 12, 1
	ld de,MoveDexNoText
	call PlaceString
	coord hl, 15, 1
	ld de,wd11e
	lb bc, LEADING_ZEROES | 1, 3
	call PrintNumber

	call GetMoveName
	coord hl, 2, 3
	call PlaceString

	call MoveDexLoadMoveData

	coord hl, 2, 5
	ld de,MoveDexEffectLabel
	call PlaceString
	ld a,[wBuffer + 1]
	call MoveDexGetEffectText
	coord hl, 2, 6
	call PlaceString

	coord hl, 2, 8
	ld de,MoveDexTypeLabel
	call PlaceString
	ld a,[wBuffer + 3]
	call MoveDexGetTypeText
	coord hl, 11, 8
	call PlaceString

	coord hl, 2, 10
	ld de,MoveDexPowerLabel
	call PlaceString
	coord hl, 14, 10
	ld de,wBuffer + 2
	lb bc, 1, 3
	call PrintNumber

	coord hl, 2, 12
	ld de,MoveDexAccuracyLabel
	call PlaceString
	ld a,[wBuffer + 4]
	call MoveDexAccuracyToPercent
	ld [wBuffer],a
	coord hl, 11, 12
	ld de,wBuffer
	lb bc, 1, 3
	call PrintNumber
	ld de,MoveDexOutOf100Text
	call PlaceString

	coord hl, 2, 14
	ld de,MoveDexPPLabel
	call PlaceString
	coord hl, 14, 14
	ld de,wBuffer + 5
	lb bc, 1, 3
	call PrintNumber

	coord hl, 2, 16
	ld de,MoveDexCritLabel
	call PlaceString
	ld a,[wd11e]
	call MoveDexIsHighCrit
	ld de,MoveDexNoValue
	jr nc,.critTextReady
	ld de,MoveDexYesValue
.critTextReady
	coord hl, 14, 16
	call PlaceString

	ld a,1
	ld [H_AUTOBGTRANSFERENABLED],a
	call Delay3
	call GBPalNormal
.waitForButton
	call JoypadLowSensitivity
	ld a,[hJoy5]
	and A_BUTTON | B_BUTTON
	jr z,.waitForButton
	call GBPalWhiteOut
	call ClearScreen
	ret

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
	coord hl, 0, 4
	ld de,MoveDexDividerLine
	call PlaceString
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

MoveDexTitleText:
	db "MoveDex@"
MoveDexNoText:
	db "No.@"
MoveDexEffectLabel:
	db "Effect@"
MoveDexTypeLabel:
	db "Type@"
MoveDexPowerLabel:
	db "Power@"
MoveDexAccuracyLabel:
	db "Accuracy@"
MoveDexPPLabel:
	db "PP@"
MoveDexCritLabel:
	db "Crit@"
MoveDexOutOf100Text:
	db "/100@"
MoveDexYesValue:
	db "Yes@"
MoveDexNoValue:
	db "No@"

MoveDexAccuracyToPercent:
	ld hl,MoveDexAccuracyTable
.loop
	cp [hl]
	jr z,.found
	inc hl
	inc hl
	jr .loop
.found
	inc hl
	ld a,[hl]
	ret

MoveDexAccuracyTable:
	db 30 percent, 30
	db 50 percent, 50
	db 55 percent, 55
	db 60 percent, 60
	db 70 percent, 70
	db 75 percent, 75
	db 80 percent, 80
	db 85 percent, 85
	db 90 percent, 90
	db 95 percent, 95
	db 100 percent, 100

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
