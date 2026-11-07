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
    ; DEV-334: Gold Cherrygrove Pokecenter door (Y3,X29) added as ordinal 1.
    ; The shared Kanto interior has two bottom exits, both return to ordinal 1.
    db MAP_REGION_JOHTO, JOHTO_CHERRYGROVE_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_CHERRYGROVE_POKECENTER_1F_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_CHERRYGROVE_POKECENTER_1F_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_CHERRYGROVE_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_CHERRYGROVE_POKECENTER_1F_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_CHERRYGROVE_LOCAL_ID
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
    ; Ruins gate Gold #3/#4 keep slots0/1; Park Gold #1/#2 activate slots2/3.
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
    ; MAP-283: Goldenrod door Gold #13 -> gate south carpet; two return lanes.
    db MAP_REGION_JOHTO, JOHTO_GOLDENROD_CITY_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_ROUTE_35_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_ROUTE_35_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID, 2, MAP_REGION_JOHTO, JOHTO_GOLDENROD_CITY_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID, 3, MAP_REGION_JOHTO, JOHTO_GOLDENROD_CITY_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_35_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_35_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID
    ; MAP-286: seven new reciprocal park gates; existing ordinals never change.
    db MAP_REGION_JOHTO, JOHTO_ROUTE_35_LOCAL_ID, 2, MAP_REGION_JOHTO, JOHTO_ROUTE_35_NATIONAL_PARK_GATE_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_36_LOCAL_ID, 2, MAP_REGION_JOHTO, JOHTO_ROUTE_36_NATIONAL_PARK_GATE_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_36_LOCAL_ID, 3, MAP_REGION_JOHTO, JOHTO_ROUTE_36_NATIONAL_PARK_GATE_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_NATIONAL_PARK_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_ROUTE_36_NATIONAL_PARK_GATE_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_NATIONAL_PARK_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_ROUTE_36_NATIONAL_PARK_GATE_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_NATIONAL_PARK_LOCAL_ID, 2, MAP_REGION_JOHTO, JOHTO_ROUTE_35_NATIONAL_PARK_GATE_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_NATIONAL_PARK_LOCAL_ID, 3, MAP_REGION_JOHTO, JOHTO_ROUTE_35_NATIONAL_PARK_GATE_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_35_NATIONAL_PARK_GATE_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_NATIONAL_PARK_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_35_NATIONAL_PARK_GATE_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_NATIONAL_PARK_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_35_NATIONAL_PARK_GATE_LOCAL_ID, 2, MAP_REGION_JOHTO, JOHTO_ROUTE_35_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_35_NATIONAL_PARK_GATE_LOCAL_ID, 3, MAP_REGION_JOHTO, JOHTO_ROUTE_35_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_36_NATIONAL_PARK_GATE_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_NATIONAL_PARK_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_36_NATIONAL_PARK_GATE_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_NATIONAL_PARK_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_36_NATIONAL_PARK_GATE_LOCAL_ID, 2, MAP_REGION_JOHTO, JOHTO_ROUTE_36_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_36_NATIONAL_PARK_GATE_LOCAL_ID, 3, MAP_REGION_JOHTO, JOHTO_ROUTE_36_LOCAL_ID
    ; MAP-297: Ecruteak west gate <-> Route38, exact paired Gold carpets.
    db MAP_REGION_JOHTO, JOHTO_ECRUTEAK_CITY_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_ROUTE_38_ECRUTEAK_GATE_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ECRUTEAK_CITY_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_ROUTE_38_ECRUTEAK_GATE_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_38_ECRUTEAK_GATE_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_ROUTE_38_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_38_ECRUTEAK_GATE_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_ROUTE_38_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_38_ECRUTEAK_GATE_LOCAL_ID, 2, MAP_REGION_JOHTO, JOHTO_ECRUTEAK_CITY_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_38_ECRUTEAK_GATE_LOCAL_ID, 3, MAP_REGION_JOHTO, JOHTO_ECRUTEAK_CITY_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_38_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_ROUTE_38_ECRUTEAK_GATE_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_38_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_ROUTE_38_ECRUTEAK_GATE_LOCAL_ID
    ; MAP-300: Ecruteak east gate <-> Route42, exact paired Gold carpets.
    db MAP_REGION_JOHTO, JOHTO_ECRUTEAK_CITY_LOCAL_ID, 2, MAP_REGION_JOHTO, JOHTO_ROUTE_42_ECRUTEAK_GATE_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ECRUTEAK_CITY_LOCAL_ID, 3, MAP_REGION_JOHTO, JOHTO_ROUTE_42_ECRUTEAK_GATE_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_42_ECRUTEAK_GATE_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_ECRUTEAK_CITY_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_42_ECRUTEAK_GATE_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_ECRUTEAK_CITY_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_42_ECRUTEAK_GATE_LOCAL_ID, 2, MAP_REGION_JOHTO, JOHTO_ROUTE_42_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_42_ECRUTEAK_GATE_LOCAL_ID, 3, MAP_REGION_JOHTO, JOHTO_ROUTE_42_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_42_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_ROUTE_42_ECRUTEAK_GATE_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_42_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_ROUTE_42_ECRUTEAK_GATE_LOCAL_ID
    ; DEV-313: Mahogany Gold door #5 (9,1) -> Gate south carpet #3.
    ; Gate south pair -> Mahogany Gold door #5; Route43 north pair registered in REF-315.
    db MAP_REGION_JOHTO, JOHTO_MAHOGANY_TOWN_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_MAHOGANY_TOWN_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_MAHOGANY_TOWN_LOCAL_ID
    ; REF-315: Route43 south entrance, ID65 north DOOR pair (preserved by DEV-319).
    db MAP_REGION_JOHTO, JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID, 2, MAP_REGION_JOHTO, JOHTO_ROUTE_43_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID, 3, MAP_REGION_JOHTO, JOHTO_ROUTE_43_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_43_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_43_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID
    ; DEV-319: Gold Route43 west-side door #3 and north carpets #4/#5 to ID66.
    db MAP_REGION_JOHTO, JOHTO_ROUTE_43_LOCAL_ID, 2, MAP_REGION_JOHTO, JOHTO_ROUTE_43_GATE_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_43_LOCAL_ID, 3, MAP_REGION_JOHTO, JOHTO_ROUTE_43_GATE_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_43_LOCAL_ID, 4, MAP_REGION_JOHTO, JOHTO_ROUTE_43_GATE_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_43_GATE_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_ROUTE_43_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_43_GATE_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_ROUTE_43_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_43_GATE_LOCAL_ID, 2, MAP_REGION_JOHTO, JOHTO_ROUTE_43_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_43_GATE_LOCAL_ID, 3, MAP_REGION_JOHTO, JOHTO_ROUTE_43_LOCAL_ID
    ; DEV-328: original Route29/46 Gate, zero-based source ordinals.
    db MAP_REGION_JOHTO, JOHTO_ROUTE_29_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_ROUTE_29_ROUTE_46_GATE_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_46_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_ROUTE_29_ROUTE_46_GATE_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_46_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_ROUTE_29_ROUTE_46_GATE_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_29_ROUTE_46_GATE_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_ROUTE_46_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_29_ROUTE_46_GATE_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_ROUTE_46_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_29_ROUTE_46_GATE_LOCAL_ID, 2, MAP_REGION_JOHTO, JOHTO_ROUTE_29_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_29_ROUTE_46_GATE_LOCAL_ID, 3, MAP_REGION_JOHTO, JOHTO_ROUTE_29_LOCAL_ID
    ; Route32 (11,73) UP enters center; both Gold DOWN carpets return here.
    ; Route32 existing ordinal 0..2 must not change (ruins/Union Cave).
    db MAP_REGION_JOHTO, JOHTO_ROUTE_32_LOCAL_ID, 3, MAP_REGION_JOHTO, JOHTO_ROUTE_32_POKECENTER_1F_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_32_POKECENTER_1F_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_ROUTE_32_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_32_POKECENTER_1F_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_ROUTE_32_LOCAL_ID
    ; REF-334: Azalea Gold door (15,9), two separate 1F carpet returns.
    ; Existing town ordinals 0/1 (Ilex Forest gate) are never shifted.
    db MAP_REGION_JOHTO, JOHTO_AZALEA_TOWN_LOCAL_ID, 2, MAP_REGION_JOHTO, JOHTO_AZALEA_POKECENTER_1F_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_AZALEA_POKECENTER_1F_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_AZALEA_TOWN_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_AZALEA_POKECENTER_1F_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_AZALEA_TOWN_LOCAL_ID
    ; REF-335: Gold VioletPokecenter exterior door and paired return carpets.
    db MAP_REGION_JOHTO, JOHTO_VIOLET_CITY_LOCAL_ID, 2, MAP_REGION_JOHTO, JOHTO_VIOLET_POKECENTER_1F_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_VIOLET_POKECENTER_1F_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_VIOLET_CITY_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_VIOLET_POKECENTER_1F_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_VIOLET_CITY_LOCAL_ID
    ; REF-335: Gold GoldenrodPokecenter exterior door and paired return carpets.
    db MAP_REGION_JOHTO, JOHTO_GOLDENROD_CITY_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_GOLDENROD_POKECENTER_1F_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_GOLDENROD_POKECENTER_1F_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_GOLDENROD_CITY_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_GOLDENROD_POKECENTER_1F_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_GOLDENROD_CITY_LOCAL_ID
    ; REF-336: Gold Ecruteak exterior door #6 and paired carpet exits.
    db MAP_REGION_JOHTO, JOHTO_ECRUTEAK_CITY_LOCAL_ID, 4, MAP_REGION_JOHTO, JOHTO_ECRUTEAK_POKECENTER_1F_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ECRUTEAK_POKECENTER_1F_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_ECRUTEAK_CITY_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ECRUTEAK_POKECENTER_1F_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_ECRUTEAK_CITY_LOCAL_ID
    ; REF-336: Gold Olivine exterior door #1 and paired carpet exits.
    db MAP_REGION_JOHTO, JOHTO_OLIVINE_CITY_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_OLIVINE_POKECENTER_1F_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_OLIVINE_POKECENTER_1F_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_OLIVINE_CITY_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_OLIVINE_POKECENTER_1F_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_OLIVINE_CITY_LOCAL_ID
    ; REF-336: Gold Cianwood exterior door #3 and paired carpet exits.
    db MAP_REGION_JOHTO, JOHTO_CIANWOOD_CITY_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_CIANWOOD_POKECENTER_1F_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_CIANWOOD_POKECENTER_1F_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_CIANWOOD_CITY_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_CIANWOOD_POKECENTER_1F_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_CIANWOOD_CITY_LOCAL_ID
    ; REF-336: Gold Mahogany exterior door #4 and paired carpet exits.
    db MAP_REGION_JOHTO, JOHTO_MAHOGANY_TOWN_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_MAHOGANY_POKECENTER_1F_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_MAHOGANY_POKECENTER_1F_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_MAHOGANY_TOWN_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_MAHOGANY_POKECENTER_1F_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_MAHOGANY_TOWN_LOCAL_ID
    ; REF-338: Blackthorn Gold door #5 and both 1F carpet return routes.
    ; Outdoor ordinal0 (only active building), room destination warp0 (left).
    db MAP_REGION_JOHTO, JOHTO_BLACKTHORN_CITY_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_BLACKTHORN_POKECENTER_1F_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_BLACKTHORN_POKECENTER_1F_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_BLACKTHORN_CITY_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_BLACKTHORN_POKECENTER_1F_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_BLACKTHORN_CITY_LOCAL_ID
    ; REF-340 B2F pilot: keep the two REF-339 1F/B1F reciprocal stair pairs.
    ; B1F Ruins ordinal0/1 remain inactive; ordinal4 now opens B2F and returns via B2F ordinal0.
    db MAP_REGION_JOHTO, JOHTO_UNION_CAVE_1F_LOCAL_ID, 2, MAP_REGION_JOHTO, JOHTO_UNION_CAVE_B1F_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_UNION_CAVE_1F_LOCAL_ID, 3, MAP_REGION_JOHTO, JOHTO_UNION_CAVE_B1F_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_UNION_CAVE_B1F_LOCAL_ID, 2, MAP_REGION_JOHTO, JOHTO_UNION_CAVE_1F_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_UNION_CAVE_B1F_LOCAL_ID, 3, MAP_REGION_JOHTO, JOHTO_UNION_CAVE_1F_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_UNION_CAVE_B1F_LOCAL_ID, 4, MAP_REGION_JOHTO, JOHTO_UNION_CAVE_B2F_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_UNION_CAVE_B2F_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_UNION_CAVE_B1F_LOCAL_ID
    ; Azalea Gold #6 <-> Slowpoke Well B1F Gold #1, B1F Gold #2 <-> B2F Gold #1.
    db MAP_REGION_JOHTO, JOHTO_AZALEA_TOWN_LOCAL_ID, 3, MAP_REGION_JOHTO, JOHTO_SLOWPOKE_WELL_B1F_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_SLOWPOKE_WELL_B1F_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_AZALEA_TOWN_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_SLOWPOKE_WELL_B1F_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_SLOWPOKE_WELL_B2F_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_SLOWPOKE_WELL_B2F_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_SLOWPOKE_WELL_B1F_LOCAL_ID
    ; REF-347 Burned Tower 1F: City Gold door + two DOWN-only carpet exits.
    db MAP_REGION_JOHTO, JOHTO_ECRUTEAK_CITY_LOCAL_ID, 5, MAP_REGION_JOHTO, JOHTO_BURNED_TOWER_1F_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_BURNED_TOWER_1F_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_ECRUTEAK_CITY_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_BURNED_TOWER_1F_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_ECRUTEAK_CITY_LOCAL_ID
    ; REF-348: all eleven Gold PIT ordinals 2-12 and the lower ladder ordinal13
    ; enter B1F. B1F ordinals0-4 are arrival-only; only ordinal5 is a return ladder.
    db MAP_REGION_JOHTO, JOHTO_BURNED_TOWER_1F_LOCAL_ID, 2, MAP_REGION_JOHTO, JOHTO_BURNED_TOWER_B1F_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_BURNED_TOWER_1F_LOCAL_ID, 3, MAP_REGION_JOHTO, JOHTO_BURNED_TOWER_B1F_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_BURNED_TOWER_1F_LOCAL_ID, 4, MAP_REGION_JOHTO, JOHTO_BURNED_TOWER_B1F_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_BURNED_TOWER_1F_LOCAL_ID, 5, MAP_REGION_JOHTO, JOHTO_BURNED_TOWER_B1F_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_BURNED_TOWER_1F_LOCAL_ID, 6, MAP_REGION_JOHTO, JOHTO_BURNED_TOWER_B1F_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_BURNED_TOWER_1F_LOCAL_ID, 7, MAP_REGION_JOHTO, JOHTO_BURNED_TOWER_B1F_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_BURNED_TOWER_1F_LOCAL_ID, 8, MAP_REGION_JOHTO, JOHTO_BURNED_TOWER_B1F_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_BURNED_TOWER_1F_LOCAL_ID, 9, MAP_REGION_JOHTO, JOHTO_BURNED_TOWER_B1F_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_BURNED_TOWER_1F_LOCAL_ID, 10, MAP_REGION_JOHTO, JOHTO_BURNED_TOWER_B1F_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_BURNED_TOWER_1F_LOCAL_ID, 11, MAP_REGION_JOHTO, JOHTO_BURNED_TOWER_B1F_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_BURNED_TOWER_1F_LOCAL_ID, 12, MAP_REGION_JOHTO, JOHTO_BURNED_TOWER_B1F_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_BURNED_TOWER_1F_LOCAL_ID, 13, MAP_REGION_JOHTO, JOHTO_BURNED_TOWER_B1F_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_BURNED_TOWER_B1F_LOCAL_ID, 5, MAP_REGION_JOHTO, JOHTO_BURNED_TOWER_1F_LOCAL_ID
    ; REF-349 stage3: preserve Gold ordinal1 (Blackthorn) unregistered; open ordinal2 (Route46).
    db MAP_REGION_JOHTO, JOHTO_ROUTE_31_LOCAL_ID, 2, MAP_REGION_JOHTO, JOHTO_DARK_CAVE_VIOLET_ENTRANCE_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_DARK_CAVE_VIOLET_ENTRANCE_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_ROUTE_31_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_46_LOCAL_ID, 2, MAP_REGION_JOHTO, JOHTO_DARK_CAVE_VIOLET_ENTRANCE_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_DARK_CAVE_VIOLET_ENTRANCE_LOCAL_ID, 2, MAP_REGION_JOHTO, JOHTO_ROUTE_46_LOCAL_ID
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
    jp nz, .skipFour
    ld a, [hli]
    cp c
    jp nz, .skipThree
    ld a, [wWarpedFromWhichWarp]
    cp [hl]
    jp nz, .skipThree
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
    jr z, .recordGateSource
    cp JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID
    jr z, .recordGateSource
    cp JOHTO_ROUTE_35_NATIONAL_PARK_GATE_LOCAL_ID
    jr z, .recordGateSource
    cp JOHTO_ROUTE_36_NATIONAL_PARK_GATE_LOCAL_ID
    jr z, .recordGateSource
    cp JOHTO_ROUTE_38_ECRUTEAK_GATE_LOCAL_ID
    jr z, .recordGateSource
    cp JOHTO_ROUTE_42_ECRUTEAK_GATE_LOCAL_ID
    jr z, .recordGateSource
    cp JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID
    jr z, .recordGateSource
    cp JOHTO_ROUTE_43_GATE_LOCAL_ID
    jr z, .recordGateSource
    cp JOHTO_ROUTE_29_ROUTE_46_GATE_LOCAL_ID
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
    ; REF-349 video: keep a dedicated dark record with ordinary OBJ colors.
    ; The destination may be a DARK cave (entry) or the outdoor landing from
    ; an UNLIT cave (exit). Preserve offset 12 through the shared doorway fade.
    ; The palette helper clears it only after the new map has been staged.
    ld a, [wCurLocalMapID]
    cp JOHTO_DARK_CAVE_VIOLET_ENTRANCE_LOCAL_ID
    jr z, .unlitDarkPalette349
    ld a, c ; source stable ID, retained by GetJohtoActiveSlot
    cp JOHTO_DARK_CAVE_VIOLET_ENTRANCE_LOCAL_ID
    jr nz, .normalPalette349
    ld a, [wMapPalOffset]
    cp 12 ; was the source cave still unlit?
    jr nz, .normalPalette349 ; Flash-lit cave exits use regular white fade
    ; REF-353: do not force the source cave white. The common doorway fade
    ; keeps its dark BG/OBJ monotonic while switching to the LCD-on loader.
