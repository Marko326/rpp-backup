; REG-5.62.118: opt-in two-part map key resolver.
; Call with DE = (region << 8) | local_map_id via callab/callba.
; On success: D = ROM bank, HL = map header address, carry clear.
; On failure: D = 0, HL = 0, carry set.  A/BC are not preserved.
; The returned bank is metadata: this routine does not leave it selected.
; Existing map IDs stay stable; aliasless future Johto locals share $FC,
; with current/last region/local saved in the existing reserved WRAM bytes.
ResolveRegionMapHeader::
	ld a, d
	cp MAP_REGION_JOHTO
	jr z, .johto
	cp MAP_REGION_KANTO
	jr nz, .invalid
.kanto
	ld a, e
	cp REGION_NATIVE_MAP_SLOT
	jr z, .invalid ; pseudo handle is never a Kanto physical map
	cp NUM_LEGACY_MAPS
	jr nc, .invalid
	; HOME-5.62.122: E survives callab; A is overwritten by Bankswitch.
	callab GetKantoMapHeaderPointer
	push hl
	ld a, e
	call GetKantoMapHeaderBank
	ld d, a
	pop hl
	and a
	ret
.johto
	ld a, e
	cp NUM_JOHTO_MAPS
	jr nc, .invalid
	ld l, e
	ld h, 0
	add hl, hl
	ld bc, JohtoMapHeaderPointers
	add hl, bc
	ld a, [hli]
	ld h, [hl]
	ld l, a
	push hl
	ld l, e
	ld h, 0
	ld bc, JohtoMapHeaderBanks
	add hl, bc
	ld d, [hl]
	pop hl
	and a
	ret
.invalid
	ld d, 0
	ld hl, 0
	scf
	ret

; A legacy one-byte ID can be translated to the new key without touching
; the saved value.  Use this only where the ID is known to be a map ID;
; not for the unrelated Town Map/Fly indices.
; Input: E = old map ID.  Output: DE = region/local map key.
LegacyMapIDToRegionKey::
	ld d, MAP_REGION_KANTO
	ld a, e
	cp NEW_BARK_TOWN
	jr z, .newBark
	cp JOHTO_ROUTE_29
	jr z, .route29
	cp JOHTO_CHERRYGROVE_CITY
	jr z, .cherrygrove
	cp JOHTO_ROUTE_30
	jr z, .route30
	cp JOHTO_ROUTE_31
	jr z, .route31
	cp JOHTO_ROUTE31_VIOLET_GATE
	jr z, .violetGate
	cp JOHTO_ROUTE_32
	jr z, .route32
	cp JOHTO_VIOLET_CITY
	ret nz
	ld d, MAP_REGION_JOHTO
	ld e, JOHTO_VIOLET_CITY_LOCAL_ID
	ret
.route32:
	ld d, MAP_REGION_JOHTO
	ld e, JOHTO_ROUTE_32_LOCAL_ID
	ret
.violetGate
	ld d, MAP_REGION_JOHTO
	ld e, JOHTO_ROUTE31_VIOLET_GATE_LOCAL_ID
	ret
.route31
	ld d, MAP_REGION_JOHTO
	ld e, JOHTO_ROUTE_31_LOCAL_ID
	ret
.route30
	ld d, MAP_REGION_JOHTO
	ld e, JOHTO_ROUTE_30_LOCAL_ID
	ret
.cherrygrove
	ld d, MAP_REGION_JOHTO
	ld e, JOHTO_CHERRYGROVE_LOCAL_ID
	ret
.route29
	ld d, MAP_REGION_JOHTO
	ld e, JOHTO_ROUTE_29_LOCAL_ID
	ret
.newBark
	ld d, MAP_REGION_JOHTO
	ld e, JOHTO_NEW_BARK_LOCAL_ID
	ret

