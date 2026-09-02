DrawHP:
; Draws the HP bar in the stats screen
	call GetPredefRegisters
	ld a, $1
	jr DrawHP_

DrawHP2:
; Draws the HP bar in the party screen
	call GetPredefRegisters
	ld a, $2

DrawHP_:
	ld [wHPBarType], a
	push hl
	ld a, [wLoadedMonHP]
	ld b, a
	ld a, [wLoadedMonHP + 1]
	ld c, a
	or b
	jr nz, .nonzeroHP
	xor a
	ld c, a
	ld e, a
	ld a, $6
	ld d, a
	jp .drawHPBarAndPrintFraction
.nonzeroHP
	ld a, [wLoadedMonMaxHP]
	ld d, a
	ld a, [wLoadedMonMaxHP + 1]
	ld e, a
	predef HPBarLength
	ld a, $6
	ld d, a
	ld c, a
.drawHPBarAndPrintFraction
	pop hl
	push de
	push hl
	push hl
	call DrawHPBar
	pop hl
	ld a, [hFlags_0xFFF6]
	bit 0, a
	jr z, .printFractionBelowBar
	ld bc, $9 ; right of bar
	jr .printFraction
.printFractionBelowBar
	ld bc, SCREEN_WIDTH + 1 ; below bar
.printFraction
	add hl, bc
	ld de, wLoadedMonHP
	lb bc, 2, 3
	call PrintNumber
	ld a, "/"
	ld [hli], a
	ld de, wLoadedMonMaxHP
	lb bc, 2, 3
	call PrintNumber
	pop hl
	pop de
	ret


; Predef 0x37
StatusScreen:
	; Gold/Silver-style summary state: page changes and Pokémon changes are
	; separate operations. This first version only exposes page navigation; the
	; same state will later be retained when UP/DOWN Pokémon switching is added.
	ld a, $1
	ld [wStatusScreenPage], a
	call LoadMonData
	ld a, [wMonDataLocation]
	cp BOX_DATA
	jr c, .DontRecalculate
; mon is in a box or daycare
	ld a, [wLoadedMonBoxLevel]
	ld [wLoadedMonLevel], a
	ld [wCurEnemyLVL], a
	ld hl, wLoadedMonHPExp - 1
	ld de, wLoadedMonStats
	ld b, $1
	call CalcStats ; Recalculate stats
.DontRecalculate
	ld hl, wd72c
	set 1, [hl]
	; Do not step NR50 down while Music Off is active. Silent routed DACs
	; make that direct master-volume change audible as a click.
	ld a, [wOptions]
	bit 5, a
	jr nz, .skipEntryVolumeReduction
	ld a, [wBGMVolume]
	cp $a0 ; BGM Volume 0 is also effectively muted
	jr z, .skipEntryVolumeReduction
	ld a, $33
	ld [rNR50], a ; Reduce the volume
.skipEntryVolumeReduction
	call GBPalWhiteOutWithDelay3
	call ClearScreen
	call UpdateSprites
	call LoadHpBarAndStatusTilePatterns
	ld de, BattleHudTiles1  ; source
	ld hl, vChars2 + $6d0 ; dest
	lb bc, BANK(BattleHudTiles1), $03
	call CopyVideoDataDouble ; ·│ :L and halfarrow line end
	ld de, BattleHudTiles2
	ld hl, vChars2 + $780
	lb bc, BANK(BattleHudTiles2), $01
	call CopyVideoDataDouble ; │
	ld de, BattleHudTiles3
	ld hl, vChars2 + $760
	lb bc, BANK(BattleHudTiles3), $02
	call CopyVideoDataDouble ; ─┘
	ld de, PTile
	ld hl, vChars2 + $720
	lb bc, BANK(PTile), (PTileEnd - PTile) / $8
	call CopyVideoDataDouble ; P (for PP), inline
	ld a, [hTilesetType]
	push af
	xor a
	ld [hTilesetType], a
	coord hl, 19, 3
	lb bc, 2, 8
	call DrawLineBox ; Draws the box around name, HP and status
	coord hl, 2, 7
	nop
	ld [hl], "⠄" ; . after No ("." is a different one)
	dec hl
	ld [hl], "№"
	coord hl, 19, 9
	lb bc, 8, 6
	call DrawLineBox ; Draws the box around types, ID No. and OT
	coord hl, 10, 9
	ld de, Type1Text
	call PlaceString ; "TYPE1/"
	; Clear the complete HP-number field before DrawHP. PrintNumber does not
	; overwrite suppressed leading digits, so stale DV/Stat Exp digits would
	; otherwise remain beside the normal HP fraction.
	call StatusScreen_ClearHPValue
	coord hl, 11, 3
	predef DrawHP

	; DrawHP returns the HP-bar length in E. Read the color immediately,
	; before DV/Stat Exp printing reuses DE as a data pointer.
	ld hl, wStatusScreenHPBarColor
	call GetHealthBarColor

	; --- BEGIN: held START/SELECT stat display ---
	; Parse all five DVs before the stat box is printed.
	call DVParse

	; Default to normal calculated stats.
	xor a
	ld [wStatusScreenStatMode], a

	; Input is read only here, never inside the shared PrintStatsBox routine.
	; SELECT has priority when START and SELECT are held together.
	call Joypad
	ld a, [hJoyHeld]
	bit BIT_SELECT, a
	jr z, .CheckHeldStartSS

	ld a, $02 ; Stat Exp
	jr .StoreHeldStatModeSS

