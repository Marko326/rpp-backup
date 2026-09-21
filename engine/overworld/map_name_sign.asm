; MAPFLOOR-5.19.42
; Crystal-style map-name sign for Red++ / Blue++.
;
; The sign follows the player's physical map landmark rather than Fly/Town Map POI
; aliases. Ordinary one-room interiors inherit their surrounding city/route; transit
; maps keep the previous landmark; Celadon Dept. Store floors are neutral so the
; rooftop remains distinct until the player actually exits back to Celadon City.
; MAPFLOOR-5.19.42 adds a separate floor identity without duplicating Town Map names;
; step 1 enables Silph Co. 1F-11F while keeping its elevator neutral.
;
; BG/window graphics are deliberately kept in CGB VRAM bank 1. Bank 0 remains owned
; by the normal overworld tiles, textbox/roof graphics, and NPC walking frames.

DEF MAP_NAME_SIGN_ATTR        EQU PAL_BG_TEXT | (1 << OAM_TILE_BANK) | (1 << OAM_PRIORITY)
; Text scratch starts after the 20x4 frame in wTileMapBackup2.
; Do not define this with EQU: wTileMapBackup2 is a relocatable WRAM label in RGBDS 0.5.2.

LoadMapNameSignGFX::
; Called by LoadMapData with the LCD disabled. Keep a private copy of the normal
; font/textbox graphics in VRAM bank 1 so the popup never overwrites overworld VRAM.
; InterruptWrapper does not preserve rVBK, so mask all interrupt sources while
; bank 1 is selected instead of changing the caller's IME state with di/ei.
	ld a, [rIE]
	push af
	xor a
	ld [rIE], a
	ld a, 1
	ld [rVBK], a
	call LoadFontTilePatterns
	call LoadTextBoxTilePatterns
	xor a
	ld [rVBK], a
	pop af
	ld [rIE], a
	ret

PrimeMapNameSignForWarpPad::
; MAPFLOOR-5.19.44: warp-pad destinations are already loaded before EnterMapAnim.
; Prime the destination sign before the target floor fades in, so sprites/background
; details at the bottom cannot appear briefly before the Window covers them.
; Fly also uses wd732 bit 3, so keep Fly timing unchanged via wFlags_D733 bit 7.
	ld a, [wd732]
	bit 3, a
	ret z
	ld a, [wFlags_D733]
	bit 7, a
	ret nz
	jp UpdateMapNameSign

UpdateMapNameSign::
; Called once per normal overworld frame.
; A raw map change triggers a fresh Town Map landmark lookup; the popup appears only
; when the resolved name pointer actually changes.
	ld a, [wMapNameSignNamePtr + 1]
	and a
	jr z, .mapChanged ; WRAM starts at 0, so initialize even if the first map ID is 0

	ld a, [wCurMap]
	ld b, a
	ld a, [wMapNameSignLastMap]
	cp b
	jr nz, .mapChanged

	ld a, [wMapNameSignTimer]
	and a
	ret z

	; Menus/dialogue/field effects also own the Window. If another owner moved it,
	; do not resurrect a stale map sign when normal overworld control resumes.
	ld a, [H_AUTOBGTRANSFERENABLED]
	and a
	jr nz, .cancel
	ld a, [hWY]
	cp MAP_NAME_SIGN_Y
	jr nz, .cancel
	ld a, [rWY]
	cp MAP_NAME_SIGN_Y
	jr nz, .cancel

	ld hl, wMapNameSignTimer
	dec [hl]
	ret nz
.hide
	ld a, SCREEN_HEIGHT_PIXELS
	ld [hWY], a
	ld [rWY], a
	ret

.cancel
	xor a
	ld [wMapNameSignTimer], a
	jr .hide