.unlitDarkPalette349
    ld a, 12 ; FadePal4 - FadePalJohtoDark349, BG dark / OBJ normal
    jr .storePalette349
.normalPalette349
    xor a
.storePalette349
    ld [wMapPalOffset], a
    ld e, JOHTO_RUNTIME_MAP_HANDLE
    ret
.skipFour
    inc hl ; source ID
.skipThree
    inc hl ; ordinal
    inc hl ; dest region
    inc hl ; dest ID
    jp .loop

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
    johto_map_profile 0, 17, MUSIC_ROUTES1, 0 ; slot 21 Route35GoldenrodGate (source music)
    johto_map_profile 1, 17, MUSIC_ROUTES1, 0 ; slot 22 Route35 (Gold Route36 theme)
    johto_map_profile 1, 18, MUSIC_ROUTES1, 0 ; slot23 Park, Gold independent park music handled by scene mode
    johto_map_profile 0, 17, MUSIC_ROUTES1, 0 ; slot24 Route35 Park gate inherits source
    johto_map_profile 0, 19, MUSIC_ROUTES1, 0 ; slot25 Route36 Park gate inherits source
    johto_map_profile 1, 20, MUSIC_ROUTES1, 0 ; slot26 Route37 Gold Route37
    johto_map_profile 1, 21, MUSIC_CITIES1, 0 ; slot27 Ecruteak City, Fly on visit
    johto_map_profile 0, 24, MUSIC_ROUTES1, 0 ; slot28 Route38/Ecruteak gate, source music
    johto_map_profile 1, 24, MUSIC_ROUTES1, 0 ; slot29 Route38, Gold Route37 family
    johto_map_profile 1, 25, MUSIC_ROUTES1, 0 ; slot30 Route39, Gold Route37 family
    johto_map_profile 1, 26, MUSIC_CITIES1, 0 ; slot31 Olivine City
    johto_map_profile 1, 28, MUSIC_ROUTES1, 0 ; slot32 Route40
    johto_map_profile 1, 30, MUSIC_ROUTES1, 0 ; slot33 Route41
    johto_map_profile 1, 31, MUSIC_CITIES1, 0 ; slot34 Cianwood City
    johto_map_profile 0, 32, MUSIC_ROUTES1, 0 ; slot35 Route42/Ecruteak gate, source music
    johto_map_profile 1, 32, MUSIC_ROUTES1, 0 ; slot36 Route42
    johto_map_profile 1, 34, MUSIC_CITIES1, 0 ; slot37 Mahogany Town
    johto_map_profile 0, 34, MUSIC_CITIES1, 0 ; slot38 Mahogany north gate, inherits city music
    johto_map_profile 1, 35, MUSIC_ROUTES1, 0 ; slot39 Route43, Gold LakeOfRage theme
    johto_map_profile 0, 35, MUSIC_ROUTES1, 0 ; slot40 Route43Gate, neutral (Route43 music)
    johto_map_profile 1, 36, MUSIC_ROUTES1, 0 ; slot41 Lake of Rage, exact Gold outdoor landmark
    johto_map_profile 1, 37, MUSIC_ROUTES1, 0 ; slot42 Route44, original Gold Lake of Rage theme
    johto_map_profile 1, 39, MUSIC_CITIES1, 0 ; slot43 Blackthorn City, outdoor
    johto_map_profile 1, 41, MUSIC_ROUTES2, 0 ; slot44 Route45
    johto_map_profile 1, 43, MUSIC_ROUTES2, 0 ; slot45 Route46
    johto_map_profile 0, 1, MUSIC_ROUTES1, 0 ; slot46 Route29/46 Gate
    ; DEV-334 shared Pokecenter template: indoor, parent Cherrygrove, heal music.
    johto_map_profile 0, 2, MUSIC_POKECENTER, 0 ; slot 47 Gold CherrygrovePokecenter1F ID123
    johto_map_profile 0, 7, MUSIC_POKECENTER, 0 ; slot48 Route32 Center ID106; no independent Fly
    johto_map_profile 0, 11, MUSIC_POKECENTER, 0 ; slot49 Azalea Gold Center ID135
    johto_map_profile 0, 5, MUSIC_POKECENTER, 0 ; slot50 Violet Gold Center ID133
    johto_map_profile 0, 15, MUSIC_POKECENTER, 0 ; slot51 Goldenrod Gold Center ID146
    johto_map_profile 0, 21, MUSIC_POKECENTER, 0 ; slot52 Ecruteak Center ID160
    johto_map_profile 0, 26, MUSIC_POKECENTER, 0 ; slot53 Olivine Center ID30
    johto_map_profile 0, 31, MUSIC_POKECENTER, 0 ; slot54 Cianwood Center ID42
    johto_map_profile 0, 34, MUSIC_POKECENTER, 0 ; slot55 Mahogany Center ID77
    johto_map_profile 0, 39, MUSIC_POKECENTER, 0 ; slot56 Blackthorn Center ID85
    johto_map_profile 0, 9, MUSIC_DUNGEON2, 0 ; slot57 Union Cave B1F
    johto_map_profile 0, 9, MUSIC_DUNGEON2, 0 ; slot58 Union Cave B2F
    johto_map_profile 0, 12, MUSIC_DUNGEON2, 0 ; slot59 Slowpoke Well B1F
    johto_map_profile 0, 12, MUSIC_DUNGEON2, 0 ; slot60 Slowpoke Well B2F
    johto_map_profile 0, 21, MUSIC_DUNGEON2, 0 ; slot61 Burned Tower 1F, no Fly
    johto_map_profile 0, 21, MUSIC_DUNGEON2, 0 ; slot62 Burned Tower B1F, no Fly
    johto_map_profile 0, 4, MUSIC_DUNGEON2, 0 ; slot63 Dark Cave Violet entrance, indoor
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