.CheckHeldStartSS
	bit BIT_START, a
	jr z, .HeldHPDisplayDoneSS

	ld a, $01 ; DV

.StoreHeldStatModeSS
	ld [wStatusScreenStatMode], a

	; Clear all seven tiles and return HL to the first tile before printing.
	; This prevents 2/5-digit values from surviving under a later 3/3 HP fraction.
	call StatusScreen_ClearHPValue

	ld a, [wStatusScreenStatMode]
	cp $02
	jr z, .PrintHeldHPStatExpSS

	; START: HP DV
	ld de, wDVCalcVar2 + 4
	lb bc, 1, 2
	jr .PrintHeldHPNumberSS

.PrintHeldHPStatExpSS
	; SELECT: HP Stat Exp
	ld de, wLoadedMonHPExp
	lb bc, 2, 5

.PrintHeldHPNumberSS
	call PrintNumber

.HeldHPDisplayDoneSS
	; --- END: held START/SELECT stat display ---
	; is mon supposed to be shiny?
	ld b, Bank(IsMonShiny)
	ld hl, IsMonShiny
	ld de, wLoadedMonDVs
	call Bankswitch
	ld hl, wShinyMonFlag
	jr nz, .shiny
	res 0, [hl]
	jr .setPAL
.shiny
	set 0, [hl]
.setPAL
	ld b, SET_PAL_STATUS_SCREEN
	call RunPaletteCommand

	; Only the temporary Lv50 link mode hides the status-screen EXP bar.
	; Normal Colosseum, Trade Center and all single-player screens keep it.
	ld a, [wLinkState]
	and a
	jr z, .drawEXPBar
	ld a, [wLinkBattleMode]
	cp LINK_MODE_COLOSSEUM_50
	jr z, .skipLinkBattleEXPBar
.drawEXPBar
	coord de, 18, 5
	ld a, [wBattleMonLevel]
	push af
	ld a, [wLoadedMonLevel]
	ld [wBattleMonLevel], a
	push af
	callba PrintEXPBar
	pop af
	ld [wLoadedMonLevel], a
	pop af
	ld [wBattleMonLevel], a
.skipLinkBattleEXPBar
	coord hl, 16, 6
	ld de, wLoadedMonStatus
	call PrintStatusCondition
	jr nz, .StatusWritten
	coord hl, 16, 6
	ld de, OKText
	call PlaceString ; "OK"