; REG-5.62.119: while warps and connections still carry legacy one-byte IDs,
; derive both saved region fields from those IDs at every map-header load.
; This fills the compatible region fields for older saves at map load.
; Both fields are overwritten, not restored as independent saved-region keys.
; $E7 and $F4 are Johto locals $00/$01; other aliases are Kanto.
; Do not replace this with an unconditional reset once region-aware warps land.
SyncLegacyMapRegions::
	; A virtual map is keyed by the saved (region, local) pair. Legacy
	; map IDs remain authoritative for every pre-existing map/save.
	ld a, [wCurMap]
	cp REGION_NATIVE_MAP_SLOT
	jr nz, .currentLegacy
	ld a, [wRegionStateMagic0]
	cp REGION_STATE_MAGIC0
	jr nz, .badNative
	ld a, [wRegionStateMagic1]
	cp REGION_STATE_MAGIC1
	jr nz, .badNative
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	jr nz, .badNative
	ld a, [wCurLocalMapID]
	cp NUM_JOHTO_MAPS
	jr c, .lastMap
.badNative
	; Invalid or pre-migration $FC save: never use a random ROM pointer.
	ld a, JOHTO_VIOLET_CITY
	ld [wCurMap], a
.currentLegacy
	ld a, [wCurMap]
	ld e, a
	call LegacyMapIDToRegionKey
	ld a, d
	ld [wCurRegion], a
	ld a, e
	ld [wCurLocalMapID], a
.lastMap
	ld a, [wLastMap]
	cp REGION_NATIVE_MAP_SLOT
	jr nz, .lastLegacy
	ld a, [wRegionStateMagic0]
	cp REGION_STATE_MAGIC0
	jr nz, .badLast
	ld a, [wRegionStateMagic1]
	cp REGION_STATE_MAGIC1
	jr nz, .badLast
	ld a, [wLastRegion]
	cp MAP_REGION_JOHTO
	jr nz, .badLast
	ld a, [wLastLocalMapID]
	cp NUM_JOHTO_MAPS
	jr c, .magic
.badLast
	ld a, JOHTO_VIOLET_CITY
	ld [wLastMap], a
.lastLegacy
	ld a, [wLastMap]
	ld e, a
	call LegacyMapIDToRegionKey
	ld a, d
	ld [wLastRegion], a
	ld a, e
	ld [wLastLocalMapID], a
.magic
	ld a, REGION_STATE_MAGIC0
	ld [wRegionStateMagic0], a
	ld a, REGION_STATE_MAGIC1
	ld [wRegionStateMagic1], a
	ret

; REG-5.62.123: bidirectional ferry region-key route for the $FE escape.
; The source map / zero-based source warp slot AND the destination warp ID
; select the region target. This lets the same boat exit address both
; (JOHTO, New Bark local $00) and (KANTO, Vermilion Ferry Dock).
; Other islands keep legacy targets. Output: E = legacy destination alias.
; The far-call destroys A/BC/HL; return the alias in E instead of A.
; An invalid $FE entry returns the safe Vermilion ferry dock, never $FE.
ResolveExplicitRegionWarp::
	ld a, [wCurMap]
	cp REGION_NATIVE_MAP_SLOT
	jp z, ResolveNativeRegionWarp
	ld a, [wCurMap]
	ld b, a
	ld a, [wWarpedFromWhichWarp]
	ld c, a
	ld hl, ExplicitWarpRegionTargets
.loop
	ld a, [hli]
	cp $ff
	jr z, .invalid
	cp b
	jr nz, .skipWarp
	ld a, [hli]
	cp c
	jr nz, .skipThree
	ld a, [hli]
	ld d, a
	ld a, [wDestinationWarpID]
	cp d
	jr nz, .skipTwo
	ld d, [hl]
	inc hl
	ld e, [hl]
	call RecordJohtoCaveEscapeSource
	call StoreNativeWarpTarget
	jr c, .invalid
	ret
.skipWarp
	inc hl
.skipThree
	inc hl
.skipTwo
	inc hl
	inc hl
	jr .loop
.invalid
	ld d, MAP_REGION_KANTO
	ld e, VERMILION_FERRY_DOCK
	call StoreNativeWarpTarget
	ret