JohtoPilotGetLastHealLandmarkOrPlayer::
    ld a, [wJohtoLastHealMagic]
    cp JOHTO_LAST_HEAL_MAGIC
    jr nz, .current
    ld a, [wJohtoLastHealLocalID]
    cp JOHTO_CHERRYGROVE_POKECENTER_1F_LOCAL_ID
    jr z, .cherrygroveHeal
    cp JOHTO_ROUTE_32_POKECENTER_1F_LOCAL_ID
    jr z, .route32Heal
    cp JOHTO_AZALEA_POKECENTER_1F_LOCAL_ID
    jr z, .azaleaHeal
    cp JOHTO_VIOLET_POKECENTER_1F_LOCAL_ID
    jr z, .violetHeal
    cp JOHTO_GOLDENROD_POKECENTER_1F_LOCAL_ID
    jr z, .goldenrodHeal
    cp JOHTO_ECRUTEAK_POKECENTER_1F_LOCAL_ID
    jp z, .ecruteakHeal
    cp JOHTO_OLIVINE_POKECENTER_1F_LOCAL_ID
    jp z, .olivineHeal
    cp JOHTO_CIANWOOD_POKECENTER_1F_LOCAL_ID
    jp z, .cianwoodHeal
    cp JOHTO_MAHOGANY_POKECENTER_1F_LOCAL_ID
    jp z, .mahoganyHeal
    cp JOHTO_BLACKTHORN_POKECENTER_1F_LOCAL_ID
    jp z, .blackthornHeal
    jr .current
.cherrygroveHeal
    ; ID123/106/135 map to Cherrygrove/Route32/Azalea landmarks.
    ; A missing or corrupt ID falls back to the player.
    ld e, 2
    ret
.route32Heal
    ld e, 7 ; Gold Route32 landmark index
    ret
.azaleaHeal
    ld e, 11 ; Gold Azalea Town landmark index
    ret
.violetHeal
    ld e, 5 ; Gold Violet City landmark index
    ret
.goldenrodHeal
    ld e, 15 ; Gold Goldenrod City landmark index
    ret
.ecruteakHeal
    ld e, 21 ; Gold Ecruteak browse landmark
    ret
.olivineHeal
    ld e, 26 ; Gold Olivine browse landmark
    ret