.StatusWritten
	coord hl, 9, 6
	ld de, StatusText
	call PlaceString ; "STATUS/"
	coord hl, 14, 2
	call PrintLevel ; Pokémon level
	ld a, [wMonHIndex]
	ld [wd11e], a
	ld [wd0b5], a
	predef IndexToPokedex
	coord hl, 3, 7
	ld de, wd11e
	lb bc, LEADING_ZEROES | 1, 3
	call PrintNumber ; Pokémon no.
	coord hl, 11, 10
	predef PrintMonType
	ld hl, NamePointers2
	call .GetStringPointer
	ld d, h
	ld e, l
	coord hl, 9, 1
	call PlaceString ; Pokémon name
	ld hl, OTPointers
	call .GetStringPointer
	ld d, h
	ld e, l
	coord hl, 12, 16
	call PlaceString ; OT
	coord hl, 12, 14
	ld de, wLoadedMonOTID
	lb bc, LEADING_ZEROES | 2, 5
	call PrintNumber ; ID Number
	call PrintShinySymbol
	ld a, [wLoadedMonSpecies]
	ld [wGenderTemp], a
	call PrintGenderStatusScreen
	ld d, $0
	call PrintStatsBox

	; The Pokémon graphic is part of the persistent summary header. Gold/Silver
	; never reload it for LEFT/RIGHT page changes, so place it before snapshotting
	; either page and leave it alone for the rest of this session.
	coord hl, 1, 0
	call LoadFlippedFrontSpriteByMonIndex

	; Page 1 is the visible window map ($9c00). Keep the screen white while its
	; complete tilemap + CGB attribute map are transferred.
	call StatusScreen_SetTransferMap1
	ld a, $1
	ld [H_AUTOBGTRANSFERENABLED], a
	call Delay3
	xor a
	ld [H_AUTOBGTRANSFERENABLED], a

	; Build page 2 from the finished page-1 tilemap. The Pokémon header/frontpic
	; remains untouched; only the page-specific fields are replaced. Then copy the
	; finished page to the hidden window map ($9800). This transfer can take three
	; frames because the player still sees the already-complete page 1.
	call StatusScreen_BuildPage2
	call StatusScreen_SetTransferMap0
	ld a, $1
	ld [H_AUTOBGTRANSFERENABLED], a
	call Delay3
	xor a
	ld [H_AUTOBGTRANSFERENABLED], a

	; Page navigation now becomes an atomic window-map flip in VBlank. No page
	; change reloads mon data, frontpic, Pokémon palette, or cry.
	call StatusScreen_ShowPage1
	call GBPalNormal
	ld a, [wcf91]
	call PlayCry ; Gold/Silver: cry on initial Pokémon load only, not page changes
	jp StatusScreen_InputLoop

.GetStringPointer
	ld a, [wMonDataLocation]
	add a
	ld c, a
	ld b, 0
	add hl, bc
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld a, [wMonDataLocation]
	cp DAYCARE_DATA
	ret z
	ld a, [wWhichPokemon]
	jp SkipFixedLengthTextEntries

OTPointers:
	dw wPartyMonOT
	dw wEnemyMonOT
	dw wBoxMonOT
	dw wDayCareMonOT

NamePointers2:
	dw wPartyMonNicks
	dw wEnemyMonNicks
	dw wBoxMonNicks
	dw wDayCareMonName

Type1Text:
	db "Type 1", $4e

Type2Text:
	db "Type 2", $4e

IDNoText:
	db $73, "№ ", $4e

OTText:
	db   "OT "
	next "@"

StatusText:
	db "Status:@"

OKText:
	db "OK@"

; Draws a line starting from hl high b and wide c
DrawLineBox:
	ld de, SCREEN_WIDTH ; New line
.PrintVerticalLine
	ld [hl], $78 ; │
	add hl, de
	dec b
	jr nz, .PrintVerticalLine
	ld [hl], $77 ; ┘
	dec hl
.PrintHorizLine
	ld [hl], $76 ; ─
	dec hl
	dec c
	jr nz, .PrintHorizLine
	ld [hl], $6f ; ← (halfarrow ending)
	ret

PTile: ; This is a single 1bpp "P" tile
	INCBIN "gfx/p_tile.1bpp"
PTileEnd:

PrintShinySymbol:
	; check if mon is shiny
	ld b, Bank(IsMonShiny)
	ld hl, IsMonShiny
	ld de, wLoadedMonDVs
	call Bankswitch
	ret z
	; draw the shiny symbol
	coord hl, 0, 0
	ld a, "[SHINY]"
	ld [hl], a
	ret

PrintGenderStatusScreen: ; called on status screen
	; get gender
	ld de, wLoadedMonDVs
	callba GetMonGender
	ld a, [wGenderTemp]
	and a
	jr z, .noGender
	dec a
	jr z, .male
	; else female
	ld a, "♀"
	jr .printSymbol
.male
	ld a, "♂"
	jr .printSymbol
.noGender
	ld a, " "
.printSymbol
	coord hl, 17, 2
	ld [hl], a
	ret

; Return HL at the first tile of the seven-tile HP / Max HP field.
StatusScreen_GetHPValuePosition:
	coord hl, 11, 3
	ld a, [hFlags_0xFFF6]
	bit 0, a
	jr z, .BelowBar
	ld bc, $9
	jr .PositionReady

.BelowBar
	ld bc, SCREEN_WIDTH + 1

.PositionReady
	add hl, bc
	ret


