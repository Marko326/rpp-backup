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
	call GetJohtoActiveSlot
	ld a, e
	cp JOHTO_INVALID_ACTIVE_SLOT
	jr z, .invalid
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
; This derives region/local identity for maps that still use legacy handles; it is not a save conversion layer.
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
	ld e, a
	call GetJohtoActiveSlot
	ld a, e
	cp JOHTO_INVALID_ACTIVE_SLOT
	jr nz, .lastMap
.badNative
	; Corrupted/unsupported native save: refuse to load a random Header.
	; Do not silently teleport to Violet/Route32. Reset to title instead;
	; the save on disk is not overwritten by this rejection.
	jp SoftReset
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
	ld e, a
	call GetJohtoActiveSlot
	ld a, e
	cp JOHTO_INVALID_ACTIVE_SLOT
	jr nz, .magic
.badLast
	; Invalid return identity must never masquerade as a real city.
	ld a, $ff ; legacy LAST_MAP sentinel (no LAST_MAP EQU symbol)
	ld [wLastMap], a
	xor a
	ld [wLastRegion], a
	ld [wLastLocalMapID], a
	jr .magic
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
	call GetJohtoActiveSlot
	ld a, e
	cp JOHTO_INVALID_ACTIVE_SLOT
	jr z, .invalid
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
	cp JOHTO_CHERRYGROVE_CITY ; $CE is reserved and never a runtime city handle
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
; Cherrygrove local 2 uses the native resolver; only legacy-source Warps
; belong in this table. Its three house destinations live in NativeRegionWarpTargets.
	db INSIDE_FERRY, 0, 0, MAP_REGION_JOHTO, JOHTO_NEW_BARK_LOCAL_ID
	db INSIDE_FERRY, 1, 0, MAP_REGION_JOHTO, JOHTO_NEW_BARK_LOCAL_ID
	db INSIDE_FERRY, 0, 2, MAP_REGION_KANTO, VERMILION_FERRY_DOCK
	db INSIDE_FERRY, 1, 2, MAP_REGION_KANTO, VERMILION_FERRY_DOCK
	db JOHTO_ROUTE_32, 0, 0, MAP_REGION_JOHTO, JOHTO_UNION_CAVE_1F_LOCAL_ID
	; Route29 still uses its legacy $F4 alias, not native $FC as a source.
	db JOHTO_ROUTE_29, 0, 2, MAP_REGION_JOHTO, JOHTO_ROUTE_29_ROUTE_46_GATE_LOCAL_ID
	; Route32 is still legacy $FB. Its two added door carpets MUST use
	; the explicit legacy-source dispatcher, not NativeRegionWarpTargets.
	db JOHTO_ROUTE_32, 1, 2, MAP_REGION_JOHTO, JOHTO_ROUTE_32_RUINS_OF_ALPH_GATE_LOCAL_ID
	db JOHTO_ROUTE_32, 2, 3, MAP_REGION_JOHTO, JOHTO_ROUTE_32_RUINS_OF_ALPH_GATE_LOCAL_ID
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
	; Malformed native warp is not a license to send player to Route32.
	; Abort the session without changing the saved game on disk.
	jp SoftReset