; Input DE = physical region/local ID. Return E = compatible old map ID,
; carry clear when registered. Do not convert Town Map or Fly indices here.
; New Johto local IDs explicitly register REGION_NATIVE_MAP_SLOT in the
; compatibility column; never reuse old map IDs or $FE/$FF.
RegionMapKeyToLegacyID::
	ld a, d
	cp MAP_REGION_KANTO
	jr z, .kanto
	cp MAP_REGION_JOHTO
	jr nz, .invalid
	ld a, e
	cp NUM_JOHTO_MAPS
	jr nc, .invalid
	ld l, e
	ld h, 0
	ld bc, JohtoMapLegacyAliases
	add hl, bc
	ld e, [hl]
	ld a, e
	cp $ff ; unregistered keys must never become writable destinations
	jr z, .invalid
	and a
	ret
.kanto
	ld a, e
	cp NUM_LEGACY_MAPS
	jr nc, .invalid
	cp NEW_BARK_TOWN ; $E7 is a Johto compatibility alias
	jr z, .invalid
	cp JOHTO_ROUTE_29 ; $F4 is reserved for Route 29
	jr z, .invalid
	cp JOHTO_CHERRYGROVE_CITY ; $CE is the pilot Cherrygrove alias
	jr z, .invalid
	cp JOHTO_ROUTE_30 ; $0B is the P2-2 Route 30 alias
	jr z, .invalid
	cp JOHTO_ROUTE_31 ; $F8 Route 31 is not a Kanto alias
	jr z, .invalid
	cp JOHTO_VIOLET_CITY ; $F9-$FB are Johto, never Kanto aliases
	jr nc, .invalid
	and a
	ret
.invalid
	scf
	ret

; Source map, zero-based source warp slot, destination warp ID,
; destination region, local ID. Destination warp 0 = New Bark;
; destination warp 2 = Vermilion dock. Both boat exit tiles are registered.
; No legacy mapObjects format or $FF LAST_MAP meaning is changed.
ExplicitWarpRegionTargets::
	db INSIDE_FERRY, 0, 0, MAP_REGION_JOHTO, JOHTO_NEW_BARK_LOCAL_ID
	db INSIDE_FERRY, 1, 0, MAP_REGION_JOHTO, JOHTO_NEW_BARK_LOCAL_ID
	db INSIDE_FERRY, 0, 2, MAP_REGION_KANTO, VERMILION_FERRY_DOCK
	db INSIDE_FERRY, 1, 2, MAP_REGION_KANTO, VERMILION_FERRY_DOCK
	db JOHTO_ROUTE_32, 0, 0, MAP_REGION_JOHTO, JOHTO_UNION_CAVE_1F_LOCAL_ID
	db $ff
ASSERT JOHTO_NEW_BARK_LOCAL_ID < NUM_JOHTO_MAPS
ASSERT VERMILION_FERRY_DOCK < NUM_LEGACY_MAPS

; Input DE = validated region/local warp target. Output E = map handle.
; Do not overwrite the saved native key with the compatibility handle.
StoreNativeWarpTarget::
	push de
	call RegionMapKeyToLegacyID
	jr c, .invalid
	pop bc
	ld a, b
	ld [wCurRegion], a
	ld a, c
	ld [wCurLocalMapID], a
	and a
	ret
.invalid
	pop bc
	scf
	ret

; MAP-5.62.192: remember only a verified outdoor-to-Union-Cave entrance.
; Reuse the existing saved (wLastMap, region, local) triple; no SRAM layout
; extension. DE is the resolved destination key; preserve it for caller.
; Importantly this runs BEFORE StoreNativeWarpTarget replaces source local ID.
RecordJohtoCaveEscapeSource::
	push de
	ld a, d
	cp MAP_REGION_JOHTO
	jp nz, .done
	ld a, e
	cp JOHTO_UNION_CAVE_1F_LOCAL_ID
	jp nz, .done
	ld a, [wWarpedFromWhichWarp]
	and a ; both outdoor entrances use source warp zero
	jp nz, .done
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	jp nz, .done
	ld a, [wCurMap]
	cp JOHTO_ROUTE_32
	jr z, .route32
	cp REGION_NATIVE_MAP_SLOT
	jp nz, .done
	ld a, [wCurLocalMapID]
	cp JOHTO_ROUTE_33_LOCAL_ID
	jp nz, .done
	ld a, [wDestinationWarpID]
	cp 1 ; Gold cave third warp, registered as RPP second warp
	jp nz, .done
	ld a, REGION_NATIVE_MAP_SLOT
	ld [wLastMap], a
	ld a, JOHTO_ROUTE_33_LOCAL_ID
	jr .saveLocal