.mapChanged
	; MAPSIGN-5.19.41: do not hide an already-visible sign before we know what
	; the new effective landmark is. If the new map needs another sign, keep the
	; Window at Y=112 and atomically replace its four rows during VBlank. This
	; matches Crystal's continuous frame behavior when crossing landmarks.
	ld a, [wCurMap]
	ld [wMapNameSignLastMap], a

	; MAPSIGN-5.19.40: transit maps inherit the previous effective landmark.
	; This prevents same-route gates (Route 12/15/16/18, etc.) from forcing a
	; duplicate route popup when the player exits on either side. Celadon Dept.
	; Store 1F-5F/elevator use the same neutral rule so Roof -> floor does not
	; immediately pop CELADON CITY; it appears only after leaving the building.
	call .IsNeutralMap
	jr nz, .resolveLandmark
	ld a, [wMapNameSignNamePtr + 1]
	and a
	jp nz, .cancel ; already initialized: preserve the previous effective landmark

	; Loading a save directly inside a neutral map still needs a stable initial
	; landmark. Resolve its physical surroundings once, but never display it.
	; B returns the optional floor identity (0 = none).
	call .ResolvePhysicalLandmark
	jp .storeWithoutShowing

.resolveLandmark
	; MAPFLOOR-5.19.42: HL is the base landmark name and B is a separate floor tag.
	; Keeping them separate lets every Silph floor share SilphCoName while still
	; treating 1F -> 2F, warp pads, etc. as real map-sign transitions.
	call .ResolvePhysicalLandmark

	ld a, [wMapNameSignNamePtr + 1]
	and a
	jr z, .storeWithoutShowing

	ld a, [wMapNameSignNamePtr]
	cp l
	jr nz, .newLandmark
	ld a, [wMapNameSignNamePtr + 1]
	cp h
	jr nz, .newLandmark
	ld a, [wMapNameSignFloor]
	cp b
	jr z, .sameLandmark

.newLandmark
	ld a, l
	ld [wMapNameSignNamePtr], a
	ld a, h
	ld [wMapNameSignNamePtr + 1], a
	ld a, b
	ld [wMapNameSignFloor], a

	; Match Crystal's notable no-sign landmarks where this project has an
	; equivalent Town Map name. Unknown pseudo locations are also never shown.
	ld de, AreaUnknownText
	call .CompareNamePointer
	jp z, .cancel
	ld de, UndergroundPathName
	call .CompareNamePointer
	jp z, .cancel
	ld de, IndigoPlateauName
	call .CompareNamePointer
	jp z, .cancel

	; The resolved name itself lives in bank $1c. Copy a bounded 20-byte window
	; into private scratch just after the 4-row frame, then flatten Town Map's '_'
	; line break locally. This avoids clobbering the globally shared wBuffer.
	; This keeps the nearly-full bank $1c completely untouched.
	call .CopyMapNameToBuffer
	call .BuildMapNameSign
	call .CopyMapNameSignToWindow
	ld a, MAP_NAME_SIGN_FRAMES
	ld [wMapNameSignTimer], a
	ret

.storeWithoutShowing
	ld a, l
	ld [wMapNameSignNamePtr], a
	ld a, h
	ld [wMapNameSignNamePtr + 1], a
	ld a, b
	ld [wMapNameSignFloor], a
.sameLandmark
	; Same/neutral/no-sign transitions should still retire an old popup immediately.
	jp .cancel

.CompareNamePointer
; Compare current landmark pointer in wMapNameSignNamePtr against DE.
	ld a, [wMapNameSignNamePtr]
	cp e
	ret nz
	ld a, [wMapNameSignNamePtr + 1]
	cp d
	ret

.ResolvePhysicalLandmark
; Resolve the map-name sign from the real loaded map.
; out: HL = base landmark name pointer, B = optional floor identity (0 = none).
; MAPFLOOR-5.19.42 keeps floor identity separate from the shared Town Map name, so
; later multi-floor sites can reuse the same mechanism without adding duplicate names.
	call .ResolveSilphFloor
	ret c
	ld a, [wCurMap]
	cp ROCK_TUNNEL_POKECENTER
	jr z, .route10
	cp BILLS_HOUSE
	jr z, .route25
	cp DIGLETTS_CAVE_EXIT
	jr z, .route2
	cp DIGLETTS_CAVE_ENTRANCE
	jr z, .route11
	cp SAFARI_ZONE_ENTRANCE
	jr z, .fuchsiaCity
	ld e, a
	callab LoadTownMapEntryFromE
	ld b, 0
	ret
.route2
	ld e, ROUTE_2
	jr .load
.route10
	ld e, ROUTE_10
	jr .load
.route11
	ld e, ROUTE_11
	jr .load
.route25
	ld e, ROUTE_25
	jr .load
.fuchsiaCity
	ld e, FUCHSIA_CITY
.load
	callab LoadTownMapEntryFromE
	ld b, 0
	ret