NativeRegionWarpTargets::
 ; HOUSE DEV: city Gold Warp #5 is RPP sole outdoor warp 0, entering
 ; house warp 0. Two Gold house exits both return to that SAME outdoor #0.
 db JOHTO_OLIVINE_CITY_LOCAL_ID, 0, 0, MAP_REGION_JOHTO, JOHTO_OLIVINE_PUNISHMENT_SPEECH_HOUSE_LOCAL_ID
 db JOHTO_OLIVINE_PUNISHMENT_SPEECH_HOUSE_LOCAL_ID, 0, 0, MAP_REGION_JOHTO, JOHTO_OLIVINE_CITY_LOCAL_ID
 db JOHTO_OLIVINE_PUNISHMENT_SPEECH_HOUSE_LOCAL_ID, 1, 0, MAP_REGION_JOHTO, JOHTO_OLIVINE_CITY_LOCAL_ID
 db JOHTO_OLIVINE_CITY_LOCAL_ID, 1, 0, MAP_REGION_JOHTO, JOHTO_OLIVINE_TIMS_HOUSE_LOCAL_ID
 db JOHTO_OLIVINE_TIMS_HOUSE_LOCAL_ID, 0, 1, MAP_REGION_JOHTO, JOHTO_OLIVINE_CITY_LOCAL_ID
 db JOHTO_OLIVINE_TIMS_HOUSE_LOCAL_ID, 1, 1, MAP_REGION_JOHTO, JOHTO_OLIVINE_CITY_LOCAL_ID
 db JOHTO_OLIVINE_CITY_LOCAL_ID, 2, 0, MAP_REGION_JOHTO, JOHTO_OLIVINE_GOOD_ROD_HOUSE_LOCAL_ID
 db JOHTO_OLIVINE_GOOD_ROD_HOUSE_LOCAL_ID, 0, 2, MAP_REGION_JOHTO, JOHTO_OLIVINE_CITY_LOCAL_ID
 db JOHTO_OLIVINE_GOOD_ROD_HOUSE_LOCAL_ID, 1, 2, MAP_REGION_JOHTO, JOHTO_OLIVINE_CITY_LOCAL_ID
 db JOHTO_CHERRYGROVE_LOCAL_ID, 0, 0, MAP_REGION_JOHTO, JOHTO_CHERRYGROVE_GYM_SPEECH_HOUSE_LOCAL_ID
 db JOHTO_CHERRYGROVE_GYM_SPEECH_HOUSE_LOCAL_ID, 0, 0, MAP_REGION_JOHTO, JOHTO_CHERRYGROVE_LOCAL_ID
 db JOHTO_CHERRYGROVE_GYM_SPEECH_HOUSE_LOCAL_ID, 1, 0, MAP_REGION_JOHTO, JOHTO_CHERRYGROVE_LOCAL_ID
 db JOHTO_CHERRYGROVE_LOCAL_ID, 1, 0, MAP_REGION_JOHTO, JOHTO_GUIDE_GENTS_HOUSE_LOCAL_ID
 db JOHTO_GUIDE_GENTS_HOUSE_LOCAL_ID, 0, 1, MAP_REGION_JOHTO, JOHTO_CHERRYGROVE_LOCAL_ID
 db JOHTO_GUIDE_GENTS_HOUSE_LOCAL_ID, 1, 1, MAP_REGION_JOHTO, JOHTO_CHERRYGROVE_LOCAL_ID
 db JOHTO_CHERRYGROVE_LOCAL_ID, 2, 0, MAP_REGION_JOHTO, JOHTO_CHERRYGROVE_EVOLUTION_SPEECH_HOUSE_LOCAL_ID
 db JOHTO_CHERRYGROVE_EVOLUTION_SPEECH_HOUSE_LOCAL_ID, 0, 2, MAP_REGION_JOHTO, JOHTO_CHERRYGROVE_LOCAL_ID
 db JOHTO_CHERRYGROVE_EVOLUTION_SPEECH_HOUSE_LOCAL_ID, 1, 2, MAP_REGION_JOHTO, JOHTO_CHERRYGROVE_LOCAL_ID
 db JOHTO_CHERRYGROVE_LOCAL_ID, 3, 0, MAP_REGION_JOHTO, JOHTO_CHERRYGROVE_MART_LOCAL_ID
 db JOHTO_CHERRYGROVE_MART_LOCAL_ID, 0, 3, MAP_REGION_JOHTO, JOHTO_CHERRYGROVE_LOCAL_ID
 db JOHTO_CHERRYGROVE_MART_LOCAL_ID, 1, 3, MAP_REGION_JOHTO, JOHTO_CHERRYGROVE_LOCAL_ID
 db JOHTO_CHERRYGROVE_LOCAL_ID, 4, 0, MAP_REGION_JOHTO, JOHTO_CHERRYGROVE_POKECENTER_1F_LOCAL_ID
 db JOHTO_CHERRYGROVE_POKECENTER_1F_LOCAL_ID, 0, 4, MAP_REGION_JOHTO, JOHTO_CHERRYGROVE_LOCAL_ID
 db JOHTO_CHERRYGROVE_POKECENTER_1F_LOCAL_ID, 1, 4, MAP_REGION_JOHTO, JOHTO_CHERRYGROVE_LOCAL_ID
 ; Route46 two south mats enter the gate north, then return lane-by-lane.
 db JOHTO_ROUTE_46_LOCAL_ID, 0, 0, MAP_REGION_JOHTO, JOHTO_ROUTE_29_ROUTE_46_GATE_LOCAL_ID
 db JOHTO_ROUTE_46_LOCAL_ID, 1, 1, MAP_REGION_JOHTO, JOHTO_ROUTE_29_ROUTE_46_GATE_LOCAL_ID
 db JOHTO_ROUTE_29_ROUTE_46_GATE_LOCAL_ID, 0, 0, MAP_REGION_JOHTO, JOHTO_ROUTE_46_LOCAL_ID
 db JOHTO_ROUTE_29_ROUTE_46_GATE_LOCAL_ID, 1, 1, MAP_REGION_JOHTO, JOHTO_ROUTE_46_LOCAL_ID
 ; Gold indoor south two lanes both target the ONE Route29 outside DOOR.
 db JOHTO_ROUTE_29_ROUTE_46_GATE_LOCAL_ID, 2, 0, MAP_REGION_JOHTO, JOHTO_ROUTE_29_LOCAL_ID
 db JOHTO_ROUTE_29_ROUTE_46_GATE_LOCAL_ID, 3, 0, MAP_REGION_JOHTO, JOHTO_ROUTE_29_LOCAL_ID
	; Mahogany's actual fifth Gold warp and the four Gold north gate exits.
	; Middle Route43Gate: original Gold bottom single DOOR and top paired carpets.
	db JOHTO_ROUTE_43_LOCAL_ID, 2, 2, MAP_REGION_JOHTO, JOHTO_ROUTE_43_GATE_LOCAL_ID
	db JOHTO_ROUTE_43_LOCAL_ID, 3, 0, MAP_REGION_JOHTO, JOHTO_ROUTE_43_GATE_LOCAL_ID
	db JOHTO_ROUTE_43_LOCAL_ID, 4, 1, MAP_REGION_JOHTO, JOHTO_ROUTE_43_GATE_LOCAL_ID
	db JOHTO_ROUTE_43_GATE_LOCAL_ID, 0, 3, MAP_REGION_JOHTO, JOHTO_ROUTE_43_LOCAL_ID
	db JOHTO_ROUTE_43_GATE_LOCAL_ID, 1, 4, MAP_REGION_JOHTO, JOHTO_ROUTE_43_LOCAL_ID
	db JOHTO_ROUTE_43_GATE_LOCAL_ID, 2, 2, MAP_REGION_JOHTO, JOHTO_ROUTE_43_LOCAL_ID
	db JOHTO_ROUTE_43_GATE_LOCAL_ID, 3, 2, MAP_REGION_JOHTO, JOHTO_ROUTE_43_LOCAL_ID
	db JOHTO_MAHOGANY_TOWN_LOCAL_ID, 0, 2, MAP_REGION_JOHTO, JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID
	db JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID, 0, 0, MAP_REGION_JOHTO, JOHTO_ROUTE_43_LOCAL_ID
	db JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID, 1, 1, MAP_REGION_JOHTO, JOHTO_ROUTE_43_LOCAL_ID
	db JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID, 2, 0, MAP_REGION_JOHTO, JOHTO_MAHOGANY_TOWN_LOCAL_ID
	db JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID, 3, 0, MAP_REGION_JOHTO, JOHTO_MAHOGANY_TOWN_LOCAL_ID
	db JOHTO_ROUTE_43_LOCAL_ID, 0, 0, MAP_REGION_JOHTO, JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID
	db JOHTO_ROUTE_43_LOCAL_ID, 1, 1, MAP_REGION_JOHTO, JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID
	; Route42 east gate: city two lanes, gate two sides, Route42 two lanes.
	db JOHTO_ECRUTEAK_CITY_LOCAL_ID, 2, 0, MAP_REGION_JOHTO, JOHTO_ROUTE_42_ECRUTEAK_GATE_LOCAL_ID
	db JOHTO_ECRUTEAK_CITY_LOCAL_ID, 3, 1, MAP_REGION_JOHTO, JOHTO_ROUTE_42_ECRUTEAK_GATE_LOCAL_ID
	db JOHTO_ROUTE_42_ECRUTEAK_GATE_LOCAL_ID, 0, 2, MAP_REGION_JOHTO, JOHTO_ECRUTEAK_CITY_LOCAL_ID
	db JOHTO_ROUTE_42_ECRUTEAK_GATE_LOCAL_ID, 1, 3, MAP_REGION_JOHTO, JOHTO_ECRUTEAK_CITY_LOCAL_ID
	db JOHTO_ROUTE_42_ECRUTEAK_GATE_LOCAL_ID, 2, 0, MAP_REGION_JOHTO, JOHTO_ROUTE_42_LOCAL_ID
	db JOHTO_ROUTE_42_ECRUTEAK_GATE_LOCAL_ID, 3, 1, MAP_REGION_JOHTO, JOHTO_ROUTE_42_LOCAL_ID
	db JOHTO_ROUTE_42_LOCAL_ID, 0, 2, MAP_REGION_JOHTO, JOHTO_ROUTE_42_ECRUTEAK_GATE_LOCAL_ID
	db JOHTO_ROUTE_42_LOCAL_ID, 1, 3, MAP_REGION_JOHTO, JOHTO_ROUTE_42_ECRUTEAK_GATE_LOCAL_ID
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
	; North Forest one-to-two gate entrance, both gate bottom mouths return to the single Forest slot 2.
	db JOHTO_ILEX_FOREST_LOCAL_ID, 2, 2, MAP_REGION_JOHTO, JOHTO_ROUTE34_ILEX_GATE_LOCAL_ID
	db JOHTO_ROUTE34_ILEX_GATE_LOCAL_ID, 2, 2, MAP_REGION_JOHTO, JOHTO_ILEX_FOREST_LOCAL_ID
	db JOHTO_ROUTE34_ILEX_GATE_LOCAL_ID, 3, 2, MAP_REGION_JOHTO, JOHTO_ILEX_FOREST_LOCAL_ID
	; North gate top two mouths and Route34 bottom two mouths are bidirectional.
	db JOHTO_ROUTE34_ILEX_GATE_LOCAL_ID, 0, 0, MAP_REGION_JOHTO, JOHTO_ROUTE_34_LOCAL_ID
	db JOHTO_ROUTE34_ILEX_GATE_LOCAL_ID, 1, 1, MAP_REGION_JOHTO, JOHTO_ROUTE_34_LOCAL_ID
	db JOHTO_ROUTE_34_LOCAL_ID, 0, 0, MAP_REGION_JOHTO, JOHTO_ROUTE34_ILEX_GATE_LOCAL_ID
	db JOHTO_ROUTE_34_LOCAL_ID, 1, 1, MAP_REGION_JOHTO, JOHTO_ROUTE34_ILEX_GATE_LOCAL_ID
	; GATE-5.62.224: south Route35 double entrance, north Goldenrod single entrance.
	db JOHTO_ROUTE_35_LOCAL_ID, 0, 0, MAP_REGION_JOHTO, JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID
	db JOHTO_ROUTE_35_LOCAL_ID, 1, 1, MAP_REGION_JOHTO, JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID
	db JOHTO_GOLDENROD_CITY_LOCAL_ID, 0, 2, MAP_REGION_JOHTO, JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID
	db JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID, 0, 0, MAP_REGION_JOHTO, JOHTO_ROUTE_35_LOCAL_ID
	db JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID, 1, 1, MAP_REGION_JOHTO, JOHTO_ROUTE_35_LOCAL_ID
	db JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID, 2, 0, MAP_REGION_JOHTO, JOHTO_GOLDENROD_CITY_LOCAL_ID
	db JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID, 3, 0, MAP_REGION_JOHTO, JOHTO_GOLDENROD_CITY_LOCAL_ID
	; West Route38 gate and EcruteakCity two-lane Gold warp graph.
	db JOHTO_ROUTE_38_LOCAL_ID, 0, 0, MAP_REGION_JOHTO, JOHTO_ROUTE_38_ECRUTEAK_GATE_LOCAL_ID
	db JOHTO_ROUTE_38_LOCAL_ID, 1, 1, MAP_REGION_JOHTO, JOHTO_ROUTE_38_ECRUTEAK_GATE_LOCAL_ID
	db JOHTO_ECRUTEAK_CITY_LOCAL_ID, 0, 2, MAP_REGION_JOHTO, JOHTO_ROUTE_38_ECRUTEAK_GATE_LOCAL_ID
	db JOHTO_ECRUTEAK_CITY_LOCAL_ID, 1, 3, MAP_REGION_JOHTO, JOHTO_ROUTE_38_ECRUTEAK_GATE_LOCAL_ID
	db JOHTO_ROUTE_38_ECRUTEAK_GATE_LOCAL_ID, 0, 0, MAP_REGION_JOHTO, JOHTO_ROUTE_38_LOCAL_ID
	db JOHTO_ROUTE_38_ECRUTEAK_GATE_LOCAL_ID, 1, 1, MAP_REGION_JOHTO, JOHTO_ROUTE_38_LOCAL_ID
	db JOHTO_ROUTE_38_ECRUTEAK_GATE_LOCAL_ID, 2, 0, MAP_REGION_JOHTO, JOHTO_ECRUTEAK_CITY_LOCAL_ID
	db JOHTO_ROUTE_38_ECRUTEAK_GATE_LOCAL_ID, 3, 1, MAP_REGION_JOHTO, JOHTO_ECRUTEAK_CITY_LOCAL_ID
	; Ruins north gate: Route36 paired, south gate 2 lanes -> same outside warp.
	db JOHTO_ROUTE_36_LOCAL_ID, 0, 0, MAP_REGION_JOHTO, JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID
	db JOHTO_ROUTE_36_LOCAL_ID, 1, 1, MAP_REGION_JOHTO, JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID
	db JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID, 0, 0, MAP_REGION_JOHTO, JOHTO_ROUTE_36_LOCAL_ID
	db JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID, 1, 1, MAP_REGION_JOHTO, JOHTO_ROUTE_36_LOCAL_ID
	db JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID, 2, 0, MAP_REGION_JOHTO, JOHTO_RUINS_OF_ALPH_LOCAL_ID
	db JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID, 3, 0, MAP_REGION_JOHTO, JOHTO_RUINS_OF_ALPH_LOCAL_ID
	db JOHTO_RUINS_OF_ALPH_LOCAL_ID, 0, 2, MAP_REGION_JOHTO, JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID
	; National Park public walkthrough, preserving original Route36 ruins indices.
	db JOHTO_ROUTE_35_LOCAL_ID, 2, 2, MAP_REGION_JOHTO, JOHTO_ROUTE_35_NATIONAL_PARK_GATE_LOCAL_ID
	db JOHTO_ROUTE_35_NATIONAL_PARK_GATE_LOCAL_ID, 2, 2, MAP_REGION_JOHTO, JOHTO_ROUTE_35_LOCAL_ID
	db JOHTO_ROUTE_35_NATIONAL_PARK_GATE_LOCAL_ID, 3, 2, MAP_REGION_JOHTO, JOHTO_ROUTE_35_LOCAL_ID
	db JOHTO_ROUTE_35_NATIONAL_PARK_GATE_LOCAL_ID, 0, 2, MAP_REGION_JOHTO, JOHTO_NATIONAL_PARK_LOCAL_ID
	db JOHTO_ROUTE_35_NATIONAL_PARK_GATE_LOCAL_ID, 1, 3, MAP_REGION_JOHTO, JOHTO_NATIONAL_PARK_LOCAL_ID
	db JOHTO_NATIONAL_PARK_LOCAL_ID, 2, 0, MAP_REGION_JOHTO, JOHTO_ROUTE_35_NATIONAL_PARK_GATE_LOCAL_ID
	db JOHTO_NATIONAL_PARK_LOCAL_ID, 3, 1, MAP_REGION_JOHTO, JOHTO_ROUTE_35_NATIONAL_PARK_GATE_LOCAL_ID
	db JOHTO_NATIONAL_PARK_LOCAL_ID, 0, 0, MAP_REGION_JOHTO, JOHTO_ROUTE_36_NATIONAL_PARK_GATE_LOCAL_ID
	db JOHTO_NATIONAL_PARK_LOCAL_ID, 1, 1, MAP_REGION_JOHTO, JOHTO_ROUTE_36_NATIONAL_PARK_GATE_LOCAL_ID
	db JOHTO_ROUTE_36_NATIONAL_PARK_GATE_LOCAL_ID, 0, 0, MAP_REGION_JOHTO, JOHTO_NATIONAL_PARK_LOCAL_ID
	db JOHTO_ROUTE_36_NATIONAL_PARK_GATE_LOCAL_ID, 1, 1, MAP_REGION_JOHTO, JOHTO_NATIONAL_PARK_LOCAL_ID
	db JOHTO_ROUTE_36_NATIONAL_PARK_GATE_LOCAL_ID, 2, 2, MAP_REGION_JOHTO, JOHTO_ROUTE_36_LOCAL_ID
	db JOHTO_ROUTE_36_NATIONAL_PARK_GATE_LOCAL_ID, 3, 3, MAP_REGION_JOHTO, JOHTO_ROUTE_36_LOCAL_ID
	db JOHTO_ROUTE_36_LOCAL_ID, 2, 2, MAP_REGION_JOHTO, JOHTO_ROUTE_36_NATIONAL_PARK_GATE_LOCAL_ID
	db JOHTO_ROUTE_36_LOCAL_ID, 3, 3, MAP_REGION_JOHTO, JOHTO_ROUTE_36_NATIONAL_PARK_GATE_LOCAL_ID
	; Original Route32 ruins gate two-lane west/east travel. Keep Route32 cave warp0.
	db JOHTO_ROUTE_32_LOCAL_ID, 1, 2, MAP_REGION_JOHTO, JOHTO_ROUTE_32_RUINS_OF_ALPH_GATE_LOCAL_ID
	db JOHTO_ROUTE_32_LOCAL_ID, 2, 3, MAP_REGION_JOHTO, JOHTO_ROUTE_32_RUINS_OF_ALPH_GATE_LOCAL_ID
	db JOHTO_RUINS_OF_ALPH_LOCAL_ID, 1, 0, MAP_REGION_JOHTO, JOHTO_ROUTE_32_RUINS_OF_ALPH_GATE_LOCAL_ID
	db JOHTO_RUINS_OF_ALPH_LOCAL_ID, 2, 1, MAP_REGION_JOHTO, JOHTO_ROUTE_32_RUINS_OF_ALPH_GATE_LOCAL_ID
	db JOHTO_ROUTE_32_RUINS_OF_ALPH_GATE_LOCAL_ID, 0, 1, MAP_REGION_JOHTO, JOHTO_RUINS_OF_ALPH_LOCAL_ID
	db JOHTO_ROUTE_32_RUINS_OF_ALPH_GATE_LOCAL_ID, 1, 2, MAP_REGION_JOHTO, JOHTO_RUINS_OF_ALPH_LOCAL_ID
	db JOHTO_ROUTE_32_RUINS_OF_ALPH_GATE_LOCAL_ID, 2, 1, MAP_REGION_JOHTO, JOHTO_ROUTE_32_LOCAL_ID
	db JOHTO_ROUTE_32_RUINS_OF_ALPH_GATE_LOCAL_ID, 3, 2, MAP_REGION_JOHTO, JOHTO_ROUTE_32_LOCAL_ID
 ; Olivine public buildings: each return targets its own exterior lane.
 db JOHTO_OLIVINE_CITY_LOCAL_ID, 3, 0, MAP_REGION_JOHTO, JOHTO_OLIVINE_POKECENTER_1F_LOCAL_ID
 db JOHTO_OLIVINE_POKECENTER_1F_LOCAL_ID, 0, 3, MAP_REGION_JOHTO, JOHTO_OLIVINE_CITY_LOCAL_ID
 db JOHTO_OLIVINE_POKECENTER_1F_LOCAL_ID, 1, 3, MAP_REGION_JOHTO, JOHTO_OLIVINE_CITY_LOCAL_ID
 db JOHTO_OLIVINE_CITY_LOCAL_ID, 4, 0, MAP_REGION_JOHTO, JOHTO_OLIVINE_CAFE_LOCAL_ID
 db JOHTO_OLIVINE_CAFE_LOCAL_ID, 0, 4, MAP_REGION_JOHTO, JOHTO_OLIVINE_CITY_LOCAL_ID
 db JOHTO_OLIVINE_CAFE_LOCAL_ID, 1, 4, MAP_REGION_JOHTO, JOHTO_OLIVINE_CITY_LOCAL_ID
 db JOHTO_OLIVINE_CITY_LOCAL_ID, 5, 0, MAP_REGION_JOHTO, JOHTO_OLIVINE_MART_LOCAL_ID
 db JOHTO_OLIVINE_MART_LOCAL_ID, 0, 5, MAP_REGION_JOHTO, JOHTO_OLIVINE_CITY_LOCAL_ID
 db JOHTO_OLIVINE_MART_LOCAL_ID, 1, 5, MAP_REGION_JOHTO, JOHTO_OLIVINE_CITY_LOCAL_ID
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
	; A missing/invalid connection can otherwise load an unrelated map.
	; The collision fence normally prevents this path; fail closed if it
	; is reached after corrupted header/connection data.
	jp SoftReset