.cianwoodHeal
    ld e, 31 ; Gold Cianwood browse landmark
    ret
.mahoganyHeal
    ld e, 34 ; Gold Mahogany browse landmark
    ret
.blackthornHeal
    ld e, 39 ; Gold Blackthorn City browse landmark
    ret
.current
    jp JohtoPilotGetTownMapLandmark

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
    cp JOHTO_ROUTE_35_NATIONAL_PARK_GATE_LOCAL_ID
    jp z, .southParkGate
    cp JOHTO_ROUTE_36_NATIONAL_PARK_GATE_LOCAL_ID
    jp z, .eastParkGate
    cp JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID
    jp z, .route35GoldenrodGate
    cp JOHTO_ILEX_AZALEA_GATE_LOCAL_ID
    jp z, .southForestGate
    cp JOHTO_ROUTE34_ILEX_GATE_LOCAL_ID
    jp z, .northForestGate
    cp JOHTO_ROUTE_38_ECRUTEAK_GATE_LOCAL_ID
    jp z, .route38GateMusic
    cp JOHTO_ROUTE_42_ECRUTEAK_GATE_LOCAL_ID
    jp z, .route42GateMusic
    cp JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID
    jp z, .route43MahoganyGateMusic
    cp JOHTO_ROUTE_43_GATE_LOCAL_ID
    jp z, .route43GateMusic
    cp JOHTO_ROUTE_29_ROUTE_46_GATE_LOCAL_ID
    jp z, .route2946GateMusic
    cp JOHTO_ROUTE31_VIOLET_GATE_LOCAL_ID
    jp z, .violetGate
    cp JOHTO_ROUTE_32_RUINS_OF_ALPH_GATE_LOCAL_ID
    jr z, .southGate
    cp JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID
    ret nz
    ld a, [wJohtoGateMusicSourceLocalID]
    cp JOHTO_ROUTE_36_LOCAL_ID
    jp z, .sourceValid
    cp JOHTO_RUINS_OF_ALPH_LOCAL_ID
    ret nz
    jp .sourceValid
.southGate
    ld a, [wJohtoGateMusicSourceLocalID]
    cp JOHTO_ROUTE_32_LOCAL_ID
    jp z, .sourceValid
    cp JOHTO_RUINS_OF_ALPH_LOCAL_ID
    ret nz
    jp .sourceValid
.violetGate
    ld a, [wJohtoGateMusicSourceLocalID]
    cp JOHTO_ROUTE_31_LOCAL_ID
    jp z, .sourceValid
    cp JOHTO_VIOLET_CITY_LOCAL_ID
    ret nz
    ; MUS-282: the city side must use its own music profile.  Falling
    ; through into .southForestGate silently reverted to the gate default.
    jp .sourceValid
.route38GateMusic
    ld a, [wJohtoGateMusicSourceLocalID]
    cp JOHTO_ECRUTEAK_CITY_LOCAL_ID
    jp z, .sourceValid
    cp JOHTO_ROUTE_38_LOCAL_ID
    ret nz
    jp .sourceValid
.route42GateMusic
    ld a, [wJohtoGateMusicSourceLocalID]
    cp JOHTO_ECRUTEAK_CITY_LOCAL_ID
    jp z, .sourceValid
    cp JOHTO_ROUTE_42_LOCAL_ID
    ret nz
    jp .sourceValid
.route43MahoganyGateMusic
    ld a, [wJohtoGateMusicSourceLocalID]
    cp JOHTO_MAHOGANY_TOWN_LOCAL_ID
    jp z, .sourceValid
    cp JOHTO_ROUTE_43_LOCAL_ID
    ret nz
    jp .sourceValid
.route43GateMusic
    ld a, [wJohtoGateMusicSourceLocalID]
    cp JOHTO_ROUTE_43_LOCAL_ID
    ret nz
    jp .sourceValid
.route2946GateMusic
    ld a, [wJohtoGateMusicSourceLocalID]
    cp JOHTO_ROUTE_46_LOCAL_ID
    jp z, .sourceValid
    cp JOHTO_ROUTE_29_LOCAL_ID
    ret nz
    jp .sourceValid

.route35GoldenrodGate
    ld a, [wJohtoGateMusicSourceLocalID]
    cp JOHTO_GOLDENROD_CITY_LOCAL_ID
    jp z, .sourceValid
    cp JOHTO_ROUTE_35_LOCAL_ID
    ret nz
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
.southParkGate
    ld a, [wJohtoGateMusicSourceLocalID]
    cp JOHTO_NATIONAL_PARK_LOCAL_ID
    jp z, .sourceValid
    cp JOHTO_ROUTE_35_LOCAL_ID
    ret nz
    jp .sourceValid
.eastParkGate
    ld a, [wJohtoGateMusicSourceLocalID]
    cp JOHTO_NATIONAL_PARK_LOCAL_ID
    jp z, .sourceValid
    cp JOHTO_ROUTE_36_LOCAL_ID
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
    ; Both shared Gold centers need the exact 10x8 interior bounds.
    cp JOHTO_CHERRYGROVE_POKECENTER_1F_LOCAL_ID
    jp z, .verticalGateClosedEdge314
    cp JOHTO_ROUTE_32_POKECENTER_1F_LOCAL_ID
    jp z, .verticalGateClosedEdge314
    cp JOHTO_AZALEA_POKECENTER_1F_LOCAL_ID
    jp z, .verticalGateClosedEdge314
    cp JOHTO_VIOLET_POKECENTER_1F_LOCAL_ID
    jp z, .verticalGateClosedEdge314
    cp JOHTO_GOLDENROD_POKECENTER_1F_LOCAL_ID
    jp z, .verticalGateClosedEdge314
    cp JOHTO_ECRUTEAK_POKECENTER_1F_LOCAL_ID
    jp z, .verticalGateClosedEdge314
    cp JOHTO_OLIVINE_POKECENTER_1F_LOCAL_ID
    jp z, .verticalGateClosedEdge314
    cp JOHTO_CIANWOOD_POKECENTER_1F_LOCAL_ID
    jp z, .verticalGateClosedEdge314
    cp JOHTO_MAHOGANY_POKECENTER_1F_LOCAL_ID
    jp z, .verticalGateClosedEdge314
    cp JOHTO_BLACKTHORN_POKECENTER_1F_LOCAL_ID
    jp z, .verticalGateClosedEdge314
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
    cp JOHTO_DARK_CAVE_VIOLET_ENTRANCE_LOCAL_ID
    jp z, .darkCaveClosedEdge
    cp JOHTO_ROUTE_33_LOCAL_ID
    jp z, .route33ClosedEdge
    cp JOHTO_AZALEA_TOWN_LOCAL_ID
    jp z, .southAzaleaEdge
    cp JOHTO_ROUTE_34_LOCAL_ID
    jp z, .southRoute34Edge
    cp JOHTO_GOLDENROD_CITY_LOCAL_ID
    jp z, .southGoldenrodEdge
    cp JOHTO_ROUTE_35_LOCAL_ID
    jp z, .southRoute35Edge
    cp JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID
    jp z, .southRoute35Edge
    ; FIX-288: new Park and both gates are finite. Without this
    ; dispatch their edge steps fell through as unrestricted land,
    ; walking/cycling into the black border outside the map array.
    cp JOHTO_ROUTE_37_LOCAL_ID
    jp z, .route37ClosedEdge
    cp JOHTO_ECRUTEAK_CITY_LOCAL_ID
    jp z, .ecruteakClosedEdge
    cp JOHTO_ROUTE_38_ECRUTEAK_GATE_LOCAL_ID
    jp z, .westClosedEdge
    cp JOHTO_ROUTE_38_LOCAL_ID
    jp z, .westClosedEdge
    cp JOHTO_ROUTE_39_LOCAL_ID
    jp z, .westClosedEdge
    cp JOHTO_OLIVINE_CITY_LOCAL_ID
    jp z, .westSeaClosedEdge
    cp JOHTO_ROUTE_40_LOCAL_ID
    jp z, .westSeaClosedEdge
    cp JOHTO_ROUTE_41_LOCAL_ID
    jp z, .westSeaClosedEdge
    cp JOHTO_CIANWOOD_CITY_LOCAL_ID
    jp z, .westSeaClosedEdge
    cp JOHTO_ROUTE_42_ECRUTEAK_GATE_LOCAL_ID
    jp z, .eastClosedEdge
    cp JOHTO_ROUTE_42_LOCAL_ID
    jp z, .eastClosedEdge
    cp JOHTO_MAHOGANY_TOWN_LOCAL_ID
    jp z, .eastClosedEdge
    cp JOHTO_ROUTE_43_LOCAL_ID
    jp z, .eastClosedEdge
    cp JOHTO_LAKE_OF_RAGE_LOCAL_ID
    jp z, .eastClosedEdge
    cp JOHTO_ROUTE_44_LOCAL_ID
    jp z, .eastClosedEdge
    cp JOHTO_BLACKTHORN_CITY_LOCAL_ID
    jp z, .eastClosedEdge
    cp JOHTO_ROUTE_45_LOCAL_ID
    jp z, .eastClosedEdge
    cp JOHTO_ROUTE_46_LOCAL_ID
    jp z, .eastClosedEdge
    call JohtoPilotIsVerticalGatePairMap314
    jr z, .verticalGateClosedEdge314
    cp JOHTO_NATIONAL_PARK_LOCAL_ID
    jp z, .southClosedEdge
    cp JOHTO_ROUTE_35_NATIONAL_PARK_GATE_LOCAL_ID
    jp z, .southClosedEdge
    cp JOHTO_ROUTE_36_NATIONAL_PARK_GATE_LOCAL_ID
    jp z, .southClosedEdge
    cp JOHTO_ILEX_AZALEA_GATE_LOCAL_ID
    jp z, .southClosedEdge
    cp JOHTO_ILEX_FOREST_LOCAL_ID
    jp z, .southClosedEdge
    cp JOHTO_ROUTE34_ILEX_GATE_LOCAL_ID
    jp z, .southClosedEdge
    ret