.ResolveSilphFloor
; Step 1 floor table. Carry = set when wCurMap is a real Silph Co. floor.
; The elevator is intentionally excluded and handled as a neutral transit map.
	ld a, [wCurMap]
	ld c, a
	ld hl, .SilphFloorMapList
.loopSilphFloors
	ld a, [hli]
	cp $ff
	jr z, .notSilphFloor
	cp c
	jr z, .silphFloorFound
	inc hl ; skip floor tag
	jr .loopSilphFloors
.silphFloorFound
	ld b, [hl]
	ld hl, SilphCoName
	scf
	ret
.notSilphFloor
	and a ; clear carry
	ret

.SilphFloorMapList
	db SILPH_CO_1F, 1
	db SILPH_CO_2F, 2
	db SILPH_CO_3F, 3
	db SILPH_CO_4F, 4
	db SILPH_CO_5F, 5
	db SILPH_CO_6F, 6
	db SILPH_CO_7F, 7
	db SILPH_CO_8F, 8
	db SILPH_CO_9F, 9
	db SILPH_CO_10F, 10
	db SILPH_CO_11F, 11
	db $ff

.IsNeutralMap
; Z = set for maps that must not become a new effective map-sign landmark.
; Safari rest houses are deliberately not listed: they already resolve to Safari
; Zone and therefore behave like ordinary one-room interiors.
	ld a, [wCurMap]
	ld c, a
	ld hl, .NeutralMapList
.loopNeutralMaps
	ld a, [hli]
	cp c
	ret z
	cp $ff
	jr nz, .loopNeutralMaps
	or 1 ; force NZ for the terminator
	ret

.NeutralMapList
	db VIRIDIAN_FOREST_EXIT, ROUTE_2_GATE, VIRIDIAN_FOREST_ENTRANCE
	db ROUTE_5_GATE, PATH_ENTRANCE_ROUTE_5
	db ROUTE_6_GATE, PATH_ENTRANCE_ROUTE_6
	db ROUTE_7_GATE, PATH_ENTRANCE_ROUTE_7, PATH_ENTRANCE_ROUTE_7_COPY
	db ROUTE_8_GATE, PATH_ENTRANCE_ROUTE_8
	db ROUTE_11_GATE_1F, ROUTE_11_GATE_2F
	db ROUTE_12_GATE_1F, ROUTE_12_GATE_2F
	db ROUTE_15_GATE_1F, ROUTE_15_GATE_2F
	db ROUTE_16_GATE_1F, ROUTE_16_GATE_2F
	db ROUTE_18_GATE_1F, ROUTE_18_GATE_2F
	db ROUTE_19_GATE, ROUTE_22_GATE, SAFARI_ZONE_ENTRANCE
	db DIGLETTS_CAVE_EXIT, DIGLETTS_CAVE_ENTRANCE
	; MAPFLOOR-5.19.42: Silph elevator inherits the floor last visited. Exiting
	; onto another floor then compares that floor tag and shows the destination.
	db SILPH_CO_ELEVATOR
	; Keep the rooftop distinct while ordinary department-store floors/elevator
	; merely bridge between it and Celadon City.
	db CELADON_MART_1, CELADON_MART_2, CELADON_MART_3, CELADON_MART_4
	db CELADON_MART_5, CELADON_MART_ELEVATOR
	db $ff

.CopyMapNameToBuffer
; Copy enough bytes for every Town Map name (validated <= 18 rendered columns).
	ld a, [wMapNameSignNamePtr]
	ld l, a
	ld a, [wMapNameSignNamePtr + 1]
	ld h, a
	ld de, wTileMapBackup2 + 4 * SCREEN_WIDTH
	ld bc, SCREEN_WIDTH
	ld a, BANK(MapNames)
	call FarCopyData2
	ld hl, wTileMapBackup2 + 4 * SCREEN_WIDTH
.normalize
	ld a, [hl]
	cp "_"
	jr nz, .checkEnd
	ld [hl], " "
.checkEnd
	cp "@"
	jr z, .appendFloor
	inc hl
	jr .normalize

.appendFloor
; MAPFLOOR-5.19.42: append " nF" to the copied display text only. The base name
; pointer remains unchanged, while wMapNameSignFloor participates in identity checks.
	ld a, [wMapNameSignFloor]
	and a
	ret z
	ld [hl], " "
	inc hl
	ld b, a
	ld c, 0
	ld a, b