; .234 continuous coastline, all six Gold reciprocal directed edges.
; E=0..3 cardinal edge on entry; E=neighbor bank or $ff on return.
; callab overwrites A with the callee ROM bank ($40), so A MUST NOT carry
; the edge direction across the far-call. E survives bank restoration.
ResolveNativeConnectionPreviewBank::
 ; E=0..3 cardinal edge on entry; E=neighbor bank or $ff on return.
 ; P23: ROM0 cannot index a ROMX map bank from wCurMap=$FC alone. Resolve
 ; the actual neighbor through the source map's stable local ID + edge.
 ld c,e
 ld a,[wCurMap]
 ; The adjacent legacy routes now target native Cherrygrove through $FC.
 ; Preserve Route29 north->Route46, add Route29 west/Route30 south->city.
 cp JOHTO_ROUTE_29
 jp z,.legacyRoute29
 cp JOHTO_ROUTE_30
 jp z,.legacyRoute30
 cp REGION_NATIVE_MAP_SLOT
 jr nz,.invalid
 ld a,[wCurRegion]
 cp MAP_REGION_JOHTO
 jr nz,.invalid
 ld a,[wCurLocalMapID]
 cp JOHTO_CHERRYGROVE_LOCAL_ID
 jr z,.nativeCherrygrove
 ld b,a
 ld hl,NativeRegionConnectionTargets