.route32
	ld a, [wCurLocalMapID]
	cp JOHTO_ROUTE_32_LOCAL_ID
	jp nz, .done
	ld a, [wDestinationWarpID]
	and a
	jp nz, .done
	ld a, JOHTO_ROUTE_32
	ld [wLastMap], a
	ld a, JOHTO_ROUTE_32_LOCAL_ID
.saveLocal
	ld [wLastLocalMapID], a
	ld a, MAP_REGION_JOHTO
	ld [wLastRegion], a
.done
	pop de
	ret

; A native interior may use the same $FE warp escape as the ferry.
; Table key: source local ID, zero-based source warp, target warp,
; destination region, destination local ID. The caller is in Johto.
ResolveNativeRegionWarp::
	ld a, [wCurLocalMapID]
	ld b, a
	ld a, [wWarpedFromWhichWarp]
	ld c, a
	ld hl, NativeRegionWarpTargets
.loop
	ld a, [hli]
	cp $ff
	jr z, .invalid
	cp b
	jr nz, .skipFour
	ld a, [hli]
	cp c
	jr nz, .skipThree
	ld a, [hli]
	ld d, a
	ld a, [wDestinationWarpID]
	cp d
	jr nz, .skipTwo
	ld d, [hl]
	inc hl
	ld e, [hl]
	call RecordJohtoCaveEscapeSource
	call StoreNativeWarpTarget
	ret nc
	jr .invalid
.skipFour
	inc hl
.skipThree
	inc hl
.skipTwo
	inc hl
	inc hl
	jr .loop
.invalid
	; Fail closed: a malformed warp cannot jump to an arbitrary ID.
	ld d, MAP_REGION_JOHTO
	ld e, JOHTO_ROUTE_32_LOCAL_ID
	call StoreNativeWarpTarget
	ret

NativeRegionWarpTargets::
	; Cave warp 0 returns to the original Route32 cave-mouth warp 0.
	db JOHTO_UNION_CAVE_1F_LOCAL_ID, 0, 0, MAP_REGION_JOHTO, JOHTO_ROUTE_32_LOCAL_ID
	; Gold cave third warp to Route33 (RPP zero-based warp 1).
	db JOHTO_UNION_CAVE_1F_LOCAL_ID, 1, 0, MAP_REGION_JOHTO, JOHTO_ROUTE_33_LOCAL_ID
	; Route33 cave Warp enters at cave (17,31), index 1 of two registered.
	db JOHTO_ROUTE_33_LOCAL_ID, 0, 1, MAP_REGION_JOHTO, JOHTO_UNION_CAVE_1F_LOCAL_ID
	; ILEX-5.62.212: keep Gold Azalea x=2/y=10,11 and the south gate east x=9/y=4,5 unchanged.
	; Forest west of the gate now has separate audited twin Warp slots.
	db JOHTO_AZALEA_TOWN_LOCAL_ID, 0, 0, MAP_REGION_JOHTO, JOHTO_ILEX_AZALEA_GATE_LOCAL_ID
	db JOHTO_AZALEA_TOWN_LOCAL_ID, 1, 1, MAP_REGION_JOHTO, JOHTO_ILEX_AZALEA_GATE_LOCAL_ID
	db JOHTO_ILEX_AZALEA_GATE_LOCAL_ID, 0, 0, MAP_REGION_JOHTO, JOHTO_AZALEA_TOWN_LOCAL_ID
	db JOHTO_ILEX_AZALEA_GATE_LOCAL_ID, 1, 1, MAP_REGION_JOHTO, JOHTO_AZALEA_TOWN_LOCAL_ID
	; ILEX-5.62.212: Gold south gate west two lanes and matching Forest south return.
	db JOHTO_ILEX_AZALEA_GATE_LOCAL_ID, 2, 0, MAP_REGION_JOHTO, JOHTO_ILEX_FOREST_LOCAL_ID
	db JOHTO_ILEX_AZALEA_GATE_LOCAL_ID, 3, 1, MAP_REGION_JOHTO, JOHTO_ILEX_FOREST_LOCAL_ID
	db JOHTO_ILEX_FOREST_LOCAL_ID, 0, 2, MAP_REGION_JOHTO, JOHTO_ILEX_AZALEA_GATE_LOCAL_ID
	db JOHTO_ILEX_FOREST_LOCAL_ID, 1, 3, MAP_REGION_JOHTO, JOHTO_ILEX_AZALEA_GATE_LOCAL_ID
	db $ff

