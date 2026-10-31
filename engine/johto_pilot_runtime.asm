; Region-aware runtime bridge for registered stable Johto map IDs.
; The legacy Kanto mapconst table remains untouched; $FC is only the live handle.

JohtoPilotSyncMapIdentity::
    ld a, [wCurMap]
    cp JOHTO_RUNTIME_MAP_HANDLE
    jr z, .nativeJohto

    ; A legacy map is physically Kanto. Keep the last native key while on the
    ; ferry, so its dynamic return warp can restore the Johto stable ID.
    xor a
    ld [wCurRegion], a
    ld a, [wCurMap]
    ld [wCurLocalMapID], a
    ld a, [wLastMap]
    cp JOHTO_RUNTIME_MAP_HANDLE
    ret z
    xor a
    ld [wLastRegion], a
    ld a, [wLastMap]
    ld [wLastLocalMapID], a
    ret

.nativeJohto
    ld a, [wRegionStateMagic0]
    cp JOHTO_REGION_MAGIC_0
    jp nz, SoftReset
    ld a, [wRegionStateMagic1]
    cp JOHTO_REGION_MAGIC_1
    jp nz, SoftReset
    ld a, [wCurRegion]
    cp MAP_REGION_JOHTO
    jp nz, SoftReset
    ld a, [wCurLocalMapID]
    ld e, a
    call GetJohtoActiveSlot
    ld a, e
    cp JOHTO_INVALID_ACTIVE_SLOT
    jp z, SoftReset
    ret

; Resolve a warp target after the source/last-map identity has been recorded.
; Ordinary Kanto IDs pass through unchanged. $FE preserves the explicit ferry
; selector (warp 0 New Bark / 2 Vermilion). $FC preserves dynamic previous-map
; return. $FB is a separate table-driven destination used by future indoor maps.
JohtoPilotResolveWarpDestination::
    ld a, [hWarpDestinationMap]
    cp JOHTO_REGION_WARP_ESCAPE
    jr z, .explicitRegionWarp
    cp JOHTO_REGISTERED_WARP_SELECTOR
    jp z, JohtoPilotResolveRegisteredWarp
    cp JOHTO_RUNTIME_MAP_HANDLE
    jr z, .lastNativeMap
    cp JOHTO_PILOT_FLY_SELECTOR
    jp z, SoftReset ; $FD is a Fly-only selector, never a warp target
    ld e, a
    ret

.explicitRegionWarp
    ld a, [wDestinationWarpID]
    and a
    jr z, .newBark
    cp 2
    jr z, .vermilion
    jp SoftReset

.newBark
    ld e, JOHTO_NEW_BARK_LOCAL_ID
    call GetJohtoActiveSlot
    ld a, e
    cp JOHTO_INVALID_ACTIVE_SLOT
    jp z, SoftReset
    ld a, MAP_REGION_JOHTO
    ld [wCurRegion], a
    ld a, JOHTO_NEW_BARK_LOCAL_ID
    ld [wCurLocalMapID], a
    ld e, JOHTO_RUNTIME_MAP_HANDLE
    ret

.vermilion
    xor a
    ld [wCurRegion], a
    ld a, VERMILION_FERRY_DOCK
    ld [wCurLocalMapID], a
    ld e, VERMILION_FERRY_DOCK
    ret

.lastNativeMap
    ld a, [wLastMap]
    cp JOHTO_RUNTIME_MAP_HANDLE
    jp nz, SoftReset
    ld a, [wLastRegion]
    cp MAP_REGION_JOHTO
    jp nz, SoftReset
    ld a, [wLastLocalMapID]
    ld e, a
    call GetJohtoActiveSlot
    ld a, e
    cp JOHTO_INVALID_ACTIVE_SLOT
    jp z, SoftReset
    ld a, [wLastRegion]
    ld [wCurRegion], a
    ld a, [wLastLocalMapID]
    ld [wCurLocalMapID], a
    ld e, JOHTO_RUNTIME_MAP_HANDLE
    ret

