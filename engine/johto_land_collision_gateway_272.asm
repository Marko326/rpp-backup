; FIX-272: ROM0 land-collision gateway for Gold-only maps.
; Enter only after sprite collision, outdoor seam, and exterior gate guards.
; Caller is in ROM0 and has checked wCurMap = JOHTO_RUNTIME_MAP_HANDLE.
; E=0: pass; E=1: wall; E=2: defer to legacy tile-pair/passability.
; Never mutate Kanto collision or the user's JP jump distances.
JohtoOverworldSouthLandDecision::
    ld e, 2
    ; DEV-337: Gold Center is an indoor Kanto-style collision tileset.
    ; Skip the long outdoor Gold-role dispatch on every interior step.
    ld a, [wCurLocalMapID]
    cp JOHTO_CHERRYGROVE_POKECENTER_1F_LOCAL_ID
    ret z
    ; Original Cherrygrove guide's-house approach exception.
    ld a, [wCurRegion]
    cp MAP_REGION_JOHTO
    jr nz, .southMaps
    ld a, [wCurLocalMapID]
    cp JOHTO_CHERRYGROVE_LOCAL_ID
    jr nz, .southMaps
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    jr nz, .southMaps
    ld a, [wXCoord]
    cp 25
    jr z, .cherryGuideApproach
    cp 29
    jr nz, .southMaps
    ld a, [wYCoord]
    cp 4 ; approach Gold Pokecenter door at (Y3,X29)
    jr nz, .southMaps
    ld e, 0
    ret
.cherryGuideApproach
    ld a, [wYCoord]
    cp 10 ; original Gold Guide Gent door at (Y9,X25)
    jr nz, .southMaps
    ld e, 0
    ret
.southMaps
    ; FIX-285: 17 Route35 / 18 Goldenrod north gate were registered after
    ; FIX-272's 10..15 interval. Route35 collision must enter the Gold role
    ; grid, not fall back to legacy 8x8 tile passability (fence can be crossed).
    ; Local ID 16 is Route36: preserve its existing independent movement.
    ld a, [wCurLocalMapID]
    cp JOHTO_ROUTE_37_LOCAL_ID
    jp z, .activeSouthMap
    cp JOHTO_ECRUTEAK_CITY_LOCAL_ID
    jp z, .activeSouthMap
    cp JOHTO_ROUTE_38_ECRUTEAK_GATE_LOCAL_ID
    jp z, .activeSouthMap
    cp JOHTO_ROUTE_38_LOCAL_ID
    jp z, .activeSouthMap
    cp JOHTO_ROUTE_39_LOCAL_ID
    jp z, .activeSouthMap
    cp JOHTO_OLIVINE_CITY_LOCAL_ID
    jp z, .activeSouthMap
    cp JOHTO_ROUTE_40_LOCAL_ID
    jr z, .westSeaMap
    cp JOHTO_ROUTE_41_LOCAL_ID
    jr z, .westSeaMap
    cp JOHTO_CIANWOOD_CITY_LOCAL_ID
    jr z, .westSeaMap
    cp JOHTO_ROUTE_42_ECRUTEAK_GATE_LOCAL_ID
    jr z, .eastMap
    cp JOHTO_ROUTE_42_LOCAL_ID
    jr z, .eastMap
    cp JOHTO_MAHOGANY_TOWN_LOCAL_ID
    jr z, .eastMap
    cp JOHTO_ROUTE_43_LOCAL_ID
    jr z, .eastMap
    ; REF-319: Lake of Rage uses the same exact Gold quadrant role grid as
    ; Route42/43/Mahogany.  Do not fall back to the legacy JOHTO_PILOT tile
    ; whitelist: shared visual tile IDs are FLOOR at some coordinates and
    ; WALL/HOP barriers at others.
    cp JOHTO_LAKE_OF_RAGE_LOCAL_ID
    jr z, .eastMap
    ; DEV-328: ID69..73 share ROMX Gold roles; ID70 IcePath remains
    ; unregistered and fails closed in JohtoEastSpatialRoleAhead.
    cp JOHTO_ROUTE_44_LOCAL_ID
    jr c, .afterEastSouth
    cp JOHTO_ROUTE_46_LOCAL_ID + 1
    jr c, .eastMap
.afterEastSouth
    cp JOHTO_ROUTE_35_LOCAL_ID
    jr z, .activeSouthMap
    cp JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID
    jr z, .activeSouthMap
    cp JOHTO_NATIONAL_PARK_LOCAL_ID
    jr z, .activeSouthMap
    cp JOHTO_ROUTE_35_NATIONAL_PARK_GATE_LOCAL_ID
    jr z, .activeSouthMap
    cp JOHTO_ROUTE_36_NATIONAL_PARK_GATE_LOCAL_ID
    jr z, .activeSouthMap
    cp JOHTO_AZALEA_TOWN_LOCAL_ID
    jr c, .route33
    cp JOHTO_GOLDENROD_CITY_LOCAL_ID + 1
    jr nc, .route33
.activeSouthMap
    ; The accepted ledge handler starts the simulated two-input jump.
    callab HandleLedges
    ld a, [wd736]
    bit 6, a
    jr nz, .allowJump
    callab JohtoSouthSpatialStep
    ret
.westSeaMap
    callab HandleLedges
    ld a, [wd736]
    bit 6, a
    jr nz, .allowJump
    callab JohtoWestSeaSpatialStep
    ret
.eastMap
    callab HandleLedges
    ld a, [wd736]
    bit 6, a
    jr nz, .allowJump
    callab JohtoEastSpatialStep
    ret
.route33
    cp JOHTO_ROUTE_33_LOCAL_ID
    ret nz ; E=2, non-south/legacy map
    callab HandleLedges
    ld a, [wd736]
    bit 6, a
    jr nz, .allowJump
    callab JohtoRoute33StepPolicy
    ret
.allowJump
    ld e, 0
    ret