.route37ClosedEdge
    callab JohtoCorridor37Edge
    ret
.ecruteakClosedEdge
    callab JohtoCorridorEcruteakEdge
    ret
.westClosedEdge
    callab JohtoWestIsKnownClosedEdge
    ret
.westSeaClosedEdge
    callab JohtoWestSeaIsKnownClosedEdge
    ret
.eastClosedEdge
    callab JohtoEastIsKnownClosedEdge
    ret
.verticalGateClosedEdge314
    callab JohtoVerticalGateClosedEdge314
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
.southRoute35Edge
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
.darkCaveClosedEdge
    ; REF-349 LEDGE FIX: this early gateway runs BEFORE HandleLedges.
    ; Do not test the Gold role in front here: a valid HOP takeoff faces
    ; a WALL, and rejecting that WALL prevents the jump handler from firing.
    ; This gateway protects ONLY the finite 40x36 map bounds; the later
    ; JohtoOverworldSouthLandDecision owns interior walls and Gold HOPs.
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    jr z, .darkCaveNorthEdge
    cp PLAYER_DIR_DOWN
    jr z, .darkCaveSouthEdge
    cp PLAYER_DIR_LEFT
    jr z, .darkCaveWestEdge
    cp PLAYER_DIR_RIGHT
    ret nz
    ld a, [wXCoord]
    cp JOHTO_DARK_CAVE_WIDTH * 2 - 1
    jp nc, .closed
    ret
.darkCaveNorthEdge
    ld a, [wYCoord]
    and a
    jp z, .closed
    ret
.darkCaveSouthEdge
    ld a, [wYCoord]
    cp JOHTO_DARK_CAVE_HEIGHT * 2 - 1
    jp nc, .closed
    ret
.darkCaveWestEdge
    ld a, [wXCoord]
    and a
    jp z, .closed
    ret
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
    ; Gold Route36: SOUTH only x17 (the sole open tile in the mature
    ; Route36/Route35 collision mask); EAST only y8/9 to Violet City.
    ; MAP-294: NORTH Route37 x25..32 only; other edges preserve Gold lanes.
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
    ld a, [wYCoord]
    cp 8
    ret z
    cp 9
    ret z
    jp .closed
.route36Up
    ld a, [wYCoord]
    and a
    ret nz
    ld a, [wXCoord]
    cp 25
    jp c, .closed
    cp 33
    ret c
    jp .closed
.route36Down
    ld a, [wYCoord]
    cp JOHTO_ROUTE_36_HEIGHT * 2 - 1
    ret c
    ld a, [wXCoord]
    cp 17
    ret z
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
    ; Violet WEST outdoor path to Route36 is Gold y8/9, but the east
    ; Route31 Gate and SOUTH Route32 keep their existing exact rules.
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
    ld a, [wYCoord]
    cp 8
    ret z
    cp 9
    ret z
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
; DEV-314: one allowlist for the shared vertical-gate profile runtime.
; A future compatible gate adds its stable ID here and profile rows in Bank $53;
; no per-hook before/after/arrival/collision branch copies are needed.
JohtoPilotIsVerticalGatePairMap314::
    ld a, [wCurLocalMapID]
    cp JOHTO_MAHOGANY_TOWN_LOCAL_ID
    ret z
    cp JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID
    ret z
    cp JOHTO_ROUTE_43_GATE_LOCAL_ID
    ret z
    cp JOHTO_ROUTE_29_ROUTE_46_GATE_LOCAL_ID
    ret z
    cp JOHTO_ROUTE_46_LOCAL_ID
    ret z
    cp JOHTO_ROUTE_29_LOCAL_ID
    ret z
    cp JOHTO_ROUTE_43_LOCAL_ID
    ret

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
    ; Route31 Gold Dark Cave warp #3 deposits the player on the cave-mouth
    ; door cell (34,5). Its lower-left 8x8 tile is $56, not the common
    ; Gold house DOOR $39; step out using the existing simulated DOWN step.
    ; Do not extend this to Route31's gate carpets or the cave interior.
    ld a, [wCurLocalMapID]
    cp JOHTO_ROUTE_31_LOCAL_ID
    jr nz, .notRoute31CaveArrival349
    ld a, [wXCoord]
    cp 34
    jr nz, .notRoute31CaveArrival349
    ld a, [wYCoord]
    cp 5
    jr nz, .notRoute31CaveArrival349
    ld e, D_DOWN
    ret
.notRoute31CaveArrival349
    call JohtoPilotIsVerticalGatePairMap314
    jr z, .verticalGateArrivalDispatch314
    cp JOHTO_ECRUTEAK_CITY_LOCAL_ID
    jr nz, .notBurnedTowerCityArrival
    ; Gold Burned Tower door is a step-out DOOR, not Ecruteak's west carpet.
    ; Only the door at (5,5) advances DOWN on arrival. West gate stays still.
    ld a, [wXCoord]
    cp 5
    jr nz, .westPortalDispatch
    ld a, [wYCoord]
    cp 5
    jr nz, .westPortalDispatch
    ld e, D_DOWN
    ret
.notBurnedTowerCityArrival
    ld a, [wCurLocalMapID]
    cp JOHTO_ROUTE_38_ECRUTEAK_GATE_LOCAL_ID
    jr z, .westPortalDispatch
    cp JOHTO_ROUTE_38_LOCAL_ID
    jr z, .westPortalDispatch
    jr .westPortalContinue
.verticalGateArrivalDispatch314
    callab JohtoVerticalGateArrivalStep314
    ret
.westPortalDispatch
    callab JohtoWestPortalArrivalStep
    ret
.westPortalContinue
    cp JOHTO_ROUTE_35_LOCAL_ID
    jr z, .newNorthSouthMap
    cp JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID
    jr z, .newNorthSouthMap
    cp JOHTO_NATIONAL_PARK_LOCAL_ID
    jr z, .newNorthSouthMap
    cp JOHTO_ROUTE_35_NATIONAL_PARK_GATE_LOCAL_ID
    jr z, .newNorthSouthMap
    cp JOHTO_ROUTE_36_NATIONAL_PARK_GATE_LOCAL_ID
    jr z, .newNorthSouthMap
    cp JOHTO_AZALEA_TOWN_LOCAL_ID
    jp c, .oldArrival
    cp JOHTO_GOLDENROD_CITY_LOCAL_ID + 1
    jp nc, .oldArrival
.newNorthSouthMap
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
    cp JOHTO_DARK_CAVE_VIOLET_ENTRANCE_LOCAL_ID
    ret z
    cp JOHTO_UNION_CAVE_B1F_LOCAL_ID
    ret z
    cp JOHTO_UNION_CAVE_B2F_LOCAL_ID
    ret z
    cp JOHTO_SLOWPOKE_WELL_B1F_LOCAL_ID
    ret z
    cp JOHTO_SLOWPOKE_WELL_B2F_LOCAL_ID
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
    ; No indoor center carpet may be treated as an outdoor STEP_ON door.
    ld a, [wCurLocalMapID]
    cp JOHTO_CHERRYGROVE_POKECENTER_1F_LOCAL_ID
    ret z
    cp JOHTO_ROUTE_32_POKECENTER_1F_LOCAL_ID
    ret z
    cp JOHTO_AZALEA_POKECENTER_1F_LOCAL_ID
    ret z
    cp JOHTO_VIOLET_POKECENTER_1F_LOCAL_ID
    ret z
    cp JOHTO_GOLDENROD_POKECENTER_1F_LOCAL_ID
    ret z
    cp JOHTO_ECRUTEAK_POKECENTER_1F_LOCAL_ID
    ret z
    cp JOHTO_OLIVINE_POKECENTER_1F_LOCAL_ID
    ret z
    cp JOHTO_CIANWOOD_POKECENTER_1F_LOCAL_ID
    ret z
    cp JOHTO_MAHOGANY_POKECENTER_1F_LOCAL_ID
    ret z
    cp JOHTO_BLACKTHORN_POKECENTER_1F_LOCAL_ID
    ret z
    ; REF-347: Gold Burned Tower Ecruteak (5,6) UP beforestep.
    ld a, [wCurLocalMapID]
    cp JOHTO_ECRUTEAK_CITY_LOCAL_ID
    jr nz, .noBurnedBefore
    callab JohtoBurnedTowerCityBeforeStep
    ld a, e
    and a
    ret nz
