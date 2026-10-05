; MENU-5.62.11: lightweight START rendering and close/redisplay helpers.
; START reuses the map-name sign's resident bank-1 font/textbox graphics on first open.
; Legacy submenus still receive the Bank-0 text contract they expect, and direct close
; restores only the saved 20x18 tilemap instead of rebuilding the whole overworld.

StartMenuUseBank1Text::
	ld e,1 << OAM_TILE_BANK
	jr StartMenuSetTextVRAMBank

StartMenuUseBank0Text::
	ld e,0

StartMenuSetTextVRAMBank:
	; The stack lives in switchable WRAM. Never push in one rSVBK bank and pop in
	; another: keep the caller bank in B until Bank 2 is selected, then save BC on
	; the Bank-2 stack and pop it again before switching back.
	ld a,[rSVBK]
	ld b,a
	; Event/map state lives in the normal switchable WRAM bank. Resolve START's
	; height and the optional Safari counter box before selecting color WRAM bank 2.
	xor a
	ld [rSVBK],a
	ld d,START_MENU_HEIGHT_WITHOUT_DEX
	CheckEvent EVENT_GOT_POKEDEX
	jr z,.rowsReady
	ld d,START_MENU_HEIGHT_WITH_DEX
.rowsReady
	ld c,0
	ld a,[wCurMap]
	cp SAFARI_ZONE_EAST
	jr c,.safariReady
	cp UNKNOWN_DUNGEON_2
	jr nc,.safariReady
	inc c
.safariReady
	ld a,2
	ld [rSVBK],a
	push bc ; B = caller rSVBK, C = Safari flag; push/pop both occur in Bank 2
	ld a,[W2_TileBasedPalettes]
	and a
	jr z,.staticMap

	; Textbox border starts at tile $79; font/space/cursor tiles continue through $ff.
	ld hl,W2_TilesetPaletteMap + $79
	ld b,$100 - $79
.tileLoop
	ld a,[hl]
	res OAM_TILE_BANK,a
	or e
	ld [hli],a
	dec b
	jr nz,.tileLoop
	pop bc
	ld a,b
	ld [rSVBK],a
	ret

.staticMap
	; The START rectangle uses shared geometry so future menu-size changes update
	; drawing and CGB attributes together.
	ld b,d
	ld hl,W2_TilesetPaletteMap + START_MENU_X
.rowLoop
	ld c,START_MENU_WIDTH
.colLoop
	ld a,[hl]
	res OAM_TILE_BANK,a
	or e
	ld [hli],a
	dec c
	jr nz,.colLoop
	ld a,SCREEN_WIDTH - START_MENU_WIDTH
	add l
	ld l,a
	jr nc,.nextRow
	inc h
.nextRow
	dec b
	jr nz,.rowLoop

	; Recover caller bank + Safari flag while still in Bank 2. D is free now because
	; the main rectangle row count has been consumed. Preserve caller bank there.
	pop bc
	ld d,b
	ld a,c
	and a
	jr z,.staticMapDone
	; Safari START also owns the counter box at the upper-left. Static palette maps
	; are cell-based, so mark this second rectangle explicitly.
	ld hl,W2_TilesetPaletteMap
	ld b,START_MENU_SAFARI_HEIGHT
.safariRowLoop
	ld c,START_MENU_SAFARI_WIDTH
.safariColLoop
	ld a,[hl]
	res OAM_TILE_BANK,a
	or e
	ld [hli],a
	dec c
	jr nz,.safariColLoop
	ld a,SCREEN_WIDTH - START_MENU_SAFARI_WIDTH
	add l
	ld l,a
	jr nc,.nextSafariRow
	inc h
.nextSafariRow
	dec b
	jr nz,.safariRowLoop
.staticMapDone
	ld a,3
	ld [W2_StaticPaletteMapChanged],a
	ld a,d
	ld [rSVBK],a
	ret

StartMenuPrepareRedisplay::
; First open snapshots the live overworld tile buffer and uses resident Bank-1 text.
; After the session enters the legacy Bank-0 text path, keep redisplays on Bank 0 so
; runtime graphics/options changes cannot expose a stale Bank-1 textbox copy.
	ld a,[wStartMenuSavedMenuItem]
	bit START_MENU_FULL_RESTORE_F,a
	jr nz,.submenuReturn
	call SaveScreenTilesToBuffer2
	call StartMenuUseBank1Text
	jr .enableTransfer
