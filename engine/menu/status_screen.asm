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


StatusScreen_LoadCurrentMon:
	call LoadMonData
	ld a, [wMonDataLocation]
	cp BOX_DATA
	ret c
; mon is in a box or daycare
	ld a, [wLoadedMonBoxLevel]
	ld [wLoadedMonLevel], a
	ld [wCurEnemyLVL], a
	ld hl, wLoadedMonHPExp - 1
	ld de, wLoadedMonStats
	ld b, $1
	call CalcStats ; Recalculate stats
	ret

; Predef 0x37
StatusScreen:
	; Bit 7 is an explicit caller-owned permission for live Pokémon navigation.
	; START -> Pokémon plus Bill's PC Deposit/Withdraw Stats may set it; other
	; callers leave it clear. Preserve that permission while resetting Summary to page 1.
	ld a, [wStatusScreenPage]
	and $80
	or $1
	ld [wStatusScreenPage], a
	xor a
	ld [wStatusScreenDeferPaletteUpdate], a
	call StatusScreen_LoadCurrentMon
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
	; START -> Pokémon -> Stats may later use vBGMap0 for Page 2. The far helper
	; cheaply returns for other callers and otherwise caches the live overworld BG0.
	callba Summary_MaybeCacheOverworldBG0
	; The display is already white and AutoBG is not needed until the completed
	; Page 1 transfer below. Clear only the WRAM tilemap here; ClearScreen would
	; spend another fixed three frames transferring an intermediate blank map.
	xor a
	ld [H_AUTOBGTRANSFERENABLED], a
	call StatusScreen_ClearTileMapNoWait
	call UpdateSprites

	; START Party and the initial Bill's PC entry may have loaded these exact shared
	; graphics immediately beforehand. The hint is deliberately one-shot: consume
	; it now so later callers cannot skip a load after unrelated VRAM activity.
	ld a, [wStatusScreenCommonTilesReady]
	and a
	jr nz, .commonTilesReady
	call LoadHpBarAndStatusTilePatterns
.commonTilesReady
	xor a
	ld [wStatusScreenCommonTilesReady], a
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
	call StatusScreen_DetectInitialStatMode
	call StatusScreen_DrawPage1

	; The Pokémon graphic is persistent across LEFT/RIGHT. UP/DOWN keeps the
	; display white while rebuilding the primary frontpic buffer and both page
	; maps, then restores the logical page that was being viewed.
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

	; START/SELECT are dedicated single-page inspection modes. Keep them fully
	; isolated from the normal Summary page lifecycle: Page 2 is not built and
	; the hidden window map is never touched while DVs/Stat Exp are being viewed.
	ld a, [wStatusScreenStatMode]
	and a
	jr nz, .PagesReady

	; Do not keep the initial white screen up just to prepare the hidden Page 2.
	; Existing dirty-page machinery will build and transfer it on the first request,
	; while Page 1 can become visible immediately after its completed transfer.
	ld hl, wStatusScreenPage
	set STATUS_SCREEN_HIDDEN_PAGE_DIRTY_F, [hl]

.PagesReady
	; Page navigation now becomes an atomic window-map flip in VBlank. No page
	; change reloads mon data, frontpic, Pokémon palette, or cry.
	call StatusScreen_ShowPage1
	call GBPalNormal
	ld a, [wcf91]
	call PlayCry ; Gold/Silver: cry on initial Pokémon load only, not page changes
	jp StatusScreen_InputLoop

StatusScreen_GetStringPointer:
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


StatusScreen_DetectInitialStatMode:
	; START/SELECT are entry modifiers, not live Summary controls. SELECT keeps
	; priority when both are held, matching the pre-Summary implementation.
	xor a
	ld [wStatusScreenStatMode], a
	call Joypad
	ld a, [hJoyHeld]
	bit BIT_SELECT, a
	jr z, .checkStart
	ld a, $02 ; Stat Exp
	ld [wStatusScreenStatMode], a
	ret
.checkStart
	bit BIT_START, a
	ret z
	ld a, $01 ; DV
	ld [wStatusScreenStatMode], a
	ret

StatusScreen_DrawPage1:
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
	; Parse all five DVs before the stat box is printed. The inspection mode was
	; sampled once on entry; Pokémon switching is disabled while that mode is set.
	call DVParse
	ld a, [wStatusScreenStatMode]
	and a
	jr z, .HeldHPDisplayDoneSS

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
	; Live switching can stage the next page while preserving the old palette.
	; Keep palette 0 on the old Pokémon until the proven
	; SUMMARY17 dual-palette wipe has completely finished.
	ld a, [wStatusScreenDeferPaletteUpdate]
	and a
	jr nz, .paletteDone
	ld b, SET_PAL_STATUS_SCREEN
	call RunPaletteCommand
