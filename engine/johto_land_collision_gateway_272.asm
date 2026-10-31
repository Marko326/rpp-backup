; FIX-272: ROM0 land-collision gateway for Gold-only maps.
; Enter only after sprite collision, outdoor seam, and exterior gate guards.
; Caller is in ROM0 and has checked wCurMap = JOHTO_RUNTIME_MAP_HANDLE.
; E=0: pass; E=1: wall; E=2: defer to legacy tile-pair/passability.
; Never mutate Kanto collision or the user's JP jump distances.
JohtoOverworldSouthLandDecision::
    ld e, 2
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
    jr nz, .southMaps
    ld a, [wYCoord]
    cp 10
    jr nz, .southMaps
    ld e, 0
    ret
.southMaps
    ld a, [wCurLocalMapID]
    cp JOHTO_AZALEA_TOWN_LOCAL_ID
    jr c, .route33
    cp JOHTO_GOLDENROD_CITY_LOCAL_ID + 1
    jr nc, .route33
    ; The accepted ledge handler starts the simulated two-input jump.
    callab HandleLedges
    ld a, [wd736]
    bit 6, a
    jr nz, .allowJump
    callab JohtoSouthSpatialStep
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
