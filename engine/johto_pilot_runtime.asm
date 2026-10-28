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
    ; Empty during the outdoor-only P4/P5 framework stage.
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
    jr z, .route30
    cp JOHTO_ROUTE_31_LOCAL_ID
    jp z, .route31
    ret
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