; Declarative warp route table for *future* enabled doorways/gates/caves.
; Each source warp uses destination map=$FB in its object data and retains its
; destination warp index. Rows: src region, src stable ID (or Kanto map ID),
; src warp ordinal (zero-based), target region, target local ID. No wildcards.
; Do NOT enable an object warp until its target header, objects, destination
; warp index, bank, landing tile and reverse route have been verified.
DEF JOHTO_REGISTERED_WARP_RECORD_BYTES EQU 5
JohtoRegisteredWarpRoutes::
    ; P6-001: Cherrygrove Gold door (9,25) is the city's first enabled
    ; warp (ordinal 0); house exits (7,2)/(7,3) are ordinals 0/1.
    ; The target ordinal in the object record is zero for all three rows.
    ; Old reference mapconst numbers are never consulted.
    db MAP_REGION_JOHTO, JOHTO_CHERRYGROVE_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_GUIDE_GENTS_HOUSE_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_GUIDE_GENTS_HOUSE_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_CHERRYGROVE_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_GUIDE_GENTS_HOUSE_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_CHERRYGROVE_LOCAL_ID
    ; Route31 gate entrance at (Y6/7, X4), opens the gate's right-hand carpet.
    db MAP_REGION_JOHTO, JOHTO_ROUTE_31_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_ROUTE31_VIOLET_GATE_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_31_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_ROUTE31_VIOLET_GATE_LOCAL_ID
    ; Violet City east gate at (Y24/25, X39), lands on left-hand carpet.
    db MAP_REGION_JOHTO, JOHTO_VIOLET_CITY_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_ROUTE31_VIOLET_GATE_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_VIOLET_CITY_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_ROUTE31_VIOLET_GATE_LOCAL_ID
    ; Gate's left pair -> city; right pair -> Route31.
    db MAP_REGION_JOHTO, JOHTO_ROUTE31_VIOLET_GATE_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_VIOLET_CITY_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE31_VIOLET_GATE_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_VIOLET_CITY_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE31_VIOLET_GATE_LOCAL_ID, 2, MAP_REGION_JOHTO, JOHTO_ROUTE_31_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE31_VIOLET_GATE_LOCAL_ID, 3, MAP_REGION_JOHTO, JOHTO_ROUTE_31_LOCAL_ID
    ; ALPH-SOUTH-002: two exterior entrance carpets -> South Gate.
    db MAP_REGION_JOHTO, JOHTO_ROUTE_32_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_ROUTE_32_RUINS_OF_ALPH_GATE_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_32_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_ROUTE_32_RUINS_OF_ALPH_GATE_LOCAL_ID
    ; Gate's west pair -> ruins; gate's east pair -> Route32.
    db MAP_REGION_JOHTO, JOHTO_ROUTE_32_RUINS_OF_ALPH_GATE_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_RUINS_OF_ALPH_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_32_RUINS_OF_ALPH_GATE_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_RUINS_OF_ALPH_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_32_RUINS_OF_ALPH_GATE_LOCAL_ID, 2, MAP_REGION_JOHTO, JOHTO_ROUTE_32_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_32_RUINS_OF_ALPH_GATE_LOCAL_ID, 3, MAP_REGION_JOHTO, JOHTO_ROUTE_32_LOCAL_ID
    ; Ruins south exit eastward to the South Gate; north and inner rooms stay absent.
    db MAP_REGION_JOHTO, JOHTO_RUINS_OF_ALPH_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_ROUTE_32_RUINS_OF_ALPH_GATE_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_RUINS_OF_ALPH_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_ROUTE_32_RUINS_OF_ALPH_GATE_LOCAL_ID
    ; ALPH-NORTH-001: ruins north DOOR (runtime #2) -> north gate south carpet.
    db MAP_REGION_JOHTO, JOHTO_RUINS_OF_ALPH_LOCAL_ID, 2, MAP_REGION_JOHTO, JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID
    ; North gate top DOOR pair -> Route36 carpet; bottom DOWN pair -> ruins DOOR.
    db MAP_REGION_JOHTO, JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_ROUTE_36_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_ROUTE_36_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID, 2, MAP_REGION_JOHTO, JOHTO_RUINS_OF_ALPH_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID, 3, MAP_REGION_JOHTO, JOHTO_RUINS_OF_ALPH_LOCAL_ID
    ; Route36 Gold #3/#4 only; National Park #1/#2 are not live.
    db MAP_REGION_JOHTO, JOHTO_ROUTE_36_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_36_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID
    ; UNION-260: Route32 Gold cave mouth #4, 1F Gold return #4 only.
    db MAP_REGION_JOHTO, JOHTO_ROUTE_32_LOCAL_ID, 2, MAP_REGION_JOHTO, JOHTO_UNION_CAVE_1F_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_UNION_CAVE_1F_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_ROUTE_32_LOCAL_ID
    ; R33-266: Gold cave south 1F #3 (17,31) <-> Route33 (11,9).
    db MAP_REGION_JOHTO, JOHTO_UNION_CAVE_1F_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_ROUTE_33_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_33_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_UNION_CAVE_1F_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_AZALEA_TOWN_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_ILEX_AZALEA_GATE_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_AZALEA_TOWN_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_ILEX_AZALEA_GATE_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ILEX_AZALEA_GATE_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_ILEX_FOREST_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ILEX_AZALEA_GATE_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_ILEX_FOREST_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ILEX_AZALEA_GATE_LOCAL_ID, 2, MAP_REGION_JOHTO, JOHTO_AZALEA_TOWN_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ILEX_AZALEA_GATE_LOCAL_ID, 3, MAP_REGION_JOHTO, JOHTO_AZALEA_TOWN_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ILEX_FOREST_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_ROUTE34_ILEX_GATE_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ILEX_FOREST_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_ILEX_AZALEA_GATE_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ILEX_FOREST_LOCAL_ID, 2, MAP_REGION_JOHTO, JOHTO_ILEX_AZALEA_GATE_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE34_ILEX_GATE_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_ROUTE_34_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE34_ILEX_GATE_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_ROUTE_34_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE34_ILEX_GATE_LOCAL_ID, 2, MAP_REGION_JOHTO, JOHTO_ILEX_FOREST_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE34_ILEX_GATE_LOCAL_ID, 3, MAP_REGION_JOHTO, JOHTO_ILEX_FOREST_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_34_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_ROUTE34_ILEX_GATE_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_34_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_ROUTE34_ILEX_GATE_LOCAL_ID
JohtoRegisteredWarpRoutesEnd::
DEF JOHTO_REGISTERED_WARP_COUNT EQU (JohtoRegisteredWarpRoutesEnd - JohtoRegisteredWarpRoutes) / JOHTO_REGISTERED_WARP_RECORD_BYTES
ASSERT (JohtoRegisteredWarpRoutesEnd - JohtoRegisteredWarpRoutes) % JOHTO_REGISTERED_WARP_RECORD_BYTES == 0
ASSERT JOHTO_REGISTERED_WARP_COUNT < 256

JohtoPilotResolveRegisteredWarp::
    ; Called only when hWarpDestinationMap = $FB. Source identity is still
    ; current; wLast* may already contain the outdoor return anchor.
    ld a, [wCurMap]
    cp JOHTO_RUNTIME_MAP_HANDLE
    jr nz, .kantoSource
    ld a, [wCurRegion]
    cp MAP_REGION_JOHTO
    jp nz, SoftReset
    ld a, [wCurLocalMapID]
    jr .haveSource
.kantoSource
    ld a, [wCurRegion]
    and a
    jp nz, SoftReset
    ld a, [wCurMap]
.haveSource
    ld c, a
    ld a, [wCurRegion]
    ld b, a
    ld hl, JohtoRegisteredWarpRoutes
    ld d, JOHTO_REGISTERED_WARP_COUNT
.loop
    ld a, d
    and a
    jp z, SoftReset ; unknown or inactive warp never falls into Kanto IDs
    dec d
    ld a, [hli]
    cp b
    jr nz, .skipFour
    ld a, [hli]
    cp c
    jr nz, .skipThree
    ld a, [wWarpedFromWhichWarp]
    cp [hl]
    jr nz, .skipThree
    inc hl ; warp ordinal
    ld a, [hli] ; destination region
    cp MAP_REGION_JOHTO
    jr z, .toJohto
    cp MAP_REGION_KANTO
    jp nz, SoftReset
    ld a, [hl] ; original Kanto map number
    cp JOHTO_REGISTERED_WARP_SELECTOR
    jp nc, SoftReset ; reject all reserved selectors including $ff
    ld [wCurLocalMapID], a
    xor a
    ld [wCurRegion], a
    ld e, [hl]
    ret
.toJohto
    ; PAL241: registered gate entry knows the actual stable source in C.
    ; wWarpedFromWhichMap holds only $FC for *every* native Johto map.
    ; Never use wLastMap or an old physical mapconst to infer gate music.
    ld a, [hl]
    cp JOHTO_ROUTE31_VIOLET_GATE_LOCAL_ID
    jr z, .recordGateSource
    cp JOHTO_ROUTE_32_RUINS_OF_ALPH_GATE_LOCAL_ID
    jr z, .recordGateSource
    cp JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID
    jr z, .recordGateSource
    cp JOHTO_ILEX_AZALEA_GATE_LOCAL_ID
    jr z, .recordGateSource
    cp JOHTO_ROUTE34_ILEX_GATE_LOCAL_ID
    jr nz, .notGateMusicEntry
.recordGateSource
    ld a, c
    ld [wJohtoGateMusicSourceLocalID], a
.notGateMusicEntry
    ld e, [hl] ; target stable ID
    call GetJohtoActiveSlot
    ld a, e
    cp JOHTO_INVALID_ACTIVE_SLOT
    jp z, SoftReset
    ld a, [hl]
    ld [wCurLocalMapID], a
    ld a, MAP_REGION_JOHTO
    ld [wCurRegion], a
    ld e, JOHTO_RUNTIME_MAP_HANDLE
    ret
.skipFour
    inc hl ; source ID
.skipThree
    inc hl ; ordinal
    inc hl ; dest region
    inc hl ; dest ID
    jr .loop

; Physical region identity is resolved by the active stable-ID gate. Each
; active slot has ONE type/landmark/music descriptor: no ID-range guesses.
; Register future indoor maps with outdoor=0 and parent landmark (0..44).
johto_map_profile: MACRO ; outside(0/1), Gold landmark(0..44), music ID, bank
    ASSERT \1 >= 0
    ASSERT \1 <= 1
    ASSERT \2 < JOHTO_TOWNMAP_LANDMARK_COUNT
    db \1, \2, \3, \4
ENDM
JohtoPilotMapProfiles::
    johto_map_profile 1, 0, MUSIC_PALLET_TOWN, 0 ; 0 New Bark, outdoor
    johto_map_profile 1, 1, MUSIC_ROUTES1, 0     ; 1 Route 29, outdoor
    johto_map_profile 1, 2, MUSIC_CITIES1, 0     ; 2 Cherrygrove, outdoor
    johto_map_profile 1, 3, MUSIC_ROUTES1, 0     ; 3 Route30, outdoor
    johto_map_profile 1, 4, MUSIC_ROUTES1, 0     ; 4 Route31, outdoor
    johto_map_profile 0, 2, MUSIC_CITIES1, 0     ; slot 5: Gold GuideGentsHouse ID125, indoor, parent city
    johto_map_profile 1, 5, MUSIC_CITIES1, 0     ; slot 6: Violet City ID5, outdoor
    johto_map_profile 0, 4, MUSIC_ROUTES1, 0     ; slot 7: Route31VioletGate ID6, indoor
    johto_map_profile 1, 7, MUSIC_ROUTES1, 0     ; slot 8: Route32 ID7, Gold Route30 theme
    johto_map_profile 0, 7, MUSIC_ROUTES1, 0     ; slot 9: Route32/Alph South Gate ID102, neutral
    johto_map_profile 1, 8, MUSIC_ROUTES1, 0     ; slot 10: Ruins of Alph outside ID20
    johto_map_profile 0, 19, MUSIC_ROUTES1, 0    ; slot 11: Route36/Ruins North Gate ID19
    johto_map_profile 1, 19, MUSIC_ROUTES1, 0    ; slot 12: Route36 ID16
    johto_map_profile 0, 9, MUSIC_DUNGEON2, 0    ; slot 13: Union Cave 1F, standalone cave landmark
    johto_map_profile 1, 10, MUSIC_ROUTES1, 0   ; slot 14: Route33, Gold Route30 theme
    johto_map_profile 1, 11, MUSIC_CITIES1, 0 ; slot 15 AzaleaTown
    johto_map_profile 0, 11, MUSIC_ROUTES1, 0 ; slot 16 IlexForestAzaleaGate
    johto_map_profile 0, 13, MUSIC_DUNGEON2, 0 ; slot 17 IlexForest
    johto_map_profile 0, 14, MUSIC_ROUTES1, 0 ; slot 18 Route34IlexForestGate
    johto_map_profile 1, 14, MUSIC_ROUTES1, 0 ; slot 19 Route34
    johto_map_profile 1, 15, MUSIC_CITIES1, 0 ; slot 20 GoldenrodCity
JohtoPilotMapProfilesEnd::
ASSERT JohtoPilotMapProfilesEnd - JohtoPilotMapProfiles == NUM_JOHTO_ACTIVE_MAPS * JOHTO_MAP_PROFILE_BYTES

; Input E = stable local map ID; output HL = descriptor for active slot.
; Only call within Bank $41. Missing or corrupt registrations fail closed.
JohtoPilotGetMapProfile::
    call GetJohtoActiveSlot
    ld a, e
    cp JOHTO_INVALID_ACTIVE_SLOT
    jp z, SoftReset
    ld l, e
    ld h, 0
    add hl, hl
    add hl, hl
    ld de, JohtoPilotMapProfiles
    add hl, de
    ret

; Far-call ABI: E returns the boolean; A/BC/HL must not be used by callers.
JohtoPilotGetOutdoorFlag::
    ld a, [wCurRegion]
    cp MAP_REGION_JOHTO
    jp nz, SoftReset
    ld a, [wCurLocalMapID]
    ld e, a
    call JohtoPilotGetMapProfile
    ld e, [hl]
    ret

; Far-call ABI: E = Gold browsing index, not active slot or stable ID.
JohtoPilotGetTownMapLandmark::
    ld a, [wCurRegion]
    cp MAP_REGION_JOHTO
    jp nz, SoftReset
    ld a, [wCurLocalMapID]
    ld e, a
    call JohtoPilotGetMapProfile
    inc hl
    ld a, [hl]
    cp JOHTO_TOWNMAP_LANDMARK_COUNT
    jp nc, SoftReset
    ld e, a
    ret

JohtoPilotLoadMapMusic::
    ld a, [wCurRegion]
    cp MAP_REGION_JOHTO
    jp nz, SoftReset
    ld a, [wCurLocalMapID]
    ld e, a
    call JohtoPilotGetMapProfile
    inc hl
    inc hl
    ld a, [hli]
    ld [wMapMusicSoundID], a
    ld a, [hl]
    ld [wMapMusicROMBank], a
    ; Neutral Gold GATEs retain the *entering* map's song and playback cursor.
    ; Validate the source against that gate's active neighbours: WRAM gate
    ; source is not guaranteed to survive Continue from an old save.
    ; Unknown sources fall back to this gate's own profile, never New Bark.
    ld a, [wCurLocalMapID]
    cp JOHTO_ILEX_AZALEA_GATE_LOCAL_ID
    jp z, .southForestGate
    cp JOHTO_ROUTE34_ILEX_GATE_LOCAL_ID
    jp z, .northForestGate
    cp JOHTO_ROUTE31_VIOLET_GATE_LOCAL_ID
    jr z, .violetGate
    cp JOHTO_ROUTE_32_RUINS_OF_ALPH_GATE_LOCAL_ID
    jr z, .southGate
    cp JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID
    ret nz
    ld a, [wJohtoGateMusicSourceLocalID]
    cp JOHTO_ROUTE_36_LOCAL_ID
    jr z, .sourceValid
    cp JOHTO_RUINS_OF_ALPH_LOCAL_ID
    ret nz
    jr .sourceValid
.southGate
    ld a, [wJohtoGateMusicSourceLocalID]
    cp JOHTO_ROUTE_32_LOCAL_ID
    jr z, .sourceValid
    cp JOHTO_RUINS_OF_ALPH_LOCAL_ID
    ret nz
    jr .sourceValid
.violetGate
    ld a, [wJohtoGateMusicSourceLocalID]
    cp JOHTO_ROUTE_31_LOCAL_ID
    jr z, .sourceValid
    cp JOHTO_VIOLET_CITY_LOCAL_ID
    ret nz
    ; MUS-282: the city side must use its own music profile.  Falling
    ; through into .southForestGate silently reverted to the gate default.
    jp .sourceValid
.southForestGate
    ld a, [wJohtoGateMusicSourceLocalID]
    cp JOHTO_AZALEA_TOWN_LOCAL_ID
    jp z, .sourceValid
    cp JOHTO_ILEX_FOREST_LOCAL_ID
    ret nz
    jp .sourceValid
.northForestGate
    ld a, [wJohtoGateMusicSourceLocalID]
    cp JOHTO_ILEX_FOREST_LOCAL_ID
    jp z, .sourceValid
    cp JOHTO_ROUTE_34_LOCAL_ID
    ret nz
    jp .sourceValid
.sourceValid
    ld e, a
    call JohtoPilotGetMapProfile
    inc hl
    inc hl
    ld a, [hli]
    ld [wMapMusicSoundID], a
    ld a, [hl]
    ld [wMapMusicROMBank], a
    ret


; Outdoor boundary contract for the first N/S Gold seam. Called only when the
; player is on the native $FC handle and normal collisions are enabled.
; E=1 means closed, E=0 means continue original collision path.
; Route30 north is open only at its source-verified two-tile path; Route31
; south is open at the corresponding two tiles. All other unregistered edges
; remain closed until matching active headers/regions are available.
JohtoPilotIsClosedOutdoorEdge::
    ld e, 0
    ld a, [wCurRegion]
    cp MAP_REGION_JOHTO
    ret nz
    ld a, [wCurLocalMapID]
    cp JOHTO_CHERRYGROVE_LOCAL_ID
    jp z, .city
    cp JOHTO_ROUTE_30_LOCAL_ID
    jp z, .route30
    cp JOHTO_ROUTE_31_LOCAL_ID
    jp z, .route31
    cp JOHTO_GUIDE_GENTS_HOUSE_LOCAL_ID
    jp z, .houseCarpet
    cp JOHTO_VIOLET_CITY_LOCAL_ID
    jp z, .violet
    cp JOHTO_ROUTE_32_LOCAL_ID
    jp z, .route32
    cp JOHTO_ROUTE31_VIOLET_GATE_LOCAL_ID
    jp z, .gate
    cp JOHTO_ROUTE_32_RUINS_OF_ALPH_GATE_LOCAL_ID
    jp z, .gate
    cp JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID
    jp z, .northGateEdge
    cp JOHTO_ROUTE_36_LOCAL_ID
    jp z, .route36Edge
    cp JOHTO_RUINS_OF_ALPH_LOCAL_ID
    jp z, .ruinsClosedEdge
    cp JOHTO_UNION_CAVE_1F_LOCAL_ID
    jp z, .unionCaveClosedEdge
    cp JOHTO_ROUTE_33_LOCAL_ID
    jp z, .route33ClosedEdge
    cp JOHTO_AZALEA_TOWN_LOCAL_ID
    jp z, .southAzaleaEdge
    cp JOHTO_ROUTE_34_LOCAL_ID
    jp z, .southRoute34Edge
    cp JOHTO_GOLDENROD_CITY_LOCAL_ID
    jp z, .southGoldenrodEdge
    cp JOHTO_ILEX_AZALEA_GATE_LOCAL_ID
    jp z, .southClosedEdge
    cp JOHTO_ILEX_FOREST_LOCAL_ID
    jp z, .southClosedEdge
    cp JOHTO_ROUTE34_ILEX_GATE_LOCAL_ID
    jp z, .southClosedEdge
    ret
.southClosedEdge
    ; All six maps use finite geometry. Non-seam edges fail closed.
    callab JohtoSouthIsKnownClosedEdge
    ret
.southAzaleaEdge
    callab JohtoSouthIsKnownClosedEdge
    ret
.southRoute34Edge
    callab JohtoSouthIsKnownClosedEdge
    ret
.southGoldenrodEdge
    callab JohtoSouthIsKnownClosedEdge
    ret
.route33ClosedEdge
    ; No Route33/Route32 cross-tileset connection until a verified full reload.
    ; West Azalea and all other neighbours are also inactive.
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    jr z, .r33Up
    cp PLAYER_DIR_DOWN
    jr z, .r33Down
    cp PLAYER_DIR_LEFT
    jr z, .r33Left
    cp PLAYER_DIR_RIGHT
    ret nz
    ld a, [wXCoord]
    cp JOHTO_ROUTE_33_WIDTH * 2 - 1
    jp nc, .closed
    ret
.r33Up
    ld a, [wYCoord]
    and a
    jp z, .closed
    ret
.r33Down
    ld a, [wYCoord]
    cp JOHTO_ROUTE_33_HEIGHT * 2 - 1
    jp nc, .closed
    ret
.r33Left
    ld a, [wXCoord]
    and a
    ret nz
    ld a, [wYCoord]
    cp 14
    ret z
    cp 15
    ret z
    jp .closed
.unionCaveClosedEdge
    ; Cave has no external seams: its only door is an explicit Warp.
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    jr z, .unionCaveUp
    cp PLAYER_DIR_DOWN
    jr z, .unionCaveDown
    cp PLAYER_DIR_LEFT
    jr z, .unionCaveLeft
    cp PLAYER_DIR_RIGHT
    jr nz, .unionCaveAllowed
    ld a, [wXCoord]
    cp JOHTO_UNION_CAVE_1F_WIDTH * 2 - 1
    jp nc, .closed
    jr .unionCaveAllowed
.unionCaveUp
    ld a, [wYCoord]
    and a
    jp z, .closed
    jr .unionCaveAllowed
.unionCaveDown
    ld a, [wYCoord]
    cp JOHTO_UNION_CAVE_1F_HEIGHT * 2 - 1
    jp nc, .closed
    jr .unionCaveAllowed
.unionCaveLeft
    ld a, [wXCoord]
    and a
    jp z, .closed
.unionCaveAllowed
    ld e, 0
    ret
.route36Edge
    ; Prevent unregistered 35/37/Violet edges, allow interior movement.
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    jr z, .route36Up
    cp PLAYER_DIR_DOWN
    jr z, .route36Down
    cp PLAYER_DIR_LEFT
    jr z, .route36Left
    cp PLAYER_DIR_RIGHT
    ret nz
    ld a, [wXCoord]
    cp JOHTO_ROUTE_36_WIDTH * 2 - 1
    ret c
    jp .closed
.route36Up
    ld a, [wYCoord]
    and a
    ret nz
    jp .closed
.route36Down
    ld a, [wYCoord]
    cp JOHTO_ROUTE_36_HEIGHT * 2 - 1
    ret c
    jp .closed
.route36Left
    ld a, [wXCoord]
    and a
    ret nz
    jp .closed
.northGateEdge
    ; Prevent accidental walking out of the physical gate map edges.
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    jr z, .northGateUp
    cp PLAYER_DIR_DOWN
    jr z, .northGateDown
    cp PLAYER_DIR_LEFT
    jr z, .northGateLeft
    cp PLAYER_DIR_RIGHT
    ret nz
    ld a, [wXCoord]
    cp JOHTO_ROUTE36_RUINS_GATE_WIDTH * 2 - 1
    ret c
    jp .closed
.northGateLeft
    ld a, [wXCoord]
    and a
    ret nz
    jp .closed
.northGateUp
    ld a, [wYCoord]
    and a
    ret nz
    jp .closed
.northGateDown
    ld a, [wYCoord]
    cp JOHTO_ROUTE36_RUINS_GATE_HEIGHT * 2 - 1
    ret c
    jp .closed
.ruinsClosedEdge
    ; No direct outdoor seams on the current isolated ruins exterior.
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_LEFT
    jr z, .ruinsWest
    cp PLAYER_DIR_RIGHT
    jr z, .ruinsEast
    cp PLAYER_DIR_UP
    jr z, .ruinsNorth
    cp PLAYER_DIR_DOWN
    ret nz
    ld a, [wYCoord]
    cp JOHTO_RUINS_OF_ALPH_HEIGHT * 2 - 1
    ret c
    jp .closed
.ruinsNorth
    ld a, [wYCoord]
    and a
    ret nz
    jp .closed
.ruinsWest
    ld a, [wXCoord]
    and a
    ret nz
    jp .closed
.ruinsEast
    ld a, [wXCoord]
    cp JOHTO_RUINS_OF_ALPH_WIDTH * 2 - 1
    ret c
    jp .closed
.gate
    ; Gold EastWestGate: standing on x0/9 carpets is safe. Only an
    ; outward LEFT/RIGHT collision at the edge triggers a registered Warp.
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_LEFT
    jr z, .gateLeft
    cp PLAYER_DIR_RIGHT
    ret nz
    ld a, [wXCoord]
    cp JOHTO_ROUTE31_VIOLET_GATE_WIDTH * 2 - 1
    ret c
    jp .closed
.gateLeft
    ld a, [wXCoord]
    and a
    ret nz
    jp .closed
.violet
    ; No unverified direct outdoor seam to Route31/Route32/Route36.
    ; The only playable east entrance is the two-door registered gate.
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_RIGHT
    jr z, .violetEast
    cp PLAYER_DIR_LEFT
    jr z, .violetWest
    cp PLAYER_DIR_DOWN
    jr z, .violetSouth
    ld a, [wYCoord]
    and a
    ret nz
    jp .closed
.violetEast
    ld a, [wXCoord]
    cp JOHTO_VIOLET_CITY_WIDTH * 2 - 1
    ret c
    jp .closed
.violetWest
    ld a, [wXCoord]
    and a
    ret nz
    jp .closed
.violetSouth
    ld a, [wYCoord]
    cp JOHTO_VIOLET_CITY_HEIGHT * 2 - 1
    ret c
    ld a, [wXCoord]
    cp 14
    jp c, .closed
    cp 16
    ret c
    jp .closed
.route32
    ; Route32 is deliberately a one-way expansion of the *map network*,
    ; not a one-way walk: its only open edge is back to Violet City.
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    jr z, .route32North
    cp PLAYER_DIR_DOWN
    jr z, .route32South
    cp PLAYER_DIR_LEFT
    jr z, .route32West
    cp PLAYER_DIR_RIGHT
    ret nz
    ld a, [wXCoord]
    cp JOHTO_ROUTE_32_WIDTH * 2 - 1
    ret c
    jp .closed
.route32North
    ld a, [wYCoord]
    and a
    ret nz
    ld a, [wXCoord]
    cp 14
    jp c, .closed
    cp 16
    ret c
    jp .closed
.route32South
    ld a, [wYCoord]
    cp JOHTO_ROUTE_32_HEIGHT * 2 - 1
    ret c
    jp .closed
.route32West
    ld a, [wXCoord]
    and a
    ret nz
    jp .closed
.houseCarpet
    ; Gold WARP_CARPET_DOWN can be stood on. At y7, DOWN must collide
    ; with the map edge, so CheckWarpsCollision can resolve a registered
    ; house exit; sideways/up movement must remain freely walkable.
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_DOWN
    ret nz
    ld a, [wYCoord]
    cp JOHTO_GUIDE_GENTS_HOUSE_HEIGHT * 2 - 1
    ret c
    jp .closed
.route30
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    jr z, .route30North
    cp PLAYER_DIR_LEFT
    jr z, .route30West
    cp PLAYER_DIR_RIGHT
    jr z, .route30East
    cp PLAYER_DIR_DOWN
    ret nz
    ld a, [wYCoord]
    cp JOHTO_ROUTE_30_HEIGHT * 2 - 1
    ret c
    ld a, [wXCoord]
    cp 3 * 2
    jp c, .closed
    cp 4 * 2
    ret c
    jp .closed
.route30North
    ld a, [wYCoord]
    and a
    ret nz
    ld a, [wXCoord]
    cp 4 ; Route30 x=4..7 -> Route31 x=24..27
    jp c, .closed
    cp 8
    ret c
    jp .closed
.route30West
    ld a, [wXCoord]
    and a
    ret nz
    jp .closed
.route30East
    ld a, [wXCoord]
    cp JOHTO_ROUTE_30_WIDTH * 2 - 1
    ret c
    jp .closed
.route31
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_DOWN
    jr z, .route31South
    cp PLAYER_DIR_UP
    jr z, .route31North
    cp PLAYER_DIR_LEFT
    jr z, .route31West
    cp PLAYER_DIR_RIGHT
    ret nz
    ld a, [wXCoord]
    cp JOHTO_ROUTE_31_WIDTH * 2 - 1
    ret c
    jp .closed
.route31North
    ld a, [wYCoord]
    and a
    ret nz
    jp .closed
.route31West
    ld a, [wXCoord]
    cp 4
    jr nz, .route31PhysicalWest
    ld a, [wYCoord]
    cp 6
    jp z, .closed
    cp 7
    jp z, .closed
.route31PhysicalWest
    ld a, [wXCoord]
    and a
    ret nz
    jp .closed
.route31South
    ld a, [wYCoord]
    cp JOHTO_ROUTE_31_HEIGHT * 2 - 1
    ret c
    ld a, [wXCoord]
    cp 24
    jp c, .closed
    cp 28
    ret c
    jp .closed
.city
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    ret nz
    ld a, [wYCoord]
    and a
    ret nz
    ld a, [wXCoord]
    cp 8 * 2
    jp c, .closed
    cp 9 * 2
    ret c
.closed
    ld e, 1
    ret


 ; P6-GATE-004: All Route31/Violet west/east gate destinations are Gold
 ; WARP_CARPET_LEFT / WARP_CARPET_RIGHT, not solid DOOR tiles.
 ; They must REMAIN on their destination carpet; the next outward
 ; collision, not an arrival script, performs the reverse Warp.
 ; This matches NPC-5.62.243 GetJohtoWarpArrivalStep (no profiles
 ; for Route31VioletGate or its outdoor carpets).
JohtoPilotGateArrivalStep::
    ; ONLY after arrival on a north-side Gold DOOR, advance one step DOWN.
    ; Route36 carpets and the south gate carpets must never auto-step.
    ld e, 0
    ld a, [wCurMap]
    cp JOHTO_RUNTIME_MAP_HANDLE
    ret nz
    ld a, [wCurRegion]
    cp MAP_REGION_JOHTO
    ret nz
    ld a, [wCurLocalMapID]
    cp JOHTO_AZALEA_TOWN_LOCAL_ID
    jp c, .oldArrival
    cp JOHTO_GOLDENROD_CITY_LOCAL_ID + 1
    jp nc, .oldArrival
    callab JohtoSouthPortalArrivalStep
    ret
.oldArrival
    ld a, [wCurLocalMapID]
    cp JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID
    jr z, .gateTop
    ; Gold UnionCave1F (17,3) is WARP_CARPET_DOWN, not a DOOR.
    ; Arrive stationary facing the original UP approach; do not force a
    ; direction or simulate a step. DOWN is only the voluntary exit input.
    cp JOHTO_UNION_CAVE_1F_LOCAL_ID
    ret z
    cp JOHTO_ROUTE_32_LOCAL_ID
    jr z, .route32CaveLanding
    cp JOHTO_ROUTE_33_LOCAL_ID
    jr z, .route33CaveLanding
    cp JOHTO_RUINS_OF_ALPH_LOCAL_ID
    ret nz
    ld a, [wXCoord]
    cp 7
    ret nz
    ld a, [wYCoord]
    cp 5
    ret nz
    jr .down
.route33CaveLanding
    ld a, [wXCoord]
    cp 11
    ret nz
    ld a, [wYCoord]
    cp 9
    ret nz
    jr .down
.route32CaveLanding
    ld a, [wXCoord]
    cp 6
    ret nz
    ld a, [wYCoord]
    cp 79
    ret nz
    jr .down
.gateTop
    ld a, [wYCoord]
    and a
    ret nz
    ld a, [wXCoord]
    cp 4
    jr z, .down
    cp 5
    ret nz
.down
    ld e, D_DOWN
    ret

; P6-GATE-001: two *registered* exterior gate door approaches only.
; In: player coordinate BEFORE step. Out: E=1 bypass normal tile collision.
; Reused by the Warp executor with matching target coordinate AFTER step.
; Never weakens neighbouring scenery or Kanto collision.
JohtoPilotGateDoorApproachAllowed::
    ld e, 0
    ld a, [wCurRegion]
    cp MAP_REGION_JOHTO
    ret nz
    ld a, [wCurLocalMapID]
    cp JOHTO_AZALEA_TOWN_LOCAL_ID
    jp c, .oldGateRules
    cp JOHTO_GOLDENROD_CITY_LOCAL_ID + 1
    jp nc, .oldGateRules
    callab JohtoSouthPortalBeforeStep
    ret
.oldGateRules
    ld a, [wCurLocalMapID]
    cp JOHTO_ROUTE_32_LOCAL_ID
    jp z, .route32Alph
    cp JOHTO_ROUTE_33_LOCAL_ID
    jp z, .route33Cave
    ; The cave interior is collision-only: never STEP_ON or override walls.
    cp JOHTO_UNION_CAVE_1F_LOCAL_ID
    ret z
    cp JOHTO_RUINS_OF_ALPH_LOCAL_ID
    jp z, .ruinsAlph
    cp JOHTO_ROUTE_36_LOCAL_ID
    jp z, .route36Alph
    cp JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID
    jp z, .northGateTopDoor
    cp JOHTO_ROUTE_31_LOCAL_ID
    jr z, .route31
    cp JOHTO_VIOLET_CITY_LOCAL_ID
    ret nz
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_RIGHT
    ret nz
    ld a, [wXCoord]
    cp 38
    ret nz
    ld a, [wYCoord]
    cp 24
    jp z, .allow
    cp 25
    ret nz
    jp .allow
.route31
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_LEFT
    ret nz
    ld a, [wXCoord]
    cp 5
    ret nz
    ld a, [wYCoord]
    cp 6
    jp z, .allow
    cp 7
    ret nz
    jp .allow
.route33Cave
    ; Only (11,10) north to the Gold CAVE at (11,9).
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    ret nz
    ld a, [wXCoord]
    cp 11
    ret nz
    ld a, [wYCoord]
    cp 10
    ret nz
    jp .allow
.route32Alph
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    jr z, .route32Cave
    cp PLAYER_DIR_LEFT
    ret nz
    ld a, [wXCoord]
    cp 5
    ret nz
    ld a, [wYCoord]
    cp 2
    jr z, .allow
    cp 3
    ret nz
    jr .allow
.route32Cave
    ld a, [wXCoord]
    cp 6
    ret nz
    ld a, [wYCoord]
    cp 80
    ret nz
    jp .allow
.ruinsAlph
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_RIGHT
    jr z, .ruinsSouth
    cp PLAYER_DIR_UP
    ret nz
    ld a, [wXCoord]
    cp 7
    ret nz
    ld a, [wYCoord]
    cp 6
    ret nz
    jr .allow
.ruinsSouth
    ld a, [wXCoord]
    cp 12
    ret nz
    ld a, [wYCoord]
    cp 20
    jr z, .allow
    cp 21
    ret nz
    jr .allow ; preserve the already-validated Ruins south right-hand lane

.route36Alph
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_DOWN
    ret nz
    ld a, [wYCoord]
    cp 12
    ret nz
    ld a, [wXCoord]
    cp 47
    jr z, .allow
    cp 48
    ret nz
    jr .allow
.northGateTopDoor
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    ret nz
    ld a, [wYCoord]
    cp 1
    ret nz
    ld a, [wXCoord]
    cp 4
    jr z, .allow
    cp 5
    ret nz
    jr .allow
.allow
    ld e, 1
    ret

JohtoPilotGateDoorWarpMatched::
    ld e, 0
    ld a, [wCurRegion]
    cp MAP_REGION_JOHTO
    ret nz
    ld a, [wCurLocalMapID]
    cp JOHTO_AZALEA_TOWN_LOCAL_ID
    jp c, .oldGateRules
    cp JOHTO_GOLDENROD_CITY_LOCAL_ID + 1
    jp nc, .oldGateRules
    callab JohtoSouthPortalAfterStep
    ret
.oldGateRules
    ld a, [wCurLocalMapID]
    cp JOHTO_ROUTE_32_LOCAL_ID
    jp z, .route32Alph
    cp JOHTO_ROUTE_33_LOCAL_ID
    jp z, .route33Cave
    ; The cave interior is collision-only: never STEP_ON or override walls.
    cp JOHTO_UNION_CAVE_1F_LOCAL_ID
    ret z
    cp JOHTO_RUINS_OF_ALPH_LOCAL_ID
    jp z, .ruinsAlph
    cp JOHTO_ROUTE_36_LOCAL_ID
    jp z, .route36Alph
    cp JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID
    jp z, .northGateTopDoor
    cp JOHTO_ROUTE_31_LOCAL_ID
    jr z, .route31
    cp JOHTO_VIOLET_CITY_LOCAL_ID
    ret nz
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_RIGHT
    ret nz
    ld a, [wXCoord]
    cp 39
    ret nz
    ld a, [wYCoord]
    cp 24
    jp z, .allow
    cp 25
    ret nz
    jp .allow
.route31
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_LEFT
    ret nz
    ld a, [wXCoord]
    cp 4
    ret nz
    ld a, [wYCoord]
    cp 6
    jp z, .allow
    cp 7
    ret nz
    jp .allow
.route33Cave
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    ret nz
    ld a, [wXCoord]
    cp 11
    ret nz
    ld a, [wYCoord]
    cp 9
    ret nz
    jp .yesDoor
.route32Alph
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    jr z, .route32Cave
    cp PLAYER_DIR_LEFT
    ret nz
    ld a, [wXCoord]
    cp 4
    ret nz
    ld a, [wYCoord]
    cp 2
    jr z, .allow
    cp 3
    ret nz
    jr .allow
.route32Cave
    ld a, [wXCoord]
    cp 6
    ret nz
    ld a, [wYCoord]
    cp 79
    ret nz
    jp .yesDoor
.ruinsAlph
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_RIGHT
    jr z, .ruinsSouth
    cp PLAYER_DIR_UP
    ret nz
    ld a, [wXCoord]
    cp 7
    ret nz
    ld a, [wYCoord]
    cp 5
    ret nz
    jr .yesDoor
.ruinsSouth
    ld a, [wXCoord]
    cp 13
    ret nz
    ld a, [wYCoord]
    cp 20
    jr z, .allow
    cp 21
    ret nz
    jr .allow ; preserve the already-validated Ruins south right-hand lane

.route36Alph
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_DOWN
    ret nz
    ld a, [wYCoord]
    cp 13
    ret nz
    ld a, [wXCoord]
    cp 47
    jr z, .allow
    cp 48
    ret nz
    jr .allow
.northGateTopDoor
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    ret nz
    ld a, [wYCoord]
    and a
    ret nz
    ld a, [wXCoord]
    cp 4
    jr z, .yesDoor
    cp 5
    ret nz
    jr .yesDoor
.yesDoor
    ld e, 2 ; special exact STEP_ON DOOR (not a carpet)
    ret
.allow
    ld e, 1
    ret

; P6-GATE-004: standing-on-carpet (not entering it) exit collision.
; EastWestGate's outdoor counterparts are both real Gold direction carpets.
; Route31 (Y6/7,X4) faces LEFT and is not the physical map edge;
; Violet City (Y24/25,X39) faces RIGHT and is the map edge.
; E=1 only for the exact open pair and correct outward direction.
JohtoPilotGateExteriorCollisionAllowed::
    ld e, 0
    ld a, [wCurLocalMapID]
    cp JOHTO_AZALEA_TOWN_LOCAL_ID
    jp c, .legacyExtra
    cp JOHTO_GOLDENROD_CITY_LOCAL_ID + 1
    jp nc, .legacyExtra
    callab JohtoSouthPortalCollisionExit
    ret
.legacyExtra
    ld a, [wCurLocalMapID]
    ; FIX-264: ExtraWarpCheck calls THIS predicate before CheckWarpsCollision.
    ; The first Union Cave fix only added the final collision guard, leaving
    ; the entry qualification false and making the north exit unreachable.
    ; Share the final coordinate/facing guard: do not create a second rule.
    cp JOHTO_UNION_CAVE_1F_LOCAL_ID
    jp z, JohtoPilotGateCollisionExitAllowed
    cp JOHTO_ROUTE_32_LOCAL_ID
    jr z,.route32Alph
    cp JOHTO_ROUTE_36_LOCAL_ID
    jp z, .route36Alph
    cp JOHTO_RUINS_OF_ALPH_LOCAL_ID
    jr z, .ruinsAlph
    cp JOHTO_ROUTE_31_LOCAL_ID
    jr z, .route31
    cp JOHTO_VIOLET_CITY_LOCAL_ID
    ret nz
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_RIGHT
    ret nz
    ld a, [wXCoord]
    cp 39
    ret nz
    ld a, [wYCoord]
    cp 24
    jr z, .yes
    cp 25
    ret nz
    jr .yes
.route31
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_LEFT
    ret nz
    ld a, [wXCoord]
    cp 4
    ret nz
    ld a, [wYCoord]
    cp 6
    jr z, .yes
    cp 7
    ret nz
    jr .yes
.route32Alph
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_LEFT
    ret nz
    ld a, [wXCoord]
    cp 4
    ret nz
    ld a, [wYCoord]
    cp 2
    jr z, .yes
    cp 3
    ret nz
    jr .yes
.ruinsAlph
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_RIGHT
    ret nz
    ld a, [wXCoord]
    cp 13
    ret nz
    ld a, [wYCoord]
    cp 20
    jr z, .yes
    cp 21
    ret nz
    jr .yes
.route36Alph
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_DOWN
    ret nz
    ld a, [wYCoord]
    cp 13
    ret nz
    ld a, [wXCoord]
    cp 47
    jr z, .yes
    cp 48
    ret nz
    jr .yes
.yes
    ld e, 1
    ret

; P6-GATE-001: a colliding warp in the EastWestGate must match the
; Gold carpet's orientation. Without this additional guard, RPP's generic
; CheckWarpsCollision can warp when the player hits a *different* obstacle
; while standing on the edge carpet. Non-gate maps retain Kanto behavior.
; Result E=1 permits the matched collision warp, E=0 denies it.
JohtoPilotGateCollisionExitAllowed::
    ld e, 1
    ld a, [wCurMap]
    cp JOHTO_RUNTIME_MAP_HANDLE
    ret nz
    ld a, [wCurRegion]
    cp MAP_REGION_JOHTO
    ret nz
    ld a, [wCurLocalMapID]
    cp JOHTO_AZALEA_TOWN_LOCAL_ID
    jp c, .legacyGuard
    cp JOHTO_GOLDENROD_CITY_LOCAL_ID + 1
    jp nc, .legacyGuard
    callab JohtoSouthPortalCollisionExit
    ret
.legacyGuard
    ld a, [wCurLocalMapID]
    cp JOHTO_ROUTE31_VIOLET_GATE_LOCAL_ID
    jr z, .isGate
    cp JOHTO_ROUTE_32_RUINS_OF_ALPH_GATE_LOCAL_ID
    jr z, .isGate
    cp JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID
    jr z, .northGateBottom
    cp JOHTO_UNION_CAVE_1F_LOCAL_ID
    jr z, .unionCaveExit
    cp JOHTO_ROUTE_36_LOCAL_ID
    ret nz
    ld e, 0
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_DOWN
    ret nz
    ld a, [wYCoord]
    cp 13
    ret nz
    ld a, [wXCoord]
    cp 47
    jr z, .yes
    cp 48
    ret nz
    jr .yes
.unionCaveExit
    ; Gold WARP_CARPET_DOWN: collide with the solid south neighbor
    ; while standing exactly on the north entrance at (17,3).
    ld e, 0
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_DOWN
    ret nz
    ld a, [wXCoord]
    cp 17
    ret nz
    ld a, [wYCoord]
    cp 3
    jr z, .yes
    cp 31
    ret nz
    jr .yes
.northGateBottom
    ld e, 0
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_DOWN
    ret nz
    ld a, [wYCoord]
    cp 7
    ret nz
    ld a, [wXCoord]
    cp 4
    jr z, .yes
    cp 5
    ret nz
    jr .yes
.isGate
    ld e, 0
    ld a, [wYCoord]
    cp 4
    jr z, .lane
    cp 5
    ret nz
.lane
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_LEFT
    jr z, .left
    cp PLAYER_DIR_RIGHT
    ret nz
    ld a, [wXCoord]
    cp JOHTO_ROUTE31_VIOLET_GATE_WIDTH * 2 - 1
    ret nz
    jr .yes
.left
    ld a, [wXCoord]
    and a
    ret nz
.yes
    ld e, 1
    ret