.loop
 ld a,[hli]
 cp $ff
 jr z,.invalid
 cp b
 jr nz,.skipThree
 ld a,[hli]
 cp c
 jr nz,.skipTwo
 ld a,[hli] ; target region
 cp MAP_REGION_JOHTO
 jr nz,.invalid
 ld e,[hl] ; target stable ID
 call GetJohtoActiveSlot
 ld a,e
 cp JOHTO_INVALID_ACTIVE_SLOT
 jr z,.invalid
 ld l,e
 ld h,0
 ld de,JohtoMapHeaderBanks
 add hl,de
 ld e,[hl]
 ret
.skipThree
 inc hl
.skipTwo
 inc hl
 inc hl
 jr .loop
.legacyRoute29
 ld a,[wCurRegion]
 cp MAP_REGION_JOHTO
 jr nz,.invalid
 ld a,[wCurLocalMapID]
 cp JOHTO_ROUTE_29_LOCAL_ID
 jr nz,.invalid
 ld a,c
 and a ; north edge still leads to Route46
 jr z,.legacyRoute29North
 cp 2 ; west edge now leads to native Cherrygrove
 jr z,.legacyRoute29Cherrygrove
 jr .invalid
.legacyRoute29North
 ld e,BANK(JohtoRoute46Blocks)
 ret
