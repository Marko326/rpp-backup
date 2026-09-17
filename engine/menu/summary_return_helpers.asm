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

DEF SUMMARY_PARTY_CALLER_NONE   EQU 0
DEF SUMMARY_PARTY_CALLER_START  EQU 1
DEF SUMMARY_PARTY_CALLER_BATTLE EQU 2

Summary_RunStartPartyStatusScreen::
	; START Party permits UP/DOWN live switching. Fall through to the shared Party
	; caller wrapper after selecting the START-specific mode.
	ld a, $80
	ld [wStatusScreenPage], a
	ld a, SUMMARY_PARTY_CALLER_START
Summary_RunPartyStatusScreen::
	; PartyMenu has just loaded the shared HP/status/EXP graphics. Mark the caller
	; explicitly and let StatusScreen consume that graphics-ready hint once.
	ld [wStatusScreenPartyCaller], a
	; Both Party caller enum values are nonzero, which is exactly the one-shot
	; contract wStatusScreenCommonTilesReady needs. Reuse A here so this shared
	; wrapper does not grow the existing large bank-$34 section.
	ld [wStatusScreenCommonTilesReady], a
	predef StatusScreen
	xor a ; SUMMARY_PARTY_CALLER_NONE
	ld [wStatusScreenPartyCaller], a
	ret

Summary_MaybeCacheOverworldBG0::
	ld a, [wStatusScreenPartyCaller]
	cp SUMMARY_PARTY_CALLER_START
	jr z, Summary_CacheOverworldBG0
	; Battle Party Summary Page 2 also overwrites vBGMap0. Preserve the fixed
	; battle BG so horizontal window shake can expose the original screen.
	cp SUMMARY_PARTY_CALLER_BATTLE
	ret nz

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
	ld a, [wStatusScreenPartyCaller]
	cp SUMMARY_PARTY_CALLER_BATTLE
	jr z, .battleBG0
	ld a, [wMapViewVRAMPointer]
	ld l, a
	ld a, [wMapViewVRAMPointer + 1]
	ld h, a
	jr .sourceReady
.battleBG0
	ld hl, vBGMap0
.sourceReady
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
	ld a, [wStatusScreenPartyCaller]
	cp SUMMARY_PARTY_CALLER_START
	jr z, Summary_RestoreOverworldBG0
	cp SUMMARY_PARTY_CALLER_BATTLE
	ret nz

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
	jp Summary_BattlePartyRestoreCommonTilesAndEnableLCD

.copyScratchToRing
	ld hl, SUMMARY_OVERWORLD_BG_CACHE
	ld a, [wStatusScreenPartyCaller]
	cp SUMMARY_PARTY_CALLER_BATTLE
	jr z, .battleBG0
	ld a, [wMapViewVRAMPointer]
	ld e, a
	ld a, [wMapViewVRAMPointer + 1]
	ld d, a
	jr .destReady
.battleBG0
	ld de, vBGMap0
.destReady
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
	call Summary_RestoreStartGraphicsFromParty

	; Normal START -> Party return exposes the saved START screen before input, so
	; keep the complete three-frame window transfer on this path.
	call LoadScreenTilesFromBuffer2
	call RunDefaultPaletteCommand
	jp Delay3

Summary_RestoreStartBagFromParty::
	; BAG-5.19.1: item use returns straight into StartMenu_Item. Restore the VRAM
	; content Party overwrote, and restore the saved START tilemap in WRAM only.
	; DisplayListMenuID redraws the Bag before its first visible transfer, so making
	; the intermediate START screen visible for three frames is redundant.
	call Summary_RestoreStartGraphicsFromParty
	call LoadScreenTilesFromBuffer2DisableBGTransfer
	jp RunDefaultPaletteCommand

Summary_RestoreStartGraphicsFromParty:
	; Fold the old pre-restore whiteout wait and the two separate
	; LCD-off graphics restores into one phase. DMG/SGB become white immediately
	; through BGP/OBP; once LCD is off, explicitly whiten CGB palette RAM too so
	; no stale Party palette can flash when LCD is enabled again.
	; Keep the old three-frame pre-LCD-off window: menu B/A SFX is advanced by
	; UpdateSound from VBlank, and disabling LCD immediately would freeze the
	; freshly-started SFX command and make the press sound audibly stretch.
	call GBPalWhiteOutWithDelay3

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
	pop hl
	pop af
	ld [hl], a

	; Party graphics overwrite both halves of the overworld sprite area and the
	; font. 47.9n restored the player through two CopyVideoData calls (four
	; VBlanks total) and then restored the 128-tile 1bpp font through
	; CopyVideoDataDouble (sixteen more VBlanks). The screen is already white and
	; the LCD is still disabled here, so restore the exact same final VRAM bytes
	; immediately instead of serialising those transfers across ~20 frames.
	xor a
	ld [rVBK], a
	call Summary_LoadPlayerSpriteGraphicsLCDOff
	call LoadFontTilePatterns
	call EnableLCD
	call UpdateSprites
	ret

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

Summary_LoadPlayerSpriteGraphicsLCDOff:
	; Match LoadPlayerSpriteGraphics' source selection and state corrections, but
	; copy the two 12-tile halves directly while LCD access is unrestricted.
	ld a, [wWalkBikeSurfState]
	dec a
	jr z, .ridingBike

	ld a, [hTilesetType]
	and a
	jr nz, .determineGraphics
	jr .startWalking

.ridingBike
	call IsBikeRidingAllowed
	jr c, .determineGraphics
.startWalking
	xor a
	ld [wWalkBikeSurfState], a
	ld [wWalkBikeSurfStateCopy], a
	jr .walking

.determineGraphics
	ld a, [wWalkBikeSurfState]
	and a
	jr z, .walking
	dec a
	jr z, .bike
	dec a
	jr z, .surf

.walking
	ld de, RedSprite
	ld a, [wPlayerGender]
	and a
	jr z, .walkingSourceReady
	ld de, LeafSprite
.walkingSourceReady
	ld a, BANK(RedSprite)
	jr .copySheet

.bike
	ld de, RedCyclingSprite
	ld a, [wPlayerGender]
	and a
	jr z, .bikeSourceReady
	ld de, LeafCyclingSprite
.bikeSourceReady
	ld a, BANK(RedSprite)
	jr .copySheet

.surf
	; Preserve GetSurfPlayerSpriteGraphics' Pikachu-validity contract. Bankswitch
	; preserves carry across the far call, which is all this test needs.
	ld a, [wd728]
	bit 2, a
	jr z, .surfSeel
	callba FindSurfingPikachuInParty
	jr c, .surfPikachu
	ld hl, wd728
	res 2, [hl]
.surfSeel
	ld de, SeelSprite
	ld a, BANK(SeelSprite)
	jr .copySheet
.surfPikachu
	ld de, SurfingPikachu
	ld a, BANK(SurfingPikachu)

.copySheet
	; The normal player loader copies 12 tiles to vNPCSprites and the following
	; 12 tiles to vNPCSprites2. Keep that layout and ordering exactly.
	ld h, d
	ld l, e
	push af
	push hl
	ld de, vNPCSprites
	ld bc, $0c * $10
	call FarCopyData2
	pop hl
	ld bc, $0c * $10
	add hl, bc
	pop af
	ld de, vNPCSprites2
	ld bc, $0c * $10
	jp FarCopyData2