; Clear the complete HP-number field and return HL to its first tile.
StatusScreen_ClearHPValue:
	call StatusScreen_GetHPValuePosition
	push hl
	ld b, 7
	ld a, " "

.ClearLoop
	ld [hli], a
	dec b
	jr nz, .ClearLoop
	pop hl
	ret


PrintStatsBox:
	; d = 0: status screen
	; d != 0: level-up, Rare Candy, and other stat windows
	ld a, d
	and a ; a is 0 from the status screen
	jr nz, .DifferentBox
	coord hl, 0, 8
	ld b, 8
	ld c, 8
	call TextBoxBorder ; Draws the box
	coord hl, 1, 9 ; Start printing stats from here
	ld bc, $0019 ; Number offset

	; Save that this call came from the status screen.
	; PlaceString uses DE, so the original D register cannot be checked later.
	ld a, $01
	jr .PrintStats

.DifferentBox
	coord hl, 9, 2
	ld b, 8
	ld c, 9
	call TextBoxBorder
	coord hl, 11, 3
	ld bc, $0018

	; Non-status screens must always show normal calculated stats.
	xor a

.PrintStats
	push af
	push bc
	push hl
	ld de, StatsText
	call PlaceString
	pop hl
	pop bc
	add hl, bc
	pop af

	; Do not let START/SELECT affect level-up or Rare Candy stat windows.
	and a
	jr z, .PrintRegularStats

	ld a, [wStatusScreenStatMode]
	cp $02
	jr z, .PrintStatExp
	cp $01
	jr z, .PrintDVs

.PrintRegularStats
	ld de, wLoadedMonAttack
	lb bc, 2, 3
	call PrintStat
	ld de, wLoadedMonDefense
	call PrintStat
	ld de, wLoadedMonSpeed
	call PrintStat
	ld de, wLoadedMonSpecial
	jp PrintNumber

.PrintStatExp
	; Stat Exp uses five digits, so begin two tiles farther left.
	dec hl
	dec hl
	ld de, wLoadedMonAttackExp
	lb bc, 2, 5
	call PrintStat
	ld de, wLoadedMonDefenseExp
	call PrintStat
	ld de, wLoadedMonSpeedExp
	call PrintStat
	ld de, wLoadedMonSpecialExp
	jp PrintNumber

.PrintDVs
	ld de, wDVCalcVar2
	lb bc, 1, 2
	call PrintStat
	ld de, wDVCalcVar2 + 1
	call PrintStat
	ld de, wDVCalcVar2 + 2
	call PrintStat
	ld de, wDVCalcVar2 + 3
	jp PrintNumber

PrintStat:
	push hl
	call PrintNumber
	pop hl
	ld de, SCREEN_WIDTH * 2
	add hl, de
	ret
	; --- END: START/SELECT 扩展显示（四维） ---

StatsText:
	db   "Attack"
	next "Defense"
	next "Speed"
	next "Special@"

StatusScreen2:
	; Compatibility predef. All known callers now enter StatusScreen only; page 2
	; is prepared and selected by the unified summary loop below.
	ret

StatusScreen_BuildPage2:
	; H_AUTOBGTRANSFERENABLED is deliberately off here. Page 1 remains visible in
	; VRAM while this routine edits only wTileMap, mirroring Gold/Silver's rule
	; that page changes never touch Pokémon lifecycle state.
	ld bc, NUM_MOVES + 1
	ld hl, wMoves
	call FillMemory
	ld hl, wLoadedMonMoves
	ld de, wMoves
	ld bc, NUM_MOVES
	call CopyData
	callab FormatMovesString
	coord hl, 9, 2
	lb bc, 5, 10
	call ClearScreenArea ; Clear under name
	coord hl, 19, 1
	lb bc, 6, 10
	call DrawLineBox ; Draws the box around name, HP and status
	coord hl, 0, 8
	ld b, 8
	ld c, 18
	call TextBoxBorder ; Draw move container
	coord hl, 2, 9
	ld de, wMovesString
	call PlaceString ; Print moves
	ld a, [wNumMovesMinusOne]
	inc a
	ld c, a
	ld a, $4
	sub c
	ld b, a ; Number of moves ?
	coord hl, 11, 10
	ld de, SCREEN_WIDTH * 2
	ld a, $72 ; special P tile id
	call StatusScreen_PrintPP ; Print "PP"
	ld a, b
	and a
	jr z, .InitPP
	ld c, a
	ld a, "-"
	call StatusScreen_PrintPP ; Fill the rest with --