.paletteDone

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
	call StatusScreen_GetStringPointer
	ld d, h
	ld e, l
	coord hl, 9, 1
	call PlaceString ; Pokémon name
	ld hl, OTPointers
	call StatusScreen_GetStringPointer
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
	ret

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
	; Keep the original DV workspace intact. START/SELECT stat display owns
	; wDVCalcVar2 for the whole summary session, so use the general scratch
	; buffer for the three-byte "EXP to next" value instead.
	ld de, wBuffer
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

	; START/SELECT inspection remains a dedicated Page-1-only mode. It deliberately
	; ignores every navigation key except B, so the original DV/Stat Exp lifecycle
	; stays isolated from both page and Pokémon switching.
	ld a, [wStatusScreenStatMode]
	and a
	jr nz, StatusScreen_InputLoop

	ld a, [hJoy5]
	and D_RIGHT | D_LEFT | D_UP | D_DOWN | A_BUTTON | B_BUTTON
	bit BIT_D_LEFT, a
	jr nz, .PreviousPage
	bit BIT_D_RIGHT, a
	jr nz, .NextPage
	bit BIT_A_BUTTON, a
	jr nz, .AButton

	; Gold/Silver-style Pokémon navigation is available only when the caller sets
	; the switch-permission bit. StatusScreen_TrySwitchPartyMon independently accepts
	; only Party or Box data, so enemy/daycare callers cannot opt in by accident.
	ld b, a
	ld a, [wStatusScreenPage]
	bit STATUS_SCREEN_MON_SWITCH_F, a
	jr z, StatusScreen_InputLoop
	ld a, b
	and D_UP | D_DOWN
	jr z, StatusScreen_InputLoop
	call StatusScreen_TrySwitchPartyMon
	jr nc, StatusScreen_InputLoop
	call StatusScreen_RebuildSwitchedPartyMon
	jr StatusScreen_InputLoop

.PreviousPage
	; Gold/Silver page navigation wraps. With Red's two pages, either direction
	; simply selects the other prepared page.
	ld a, [wStatusScreenPage]
	and STATUS_SCREEN_PAGE_MASK
	cp $1
	jr z, .ShowPage2
	jr .ShowPage1

.NextPage
	ld a, [wStatusScreenPage]
	and STATUS_SCREEN_PAGE_MASK
	cp $1
	jr z, .ShowPage2
	jr .ShowPage1

.AButton
	; A always toggles between the two pages. B remains the only exit.
	ld a, [wStatusScreenPage]
	and STATUS_SCREEN_PAGE_MASK
	cp $1
	jr z, .ShowPage2
	jr .ShowPage1

.ShowPage1
	call StatusScreen_PreparePage1IfDirty
	call StatusScreen_ShowPage1
	jr StatusScreen_InputLoop

.ShowPage2
	call StatusScreen_PreparePage2IfDirty
	call StatusScreen_ShowPage2
	jr StatusScreen_InputLoop

StatusScreen_TrySwitchPartyMon:
	; A = D_UP / D_DOWN. Carry is set only when the selection actually changes.
	; The caller owns permission; only Party and Box data are accepted here.
	ld c, a
	ld a, [wMonDataLocation]
	cp PLAYER_PARTY_DATA
	jr z, .party
	cp BOX_DATA
	jr nz, .cantSwitch
	ld a, [wNumInBox]
	jr .gotCount
.party
	ld a, [wPartyCount]
.gotCount
	cp 2
	jr c, .cantSwitch
	ld b, a
	ld a, c
	bit BIT_D_UP, a
	jr z, .down
	ld a, [wWhichPokemon]
	and a
	jr z, .cantSwitch
	dec a
	jr .store
.down
	ld a, [wWhichPokemon]
	inc a
	cp b
	jr nc, .cantSwitch
.store
	ld [wWhichPokemon], a
	; Keep the caller synchronized with the Pokémon currently shown. START consumes
	; this as its final party cursor directly; Bill's PC converts the absolute index
	; back to its scroll-offset + visible-row representation after Stats exits.
	ld [wPartyAndBillsPCSavedMenuItem], a
	scf
	ret
.cantSwitch
	and a
	ret