.legacyRoute29Cherrygrove
 ld e,BANK(JohtoCherrygroveCityBlocks)
 ret
.legacyRoute30
 ld a,[wCurRegion]
 cp MAP_REGION_JOHTO
 jr nz,.invalid
 ld a,[wCurLocalMapID]
 cp JOHTO_ROUTE_30_LOCAL_ID
 jr nz,.invalid
 ld a,c
 cp 1 ; south edge leads to native Cherrygrove
 jr nz,.invalid
 ld e,BANK(JohtoCherrygroveCityBlocks)
 ret
.nativeCherrygrove
 ld a,c
 and a ; north edge returns to legacy Route30
 jr z,.cherrygroveNorth
 cp 3 ; east edge returns to legacy Route29
 jr nz,.invalid
 ld e,BANK(JohtoRoute29Blocks)
 ret
.cherrygroveNorth
 ld e,BANK(JohtoRoute30Blocks)
 ret
.invalid
 ld e,$ff
 ret
NativeRegionConnectionTargets::
 ; Cherrygrove is native local 2; Route29/Route30 themselves remain legacy.
 db JOHTO_ROUTE_29_LOCAL_ID, 2, MAP_REGION_JOHTO, JOHTO_CHERRYGROVE_LOCAL_ID ; Route29 WEST -> Cherrygrove
 db JOHTO_ROUTE_30_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_CHERRYGROVE_LOCAL_ID ; Route30 SOUTH -> Cherrygrove
 ; Route29/Route46 north-south preview is all solid Gold wall, never enter.
 db JOHTO_ROUTE_29_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_ROUTE_46_LOCAL_ID
 ; Gold east exterior spine, exact reciprocal connection ordinals.
 db JOHTO_MAHOGANY_TOWN_LOCAL_ID, 3, MAP_REGION_JOHTO, JOHTO_ROUTE_44_LOCAL_ID
 db JOHTO_ROUTE_44_LOCAL_ID, 2, MAP_REGION_JOHTO, JOHTO_MAHOGANY_TOWN_LOCAL_ID
 db JOHTO_ROUTE_44_LOCAL_ID, 3, MAP_REGION_JOHTO, JOHTO_BLACKTHORN_CITY_LOCAL_ID
 db JOHTO_BLACKTHORN_CITY_LOCAL_ID, 2, MAP_REGION_JOHTO, JOHTO_ROUTE_44_LOCAL_ID
 db JOHTO_BLACKTHORN_CITY_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_ROUTE_45_LOCAL_ID
 db JOHTO_ROUTE_45_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_BLACKTHORN_CITY_LOCAL_ID
 db JOHTO_ROUTE_45_LOCAL_ID, 2, MAP_REGION_JOHTO, JOHTO_ROUTE_46_LOCAL_ID
 db JOHTO_ROUTE_46_LOCAL_ID, 3, MAP_REGION_JOHTO, JOHTO_ROUTE_45_LOCAL_ID
	db JOHTO_MAHOGANY_TOWN_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_ROUTE_43_LOCAL_ID
	db JOHTO_ROUTE_43_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_MAHOGANY_TOWN_LOCAL_ID
	db JOHTO_ROUTE_43_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_LAKE_OF_RAGE_LOCAL_ID
	db JOHTO_LAKE_OF_RAGE_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_ROUTE_43_LOCAL_ID
 ; SPID.233: contiguous Route38 <-> Route39 <-> OlivineCity (Gold).
 db JOHTO_ROUTE_38_LOCAL_ID, 2, MAP_REGION_JOHTO, JOHTO_ROUTE_39_LOCAL_ID
 db JOHTO_ROUTE_39_LOCAL_ID, 3, MAP_REGION_JOHTO, JOHTO_ROUTE_38_LOCAL_ID
 db JOHTO_ROUTE_39_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_OLIVINE_CITY_LOCAL_ID
 db JOHTO_OLIVINE_CITY_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_ROUTE_39_LOCAL_ID
 db JOHTO_OLIVINE_CITY_LOCAL_ID, 2, MAP_REGION_JOHTO, JOHTO_ROUTE_40_LOCAL_ID
 db JOHTO_ROUTE_40_LOCAL_ID, 3, MAP_REGION_JOHTO, JOHTO_OLIVINE_CITY_LOCAL_ID
 db JOHTO_ROUTE_40_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_ROUTE_41_LOCAL_ID
 db JOHTO_ROUTE_41_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_ROUTE_40_LOCAL_ID
 db JOHTO_ROUTE_41_LOCAL_ID, 2, MAP_REGION_JOHTO, JOHTO_CIANWOOD_CITY_LOCAL_ID
 db JOHTO_CIANWOOD_CITY_LOCAL_ID, 3, MAP_REGION_JOHTO, JOHTO_ROUTE_41_LOCAL_ID
	; Gold city east and Route42 west seamless preview, collision fence controls travel.
	db JOHTO_ECRUTEAK_CITY_LOCAL_ID, 3, MAP_REGION_JOHTO, JOHTO_ROUTE_42_LOCAL_ID
	db JOHTO_ROUTE_42_LOCAL_ID, 2, MAP_REGION_JOHTO, JOHTO_ECRUTEAK_CITY_LOCAL_ID
	; Gold Route42 east <-> MahoganyTown west, offset 0.
	db JOHTO_ROUTE_42_LOCAL_ID, 3, MAP_REGION_JOHTO, JOHTO_MAHOGANY_TOWN_LOCAL_ID
	db JOHTO_MAHOGANY_TOWN_LOCAL_ID, 2, MAP_REGION_JOHTO, JOHTO_ROUTE_42_LOCAL_ID
	; Gold Route36 north(0) <-> Route37 south(1), stable local IDs 16 and 21.
	db JOHTO_ROUTE_36_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_ROUTE_37_LOCAL_ID
	db JOHTO_ROUTE_37_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_ROUTE_36_LOCAL_ID
	; Gold City west <-> Route38 east (visual strip, no gate bypass).
	db JOHTO_ECRUTEAK_CITY_LOCAL_ID, 2, MAP_REGION_JOHTO, JOHTO_ROUTE_38_LOCAL_ID
	db JOHTO_ROUTE_38_LOCAL_ID, 3, MAP_REGION_JOHTO, JOHTO_ECRUTEAK_CITY_LOCAL_ID
	; Gold Route37 north(0) <-> EcruteakCity south(1).
	db JOHTO_ROUTE_37_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_ECRUTEAK_CITY_LOCAL_ID
	db JOHTO_ECRUTEAK_CITY_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_ROUTE_37_LOCAL_ID
	; R35-5.62.223: Route36 south <-> Route35 north; native/local IDs disambiguate $FC.
	db JOHTO_ROUTE_36_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_ROUTE_35_LOCAL_ID
	db JOHTO_ROUTE_35_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_ROUTE_36_LOCAL_ID
	; R36-5.62.218: legacy Violet City west -> native Route36.
	db JOHTO_VIOLET_CITY_LOCAL_ID, 2, MAP_REGION_JOHTO, JOHTO_ROUTE_36_LOCAL_ID
	; R33-5.62.191: Route32 SOUTH(1) reaches native Route33 local 9.
	db JOHTO_ROUTE_32_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_ROUTE_33_LOCAL_ID
	; MAP-5.62.195: modern Route33 west <-> modern AzaleaTown east.
	db JOHTO_ROUTE_33_LOCAL_ID, 2, MAP_REGION_JOHTO, JOHTO_AZALEA_TOWN_LOCAL_ID
	db JOHTO_AZALEA_TOWN_LOCAL_ID, 3, MAP_REGION_JOHTO, JOHTO_ROUTE_33_LOCAL_ID
	; P19-5.62.216: only Route34 north <-> Goldenrod south.
	db JOHTO_ROUTE_34_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_GOLDENROD_CITY_LOCAL_ID
	db JOHTO_GOLDENROD_CITY_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_ROUTE_34_LOCAL_ID
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
 ; All three opened Gold Olivine House1 exterior DOOR landings need DOWN.
 ; Source-guarded native arrivals only. Indoor (2,7)/(3,7) stays on carpet.
 db REGION_NATIVE_MAP_SLOT, JOHTO_OLIVINE_CITY_LOCAL_ID, 11, 29, REGION_NATIVE_MAP_SLOT, D_DOWN ; PunishmentSpeechHouse
 db REGION_NATIVE_MAP_SLOT, JOHTO_OLIVINE_CITY_LOCAL_ID, 11, 25, REGION_NATIVE_MAP_SLOT, D_DOWN ; TimsHouse
 db REGION_NATIVE_MAP_SLOT, JOHTO_OLIVINE_CITY_LOCAL_ID, 15, 13, REGION_NATIVE_MAP_SLOT, D_DOWN ; GoodRodHouse
 db REGION_NATIVE_MAP_SLOT, JOHTO_OLIVINE_CITY_LOCAL_ID, 21, 13, REGION_NATIVE_MAP_SLOT, D_DOWN ; Pokecenter
 db REGION_NATIVE_MAP_SLOT, JOHTO_OLIVINE_CITY_LOCAL_ID, 21, 7, REGION_NATIVE_MAP_SLOT, D_DOWN ; Cafe
 db REGION_NATIVE_MAP_SLOT, JOHTO_OLIVINE_CITY_LOCAL_ID, 17, 19, REGION_NATIVE_MAP_SLOT, D_DOWN ; Mart
 db REGION_NATIVE_MAP_SLOT, JOHTO_CHERRYGROVE_LOCAL_ID, 7, 17, REGION_NATIVE_MAP_SLOT, D_DOWN ; CherrygroveGymSpeechHouse
 db REGION_NATIVE_MAP_SLOT, JOHTO_CHERRYGROVE_LOCAL_ID, 9, 25, REGION_NATIVE_MAP_SLOT, D_DOWN ; GuideGentsHouse
 db REGION_NATIVE_MAP_SLOT, JOHTO_CHERRYGROVE_LOCAL_ID, 11, 31, REGION_NATIVE_MAP_SLOT, D_DOWN ; CherrygroveEvolutionSpeechHouse
 db REGION_NATIVE_MAP_SLOT, JOHTO_CHERRYGROVE_LOCAL_ID, 3, 23, REGION_NATIVE_MAP_SLOT, D_DOWN ; CherrygroveMart
 db REGION_NATIVE_MAP_SLOT, JOHTO_CHERRYGROVE_LOCAL_ID, 3, 29, REGION_NATIVE_MAP_SLOT, D_DOWN ; CherrygrovePokecenter1F
 ; Gold house landing on (2,7) remains on its WARP_CARPET_DOWN tile.
 ; No automatic UP: all accepted native arrival profiles are DOWN-only.
 ; Route29/46 gate top Gold DOOR: move DOWN; bottom/outside carpet: NONE.
 db REGION_NATIVE_MAP_SLOT, JOHTO_ROUTE_29_ROUTE_46_GATE_LOCAL_ID, 0, 4, REGION_NATIVE_MAP_SLOT, D_DOWN
 db REGION_NATIVE_MAP_SLOT, JOHTO_ROUTE_29_ROUTE_46_GATE_LOCAL_ID, 0, 5, REGION_NATIVE_MAP_SLOT, D_DOWN
 ; Legacy Route29 destination is solid DOOR; its one landing needs D_DOWN.
 db JOHTO_ROUTE_29, JOHTO_ROUTE_29_LOCAL_ID, 1, 27, REGION_NATIVE_MAP_SLOT, D_DOWN
 ; Gate and road arrivals: resolved by destination + Gold landing cell.
 ; Middle gate north side gets DOWN on arrival; southern Gold solid DOOR
 ; returns to Route43 (17,35) and steps SOUTH off the roof entrance.
 db REGION_NATIVE_MAP_SLOT, JOHTO_ROUTE_43_GATE_LOCAL_ID, 0, 4, REGION_NATIVE_MAP_SLOT, D_DOWN
 db REGION_NATIVE_MAP_SLOT, JOHTO_ROUTE_43_GATE_LOCAL_ID, 0, 5, REGION_NATIVE_MAP_SLOT, D_DOWN
 db REGION_NATIVE_MAP_SLOT, JOHTO_ROUTE_43_LOCAL_ID, 35, 17, REGION_NATIVE_MAP_SLOT, D_DOWN
 db REGION_NATIVE_MAP_SLOT, JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID, 0, 4, REGION_NATIVE_MAP_SLOT, D_DOWN
 db REGION_NATIVE_MAP_SLOT, JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID, 0, 5, REGION_NATIVE_MAP_SLOT, D_DOWN
 db REGION_NATIVE_MAP_SLOT, JOHTO_MAHOGANY_TOWN_LOCAL_ID, 1, 9, REGION_NATIVE_MAP_SLOT, D_DOWN
 ; Outside Route43 gate's paired COLLISION_ONLY carpets (9/10,51)
 ; must keep their landing cell; an automatic UP prevents immediate
 ; DOWN collision-reentry. Unmatched arrivals already default to NONE.
	; Route32's solid cave-mouth art requires one step south after returning.
	db JOHTO_ROUTE_32, JOHTO_ROUTE_32_LOCAL_ID, 79, 6, REGION_NATIVE_MAP_SLOT, D_DOWN
	; Route33's Gold cave warp is a solid north-wall doorway too.
	db REGION_NATIVE_MAP_SLOT, JOHTO_ROUTE_33_LOCAL_ID, 9, 11, REGION_NATIVE_MAP_SLOT, D_DOWN
	; ILEX-5.62.215: only DOWN arrivals need an extra step away from the door.
	; UP arrivals already stand on the correct destination tile; do not move.
	; Keep the original RPP warp/step executor and match the exact source map.
	db REGION_NATIVE_MAP_SLOT, JOHTO_ROUTE34_ILEX_GATE_LOCAL_ID, 0, 4, REGION_NATIVE_MAP_SLOT, D_DOWN
	db REGION_NATIVE_MAP_SLOT, JOHTO_ROUTE34_ILEX_GATE_LOCAL_ID, 0, 5, REGION_NATIVE_MAP_SLOT, D_DOWN
	; On entering from Route35, Gate north y0 needs one inward step.
	; On exiting Gate south, GoldenrodCity north y1 also needs one step DOWN.
	; Gate south y7 and Route35 outside remain unmodified. Both are
	; destination-scoped, as on the accepted Route34/Ilex north gate.
	db REGION_NATIVE_MAP_SLOT, JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID, 0, 4, REGION_NATIVE_MAP_SLOT, D_DOWN
	db REGION_NATIVE_MAP_SLOT, JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID, 0, 5, REGION_NATIVE_MAP_SLOT, D_DOWN
	db REGION_NATIVE_MAP_SLOT, JOHTO_GOLDENROD_CITY_LOCAL_ID, 1, 19, REGION_NATIVE_MAP_SLOT, D_DOWN
	; Same Gold north/south contract: gate northern pair needs D_DOWN,
	; ruins single solid door needs D_DOWN; return to Route36 and gate
	; southern pair has NONE. Both sides require exact source map key.

	db REGION_NATIVE_MAP_SLOT, JOHTO_ILEX_FOREST_LOCAL_ID, 5, 1, REGION_NATIVE_MAP_SLOT, D_DOWN
	db REGION_NATIVE_MAP_SLOT, JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID, 0, 4, REGION_NATIVE_MAP_SLOT, D_DOWN
	db REGION_NATIVE_MAP_SLOT, JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID, 0, 5, REGION_NATIVE_MAP_SLOT, D_DOWN
	db REGION_NATIVE_MAP_SLOT, JOHTO_RUINS_OF_ALPH_LOCAL_ID, 5, 7, REGION_NATIVE_MAP_SLOT, D_DOWN
	; National Park south gate: entering from park south lands on a north-edge tile;
	; this is the reviewed down-step side only, unlike park/gate return mats.
	db REGION_NATIVE_MAP_SLOT, JOHTO_ROUTE_35_NATIONAL_PARK_GATE_LOCAL_ID, 0, 3, REGION_NATIVE_MAP_SLOT, D_DOWN
	db REGION_NATIVE_MAP_SLOT, JOHTO_ROUTE_35_NATIONAL_PARK_GATE_LOCAL_ID, 0, 4, REGION_NATIVE_MAP_SLOT, D_DOWN
	db REGION_NATIVE_MAP_SLOT, JOHTO_ROUTE_35_LOCAL_ID, 5, 3, REGION_NATIVE_MAP_SLOT, D_DOWN ; Gold solid DOOR
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