.InitPP
	ld hl, wLoadedMonMoves
	coord de, 14, 10
	ld b, 0
.PrintPP
	ld a, [hli]
	and a
	jr z, .PPDone
	push bc
	push hl
	push de
	ld hl, wCurrentMenuItem
	ld a, [hl]
	push af
	ld a, b
	ld [hl], a
	push hl
	callab GetMaxPP
	pop hl
	pop af
	ld [hl], a
	pop de
	pop hl
	push hl
	ld bc, wPartyMon1PP - wPartyMon1Moves - 1
	add hl, bc
	ld a, [hl]
	and $3f
	ld [wStatusScreenCurrentPP], a
	ld h, d
	ld l, e
	push hl
	ld de, wStatusScreenCurrentPP
	lb bc, 1, 2
	call PrintNumber
	ld a, "/"
	ld [hli], a
	ld de, wMaxPP
	lb bc, 1, 2
	call PrintNumber
	pop hl
	ld de, SCREEN_WIDTH * 2
	add hl, de
	ld d, h
	ld e, l
	pop hl
	pop bc
	inc b
	ld a, b
	cp $4
	jr nz, .PrintPP
.PPDone
	; Always keep the EXP labels and the next-level text (for example, L51).
	; Lv50 link mode hides only the two numeric EXP values below those labels.
	coord hl, 9, 3
	ld de, StatusScreenExpText
	call PlaceString
	ld a, [wLoadedMonLevel]
	push af
	cp MAX_LEVEL
	jr z, .Level100
	inc a
	ld [wLoadedMonLevel], a ; Increase temporarily if not 100
.Level100
	coord hl, 14, 6
	ld [hl], $70 ; 1-tile "to"
	inc hl
	inc hl
	call PrintLevel
	pop af
	ld [wLoadedMonLevel], a

	; Only an active Lv50 link session suppresses the total EXP and the EXP
	; needed for the next level. Normal link and single-player modes show both.
	ld a, [wLinkState]
	and a
	jr z, .drawEXPValues
	ld a, [wLinkBattleMode]
	cp LINK_MODE_COLOSSEUM_50
	jr z, .skipLinkBattleEXPValues
.drawEXPValues
	ld de, wLoadedMonExp
	coord hl, 12, 4
	lb bc, 3, 7
	call PrintNumber ; total exp
	call CalcExpToLevelUp
	ld de, wStatusScreenExpToNext
	coord hl, 7, 6
	lb bc, 3, 7
	call PrintNumber ; exp needed to level up
.skipLinkBattleEXPValues
	coord hl, 9, 0
	call StatusScreen_ClearName
	coord hl, 9, 1
	call StatusScreen_ClearName
	ld a, [wMonHIndex]
	ld [wd11e], a
	call GetMonName
	coord hl, 9, 1
	call PlaceString
	ret

StatusScreen_InputLoop:
	call JoypadLowSensitivity
	; The old per-page wait loop serviced link communication every frame. Keep
	; that contract while the summary owns input itself.
	predef CableClub_Run
	ld a, [hJoy5]
	and D_RIGHT | D_LEFT | D_UP | D_DOWN | A_BUTTON | B_BUTTON
	jr z, StatusScreen_InputLoop
	bit BIT_B_BUTTON, a
	jp nz, StatusScreen_Exit
	bit BIT_D_LEFT, a
	jr nz, .PreviousPage
	bit BIT_D_RIGHT, a
	jr nz, .NextPage
	bit BIT_A_BUTTON, a
	jr nz, .AButton
	; Gold/Silver reserves UP/DOWN for Pokémon navigation. SUMMARY01 deliberately
	; leaves those inputs inactive until the page lifecycle is proven stable.
	jr StatusScreen_InputLoop

.PreviousPage
	; Gold/Silver page navigation wraps. With Red's two pages, either direction
	; simply selects the other prepared page.
	ld a, [wStatusScreenPage]
	cp $1
	jr z, .ShowPage2
	jr .ShowPage1

.NextPage
	ld a, [wStatusScreenPage]
	cp $1
	jr z, .ShowPage2
	jr .ShowPage1

.AButton
	; Gold/Silver compatibility: A advances a page; A on the final page exits.
	ld a, [wStatusScreenPage]
	cp $1
	jr z, .ShowPage2
	jp StatusScreen_Exit

.ShowPage1
	call StatusScreen_ShowPage1
	jr StatusScreen_InputLoop

.ShowPage2
	call StatusScreen_ShowPage2
	jr StatusScreen_InputLoop

