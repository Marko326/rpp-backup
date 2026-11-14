; REF-368D: source-anchored Dig/Escape Rope for all five Ice Path floors.
; Mirrors the safe Dark Cave special-warp path; never teleports to heal
; center and never overwrites a valid mouth on internal stair transfers.
; Unused, save-backed event slots EVENT_9CA/9CB are reserved by this stage.
SECTION "REF368D Ice Path Outdoor Escape", ROMX
DEF JOHTO_ICE_PATH_ANCHOR_BYTE EQU EVENT_9CA / 8
ASSERT (EVENT_9CA % 8) == 2
ASSERT (EVENT_9CB % 8) == 3

; E = Gold outdoor source stable ID. Internal floors are ignored.
JohtoIcePathRememberOutdoorSource368D::
    ld a, e
    cp JOHTO_ROUTE_44_LOCAL_ID
    jr z, .route44
    cp JOHTO_BLACKTHORN_CITY_LOCAL_ID
    ret nz
    ld b, $08
    jr .save
.route44
    ld b, $04
.save
    ld hl, wEventFlags + JOHTO_ICE_PATH_ANCHOR_BYTE
    ld a, [hl]
    and $f3 ; retain unrelated bits; replace only the two Ice Path bits
    or b
    ld [hl], a
    ret

; C set means current region/map is an Ice Path floor and the saved
; exterior is exactly Route44 or Blackthorn (not zero or corrupt 11).
JohtoIcePathEscapeAllowed368D::
    ld a, [wCurMap]
    cp JOHTO_RUNTIME_MAP_HANDLE
    jr nz, .deny
    ld a, [wCurRegion]
    cp MAP_REGION_JOHTO
    jr nz, .deny
    ld a, [wCurLocalMapID]
    cp JOHTO_ICE_PATH_1F_LOCAL_ID
    jr z, .anchor
    cp JOHTO_ICE_PATH_B1F_LOCAL_ID
    jr z, .anchor
    cp JOHTO_ICE_PATH_B2F_MAHOGANY_SIDE_LOCAL_ID
    jr z, .anchor
    cp JOHTO_ICE_PATH_B3F_LOCAL_ID
    jr z, .anchor
    cp JOHTO_ICE_PATH_B2F_BLACKTHORN_SIDE_LOCAL_ID
    jr nz, .deny
.anchor
    ld a, [wEventFlags + JOHTO_ICE_PATH_ANCHOR_BYTE]
    and $0c
    cp $04
    jr z, .allow
    cp $08
    jr nz, .deny
.allow
    scf
    ret
.deny
    and a
    ret

; Called only after an Ice Path rope/Dig is accepted. Return on FLOOR
; directly below the original outdoor cave mouth, not on the CAVE warp.
; Route44 cave (56,7) -> (56,8); Blackthorn cave (36,9) -> (36,10).
JohtoIcePathApplyEscape368D::
    ld a, [wEventFlags + JOHTO_ICE_PATH_ANCHOR_BYTE]
    and $0c
    cp $04
    jr z, .route44
    cp $08
    jp nz, SoftReset ; invalid, never fall back to Kanto heal map
    ld a, JOHTO_BLACKTHORN_CITY_LOCAL_ID
    ld hl, .blackthornData
    jr .land
.route44
    ld a, JOHTO_ROUTE_44_LOCAL_ID
    ld hl, .route44Data
.land
    ld [wCurLocalMapID], a
    ld a, JOHTO_RUNTIME_MAP_HANDLE
    ld [wCurMap], a
    ld [wDestinationMap], a
    ld a, MAP_REGION_JOHTO
    ld [wCurRegion], a
    ld de, wCurrentTileBlockMapViewPointer
    ld c, 6
.copy
    ld a, [hli]
    ld [de], a
    inc de
    dec c
    jr nz, .copy
    ret
.route44Data
    FLYWARP_DATA JOHTO_ROUTE_44_WIDTH, 8, 56
.blackthornData
    FLYWARP_DATA JOHTO_BLACKTHORN_CITY_WIDTH, 10, 36