StatusScreen_RebuildSwitchedPartyMon:
	; 22 keeps 21's early CPU-side image/palette preparation and safe visible order.
	; The next Pokémon colors are staged in unused palette 7, allowing the HP-bar
	; palette to change with the new text while palette 2 still protects the old pic.
	xor a
	ld [wStatusScreenStatMode], a
	ld [H_AUTOBGTRANSFERENABLED], a
	call StatusScreen_LoadCurrentMon
	call StatusScreen_UpdateShinyFlag

	; Stage the next Pokémon colors in unused palette 7 and prepare the new 7x7 2bpp
	; image entirely off-screen. Palette 2 remains the old/current Pokémon for now.
	callba StatusScreen_PrepareNextPokemonPaletteScratch
	call StatusScreen_PrepareFlippedFrontPicDualPalette
	call StatusScreen_ClearTileMapNoWait

	; Build the new text/data in WRAM but deliberately keep palette 0 on the old
	; Pokémon. The old frontpic remains visible until the later SUMMARY17 wipe.
	ld a, 1
	ld [wStatusScreenDeferPaletteUpdate], a
	call StatusScreen_DrawPage1
	ld a, [wStatusScreenPage]
	and STATUS_SCREEN_PAGE_MASK
	cp $2
	jr nz, .pagePrepared
	call StatusScreen_BuildPage2
.pagePrepared
	; ClearTileMapNoWait erased the 7x7 tile references. Restore those references
	; before the page transfer; vFrontPic still contains the old Pokémon graphics.
	call StatusScreen_DrawFlippedFrontPicTileMap
	xor a
	ld [wStatusScreenDeferPaletteUpdate], a

	; Put the newly calculated green/yellow/red HP palette into slot 1 before the
	; ordinary page transfer. The first transfer VBlank therefore changes HP color
	; together with the new HP/text tiles, while the old frontpic colors stay intact.
	callba StatusScreen_PrepareHPBarPalette1

	; Use SUMMARY17's exact complete page-transfer helper, unchanged. This retains
	; the existing GBC static-palette/AutoBG handshake and avoids the failed
	; SUMMARY18/19/20 partial-refresh and fixed-portion assumptions.
	ld a, [wStatusScreenPage]
	and STATUS_SCREEN_PAGE_MASK
	cp $2
	jr z, .transferPage2
.transferPage1
	call StatusScreen_SetTransferMap1
	call StatusScreen_TransferPreparedMap
	jr .pageVisible
.transferPage2
	call StatusScreen_SetTransferMap0
	call StatusScreen_TransferPreparedMap
.pageVisible

	; Text/data (including the correct HP-bar color) is now fully visible. Promote
	; the already-staged next Pokémon colors from unused slot 7 into transition slot
	; 2, then immediately enter the unchanged 49-tile wipe.
	callba StatusScreen_CommitPreparedNextPokemonPalette2
	call StatusScreen_CommitPreparedFlippedFrontPicDualPalette

	; Commit the new normal palette 0. The visible picture may remain on palette 2
	; after this switch because palette 0 and palette 2 now contain the same Pokémon
	; colors. The next normal page transfer (page navigation or another mon switch)
	; safely restores ordinary palette-0 picture attributes before palette 2 is reused.
	ld b, SET_PAL_STATUS_SCREEN
	call RunPaletteCommand
	call GBPalNormal
	call StatusScreen_ForceBgPaletteUpdateAndWait

	; The opposite physical page still belongs to the previous Pokémon. Rebuild it
	; only if the player actually navigates there, exactly like SUMMARY17.
	ld hl, wStatusScreenPage
	set STATUS_SCREEN_HIDDEN_PAGE_DIRTY_F, [hl]
	ret


StatusScreen_UpdateShinyFlag:
	ld b, Bank(IsMonShiny)
	ld hl, IsMonShiny
	ld de, wLoadedMonDVs
	call Bankswitch
	ld hl, wShinyMonFlag
	jr nz, .shiny
	res 0, [hl]
	ret
.shiny
	set 0, [hl]
	ret

