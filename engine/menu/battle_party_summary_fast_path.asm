; Battle Party <-> Summary fast path.
;
; Kept in its own floating ROMX section in bank $34 so the optimization does not
; enlarge ROM0 Home or capacity-constrained battle bank $0F sections.

Summary_DisplayBattlePartyMenu::
	; DisplayBattleMenu turns the selected Pokémon cursor into the parent-menu
	; outline arrow before dispatching here, and PartyMenuOrRockOrRun has already
	; snapshotted that tile into wTileMapBackup2. The Party covers the full screen,
	; so the parent marker is unnecessary. Remove it from the saved battle-menu
	; frame now; otherwise the fast return can briefly restore the stale $EC tile
	; before AutoBG's three one-third transfers have all caught up.
	ld hl, wTileMapBackup2 + 14 * SCREEN_WIDTH + 15
	ld [hl], " "

	; Battle's normal Pokémon command does not need DisplayPartyMenu's two staged
	; three-frame blank transfers. White out, stop AutoBG, then prepare all shared
	; Party VRAM while the LCD is already off. Only the final RedrawPartyMenu
	; transfer remains visible/synchronized.
	ld a, [hTilesetType]
	push af
	xor a
	ld [hTilesetType], a
	call GBPalWhiteOut
	ld [H_AUTOBGTRANSFERENABLED], a
	call ClearSprites
	call UpdateSprites
	call DisableLCD

	; Load the graphics PartyMenuInit normally uploads with the LCD enabled.
	; GoodCopyVideoData detects LCD-off and copies these immediately.
	call LoadHpBarAndStatusTilePatterns

	; Clear only the WRAM tilemap. There is no reason to transfer this intermediate
	; blank screen because RedrawPartyMenu will transfer the completed Party page.
	coord hl, 0, 0
	ld bc, SCREEN_WIDTH * SCREEN_HEIGHT
	ld a, " "
	call FillMemory

	; Reuse the stock party-icon loader from its zero-byte LCD-off entry. Its tail
	; enables the LCD, after which the stock Party redraw performs the final Delay3.
	callba LoadMonPartySpriteGfxLCDOff
	call PartyMenuInitState
	call RedrawPartyMenu
	jr Summary_HandleBattlePartyMenuInput

Summary_RunBattlePartyStatusScreen::
	; Reuse the existing Summary live-switch contract used by START Party and
	; Bill's PC. Release the direction that selected Stats first, then grant the
	; ordinary PLAYER_PARTY_DATA switch pipeline permission through bit 7.
	callba Summary_WaitForVerticalRelease
	ld a, 1 << STATUS_SCREEN_MON_SWITCH_F
	ld [wStatusScreenPage], a
	ld a, SUMMARY_PARTY_CALLER_BATTLE
	jp Summary_RunPartyStatusScreen

Summary_BattlePartyRestoreCommonTilesAndEnableLCD::
	; Summary_RestoreOverworldBG0 reaches here with LCD off and rVBK=0. For the
	; Battle Party caller, restore shared Party graphics immediately instead of
	; serializing the same upload over six VBlanks after LCD is enabled.
	ld a, [wStatusScreenPartyCaller]
	cp SUMMARY_PARTY_CALLER_BATTLE
	jr nz, .enableLCD
	call LoadHpBarAndStatusTilePatterns
.enableLCD
	jp EnableLCD

Summary_GoBackToBattlePartyMenu::
	; Summary already restored the shared Party graphics while LCD was off. Reuse
	; PartyMenuInit's state-only entry instead of copying that ROM0 logic here.
	ld a, [hTilesetType]
	push af
	xor a
	ld [hTilesetType], a
	call PartyMenuInitState
	call RedrawPartyMenu

Summary_HandleBattlePartyMenuInput:
	; HandlePartyMenuInput normally returns through BankswitchBack because stock
	; PartyMenuInit switched to bank 1. These bank-$34 fast paths intentionally skip
	; that switch, so make the stock exit restore $34; the outer callba then restores
	; the original battle bank.
	ld a, BANK(Summary_DisplayBattlePartyMenu)
	ld [wBankswitchHomeSavedROMBank], a
	jp HandlePartyMenuInput

Summary_BattlePartyRestoreEnemyFrontPicIfDirty::
	ld a, [wBattlePartySummaryEnemyPicDirty]
	and a
	ret z
	xor a
	ld [wBattlePartySummaryEnemyPicDirty], a

	; Stock post-Summary enemy-picture restore, relocated from capacity-constrained
	; battle bank $0F to this dedicated bank-$34 section.
	ld a, [wEnemyBattleStatus2]
	bit HasSubstituteUp, a
	ld hl, AnimationSubstitute
	jr nz, .doEnemyMonAnimation
	ld a, [wEnemyMonMinimized]
	and a
	ld hl, AnimationMinimizeMon
	jr nz, .doEnemyMonAnimation
	ld a, [wEnemyMonSpecies]
	ld [wcf91], a
	ld [wd0b5], a
	call GetMonHeader
	ld de, vFrontPic
	jp LoadMonFrontSprite
.doEnemyMonAnimation
	ld a, 1
	ld [H_WHOSETURN], a
	ld b, BANK(AnimationSubstitute) ; BANK(AnimationMinimizeMon)
	jp Bankswitch