; Native connection lookup: source Johto local / direction / destination
; region / destination local. Direction index: north=0, south=1,
; west=2, east=3. Input D=direction, E=legacy connection-byte target.
; Output E=compatibility map handle. The updated native key is saved only
; if the connection explicitly names REGION_NATIVE_MAP_SLOT.
SelectNativeMapConnection::
	ld a, e
	cp REGION_NATIVE_MAP_SLOT
	ret nz
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	jr nz, .invalid
	ld a, [wCurLocalMapID]
	ld b, a
	ld c, d
	ld hl, NativeRegionConnectionTargets
.loop
	ld a, [hli]
	cp $ff
	jr z, .invalid
	cp b
	jr nz, .skipThree
	ld a, [hli]
	cp c
	jr nz, .skipTwo
	ld d, [hl]
	inc hl
	ld e, [hl]
	call StoreNativeWarpTarget
	ret nc
	jr .invalid
.skipThree
	inc hl
.skipTwo
	inc hl
	inc hl
	jr .loop
.invalid
	; Fence must prevent reaching an unregistered edge. Never load $FC
	; with a stale key if an entry is accidentally left out.
	ld e, JOHTO_ROUTE_32
	ret

NativeRegionConnectionTargets::
	; R33-5.62.191: Route32 SOUTH(1) reaches native Route33 local 9.
	db JOHTO_ROUTE_32_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_ROUTE_33_LOCAL_ID
	; MAP-5.62.195: modern Route33 west <-> modern AzaleaTown east.
	db JOHTO_ROUTE_33_LOCAL_ID, 2, MAP_REGION_JOHTO, JOHTO_AZALEA_TOWN_LOCAL_ID
	db JOHTO_AZALEA_TOWN_LOCAL_ID, 3, MAP_REGION_JOHTO, JOHTO_ROUTE_33_LOCAL_ID
	db $ff

; Route32's original Gold cave tile (6,79) is solid to generic RPP
; movement. Allow the one northward step from (6,80), then transfer on
; the actual (6,79) tile, not at the approach (6,80).
; This is independent of Kanto door tiles and native map-edge guards.
JohtoRoute32CaveEntranceCheck::
	ld a, [wXCoord]
	cp 6
	jr nz, .blocked
	ld a, [wYCoord]
	cp 80
	jr nz, .blocked
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_UP
	jr nz, .blocked
	scf
	ret
.blocked
	and a
	ret

; Only the actual Gold doorway tile may complete a step-on Route32 warp.
JohtoRoute32CaveWarpTileCheck::
	ld a, [wXCoord]
	cp 6
	jr nz, .blocked
	ld a, [wYCoord]
	cp 79
	jr nz, .blocked
	scf
	ret
.blocked
	and a
	ret