StatusScreen_PrepareFlippedFrontPicDualPalette:
	; Live-switch helper. StatusScreen_LoadCurrentMon has already loaded a valid
	; Pokémon header from Party or Box, so reuse the original Home decompression and
	; alignment helpers while replacing only the final CopyVideoData stage.
	ld a, 1
	ld [wSpriteFlipped], a
	ld hl, wMonHFrontSprite - wMonHeader
	call UncompressMonSprite
	ld hl, wMonHSpriteDim
	ld a, [hli]
	ld c, a

	and $f
	ld [H_SPRITEWIDTH], a
	ld b, a
	ld a, $7
	sub b
	inc a
	srl a
	ld b, a
	add a
	add a
	add a
	sub b
	ld [H_SPRITEOFFSET], a
	ld a, c
	swap a
	and $f
	ld b, a
	add a
	add a
	add a
	ld [H_SPRITEHEIGHT], a
	ld a, $7
	sub b
	ld b, a
	ld a, [H_SPRITEOFFSET]
	add b
	add a
	add a
	add a
	ld [H_SPRITEOFFSET], a
	xor a
	ld [$4000], a
	ld hl, sSpriteBuffer0
	call ZeroSpriteBuffer
	ld de, sSpriteBuffer1
	ld hl, sSpriteBuffer0
	call AlignSpriteDataCentered
	ld hl, sSpriteBuffer1
	call ZeroSpriteBuffer
	ld de, sSpriteBuffer2
	ld hl, sSpriteBuffer1
	call AlignSpriteDataCentered

	; Interlace the two 1bpp planes into the same contiguous 49-tile 2bpp buffer
	; used by the stock loader, including its horizontal nibble flip.
	xor a
	ld [$4000], a
	ld hl, sSpriteBuffer2 + (SPRITEBUFFERSIZE - 1)
	ld de, sSpriteBuffer1 + (SPRITEBUFFERSIZE - 1)
	ld bc, sSpriteBuffer0 + (SPRITEBUFFERSIZE - 1)
	ld a, SPRITEBUFFERSIZE / 2
	ld [H_SPRITEINTERLACECOUNTER], a
.interlaceLoop
	ld a, [de]
	dec de
	ld [hld], a
	ld a, [bc]
	dec bc
	ld [hld], a
	ld a, [de]
	dec de
	ld [hld], a
	ld a, [bc]
	dec bc
	ld [hld], a
	ld a, [H_SPRITEINTERLACECOUNTER]
	dec a
	ld [H_SPRITEINTERLACECOUNTER], a
	jr nz, .interlaceLoop
	ld bc, 2 * SPRITEBUFFERSIZE
	ld hl, sSpriteBuffer1
.flipLoop
	swap [hl]
	inc hl
	dec bc
	ld a, b
	or c
	jr nz, .flipLoop
	; Stop here: the prepared pixels live only in SRAM. Do not touch vFrontPic or
	; the visible tilemap until the ordinary text/data transfer has fully completed.
	ret

StatusScreen_CommitPreparedFlippedFrontPicDualPalette:
	; Palette 2 must be resident before graphics batch 0 becomes visible. Its data
	; was prepared early, but hardware commit is intentionally requested only after
	; the text/data transfer, preventing the old picture from taking the next colors.
	call StatusScreen_WaitForBgPaletteCommit
	call StatusScreen_CopyFrontPicDualPalette
	call StatusScreen_DrawFlippedFrontPicTileMap
	xor a
	ld [wSpriteFlipped], a
	ret

StatusScreen_DrawFlippedFrontPicTileMap:
	; Match CopyUncompressedPicToHL's flipped 7x7 tile-ID layout without another
	; banked call: tile 0 begins at coord(7,0), IDs run downward, then columns move
	; left. The visible VRAM map already has this layout during the wipe; rebuilding
	; it here only restores the cleared WRAM page for the later normal transfer.
	coord hl, 7, 0
	xor a
	ld b, 7
.columnLoop
	push bc
	push hl
	ld c, 7
.rowLoop
	ld [hl], a
	ld de, SCREEN_WIDTH
	add hl, de
	inc a
	dec c
	jr nz, .rowLoop
	pop hl
	dec hl
	pop bc
	dec b
	jr nz, .columnLoop
	ret

StatusScreen_CopyFrontPicDualPalette:
	; Local equivalent of CopyVideoData for the 49-tile frontpic. Before each
	; DelayFrame, arm one batch number in wStatusScreenPage. VBlankCopy writes the
	; graphics first; the existing GBC VBlank hook then updates those same cells'
	; attributes to palette 2 before the frame becomes visible.
	ld a, [H_AUTOBGTRANSFERENABLED]
	push af
	xor a
	ld [H_AUTOBGTRANSFERENABLED], a
	ld hl, sSpriteBuffer1
	ld a, l
	ld [H_VBCOPYSRC], a
	ld a, h
	ld [H_VBCOPYSRC + 1], a
	ld hl, vFrontPic
	ld a, l
	ld [H_VBCOPYDEST], a
	ld a, h
	ld [H_VBCOPYDEST + 1], a
	ld c, 49
	ld d, 0
