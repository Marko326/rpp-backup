; Preserve the live overworld BG0 across START Party Summary.
;
; Summary Page 2 uses vBGMap0 ($9800), which is also the overworld ring buffer.
; Instead of rebuilding the current map later with ReloadMapData/RedrawMapView,
; cache the exact visible 20x18 ring-buffer area before Summary touches it and
; restore it while Summary is still white on exit. vBGMap1 rows 20..31 are never
; touched by the project's normal 20x18 window transfer, leaving 384 scratch
; bytes in each VRAM bank; 20x18 needs 360 bytes. Bank 0 stores tile numbers and
; CGB VRAM bank 1 stores the matching attributes.

DEF SUMMARY_OVERWORLD_BG_CACHE EQU vBGMap1 + 20 * BG_MAP_WIDTH

Summary_RunStartPartyStatusScreen::
	; Preserve the START Party caller contract: START Party permits UP/DOWN live
	; switching and can reuse the HP/status/EXP graphics loaded by PartyMenuInit.
	ld a, $80
	ld [wStatusScreenPage], a
	ld a, 1
	ld [wStatusScreenCommonTilesReady], a
	ld [wStatusScreenStartPartyCaller], a
	predef StatusScreen
	xor a
	ld [wStatusScreenStartPartyCaller], a
	ret

Summary_MaybeCacheOverworldBG0::
	ld a, [wStatusScreenStartPartyCaller]
	and a
	ret z

Summary_CacheOverworldBG0::
	; StatusScreen has already white-outed the display. Disable LCD so both VRAM
	; banks can be copied without VBlank slicing or any visible intermediate state.
	call DisableLCD
	xor a
	ld [rVBK], a
	call .copyRingToScratch
	; This project deliberately leaves wGBC at 0 even in CGB mode, so it cannot
	; be used as a hardware discriminator. Page 2 overwrites the CGB attribute
	; plane in VRAM bank 1, therefore preserve it unconditionally. On DMG, rVBK
	; writes are ignored, making the second copy harmless.
	ld a, 1
	ld [rVBK], a
	call .copyRingToScratch
	xor a
	ld [rVBK], a
	jp EnableLCD

.copyRingToScratch
	ld a, [wMapViewVRAMPointer]
	ld l, a
	ld a, [wMapViewVRAMPointer + 1]
	ld h, a
	ld de, SUMMARY_OVERWORLD_BG_CACHE
	ld b, SCREEN_HEIGHT
.row
	push hl
	ld c, SCREEN_WIDTH
.col
	ld a, [hl]
	ld [de], a
	inc de
	; Move horizontally inside one 32-tile BG-map row. If the current ring phase
	; crosses x=31, wrap to x=0 without advancing to the next VRAM row.
	inc l
	ld a, l
	and BG_MAP_WIDTH - 1
	jr nz, .noXWrap
	ld a, l
	sub BG_MAP_WIDTH
	ld l, a
.noXWrap
	dec c
	jr nz, .col
	pop hl
	; Advance the saved ring-row start by 32 bytes and wrap $9c00 back to $9800.
	ld a, l
	add BG_MAP_WIDTH
	ld l, a
	jr nc, .noYCarry
	inc h
.noYCarry
	ld a, h
	and $03
	or $98
	ld h, a
	dec b
	jr nz, .row
	ret

Summary_MaybeRestoreOverworldBG0::
	ld a, [wStatusScreenStartPartyCaller]
	and a
	ret z

Summary_RestoreOverworldBG0::
	; StatusScreen_Exit has just synchronized to VBlank with the display white, so
	; DisableLCD normally succeeds immediately. Restore the exact old ring phase.
	call DisableLCD
	xor a
	ld [rVBK], a
	call .copyScratchToRing
	; Restore the matching CGB attributes as well as the tile numbers. Do not test
	; wGBC here; see the cache-side note above.
	ld a, 1
	ld [rVBK], a
	call .copyScratchToRing
	xor a
	ld [rVBK], a
	jp EnableLCD

.copyScratchToRing
	ld hl, SUMMARY_OVERWORLD_BG_CACHE
	ld a, [wMapViewVRAMPointer]
	ld e, a
	ld a, [wMapViewVRAMPointer + 1]
	ld d, a
	ld b, SCREEN_HEIGHT
.row
	push de
	ld c, SCREEN_WIDTH
.col
	ld a, [hli]
	ld [de], a
	inc e
	ld a, e
	and BG_MAP_WIDTH - 1
	jr nz, .noXWrap
	ld a, e
	sub BG_MAP_WIDTH
	ld e, a
.noXWrap
	dec c
	jr nz, .col
	pop de
	ld a, e
	add BG_MAP_WIDTH
	ld e, a
	jr nc, .noYCarry
	inc d
.noYCarry
	ld a, d
	and $03
	or $98
	ld d, a
	dec b
	jr nz, .row
	ret

Summary_RestoreStartMenuFromParty::
	; Fold the old pre-restore whiteout wait and the two separate
	; LCD-off graphics restores into one phase. DMG/SGB become white immediately
	; through BGP/OBP; once LCD is off, explicitly whiten CGB palette RAM too so
	; no stale Party palette can flash when LCD is enabled again.
	call GBPalWhiteOut

	; Stop VBlank/OAM DMA before modifying wOAMBuffer. This closes the CGB timing
	; window where cleared sprite data could reach OAM while the previous Party
	; palette was still active.
	call DisableLCD
	call .loadWhiteCGBPalettesWhileLCDOff

	call ClearSprites
	ld a, 1
	ld [wUpdateSpritesEnabled], a

	; Mirror ReloadMapSpriteTilePatterns' wFontLoaded contract while combining its
	; LCD-off section with the overworld tileset/textbox restore.
	ld hl, wFontLoaded
	ld a, [hl]
	push af
	res 0, [hl]
	push hl
	xor a
	ld [wSpriteSetID], a
	callba InitMapSprites
	call LoadTilesetTilePatternData
	call LoadTextBoxTilePatterns
	call EnableLCD
	pop hl
	pop af
	ld [hl], a

	; These two routines intentionally remain LCD-on: the existing video-copy
	; pipeline schedules their data during VBlank and preserves its normal timing.
	call LoadPlayerSpriteGraphics
	call LoadFontTilePatterns
	call UpdateSprites

	; Restore the START tilemap saved before entering Party. The normal three-frame
	; window transfer is still required so both tile IDs and CGB attributes reach
	; vBGMap1; it now doubles as the only fixed restore wait on this path.
	call LoadScreenTilesFromBuffer2
	call RunDefaultPaletteCommand
	jp Delay3

.loadWhiteCGBPalettesWhileLCDOff
	; CGB white is RGB15 $7fff. Writes to these CGB-only registers are harmless on
	; DMG/SGB, while on CGB LCD-off access is unrestricted. Keep BGP/OBP at zero so
	; the normal palette pipeline also converges to white until LoadGBPal restores
	; the overworld mapping in the caller.
	ld a, $80
	ld [rBGPI], a
	ld b, 32
.bgLoop
	ld a, $ff
	ld [rBGPD], a
	ld a, $7f
	ld [rBGPD], a
	dec b
	jr nz, .bgLoop

	ld a, $80
	ld [rOBPI], a
	ld b, 32
.objLoop
	ld a, $ff
	ld [rOBPD], a
	ld a, $7f
	ld [rOBPD], a
	dec b
	jr nz, .objLoop
	ret