.submenuReturn
	call StartMenuUseBank0Text
.enableTransfer
	ld a,1
	ld [H_AUTOBGTRANSFERENABLED],a
	ret

StartMenuPrepareSubmenuText::
; Legacy START submenus assume DisplayTextIDInit already loaded the font into Bank 0.
; Defer that cost until a real submenu is selected. Save the complete START tilemap
; first so the submenu can restore it before RedisplayStartMenu.
	ld hl,wStartMenuSavedMenuItem
	set START_MENU_FULL_RESTORE_F,[hl]
	call SaveScreenTilesToBuffer2
	xor a
	ld [rVBK],a
	ld de,FontGraphics
	ld hl,vFont
	lb bc, BANK(FontGraphics), (FontGraphicsEnd - FontGraphics) / $8
	call CopyVideoDataDoubleStartMenu
	jp StartMenuUseBank0Text

StartMenuPrepareClose::
; Carry returns set whenever this START session used the legacy Bank-0 text path
; (submenu or auto-text fallback); HOME then resumes the proven full restore tail.
	ld a,[wStartMenuSavedMenuItem]
	bit START_MENU_FULL_RESTORE_F,a
	jr nz,.fullRestore

; Fast path: START never overwrote Bank-0 sprite graphics. Restore the 20x18 WRAM
; snapshot before overworld control resumes; no map rebuild or VRAM graphics reload.
	ld a,$90
	ld [hWY],a
	call DelayFrame
	call LoadGBPal
	call LoadScreenTilesFromBuffer2DisableBGTransfer
	call StartMenuUseBank0Text

	; Keep the normal DisplayTextID facing-direction contract.
	ld hl,wSpriteStateData2 + $19
	ld c,$0f
	ld de,$0010
.restoreSpriteFacingDirectionLoop
	ld a,[hl]
	dec h
	ld [hl],a
	inc h
	add hl,de
	dec c
	jr nz,.restoreSpriteFacingDirectionLoop
	ld hl,wFontLoaded
	res 0,[hl]
	and a ; clear carry: no HOME map restore needed
	ret

.fullRestore
; The legacy path is already using Bank 0. Restore textbox/roof graphics, hide the
; Window, then let HOME resume after the normal CloseTextDisplay hide stage.
	call LoadTextBoxTilePatterns
	ld a,$90
	ld [hWY],a
	call DelayFrame
	call LoadGBPal
	xor a
	ld [H_AUTOBGTRANSFERENABLED],a
	call StartMenuUseBank0Text
	scf
	ret

StartMenuFinishWhiteReturn::
	; MENU-5.62.11: CGB can commit BG before OBJ, and row/column redraw can defer
	; palette writes for a VBlank. Keep BG white during the existing three START
	; transfer frames, explicitly arm the OBJ producer, then wait only while the
	; producer/consumer handshake says the real OBJ palette commit is still pending.
	xor a
	ld [wUpdateSpritesEnabled],a
	call LoadGBPal
	xor a
	ld [rBGP],a

	; Force one known OBJ transaction so the wait below cannot mistake unchanged
	; OBP registers for a palette that has already reached real CGB palette RAM.
	ld a,[rSVBK]
	ld b,a
	ld a,2
	ld [rSVBK],a
	ld a,1
	ld [W2_ForceOBPUpdate],a
	ld a,b
	ld [rSVBK],a

	call Delay3
.waitForObjPaletteCommit
	; W2_ForceOBPUpdate is cleared after pre-VBlank prepares the converted OBJ
	; buffer. W2_SprPaletteDataModified is cleared only after VBlank actually writes
	; that buffer to CGB OBJ palette RAM. A row/column redraw leaves the latter set,
	; so this loop naturally waits exactly one more frame when that collision occurs.
	ld a,[rSVBK]
	ld b,a
	ld a,2
	ld [rSVBK],a
	ld a,[W2_ForceOBPUpdate]
	ld c,a
	ld a,[W2_SprPaletteDataModified]
	or c
	ld c,a
	ld a,b
	ld [rSVBK],a
	ld a,c
	and a
	jr z,.objPaletteReady
	call DelayFrame
	jr .waitForObjPaletteCommit
.objPaletteReady
	ld a,1
	ld [wUpdateSpritesEnabled],a
	jp LoadGBPal
