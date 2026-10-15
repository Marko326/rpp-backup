; REG-5.62.118: opt-in two-part map key resolver.
; Call with DE = (region << 8) | local_map_id via callab/callba.
; On success: D = ROM bank, HL = map header address, carry clear.
; On failure: D = 0, HL = 0, carry set.  A/BC are not preserved.
; The returned bank is metadata: this routine does not leave it selected.
; Existing warp/save users still use wCurMap until later REG phases.
ResolveRegionMapHeader::
	ld a, d
	cp MAP_REGION_JOHTO
	jr z, .johto
	cp MAP_REGION_KANTO
	jr nz, .invalid
.kanto
	ld a, e
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
	ld a, [wCurMap]
	cp NEW_BARK_TOWN
	jr z, .currentJohto
	cp JOHTO_ROUTE_29
	jr z, .currentJohto
	cp JOHTO_ROUTE_30
	jr z, .currentJohto
	cp JOHTO_ROUTE_31
	jr z, .currentJohto
	cp JOHTO_VIOLET_CITY
	jr nc, .currentJohto ; F9 city / FA gate; other high IDs blocked
	cp JOHTO_CHERRYGROVE_CITY
	ld a, MAP_REGION_KANTO
	jr nz, .currentReady
.currentJohto
	ld a, MAP_REGION_JOHTO
.currentReady
	ld [wCurRegion], a
	ld a, [wLastMap]
	cp NEW_BARK_TOWN
	jr z, .lastJohto
	cp JOHTO_ROUTE_29
	jr z, .lastJohto
	cp JOHTO_ROUTE_30
	jr z, .lastJohto
	cp JOHTO_ROUTE_31
	jr z, .lastJohto
	cp JOHTO_VIOLET_CITY
	jr nc, .lastJohto ; F9 city / FA gate
	cp JOHTO_CHERRYGROVE_CITY
	ld a, MAP_REGION_KANTO
	jr nz, .lastReady
.lastJohto
	ld a, MAP_REGION_JOHTO
.lastReady
	ld [wLastRegion], a
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
	call RegionMapKeyToLegacyID
	jr c, .invalid
	ld a, d
	ld [wCurRegion], a
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
	ld a, d
	ld [wCurRegion], a
	ret

; Input DE = physical region/local ID. Return E = compatible old map ID,
; carry clear when registered. Do not convert Town Map or Fly indices here.
; Additional Johto local IDs must be registered with a distinct legacy alias
; until every other old-map-ID consumer has been migrated.
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
	cp $ff ; no old-engine alias available yet
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
	db $ff
ASSERT JOHTO_NEW_BARK_LOCAL_ID < NUM_JOHTO_MAPS
ASSERT VERMILION_FERRY_DOCK < NUM_LEGACY_MAPS