; Legacy Route32 uses its original $FB map handle; two Gold left-facing
; carpets at (4,2/3) must be standable from (5,2/3) and permit vertical
; lane change, but require a SECOND leftward collision for their Warp.
JohtoRoute32RuinsGateCarpetStepCheck::
	ld a, [wXCoord]
	cp 5
	jr z, .approach
	cp 4
	jr nz, .denied
	ld a, [wYCoord]
	cp 2
	jr z, .upper
	cp 3
	jr nz, .denied
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_UP
	jr z, .allowed
	jr .denied
.upper
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_DOWN
	jr z, .allowed
	jr .denied
.approach
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_LEFT
	jr nz, .denied
	ld a, [wYCoord]
	cp 2
	jr z, .allowed
	cp 3
	jr z, .allowed
.denied
	and a
	ret
.allowed
	scf
	ret


; This same map's inner Warp carpets are not at the map edge; the generic
; ExtraWarpCheck edge test is false, so the precise predicate is necessary.
JohtoRoute32RuinsGateFacingCheck::
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	jr nz, .no
	ld a, [wCurLocalMapID]
	cp JOHTO_ROUTE_32_LOCAL_ID
	jr nz, .no
	ld a, [wXCoord]
	cp 4
	jr nz, .no
	ld a, [wYCoord]
	cp 2
	jr z, .direction
	cp 3
	jr nz, .no
.direction
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_LEFT
	jr nz, .no
	scf
	ret
.no
	and a
	ret