.copyLoop
	ld a, c
	cp 8
	jr c, .lastBatch
	ld a, 8
	jr .armBatch
.lastBatch
	ld a, c
.armBatch
	ld [H_VBCOPYSIZE], a
	push af
	ld a, d
	call StatusScreen_ArmPicturePaletteBatch
	pop af
	call DelayFrame
	ld a, c
	sub 8
	jr c, .done
	ld c, a
	inc d
	jr .copyLoop
.done
	; Clear the temporary batch/active bits; page, hidden-dirty and ownership bits
	; remain untouched.
	ld a, [wStatusScreenPage]
	and %10000111
	ld [wStatusScreenPage], a
	pop af
	ld [H_AUTOBGTRANSFERENABLED], a
	ret

StatusScreen_ArmPicturePaletteBatch:
	; A = batch index 0..6. Encode it in bits 3..5 and set bit 6. The VBlank-side
	; consumer clears only the active bit after applying that batch's attributes.
	and 7
	add a
	add a
	add a
	ld b, a
	ld a, [wStatusScreenPage]
	and %10000111
	or b
	set STATUS_SCREEN_WIPE_ACTIVE_F, a
	ld [wStatusScreenPage], a
	ret

StatusScreen_PreparePage1IfDirty:
	; Dirty always refers to the hidden page. Therefore this path is reached only
	; while Page 2 is visible. Recreate Page 1 in WRAM, transfer it to hidden
	; vBGMap1, then clear the dirty marker before the LCDC page flip.
	ld a, [wStatusScreenPage]
	bit STATUS_SCREEN_HIDDEN_PAGE_DIRTY_F, a
	ret z
	xor a
	ld [H_AUTOBGTRANSFERENABLED], a
	call StatusScreen_SetTransferMap1
	call StatusScreen_ClearTileMapNoWait
	call StatusScreen_DrawPage1
	; ClearTileMapNoWait also erased the 7x7 frontpic tile IDs. The graphics are
	; still resident in vFrontPic, so restore only the flipped tilemap references
	; before transferring the rebuilt hidden Page 1.
	call StatusScreen_DrawFlippedFrontPicTileMap
	call StatusScreen_TransferPreparedMap
	ld hl, wStatusScreenPage
	res STATUS_SCREEN_HIDDEN_PAGE_DIRTY_F, [hl]
	ret

StatusScreen_PreparePage2IfDirty:
	; While Page 1 is visible, its freshly drawn tilemap remains in wTileMap after
	; a live switch. Derive Page 2 from that buffer only when the player asks to
	; see it, then transfer the completed page to hidden vBGMap0.
	ld a, [wStatusScreenPage]
	bit STATUS_SCREEN_HIDDEN_PAGE_DIRTY_F, a
	ret z
	call StatusScreen_SetTransferMap0
	call StatusScreen_BuildPage2
	call StatusScreen_TransferPreparedMap
	ld hl, wStatusScreenPage
	res STATUS_SCREEN_HIDDEN_PAGE_DIRTY_F, [hl]
	ret


StatusScreen_ClearTileMapNoWait:
	; Clear the full 20x18 WRAM tilemap exactly like ClearScreen, but return
	; immediately instead of waiting three frames for AutoBG. StatusScreen callers
	; use this only while AutoBG is disabled and perform an explicit map transfer
	; after the page has been completely redrawn.
	ld bc, SCREEN_WIDTH * SCREEN_HEIGHT
	inc b
	coord hl, 0, 0
	ld a, " "
.loop
	ld [hli], a
	dec c
	jr nz, .loop
	dec b
	jr nz, .loop
	ret

StatusScreen_ForceBgPaletteUpdateAndWait:
	; SetPal_StatusScreen has written the desired palette sources in WRAM. Force
	; the normal pre-VBlank conversion and wait until the VBlank consumer has
	; copied the result into CGB palette RAM. This preserves the correctness
	; boundary established by SUMMARY08/10 while the frontpic upload itself stays
	; visible instead of being hidden by a white curtain.
	ld a, [rSVBK]
	ld b, a
	ld a, 2
	ld [rSVBK], a
	ld a, 1
	ld [W2_ForceBGPUpdate], a
	ld a, b
	ld [rSVBK], a
	jp StatusScreen_WaitForBgPaletteCommit