.noBurnedBefore
    call JohtoBatchCenterDoorBeforeStep336
    ld a, e
    and a
    ret nz
    ld a, [wCurLocalMapID]
    call JohtoPilotIsVerticalGatePairMap314
    jr z, .verticalGateDispatch314
    cp JOHTO_ECRUTEAK_CITY_LOCAL_ID
    jr z, .bothPortalDispatch
    cp JOHTO_ROUTE_38_ECRUTEAK_GATE_LOCAL_ID
    jr z, .westPortalDispatch
    cp JOHTO_ROUTE_38_LOCAL_ID
    jr z, .westPortalDispatch
    cp JOHTO_ROUTE_42_ECRUTEAK_GATE_LOCAL_ID
    jr z, .eastPortalDispatch
    cp JOHTO_ROUTE_42_LOCAL_ID
    jr z, .eastPortalDispatch
    jr .westPortalContinue
.verticalGateDispatch314
    callab JohtoVerticalGateBeforeStep314
    ret
.bothPortalDispatch
    callab JohtoWestPortalBeforeStep
    ld a, e
    and a
    ret nz
    callab JohtoEastPortalBeforeStep
    ret
.westPortalDispatch
    callab JohtoWestPortalBeforeStep
    ret
.eastPortalDispatch
    callab JohtoEastPortalBeforeStep
    ret
.westPortalContinue
    cp JOHTO_ROUTE_35_LOCAL_ID
    jr z, .newNorthSouthMap
    cp JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID
    jr z, .newNorthSouthMap
    cp JOHTO_NATIONAL_PARK_LOCAL_ID
    jr z, .newNorthSouthMap
    cp JOHTO_ROUTE_35_NATIONAL_PARK_GATE_LOCAL_ID
    jr z, .newNorthSouthMap
    cp JOHTO_ROUTE_36_NATIONAL_PARK_GATE_LOCAL_ID
    jr z, .newNorthSouthMap
    cp JOHTO_AZALEA_TOWN_LOCAL_ID
    jp c, .oldGateRules
    cp JOHTO_GOLDENROD_CITY_LOCAL_ID + 1
    jp nc, .oldGateRules
.newNorthSouthMap
    callab JohtoSouthPortalBeforeStep
    ret
.oldGateRules
    ld a, [wCurLocalMapID]
    cp JOHTO_ROUTE_32_LOCAL_ID
    jp z, .route32Alph
    cp JOHTO_ROUTE_33_LOCAL_ID
    jp z, .route33Cave
    ; Cave interior must never bypass pre-step wall collision here.
    ; Gold LADDER step-in transfer is handled only after the exact warp
    ; coordinate matches in JohtoPilotGateDoorWarpMatched below.
    cp JOHTO_UNION_CAVE_1F_LOCAL_ID
    ret z
    cp JOHTO_UNION_CAVE_B1F_LOCAL_ID
    ret z
    cp JOHTO_UNION_CAVE_B2F_LOCAL_ID
    ret z
    cp JOHTO_SLOWPOKE_WELL_B1F_LOCAL_ID
    ret z
    cp JOHTO_SLOWPOKE_WELL_B2F_LOCAL_ID
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
    cp PLAYER_DIR_UP
    jr z, .violetCenterBefore
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
.violetCenterBefore
    ld a, [wXCoord]
    cp 31
    ret nz
    ld a, [wYCoord]
    cp 26
    jp z, .allow
    ret
.route31
    ; Gold Dark Cave at (34,5): approach one cell south, facing UP.
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    jr nz, .route31GateOld349
    ld a, [wXCoord]
    cp 34
    ret nz
    ld a, [wYCoord]
    cp 6
    jp z, .allow
    ret
.route31GateOld349
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
    jr z, .route32NorthDoor
    cp PLAYER_DIR_LEFT
    ret nz
    ld a, [wXCoord]
    cp 5
    ret nz
    ld a, [wYCoord]
    cp 2
    jp z, .allow
    cp 3
    ret nz
    jp .allow
.route32NorthDoor
    ld a, [wXCoord]
    cp 11
    jr nz, .route32Cave
    ld a, [wYCoord]
    cp 74
    jp z, .allow
    ret
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
    cp PLAYER_DIR_LEFT
    jr nz, .ruins36
    ld a, [wXCoord]
    cp 19
    ret nz
    ld a, [wYCoord]
    cp 8
    jp z, .allow
    cp 9
    jp z, .allow
    ret
.ruins36
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
    cp JOHTO_CHERRYGROVE_POKECENTER_1F_LOCAL_ID
    jr z, .centerCarpetStand
    cp JOHTO_ROUTE_32_POKECENTER_1F_LOCAL_ID
    jr z, .centerCarpetStand
    cp JOHTO_AZALEA_POKECENTER_1F_LOCAL_ID
    jr z, .centerCarpetStand
    cp JOHTO_VIOLET_POKECENTER_1F_LOCAL_ID
    jp z, .centerCarpetStand
    cp JOHTO_GOLDENROD_POKECENTER_1F_LOCAL_ID
    jp z, .centerCarpetStand
    cp JOHTO_ECRUTEAK_POKECENTER_1F_LOCAL_ID
    jp z, .centerCarpetStand
    cp JOHTO_OLIVINE_POKECENTER_1F_LOCAL_ID
    jp z, .centerCarpetStand
    cp JOHTO_CIANWOOD_POKECENTER_1F_LOCAL_ID
    jp z, .centerCarpetStand
    cp JOHTO_MAHOGANY_POKECENTER_1F_LOCAL_ID
    jp z, .centerCarpetStand
    cp JOHTO_BLACKTHORN_POKECENTER_1F_LOCAL_ID
    jp z, .centerCarpetStand
    ld a, [wCurLocalMapID]
    cp JOHTO_ECRUTEAK_CITY_LOCAL_ID
    jr nz, .noBurnedAfter
    callab JohtoBurnedTowerCityAfterStep
    ld a, e
    and a
    ret nz
.noBurnedAfter
    ld a, [wCurLocalMapID]
    cp JOHTO_DARK_CAVE_VIOLET_ENTRANCE_LOCAL_ID
    jr z, .centerCarpetStand
    cp JOHTO_BURNED_TOWER_1F_LOCAL_ID
    jr z, .burnedTowerWarpMode
    cp JOHTO_BURNED_TOWER_B1F_LOCAL_ID
    jr nz, .noBurnedCarpet
.burnedTowerWarpMode
    callab JohtoBurnedTowerWarpTriggerMode
    ret
.noBurnedCarpet
    call JohtoBatchCenterDoorAfterStep336
    ld a, e
    and a
    ret nz
    ld a, [wCurLocalMapID]
    cp JOHTO_CHERRYGROVE_LOCAL_ID
    jp z, .cherrygroveGoldDoor
    call JohtoPilotIsVerticalGatePairMap314
    jr z, .verticalGateDispatch314
    cp JOHTO_ECRUTEAK_CITY_LOCAL_ID
    jr z, .westPortalDispatch
    cp JOHTO_ROUTE_38_ECRUTEAK_GATE_LOCAL_ID
    jr z, .westPortalDispatch
    cp JOHTO_ROUTE_38_LOCAL_ID
    jr z, .westPortalDispatch
    jr .westPortalContinue
.centerCarpetStand
    ; The warp coordinate has already matched the exact Gold carpet.
    ; E=1 arms the standing flag but prevents STEP_ON and sideways warp.
    ld e, 1
    ret
.cherrygroveGoldDoor
    ; This hook runs only after a registered-warp coordinate matches.
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    ret nz
    ld a, [wYCoord]
    cp 9
    jr z, .guideDoor
    cp 3
    ret nz
    ld a, [wXCoord]
    cp 29
    ret nz
    jr .allowCherry
.guideDoor
    ld a, [wXCoord]
    cp 25
    ret nz
.allowCherry
    ; E=2 means enter immediately via WarpFound1 on this UP step.
    ; E=1 would only arm an indoor carpet and *not* enter the Center.
    ld e, 2
    ret
.verticalGateDispatch314
    callab JohtoVerticalGateAfterStep314
    ret
.westPortalDispatch
    callab JohtoWestPortalAfterStep
    ret