; Only arrivals that must leave an impassable doorway use
; simulated movement. Cave interiors stay on their Warp tile like Kanto's
; Victory Road; pressing toward the wall exits through a collision Warp.
; Data: destination handle/local/Y/X, incoming source handle, auto-step key.
; Source matching prevents a saved position or unrelated transfer from stepping.
; Input: current map state. Output E=joypad direction, or 0 for native fallback.
GetJohtoWarpArrivalStep::
	ld e, 0
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	ret nz
	ld a, [wCurMap]
	ld b, a
	ld a, [wCurLocalMapID]
	ld c, a
	ld hl, .profiles
.loop
	ld a, [hli]
	cp $ff
	ret z
	cp b
	jr nz, .skipFive
	ld a, [hli]
	cp c
	jr nz, .skipFour
	ld a, [hli]
	ld d, a
	ld a, [wYCoord]
	cp d
	jr nz, .skipThree
	ld a, [hli]
	ld d, a
	ld a, [wXCoord]
	cp d
	jr nz, .skipTwo
	ld a, [hli]
	ld d, a
	ld a, [wWarpedFromWhichMap]
	cp d
	jr nz, .skipOne
	ld e, [hl]
	ret
.skipFive
	inc hl
.skipFour
	inc hl
.skipThree
	inc hl
.skipTwo
	inc hl
.skipOne
	inc hl
	jr .loop
.profiles
	; Route32's solid cave-mouth art requires one step south after returning.
	db JOHTO_ROUTE_32, JOHTO_ROUTE_32_LOCAL_ID, 79, 6, REGION_NATIVE_MAP_SLOT, D_DOWN
	; Route33's Gold cave warp is a solid north-wall doorway too.
	db REGION_NATIVE_MAP_SLOT, JOHTO_ROUTE_33_LOCAL_ID, 9, 11, REGION_NATIVE_MAP_SLOT, D_DOWN
	db $ff

; Native cave entrances use the existing map transition SFX, not new audio.
; Input: current source/target warp state. Output E = SFX ID, or 0 for
; regular RPP Kanto/Johto door-tile processing in PlayMapChangeSound.
GetJohtoCaveMapChangeSFX::
	ld e, 0
	ld a, [wWarpedFromWhichMap]
	cp JOHTO_ROUTE_32
	jr z, .checkCaveEntry
	cp REGION_NATIVE_MAP_SLOT
	jr nz, .checkExit
	ld a, [wCurMap]
	cp REGION_NATIVE_MAP_SLOT
	jr nz, .checkExit
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	jr nz, .checkExit
	ld a, [wCurLocalMapID]
	cp JOHTO_UNION_CAVE_1F_LOCAL_ID
	jr nz, .checkExit
	ld e, SFX_GO_INSIDE
	ret
.checkCaveEntry
	ld a, [wCurMap]
	cp REGION_NATIVE_MAP_SLOT
	ret nz
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	ret nz
	ld a, [wCurLocalMapID]
	cp JOHTO_UNION_CAVE_1F_LOCAL_ID
	ret nz
	ld e, SFX_GO_INSIDE
	ret
.checkExit
	cp REGION_NATIVE_MAP_SLOT
	ret nz
	ld a, [wCurMap]
	cp JOHTO_ROUTE_32
	jr z, .confirmExit
	cp REGION_NATIVE_MAP_SLOT
	ret nz
.confirmExit
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	ret nz
	ld a, [wCurLocalMapID]
	cp JOHTO_ROUTE_32_LOCAL_ID
	jr z, .playExit
	cp JOHTO_ROUTE_33_LOCAL_ID
	ret nz
.playExit
	ld e, SFX_GO_OUTSIDE
	ret

; Route33's warp tile must only fire at its real Gold (11,9) coordinate.
; Called only on native Route33; no generic JOHTO_MODERN warp permission.
JohtoRoute33CaveWarpTileCheck::
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	jr nz, .reject
	ld a, [wCurLocalMapID]
	cp JOHTO_ROUTE_33_LOCAL_ID
	jr nz, .reject
	ld a, [wYCoord]
	cp 9
	jr nz, .reject
	ld a, [wXCoord]
	cp 11
	jr nz, .reject
	scf
	ret
.reject
	and a
	ret