StatusScreen_WaitForBgPaletteCommit:
	; W2_ForceBGPUpdate is cleared by RefreshPalettesPreVBlank after preparing the
	; converted buffer. W2_BgPaletteDataModified is cleared only after the VBlank
	; hook actually writes that buffer into CGB palette RAM. Check first so callers
	; can overlap unrelated CPU work with the transaction; only wait another frame
	; when either producer or consumer is still busy.
.check
	ld a, [rSVBK]
	ld b, a
	ld a, 2
	ld [rSVBK], a
	ld a, [W2_ForceBGPUpdate]
	ld c, a
	ld a, [W2_BgPaletteDataModified]
	or c
	ld c, a
	ld a, b
	ld [rSVBK], a
	ld a, c
	and a
	ret z
	call DelayFrame
	jr .check

StatusScreen_TransferPreparedMap:
	; A live-switch wipe leaves the visible 7x7 picture attributes on palette 2.
	; Do not rely on a destination change or a previous RunPaletteCommand to mark
	; the static attribute map dirty: same-page consecutive switches can otherwise
	; promote the next Pokemon colors into palette 2 while the old picture still
	; references it, producing a one-frame recolored old sprite.
	ld a, 2
	ld [rSVBK], a
	ld a, 3
	ld [W2_StaticPaletteMapChanged], a
	xor a
	ld [rSVBK], a

	ld a, $1
	ld [H_AUTOBGTRANSFERENABLED], a
	call Delay3

	; Delay3 is the normal three-portion transfer time, but palette-map preparation
	; and its VBlank DMA use an explicit producer/consumer handshake. Wait for all
	; three portions and any final prepared window portion to be consumed before
	; palette 2 is allowed to change. In the common case this exits immediately.
.waitForPaletteMapCommit
	ld a, 2
	ld [rSVBK], a
	ld a, [W2_StaticPaletteMapChanged]
	and a
	jr nz, .paletteMapPending
	ld a, [W2_StaticPaletteMapChanged_vbl]
	and a
	jr nz, .paletteMapPending
	ld a, [W2_UpdatedWindowPortion]
	and a
	jr nz, .paletteMapPending
	xor a
	ld [rSVBK], a
	jr .transferComplete

.paletteMapPending
	xor a
	ld [rSVBK], a
	call DelayFrame
	jr .waitForPaletteMapCommit

.transferComplete
	xor a
	ld [H_AUTOBGTRANSFERENABLED], a
	ret

StatusScreen_ShowPage1:
	callba WaitForVBlank
	ld a, [rLCDC]
	set 6, a ; window tile map = $9c00
	ld [rLCDC], a
	ld a, [wStatusScreenPage]
	and %11111100
	or $1
	ld [wStatusScreenPage], a
	ret

StatusScreen_ShowPage2:
	callba WaitForVBlank
	ld a, [rLCDC]
	res 6, a ; window tile map = $9800
	ld [rLCDC], a
	ld a, [wStatusScreenPage]
	and %11111100
	or $2
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
	; On CGB, GBPalWhiteOut first changes the DMG compatibility registers; the
	; converted hardware palettes are committed by the following VBlank hook.
	; WaitForVBlank only checks the current LCD mode and can return inside the
	; already-running VBlank, exposing Page 1 for one frame on a fast Page-2 exit.
	call DelayFrame
	callba WaitForVBlank
	ld a, [rLCDC]
	set 6, a ; restore the project's normal window tile map at $9c00
	ld [rLCDC], a
	; Restore START Party's cached overworld BG0 before returning. Other StatusScreen
	; callers take the far helper's immediate return path.
	callba Summary_MaybeRestoreOverworldBG0
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
	; Do not leak the Summary exit key or a held START/SELECT stat modifier into
	; the caller's Party/PC/START-menu input loop. This mirrors the project's
	; existing anti-input-penetration pattern used by other modal flows.
	xor a
	ld [wStatusScreenStatMode], a
	ld [wStatusScreenPage], a
	ld [wStatusScreenCommonTilesReady], a
	ld [hJoyHeld], a
	ld [hJoyPressed], a
	ld [hJoyReleased], a
	ld [hJoy5], a
	; START Party immediately restores/redraws its saved full-screen
	; tilemap, and RedrawPartyMenu already performs the required three-frame BG
	; transfer. Avoid clearing wTileMap and waiting another three frames here.
	ld a, [wStatusScreenStartPartyCaller]
	and a
	ret nz
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
	ld de, wBuffer + 2
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
	ld hl, wBuffer
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