StatusScreen_ShowPage1:
	; Flip only the window tilemap selector, and do it during VBlank so a single
	; frame can never contain halves of two pages. Pokémon graphics/palettes are
	; identical in both prepared maps.
	callba WaitForVBlank
	ld a, [rLCDC]
	set 6, a ; window tile map = $9c00
	ld [rLCDC], a
	ld a, $1
	ld [wStatusScreenPage], a
	ret

StatusScreen_ShowPage2:
	callba WaitForVBlank
	ld a, [rLCDC]
	res 6, a ; window tile map = $9800
	ld [rLCDC], a
	ld a, $2
	ld [wStatusScreenPage], a
	ret

StatusScreen_SetTransferMap0:
	xor a
	ld [H_AUTOBGTRANSFERDEST], a
	ld a, vBGMap0 / $100
	ld [H_AUTOBGTRANSFERDEST + 1], a
	ret

StatusScreen_SetTransferMap1:
	xor a
	ld [H_AUTOBGTRANSFERDEST], a
	ld a, vBGMap1 / $100
	ld [H_AUTOBGTRANSFERDEST + 1], a
	ret

StatusScreen_Exit:
	; Restore the project's normal full-screen window map before returning to any
	; caller. Whiteout hides this bookkeeping, then ClearScreen repopulates map 1
	; exactly as the original status-screen exit did.
	call GBPalWhiteOut
	call StatusScreen_ShowPage1
	call StatusScreen_SetTransferMap1
	ld a, $1
	ld [H_AUTOBGTRANSFERENABLED], a
	pop af
	ld [hTilesetType], a
	ld hl, wd72c
	res 1, [hl]
	ld a, [wOptions]
	bit 5, a
	jr nz, .skipExitVolumeRestore
	ld a, [wBGMVolume]
	cp $a0 ; BGM Volume 0 is also effectively muted
	jr z, .skipExitVolumeRestore
	ld a, $77
	ld [rNR50], a
.skipExitVolumeRestore
	jp ClearScreen

CalcExpToLevelUp:
	; Gold/Silver keeps total EXP immutable and writes "EXP to next" separately.
	; Page 2 can therefore be prepared/revisited without corrupting mon data.
	ld a, [wLoadedMonLevel]
	cp MAX_LEVEL
	jr z, .atMaxLevel
	inc a
	ld d, a
	callab CalcExperience
	ld hl, wLoadedMonExp + 2
	ld de, wStatusScreenExpToNext + 2
	ld a, [hExperience + 2]
	sub [hl]
	ld [de], a
	dec hl
	dec de
	ld a, [hExperience + 1]
	sbc [hl]
	ld [de], a
	dec hl
	dec de
	ld a, [hExperience]
	sbc [hl]
	ld [de], a
	ret
.atMaxLevel
	ld hl, wStatusScreenExpToNext
	xor a
	ld [hli], a
	ld [hli], a
	ld [hl], a
	ret

StatusScreenExpText:
	db   "Exp.Points"
	next "Next@"

StatusScreen_ClearName:
	ld bc, 10
	ld a, " "
	jp FillMemory

StatusScreen_PrintPP:
; print PP or -- c times, going down two rows each time
	ld [hli], a
	ld [hld], a
	add hl, de
	dec c
	jr nz, StatusScreen_PrintPP
	ret

; --- BEGIN: DV parsing from yellow legacy ---
; 解析 4 项 DV 并组合 HP DV，结果写入 wDVCalcVar2..wDVCalcVar2+4
DVParse:
	push hl
	push bc
	ld hl, wDVCalcVar2
	ld b, $00

	; Attack DV
	ld a, [wLoadedMonDVs]
	swap a
	and $0F
	ld [hl], a
	inc hl
	and $01
	sla a
	sla a
	sla a
	or b
	ld b, a

	; Defense DV
	ld a, [wLoadedMonDVs]
	and $0F
	ld [hl], a
	inc hl
	and $01
	sla a
	sla a
	or b
	ld b, a

	; Speed DV
	ld a, [wLoadedMonDVs + 1]
	swap a
	and $0F
	ld [hl], a
	inc hl
	and $01
	sla a
	or b
	ld b, a

	; Special DV
	ld a, [wLoadedMonDVs + 1]
	and $0F
	ld [hl], a
	inc hl
	and $01
	or b
	ld b, a

	; HP DV（由最低位组合）
	ld [hl], b
	pop bc
	pop hl
	ret
; --- END: DV parsing from yellow legacy ---