.westPortalContinue
    cp JOHTO_ROUTE_35_LOCAL_ID
    jr z, .newNorthSouthMap
    cp JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID
    jr z, .newNorthSouthMap
    cp JOHTO_NATIONAL_PARK_LOCAL_ID
    jr z, .newNorthSouthMap
    cp JOHTO_ROUTE_35_NATIONAL_PARK_GATE_LOCAL_ID
    jr z, .newNorthSouthMap
    cp JOHTO_ROUTE_36_NATIONAL_PARK_GATE_LOCAL_ID
    jr z, .newNorthSouthMap
    cp JOHTO_AZALEA_TOWN_LOCAL_ID
    jp c, .oldGateRules
    cp JOHTO_GOLDENROD_CITY_LOCAL_ID + 1
    jp nc, .oldGateRules
.newNorthSouthMap
    callab JohtoSouthPortalAfterStep
    ret
.oldGateRules
    ld a, [wCurLocalMapID]
    cp JOHTO_ROUTE_32_LOCAL_ID
    jp z, .route32Alph
    cp JOHTO_ROUTE_33_LOCAL_ID
    jp z, .route33Cave
    ; Gold cave warps are mixed. LADDER warps fire on the step that enters
    ; the tile; WARP_CARPET_DOWN only arms standing state and waits for DOWN.
    ; This hook runs after the exact registered warp coordinate has matched.
    cp JOHTO_UNION_CAVE_1F_LOCAL_ID
    jr z, .unionCave1FWarpMatched342
    cp JOHTO_UNION_CAVE_B1F_LOCAL_ID
    jr z, .unionCaveB1FWarpMatched342
    cp JOHTO_UNION_CAVE_B2F_LOCAL_ID
    jr z, .unionCaveB2FWarpMatched342
    cp JOHTO_SLOWPOKE_WELL_B1F_LOCAL_ID
    jr z, .unionCaveLadder342
    cp JOHTO_SLOWPOKE_WELL_B2F_LOCAL_ID
    jr z, .unionCaveLadder342
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
    cp PLAYER_DIR_UP
    jr z, .violetCenterMatched
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
.violetCenterMatched
    ld a, [wXCoord]
    cp 31
    ret nz
    ld a, [wYCoord]
    cp 25
    jp z, .yesDoor
    ret
.unionCave1FWarpMatched342
    ; 1F: (17,3)/(17,31) are WARP_CARPET_DOWN;
    ; (5,19)/(3,33) are LADDER.
    ld a, [wXCoord]
    cp 17
    jr z, .unionCaveDirectional342
    jr .unionCaveLadder342
.unionCaveB1FWarpMatched342
    ; B1F (3,3)/(3,11) are closed Ruins WARP_CARPET_DOWN entries.
    ; Active (7,19)/(3,33)/(17,31) are LADDER.
    ld a, [wXCoord]
    cp 3
    jr nz, .unionCaveLadder342
    ld a, [wYCoord]
    cp 3
    jr z, .unionCaveDirectional342
    cp 11
    jr z, .unionCaveDirectional342
    jr .unionCaveLadder342
.unionCaveB2FWarpMatched342
    ; B2F (5,3) is LADDER.
.unionCaveLadder342
    ld e, 2 ; immediate transfer on the step into the ladder tile
    ret
.unionCaveDirectional342
    ld e, 1 ; stand on the carpet; directional collision decides later
    ret

.route31
    ; Gold cave opening: warp immediately on the UP step into (34,5).
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    jr nz, .route31GateOldAfter349
    ld a, [wXCoord]
    cp 34
    ret nz
    ld a, [wYCoord]
    cp 5
    ret nz
    ld e, 2
    ret
.route31GateOldAfter349
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
    jr z, .route32NorthDoor
    cp PLAYER_DIR_LEFT
    ret nz
    ld a, [wXCoord]
    cp 4
    ret nz
    ld a, [wYCoord]
    cp 2
    jp z, .allow
    cp 3
    ret nz
    jp .allow
.route32NorthDoor
    ld a, [wXCoord]
    cp 11
    jr nz, .route32Cave
    ld a, [wYCoord]
    cp 73
    jp z, .yesDoor
    ret
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
    cp PLAYER_DIR_LEFT
    jr nz, .ruins36
    ld a, [wXCoord]
    cp 18
    ret nz
    ld a, [wYCoord]
    cp 8
    jp z, .allow
    cp 9
    jp z, .allow
    ret
.ruins36
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
    cp JOHTO_DARK_CAVE_VIOLET_ENTRANCE_LOCAL_ID
    jp z, JohtoDarkCaveDownCarpet349
    ld a, [wCurLocalMapID]
    cp JOHTO_DARK_CAVE_VIOLET_ENTRANCE_LOCAL_ID
    jp z, JohtoDarkCaveDownCarpet349
    cp JOHTO_BURNED_TOWER_1F_LOCAL_ID
    jr nz, .notBurnedExit
    callab JohtoBurnedTower1FDownCarpet
    ret
.notBurnedExit
    ld a, [wCurLocalMapID]
    cp JOHTO_CHERRYGROVE_POKECENTER_1F_LOCAL_ID
    jr z, .centerCarpetExit
    cp JOHTO_ROUTE_32_POKECENTER_1F_LOCAL_ID
    jr z, .centerCarpetExit
    cp JOHTO_AZALEA_POKECENTER_1F_LOCAL_ID
    jr z, .centerCarpetExit
    cp JOHTO_VIOLET_POKECENTER_1F_LOCAL_ID
    jp z, .centerCarpetExit
    cp JOHTO_GOLDENROD_POKECENTER_1F_LOCAL_ID
    jp z, .centerCarpetExit
    cp JOHTO_ECRUTEAK_POKECENTER_1F_LOCAL_ID
    jp z, .centerCarpetExit
    cp JOHTO_OLIVINE_POKECENTER_1F_LOCAL_ID
    jp z, .centerCarpetExit
    cp JOHTO_CIANWOOD_POKECENTER_1F_LOCAL_ID
    jp z, .centerCarpetExit
    cp JOHTO_MAHOGANY_POKECENTER_1F_LOCAL_ID
    jp z, .centerCarpetExit
    cp JOHTO_BLACKTHORN_POKECENTER_1F_LOCAL_ID
    jp z, .centerCarpetExit
    call JohtoPilotIsVerticalGatePairMap314
    jr z, .verticalGateDispatch314
    cp JOHTO_ECRUTEAK_CITY_LOCAL_ID
    jr z, .bothPortalDispatch
    cp JOHTO_ROUTE_38_ECRUTEAK_GATE_LOCAL_ID
    jr z, .westPortalDispatch
    cp JOHTO_ROUTE_38_LOCAL_ID
    jr z, .westPortalDispatch
    cp JOHTO_ROUTE_42_ECRUTEAK_GATE_LOCAL_ID
    jr z, .eastPortalDispatch
    cp JOHTO_ROUTE_42_LOCAL_ID
    jr z, .eastPortalDispatch
    jr .westPortalContinue
.centerCarpetExit
    callab JohtoSharedCenterDownCollision336
    ret
.verticalGateDispatch314
    callab JohtoVerticalGateCollisionExit314
    ret
.bothPortalDispatch
    callab JohtoWestPortalCollisionExit
    ld a, e
    and a
    ret nz
    callab JohtoEastPortalCollisionExit
    ret
.westPortalDispatch
    callab JohtoWestPortalCollisionExit
    ret
.eastPortalDispatch
    callab JohtoEastPortalCollisionExit
    ret
.westPortalContinue
    cp JOHTO_ROUTE_35_LOCAL_ID
    jr z, .newNorthSouthMap
    cp JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID
    jr z, .newNorthSouthMap
    cp JOHTO_NATIONAL_PARK_LOCAL_ID
    jr z, .newNorthSouthMap
    cp JOHTO_ROUTE_35_NATIONAL_PARK_GATE_LOCAL_ID
    jr z, .newNorthSouthMap
    cp JOHTO_ROUTE_36_NATIONAL_PARK_GATE_LOCAL_ID
    jr z, .newNorthSouthMap
    cp JOHTO_AZALEA_TOWN_LOCAL_ID
    jp c, .legacyExtra
    cp JOHTO_GOLDENROD_CITY_LOCAL_ID + 1
    jp nc, .legacyExtra
.newNorthSouthMap
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
    cp JOHTO_DARK_CAVE_VIOLET_ENTRANCE_LOCAL_ID
    jp z, JohtoPilotGateCollisionExitAllowed
    cp JOHTO_UNION_CAVE_B1F_LOCAL_ID
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
    jp z, .yes
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
    cp PLAYER_DIR_LEFT
    jr nz, .ruins36
    ld a, [wXCoord]
    cp 18
    ret nz
    ld a, [wYCoord]
    cp 8
    jp z, .yes
    cp 9
    jp z, .yes
    ret
.ruins36
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
    ld a, [wCurLocalMapID]
    cp JOHTO_DARK_CAVE_VIOLET_ENTRANCE_LOCAL_ID
    jp z, JohtoDarkCaveDownCarpet349
    ld a, [wCurMap]
    cp JOHTO_RUNTIME_MAP_HANDLE
    ret nz
    ld a, [wCurRegion]
    cp MAP_REGION_JOHTO
    ret nz
    ld a, [wCurLocalMapID]
    cp JOHTO_BURNED_TOWER_1F_LOCAL_ID
    jr nz, .notBurnedExit
    callab JohtoBurnedTower1FDownCarpet
    ret