.countFloorTens
	cp 10
	jr c, .writeFloorDigits
	sub 10
	inc c
	jr .countFloorTens
.writeFloorDigits
	ld b, a ; ones digit
	ld a, c
	and a
	jr z, .writeFloorOnes
	add "0"
	ld [hli], a
.writeFloorOnes
	ld a, b
	add "0"
	ld [hli], a
	ld [hl], "F"
	inc hl
	ld [hl], "@"
	ret

.BuildMapNameSign
; Build a 20x4 frame in wTileMapBackup2 using graphics already mirrored in VRAM1.
	ld hl, wTileMapBackup2
	ld b, 2
	ld c, SCREEN_WIDTH - 2
	call TextBoxBorder

	; Count rendered width. $54 is the "Poké" dictionary token used by the three
	; Pokémon landmark names and expands to four visible characters.
	ld de, wTileMapBackup2 + 4 * SCREEN_WIDTH
	ld c, 0
.countName
	ld a, [de]
	inc de
	cp "@"
	jr z, .haveLength
	cp $54
	jr nz, .oneCharacter
	inc c
	inc c
	inc c
.oneCharacter
	inc c
	jr .countName
.haveLength
	ld a, SCREEN_WIDTH
	sub c
	srl a
	ld c, a
	ld b, 0
	ld hl, wTileMapBackup2 + 2 * SCREEN_WIDTH
	add hl, bc
	ld de, wTileMapBackup2 + 4 * SCREEN_WIDTH

	; PlaceString normally honors the global letter delay. Suppress it only while
	; constructing this off-screen tile buffer, then restore the caller's flags.
	ld a, [wd730]
	push af
	set 6, a
	ld [wd730], a
	call PlaceString
	pop af
	ld [wd730], a
	ret

.CopyMapNameSignToWindow
; Copy four rows to Window BG map $9c00 during a clean VBlank. Then write matching
; CGB attributes with palette 7 + VRAM bank 1 + BG priority, mirroring Crystal's
; text-palette/priority behavior without touching the normal overworld buffers.
;
; Always wait for a fresh VBlank rather than assuming the call happened early enough
; in the current one to finish both the tile and attribute copies safely. Mask all
; interrupt sources while waiting so InterruptWrapper cannot alter rVBK and the normal
; VBlank handler cannot consume the transfer window. Preserve the caller's IME state.
	ld a, [rIE]
	push af
	xor a
	ld [rIE], a
.waitVisible
	ld a, [rLY]
	cp SCREEN_HEIGHT_PIXELS
	jr nc, .waitVisible
.waitVBlank
	ld a, [rLY]
	cp SCREEN_HEIGHT_PIXELS
	jr c, .waitVBlank

	xor a
	ld [rVBK], a
	ld de, wTileMapBackup2
	ld hl, vBGMap1
	ld b, 4
.copyTileRow
	ld c, SCREEN_WIDTH
.copyTile
	ld a, [de]
	inc de
	ld [hli], a
	dec c
	jr nz, .copyTile
	ld a, BG_MAP_WIDTH - SCREEN_WIDTH
	add l
	ld l, a
	jr nc, .tileRowReady
	inc h
.tileRowReady
	dec b
	jr nz, .copyTileRow

	ld a, 1
	ld [rVBK], a
	ld hl, vBGMap1
	ld b, 4
.copyAttrRow
	ld c, SCREEN_WIDTH
	ld a, MAP_NAME_SIGN_ATTR
.copyAttr
	ld [hli], a
	dec c
	jr nz, .copyAttr
	ld a, BG_MAP_WIDTH - SCREEN_WIDTH
	add l
	ld l, a
	jr nc, .attrRowReady
	inc h
.attrRowReady
	dec b
	jr nz, .copyAttrRow

	xor a
	ld [rVBK], a
	ld a, 7
	ld [rWX], a
	ld a, MAP_NAME_SIGN_Y
	ld [hWY], a
	ld [rWY], a

	; This VBlank was intentionally owned by the sign transfer. Drop its pending
	; interrupt request so the normal handler cannot run late after VRAM is locked.
	ld a, [rIF]
	res 0, a
	ld [rIF], a
	pop af
	ld [rIE], a
	ret