.notBurnedExit
    ld a, [wCurLocalMapID]
    cp JOHTO_CHERRYGROVE_POKECENTER_1F_LOCAL_ID
    jr z, .centerCarpetExit
    cp JOHTO_ROUTE_32_POKECENTER_1F_LOCAL_ID
    jr z, .centerCarpetExit
    cp JOHTO_AZALEA_POKECENTER_1F_LOCAL_ID
    jr z, .centerCarpetExit
    cp JOHTO_VIOLET_POKECENTER_1F_LOCAL_ID
    jp z, .centerCarpetExit
    cp JOHTO_GOLDENROD_POKECENTER_1F_LOCAL_ID
    jp z, .centerCarpetExit
    cp JOHTO_ECRUTEAK_POKECENTER_1F_LOCAL_ID
    jp z, .centerCarpetExit
    cp JOHTO_OLIVINE_POKECENTER_1F_LOCAL_ID
    jp z, .centerCarpetExit
    cp JOHTO_CIANWOOD_POKECENTER_1F_LOCAL_ID
    jp z, .centerCarpetExit
    cp JOHTO_MAHOGANY_POKECENTER_1F_LOCAL_ID
    jp z, .centerCarpetExit
    cp JOHTO_BLACKTHORN_POKECENTER_1F_LOCAL_ID
    jp z, .centerCarpetExit
    cp JOHTO_ECRUTEAK_CITY_LOCAL_ID
    jr z, .bothPortalDispatch
    cp JOHTO_ROUTE_38_ECRUTEAK_GATE_LOCAL_ID
    jr z, .westPortalDispatch
    cp JOHTO_ROUTE_38_LOCAL_ID
    jr z, .westPortalDispatch
    cp JOHTO_ROUTE_42_ECRUTEAK_GATE_LOCAL_ID
    jr z, .eastPortalDispatch
    cp JOHTO_ROUTE_42_LOCAL_ID
    jr z, .eastPortalDispatch
    jr .westPortalContinue
.bothPortalDispatch
    callab JohtoWestPortalCollisionExit
    ld a, e
    and a
    ret nz
    callab JohtoEastPortalCollisionExit
    ret
.westPortalDispatch
    callab JohtoWestPortalCollisionExit
    ret
.eastPortalDispatch
    callab JohtoEastPortalCollisionExit
    ret
.centerCarpetExit
    callab JohtoSharedCenterDownCollision336
    ret
.westPortalContinue
    cp JOHTO_ROUTE_35_LOCAL_ID
    jr z, .newNorthSouthMap
    cp JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID
    jr z, .newNorthSouthMap
    cp JOHTO_NATIONAL_PARK_LOCAL_ID
    jr z, .newNorthSouthMap
    cp JOHTO_ROUTE_35_NATIONAL_PARK_GATE_LOCAL_ID
    jr z, .newNorthSouthMap
    cp JOHTO_ROUTE_36_NATIONAL_PARK_GATE_LOCAL_ID
    jr z, .newNorthSouthMap
    cp JOHTO_AZALEA_TOWN_LOCAL_ID
    jp c, .legacyGuard
    cp JOHTO_GOLDENROD_CITY_LOCAL_ID + 1
    jp nc, .legacyGuard
.newNorthSouthMap
    callab JohtoSouthPortalCollisionExit
    ret
.legacyGuard
    ld a, [wCurLocalMapID]
    cp JOHTO_ROUTE31_VIOLET_GATE_LOCAL_ID
    jp z, .isGate
    cp JOHTO_ROUTE_32_RUINS_OF_ALPH_GATE_LOCAL_ID
    jp z, .isGate
    cp JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID
    jr z, .northGateBottom
    cp JOHTO_UNION_CAVE_1F_LOCAL_ID
    jr z, .unionCaveExit
    cp JOHTO_UNION_CAVE_B1F_LOCAL_ID
    jr z, .unionCaveNoCollisionWarp342
    cp JOHTO_UNION_CAVE_B2F_LOCAL_ID
    jr z, .unionCaveNoCollisionWarp342
    cp JOHTO_SLOWPOKE_WELL_B1F_LOCAL_ID
    jr z, .unionCaveNoCollisionWarp342
    cp JOHTO_SLOWPOKE_WELL_B2F_LOCAL_ID
    jr z, .unionCaveNoCollisionWarp342
    cp JOHTO_ROUTE_36_LOCAL_ID
    ret nz
    ld e, 0
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_LEFT
    jr nz, .ruins36
    ld a, [wXCoord]
    cp 18
    ret nz
    ld a, [wYCoord]
    cp 8
    jp z, .yes
    cp 9
    jp z, .yes
    ret
.ruins36
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
.unionCaveNoCollisionWarp342
    ; B1F/B2F internal stairs are LADDER: once standing on one, bumping a
    ; wall or pressing another direction must not transfer. B1F Ruins
    ; carpets are still inactive, so collision cannot activate them either.
    ld e, 0
    ret
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


; REF-336 center-door ingress. Existing old gate corridors are not bypassed.
; Input: wCurLocalMapID, wPlayerDirection, wXCoord/wYCoord.
; Before-step requires the OUTSIDE tile directly below each Gold door;
; after-step requires a matching registered Warp at the door itself.
; E=1 before stepping, E=2 after matching => immediate STEP_ON door.
JohtoBatchCenterDoorBeforeStep336::
    ld e, 0
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    ret nz
    ld a, [wCurLocalMapID]
    cp JOHTO_ECRUTEAK_CITY_LOCAL_ID
    jp z, .ecruteak
    cp JOHTO_OLIVINE_CITY_LOCAL_ID
    jp z, .olivine
    cp JOHTO_CIANWOOD_CITY_LOCAL_ID
    jp z, .cianwood
    cp JOHTO_MAHOGANY_TOWN_LOCAL_ID
    jp z, .mahogany
    cp JOHTO_BLACKTHORN_CITY_LOCAL_ID
    jp z, .blackthorn
    ret
.ecruteak
    ld a, [wXCoord]
    cp 23
    ret nz
    ld a, [wYCoord]
    cp 28
    jr z, .allow
    ret
.olivine
    ld a, [wXCoord]
    cp 13
    ret nz
    ld a, [wYCoord]
    cp 22
    jr z, .allow
    ret
.cianwood
    ld a, [wXCoord]
    cp 23
    ret nz
    ld a, [wYCoord]
    cp 44
    jr z, .allow
    ret
.mahogany
    ld a, [wXCoord]
    cp 15
    ret nz
    ld a, [wYCoord]
    cp 14
    jr z, .allow
    ret
.blackthorn
    ld a, [wXCoord]
    cp 21
    ret nz
    ld a, [wYCoord]
    cp 30
    jr z, .allow
    ret
.allow
    ld e, 1
    ret

JohtoBatchCenterDoorAfterStep336::
    ld e, 0
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    ret nz
    ld a, [wCurLocalMapID]
    cp JOHTO_ECRUTEAK_CITY_LOCAL_ID
    jp z, .ecruteak
    cp JOHTO_OLIVINE_CITY_LOCAL_ID
    jp z, .olivine
    cp JOHTO_CIANWOOD_CITY_LOCAL_ID
    jp z, .cianwood
    cp JOHTO_MAHOGANY_TOWN_LOCAL_ID
    jp z, .mahogany
    cp JOHTO_BLACKTHORN_CITY_LOCAL_ID
    jp z, .blackthorn
    ret
.ecruteak
    ld a, [wXCoord]
    cp 23
    ret nz
    ld a, [wYCoord]
    cp 27
    jr z, .allow
    ret
.olivine
    ld a, [wXCoord]
    cp 13
    ret nz
    ld a, [wYCoord]
    cp 21
    jr z, .allow
    ret
.cianwood
    ld a, [wXCoord]
    cp 23
    ret nz
    ld a, [wYCoord]
    cp 43
    jr z, .allow
    ret
.mahogany
    ld a, [wXCoord]
    cp 15
    ret nz
    ld a, [wYCoord]
    cp 13
    jr z, .allow
    ret
.blackthorn
    ld a, [wXCoord]
    cp 21
    ret nz
    ld a, [wYCoord]
    cp 29
    jr z, .allow
    ret
.allow
    ld e, 2
    ret

; Gold Violet Dark Cave DOWN carpets: Route31 (3,15), Route46 (35,33).
JohtoDarkCaveDownCarpet349::
    ld e, 0
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_DOWN
    ret nz
    ld a, [wXCoord]
    cp 3
    jr nz, .route46Carpet
    ld a, [wYCoord]
    cp 15
    jr z, .allow
.route46Carpet
    ld a, [wXCoord]
    cp 35
    ret nz
    ld a, [wYCoord]
    cp 33
    ret nz
.allow
    ld e, 1
    ret
