; Gold 16x16 quad terrain roles (0 floor, 1 solid, 2 water).
; Preserves no live tile/palette cache. E=3 means not a south-batch map.
; Reads records in the same fixed ROMX bank as this function; caller uses callab.
JohtoSouthSpatialRoleAhead::
    ld e, 3
    ld a, [wCurMap]
    cp JOHTO_RUNTIME_MAP_HANDLE
    ret nz
    ld a, [wCurRegion]
    cp MAP_REGION_JOHTO
    ret nz
    ld a, [wCurLocalMapID]
    cp JOHTO_AZALEA_TOWN_LOCAL_ID
    jp z, .AzaleaTown
    cp JOHTO_ILEX_AZALEA_GATE_LOCAL_ID
    jp z, .IlexForestAzaleaGate
    cp JOHTO_ILEX_FOREST_LOCAL_ID
    jp z, .IlexForest
    cp JOHTO_ROUTE34_ILEX_GATE_LOCAL_ID
    jp z, .Route34IlexForestGate
    cp JOHTO_ROUTE_34_LOCAL_ID
    jp z, .Route34
    cp JOHTO_GOLDENROD_CITY_LOCAL_ID
    jp z, .GoldenrodCity
    cp JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID
    jp z, .Route35Gate
    cp JOHTO_ROUTE_35_LOCAL_ID
    jp z, .Route35
    cp JOHTO_ROUTE_37_LOCAL_ID
    jp z, .Route37
    cp JOHTO_ECRUTEAK_CITY_LOCAL_ID
    jp z, .EcruteakCity
    cp JOHTO_ROUTE_38_ECRUTEAK_GATE_LOCAL_ID
    jp z, .Route38Gate
    cp JOHTO_ROUTE_38_LOCAL_ID
    jp z, .Route38
    cp JOHTO_ROUTE_39_LOCAL_ID
    jp z, .Route39
    cp JOHTO_OLIVINE_CITY_LOCAL_ID
    jp z, .OlivineCity
    cp JOHTO_NATIONAL_PARK_LOCAL_ID
    jp z, .NationalPark
    cp JOHTO_ROUTE_35_NATIONAL_PARK_GATE_LOCAL_ID
    jp z, .SouthParkGate
    cp JOHTO_ROUTE_36_NATIONAL_PARK_GATE_LOCAL_ID
    jp z, .EastParkGate
    ret
.AzaleaTown
    ld hl, JohtoSouthAzaleaTownRoles
    ld b, 40
    ld c, 18
    jp .common
.IlexForestAzaleaGate
    ld hl, JohtoSouthIlexForestAzaleaGateRoles
    jp .gate10x8
.IlexForest
    ld hl, JohtoSouthIlexForestRoles
    ld b, 30
    ld c, 54
    jp .common
.Route34IlexForestGate
    ld hl, JohtoSouthRoute34IlexForestGateRoles
    jp .gate10x8
.Route34
    ld hl, JohtoSouthRoute34Roles
    ld b, 20
    ld c, 54
    jp .common
.GoldenrodCity
    ld hl, JohtoSouthGoldenrodCityRoles
    ld b, 40
    ld c, 36
    jp .common
.Route35Gate
    ld hl, JohtoNorthRoute35GoldenrodGateRoles
    jp .gate10x8
.Route35
    ld hl, JohtoNorthRoute35Roles
    ld b, 20
    ld c, 36
    jp .common
.Route37
    ld hl, JohtoRoute37Roles
    ld b, 20
    ld c, 18
    jp .common
.EcruteakCity
    ld hl, JohtoEcruteakRoles
    ld b, 40
    ld c, 36
    jp .common
.Route38Gate
    ld hl, JohtoRoute38EcruteakGateRoles
    jp .gate10x8
.Route38
    ld hl, JohtoRoute38Roles
    ld b, 40
    ld c, 18
    jp .common
.Route39
    ld hl, JohtoRoute39Roles
    ld b, 20
    ld c, 36
    jp .common
.OlivineCity
    ld hl, JohtoOlivineRoles
    ld b, 40
    ld c, 36
    jp .common
.NationalPark
    ld hl, JohtoParkRoles
    ld b, 40
    ld c, 54
    jp .common
.SouthParkGate
    ld hl, JohtoParkSouthGateRoles
    ld b, 8
    ld c, 8
    jp .common
.EastParkGate
    ld hl, JohtoParkEastGateRoles
    ; All five 10x8 Gold gate role grids share only their dimensions;
    ; each keeps its own HL data pointer, carpet/Warp and collision backend.
.gate10x8
    ld b, 10
    ld c, 8

.common
    push hl ; exact map's role grid
    ld a, [wXCoord]
    ld e, a
    ld a, [wYCoord]
    ld d, a
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    jp z, .north
    cp PLAYER_DIR_DOWN
    jp z, .south
    cp PLAYER_DIR_LEFT
    jp z, .west
    cp PLAYER_DIR_RIGHT
    jp nz, .bad
    inc e
    jp .bounds
.north
    dec d
    jp .bounds
.south
    inc d
    jp .bounds
.west
    dec e
.bounds
    ld a, e
    cp b
    jp nc, .offMap
    ld a, d
    cp c
    jp nc, .offMap
    ; FIX-271: the accepted NPC-243 Gold collision masks mark several
    ; unregistered doors/carpet faces solid. Gold FLOOR role data alone
    ; must not override those precise, source-tested portal boundaries.
    call JohtoSouthMatureDoorFence
    jp nc, .matureDoorAllowed
    pop hl ; discard selected role grid on a rejected target
    ld e, 1
    ret
.matureDoorAllowed
    ; The one Ilex CUT_TREE at (8,25) stays solid until Cut has
    ; replaced its original 32x32 block $0f with clone $2d. Never use
    ; the immutable Gold role mask to permanently block a cleared tree.
    push bc
    push de
    ld a, [wCurLocalMapID]
    cp JOHTO_ILEX_FOREST_LOCAL_ID
    jr z, .checkForestCut
    cp JOHTO_ROUTE_35_LOCAL_ID
    jr nz, .notClearedForestCut
    ; Route35's Gold (17,6) CUT_TREE uses the existing $5B -> $90
    ; clone. The immutable Gold collision mask remains blocked until Cut.
    ld a, d
    cp 6
    jr nz, .notClearedForestCut
    ld a, e
    cp 17
    jr nz, .notClearedForestCut
    jr .readClearedBlock
.checkForestCut
    ld a, d
    cp 25
    jr nz, .notClearedForestCut
    ld a, e
    cp 8
    jr nz, .notClearedForestCut
.readClearedBlock
    call .isForestCutBlockCleared
    jr nc, .notClearedForestCut
    pop de
    pop bc
    pop hl
    ld e, 0
    ret
.notClearedForestCut
    pop de
    pop bc
    ; A 16-bit y*width+x offset (w<=40, h<=54), no 8-bit overflow.
    ld hl, 0
.row
    ld a, d
    and a
    jp z, .index
    push de
    ld d, 0
    ld e, b
    add hl, de
    pop de
    dec d
    jp .row
.index
    ld d, 0
    add hl, de
    pop de ; role-grid base
    add hl, de
    ld e, [hl]
    ret
.offMap
    ; JohtoPilotIsClosedOutdoorEdge owns allowed/blocked map seams.
    pop hl
    ld e, 0
    ret
.bad
    pop hl
    ld e, 1
    ret

; Read the actual 32x32 block in front of the player, using the same
; on-screen address rules as JohtoRoutesCutTreeAhead. Carry=1 only for
; the newly cleared forest block $2d (the headbutt quadrant is unchanged).
.isForestCutBlockCleared
    ld a, [wCurMapWidth]
    add 6
    ld c, a
    ld b, 0
    ld hl, wCurrentTileBlockMapViewPointer
    ld a, [hli]
    ld h, [hl]
    ld l, a
    add hl, bc
    ld a, [wSpriteStateData1 + 9]
    cp SPRITE_FACING_DOWN
    jr z, .cutFacingDown
    cp SPRITE_FACING_UP
    jr z, .cutFacingUp
    cp SPRITE_FACING_LEFT
    jr z, .cutFacingLeft
    ld a, [wXBlockCoord]
    and a
    jr z, .cutCenter
    jr .cutFacingRight
.cutFacingDown
    ld a, [wYBlockCoord]
    and a
    jr z, .cutCenter
    jr .cutBelow
.cutFacingUp
    ld a, [wYBlockCoord]
    and a
    jr z, .cutAbove
    jr .cutCenter
.cutFacingLeft
    ld a, [wXBlockCoord]
    and a
    jr z, .cutLeft
    jr .cutCenter
.cutBelow
    add hl, bc
.cutCenter
    add hl, bc
.cutAbove
    ld de, 2
    add hl, de
    jr .cutRead
.cutLeft
    ld de, 1
    add hl, bc
    add hl, de
    jr .cutRead
.cutFacingRight
    ld de, 3
    add hl, bc
    add hl, de
.cutRead
    ld a, [wCurLocalMapID]
    cp JOHTO_ROUTE_35_LOCAL_ID
    ld a, [hl]
    jr nz, .forestClearedBlock
    cp $90
    jr z, .cutCleared
    and a ; Gold $5B must never inherit CP carry as a cleared tree.
    ret
.forestClearedBlock
    cp $2d
    jr z, .cutCleared
    and a ; Critical: CP $2D on uncut $0F leaves Carry=1.
    ret
.cutCleared
    scf
    ret

; FIX-275: Surf shore may only be a genuinely passable land cell.
; Return Carry for a valid non-water landing using the SAME mature land
; collision predicate as ordinary walking, never an empty tilecoll list.
JohtoSouthGoldShoreProbe::
    call JohtoSouthSpatialRoleAhead
    ld a, e
    and a
    ret nz ; Water, blocked, or an unsupported map cannot be a shore.
    call JohtoSouthSpatialStep
    ld a, e
    and a
    ret nz
    scf
    ret

JohtoSouthGoldWaterProbe::
    push bc
    push de
    push hl
    call JohtoSouthSpatialRoleAhead
    ld a, e
    cp 2
    jr z, .water
    pop hl
    pop de
    pop bc
    and a
    ret
.water
    pop hl
    pop de
    pop bc
    scf
    ret

JohtoSouthSpatialStep::
    ; FIX-275: for Ilex use the complete accepted ILEX-217 land/Cut mask
    ; rather than treating Gold art roles as a second walkability engine.
    ld a, [wCurMap]
    cp JOHTO_RUNTIME_MAP_HANDLE
    jr nz, .ordinary
    ld a, [wCurRegion]
    cp MAP_REGION_JOHTO
    jr nz, .ordinary
    ld a, [wCurLocalMapID]
    cp JOHTO_ILEX_FOREST_LOCAL_ID
    jr nz, .ordinary
    push bc
    push de
    push hl
    call JohtoIlexForestCanStepAhead
    ld a, 1
    jr c, .matureDone
    xor a
.matureDone
    pop hl
    pop de
    pop bc
    ld e, a
    ret
.ordinary
    push bc
    push de
    push hl
    ; FIX-288: the East Park Gate legacy Gold role converter marks
    ; several interior floor cells (notably x1/y5) as walls. Use the
    ; validated NPC-243 two-byte-per-row mask for this one gate.
    ld a, [wCurLocalMapID]
    cp JOHTO_ECRUTEAK_CITY_LOCAL_ID
    jr z, .westCarpet
    cp JOHTO_ROUTE_38_ECRUTEAK_GATE_LOCAL_ID
    jr z, .westCarpet
    cp JOHTO_ROUTE_38_LOCAL_ID
    jr z, .westCarpet
    cp JOHTO_ROUTE_36_NATIONAL_PARK_GATE_LOCAL_ID
    jr nz, .otherSpatialRole
    call JohtoParkEastGateMatureStep
    jr .haveSpatialRole
.westCarpet
    call JohtoWestCarpetSpatialStep
    jr .haveSpatialRole
.otherSpatialRole
    call JohtoSouthSpatialRoleAhead
.haveSpatialRole
    ld a, e
    cp 2
    jr nz, .notWater
    ld a, [wWalkBikeSurfState]
    cp 2
    jr nz, .block
    jr .allow
.notWater
    and a
    jr z, .allow
.block
    ld e, 1
    jr .done
.allow
    ld e, 0
.done
    pop hl
    pop bc ; discard incoming E/D registers from stack below? (corrected below)
    pop bc
    ret


; MAP-297: mature west-gate carpets are blocked in the static mask because
; only outward collision may Warp. Permit ordinary approach/vertical lane moves.
; Returns E=0 pass / E=1 block for the three carpet-bearing maps.
; Shared horizontal-carpet ingress. Both Ecruteak gates use one banked
; target-cell predicate; their wall role grids and outward Warp guards remain
; separate. Park East retains its accepted mature-mask backend.
JohtoWestCarpetSpatialStep::
    ld a, [wCurLocalMapID]
    cp JOHTO_ROUTE_38_ECRUTEAK_GATE_LOCAL_ID
    jr nz, .ordinaryWest
    callab JohtoGateHorizontalCarpetInbound303
    ld a, e
    and a
    ret z
    jp .role
.ordinaryWest
    cp JOHTO_ECRUTEAK_CITY_LOCAL_ID
    jr z, .city
    cp JOHTO_ROUTE_38_LOCAL_ID
    jp z, .route38
    jp .role
.city
    ; Burned Tower entrance is the same narrow UP-step Gold DOOR as centers.
    ld a, [wXCoord]
    cp 5
    jr nz, .cityWestCarpet
    ld a, [wYCoord]
    cp 6
    jr nz, .cityWestCarpet
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    jr nz, .cityWestCarpet
    ld e, 0
    ret
.cityWestCarpet
    ld a, [wXCoord]
    cp 1
    jr nz, .cityVertical
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_LEFT
    jr nz, .cityVertical
    ld a, [wYCoord]
    cp 18
    jr z, .allow
    cp 19
    jr z, .allow
.cityVertical
    ld a, [wXCoord]
    and a
    jr nz, .role
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    jr z, .cityUp
    cp PLAYER_DIR_DOWN
    jr nz, .role
    ld a, [wYCoord]
    cp 18
    jr z, .allow
    jr .role
.cityUp
    ld a, [wYCoord]
    cp 19
    jr z, .allow
    jr .role
.route38
    ld a, [wXCoord]
    cp 34
    jr nz, .r38Vertical
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_RIGHT
    jr nz, .r38Vertical
    ld a, [wYCoord]
    cp 8
    jr z, .allow
    cp 9
    jr z, .allow
.r38Vertical
    ld a, [wXCoord]
    cp 35
    jr nz, .role
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    jr z, .r38Up
    cp PLAYER_DIR_DOWN
    jr nz, .role
    ld a, [wYCoord]
    cp 8
    jr z, .allow
    cp 7
    jr z, .allow
    jr .role
.r38Up
    ld a, [wYCoord]
    cp 9
    jr z, .allow
.role
    call JohtoSouthSpatialRoleAhead
    ld a, e
    cp 2
    jr nz, .notWaterWest
    ld a, [wWalkBikeSurfState]
    cp 2
    jr z, .allow
    jr .block
.notWaterWest
    and a
    jr z, .allow
.block
    ld e, 1
    ret
.allow
    ld e, 0
    ret

; FIX-288: exact 10x8 Park east gate passability, from NPC-243 mature mask.
; The four verified x0/x9 (y4/y5) warp carpets are physically walkable,
; but only an outward collision on them may activate the registered warp.
; Input live map/player position and direction. E=0 pass, E=1 block.
JohtoParkEastGateMatureStep::
    ld a, [wXCoord]
    ld c, a
    ld a, [wYCoord]
    ld b, a
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    jr z, .up
    cp PLAYER_DIR_DOWN
    jr z, .down
    cp PLAYER_DIR_LEFT
    jr z, .left
    cp PLAYER_DIR_RIGHT
    jp nz, .block
    inc c
    jr .bounds
.left
    dec c
    jr .bounds
.up
    dec b
    jr .bounds
.down
    inc b
.bounds
    ld a, c
    cp 10
    jp nc, .block
    ld a, b
    cp 8
    jp nc, .block
    ; Mature mask intentionally seals the 4 gate edge carpets until warp.
    ; Moving onto those cells from inside is allowed; the outer boundary
    ; is separately protected by JohtoPilotIsClosedOutdoorEdge.
    ld a, c
    and a
    jr z, .maybeCarpet
    cp 9
    jr nz, .mask
.maybeCarpet
    ld a, b
    cp 4
    jr z, .pass
    cp 5
    jr z, .pass
.mask
    ld hl, JohtoParkEastGateBlockedRows
    ld a, b
    add a ; two mask bytes per row, 10 cell columns
    ld e, a
    ld d, 0
    add hl, de
    ld a, c
    cp 8
    jr c, .lowMaskByte
    inc hl
    sub 8
.lowMaskByte
    ld b, a
    and a ; zero bit index must not underflow shift counter to $ff
    ld a, 1
    jr z, .maskReady
.shiftMask
    add a
    dec b
    jr nz, .shiftMask
.maskReady
    and [hl]
    jr nz, .block
.pass
    ld e, 0
    ret
.block
    ld e, 1
    ret
JohtoParkEastGateBlockedRows::
    INCBIN "maps/johto_pilot/Route36NationalParkGate.mature_blocked_mask.bin"
JohtoParkEastGateBlockedRowsEnd::
ASSERT JohtoParkEastGateBlockedRowsEnd - JohtoParkEastGateBlockedRows == 16

; FIX-281: live carpet pairs are excluded from the closed-door blacklist.
; FIX-271: exact difference between mature NPC-243 passability masks and
; Gold art-role arrays. Source map roles remain unchanged for Surf/Gold audit.
; E/D are the *target* 8x8 coordinates, with B/C and HL used by the caller.
; Carry=1 means block. No state, bank switch, or generated binary assets.
JohtoSouthMatureDoorFence::
    push bc
    push hl
    ld a, [wCurLocalMapID]
    cp JOHTO_ILEX_FOREST_LOCAL_ID
    jp z, .forest
    cp JOHTO_AZALEA_TOWN_LOCAL_ID
    jp z, .azaleaDoor
    cp JOHTO_GOLDENROD_CITY_LOCAL_ID
    jp z, .goldenrodDoor
.scanOther
    ld a, [wCurLocalMapID]
    ld b, a
    ld hl, .closedDoorTargets
.next
    ld a, [hli]
    cp $ff
    jp z, .open
    cp b
    jp nz, .skipX
    ld a, [hli]
    cp e
    jp nz, .skipY
    ld a, [hl]
    cp d
    jp z, .blocked
    inc hl
    jp .next
.skipX
    inc hl
.skipY
    inc hl
    jp .next
.goldenrodDoor
    ; Gold (15,27) is the only additional opened city building.
    ld a, e
    cp 15
    jr nz, .scanOther
    ld a, d
    cp 27
    jr nz, .scanOther
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    jp z, .open
    jp .blocked
.azaleaDoor
    ; The only newly enabled building target is Gold (15,9). It is a
    ; true DOOR and may be entered solely from (15,10) facing UP.
    ld a, e
    cp 15
    jr nz, .scanOther
    ld a, d
    cp 9
    jr nz, .scanOther
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    jp z, .open
    jp .blocked
.forest
    ; NPC-243 ILEX-217: special north DOOR at (1,5) is approached
    ; from (1,6) facing UP, never from the sides or from above.
    ld a, e
    cp 1
    jp nz, .forestSouth
    ld a, d
    cp 5
    jp nz, .open
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    jp z, .open
    jp .blocked
.forestSouth
    ; Gold WARP_CARPET_RIGHT at (3,42)/(3,43): preserve the
    ; mature branch's approved lane switches and eastward approach.
    ld a, e
    cp 3
    jp nz, .open
    ld a, d
    cp 42
    jp z, .upperCarpet
    cp 43
    jp nz, .open
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_RIGHT
    jp z, .open
    cp PLAYER_DIR_DOWN
    jp z, .open
    jp .blocked
.upperCarpet
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_RIGHT
    jp z, .open
    cp PLAYER_DIR_UP
    jp z, .open
    cp PLAYER_DIR_DOWN
    jp z, .open
.blocked
    pop hl
    pop bc
    scf
    ret
.open
    pop hl
    pop bc
    and a
    ret

; Source: NPC-5.62.243's blocked_mask.bin vs Gold role arrays.
; The Azalea south gate (2,10)/(2,11) and Route34 north gate
; (13,37)/(14,37) are registered carpets and intentionally excluded.
; The 24 previous building targets plus Route35 park (3,5) stay solid.
.closedDoorTargets
    db JOHTO_AZALEA_TOWN_LOCAL_ID, 9, 5
    db JOHTO_AZALEA_TOWN_LOCAL_ID, 21, 5
    db JOHTO_AZALEA_TOWN_LOCAL_ID, 21, 13
    db JOHTO_AZALEA_TOWN_LOCAL_ID, 10, 15
    db JOHTO_ROUTE_34_LOCAL_ID, 11, 14
    db JOHTO_ROUTE_34_LOCAL_ID, 11, 15
    db JOHTO_ROUTE_34_LOCAL_ID, 13, 15
    ; FIX-281: (13,37)/(14,37) are LIVE Route34 -> Ilex north gate
    ; WARP_CARPET_DOWN cells. They must allow lateral lane changes on foot
    ; or bike; outward DOWN collision alone activates the registered warp.
    ; Never blacklist a live carpet as an unopened building entrance.
    db JOHTO_ROUTE_34_LOCAL_ID, 13, 41
    ; FIX-284: NPC-243 mature Route35 mask blocks the unregistered
    ; National Park entrance (3,5); Gold art roles alone mark it FLOOR.
    ; Only the separate live gate carpets (9,33)/(10,33) stay open.
    db JOHTO_GOLDENROD_CITY_LOCAL_ID, 9, 5
    db JOHTO_GOLDENROD_CITY_LOCAL_ID, 33, 5
    db JOHTO_GOLDENROD_CITY_LOCAL_ID, 15, 7
    db JOHTO_GOLDENROD_CITY_LOCAL_ID, 24, 7
    db JOHTO_GOLDENROD_CITY_LOCAL_ID, 33, 9
    db JOHTO_GOLDENROD_CITY_LOCAL_ID, 9, 13
    db JOHTO_GOLDENROD_CITY_LOCAL_ID, 5, 15
    db JOHTO_GOLDENROD_CITY_LOCAL_ID, 14, 21
    db JOHTO_GOLDENROD_CITY_LOCAL_ID, 31, 21
    db JOHTO_GOLDENROD_CITY_LOCAL_ID, 5, 25
    db JOHTO_GOLDENROD_CITY_LOCAL_ID, 24, 27
    db JOHTO_GOLDENROD_CITY_LOCAL_ID, 11, 29
    db JOHTO_GOLDENROD_CITY_LOCAL_ID, 29, 29
    db $ff

JohtoSouthAzaleaTownRoles:: INCBIN "maps/johto_pilot/AzaleaTown.roles.bin"
JohtoSouthAzaleaTownRolesEnd::
ASSERT JohtoSouthAzaleaTownRolesEnd - JohtoSouthAzaleaTownRoles == 720

JohtoSouthIlexForestAzaleaGateRoles:: INCBIN "maps/johto_pilot/IlexForestAzaleaGate.roles.bin"
JohtoSouthIlexForestAzaleaGateRolesEnd::
ASSERT JohtoSouthIlexForestAzaleaGateRolesEnd - JohtoSouthIlexForestAzaleaGateRoles == 80

JohtoSouthIlexForestRoles:: INCBIN "maps/johto_pilot/IlexForest.roles.bin"
JohtoSouthIlexForestRolesEnd::
ASSERT JohtoSouthIlexForestRolesEnd - JohtoSouthIlexForestRoles == 1620

JohtoSouthRoute34IlexForestGateRoles:: INCBIN "maps/johto_pilot/Route34IlexForestGate.roles.bin"
JohtoSouthRoute34IlexForestGateRolesEnd::
ASSERT JohtoSouthRoute34IlexForestGateRolesEnd - JohtoSouthRoute34IlexForestGateRoles == 80

JohtoSouthRoute34Roles:: INCBIN "maps/johto_pilot/Route34.roles.bin"
JohtoSouthRoute34RolesEnd::
ASSERT JohtoSouthRoute34RolesEnd - JohtoSouthRoute34Roles == 1080

JohtoSouthGoldenrodCityRoles:: INCBIN "maps/johto_pilot/GoldenrodCity.roles.bin"
JohtoSouthGoldenrodCityRolesEnd::
ASSERT JohtoSouthGoldenrodCityRolesEnd - JohtoSouthGoldenrodCityRoles == 1440

; E=1 closed edge, E=0 ordinary move. Negative coordinates never wrap
; into an unregistered map; direct approved lanes only in Gold topology.
JohtoNorthRoute35GoldenrodGateRoles:: INCBIN "maps/johto_pilot/Route35GoldenrodGate.roles.bin"
JohtoNorthRoute35GoldenrodGateRolesEnd::
ASSERT JohtoNorthRoute35GoldenrodGateRolesEnd - JohtoNorthRoute35GoldenrodGateRoles == 80
JohtoNorthRoute35Roles:: INCBIN "maps/johto_pilot/Route35.roles.bin"
JohtoNorthRoute35RolesEnd::
ASSERT JohtoNorthRoute35RolesEnd - JohtoNorthRoute35Roles == 720

JohtoRoute37Roles:: INCBIN "maps/johto_pilot/Route37.roles.bin"
ASSERT @ - JohtoRoute37Roles == 20 * 18
JohtoEcruteakRoles:: INCBIN "maps/johto_pilot/EcruteakCity.roles.bin"
ASSERT @ - JohtoEcruteakRoles == 40 * 36
JohtoRoute38EcruteakGateRoles:: INCBIN "maps/johto_pilot/Route38EcruteakGate.roles.bin"
ASSERT @ - JohtoRoute38EcruteakGateRoles == 10 * 8
JohtoRoute38Roles:: INCBIN "maps/johto_pilot/Route38.roles.bin"
ASSERT @ - JohtoRoute38Roles == 40 * 18
JohtoRoute39Roles:: INCBIN "maps/johto_pilot/Route39.roles.bin"
ASSERT @ - JohtoRoute39Roles == 20 * 36
JohtoOlivineRoles:: INCBIN "maps/johto_pilot/OlivineCity.roles.bin"
ASSERT @ - JohtoOlivineRoles == 40 * 36
JohtoParkRoles:: INCBIN "maps/johto_pilot/NationalPark.roles.bin"
JohtoParkRolesEnd::
ASSERT JohtoParkRolesEnd - JohtoParkRoles == 2160
JohtoParkSouthGateRoles:: INCBIN "maps/johto_pilot/Route35NationalParkGate.roles.bin"
JohtoParkSouthGateRolesEnd::
ASSERT JohtoParkSouthGateRolesEnd - JohtoParkSouthGateRoles == 64
JohtoParkEastGateRoles:: INCBIN "maps/johto_pilot/Route36NationalParkGate.roles.bin"
JohtoParkEastGateRolesEnd::
ASSERT JohtoParkEastGateRolesEnd - JohtoParkEastGateRoles == 80

JohtoSouthIsKnownClosedEdge::
    ld e, 0
    ld a, [wCurLocalMapID]
    cp JOHTO_AZALEA_TOWN_LOCAL_ID
    jp z, .azalea
    cp JOHTO_ROUTE_34_LOCAL_ID
    jp z, .route34
    cp JOHTO_GOLDENROD_CITY_LOCAL_ID
    jp z, .goldenrod
    cp JOHTO_ROUTE_35_LOCAL_ID
    jp z, .route35
    cp JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID
    jp z, .route35Gate
    cp JOHTO_ROUTE_37_LOCAL_ID
    jp z, .route37
    cp JOHTO_ECRUTEAK_CITY_LOCAL_ID
    jp z, .ecruteak
    cp JOHTO_NATIONAL_PARK_LOCAL_ID
    jp z, .park
    cp JOHTO_ROUTE_35_NATIONAL_PARK_GATE_LOCAL_ID
    jp z, .parkSouthGate
    cp JOHTO_ROUTE_36_NATIONAL_PARK_GATE_LOCAL_ID
    jp z, .parkEastGate
    cp JOHTO_ILEX_AZALEA_GATE_LOCAL_ID
    jp z, .smallGate
    cp JOHTO_ROUTE34_ILEX_GATE_LOCAL_ID
    jp z, .smallGate
    cp JOHTO_ILEX_FOREST_LOCAL_ID
    jp z, .forest
    ret
.azalea
    ld b, 40
    ld c, 18
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_RIGHT
    jp nz, .regular
    ld a, [wXCoord]
    cp 39
    ret nz
    ld a, [wYCoord]
    cp 14
    ret z
    cp 15
    ret z
    jp .closed
.route34
    ld b, 20
    ld c, 54
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    jp nz, .regular
    ld a, [wYCoord]
    and a
    ret nz
    ld a, [wXCoord]
    cp 8
    jp c, .closed
    cp 12 ; FIX-279: Gold has four contiguous north seam columns 8..11
    ret c
    jp .closed
.goldenrod
    ld b, 40
    ld c, 36
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_DOWN
    jp nz, .regular
    ld a, [wYCoord]
    cp 35
    ret nz
    ld a, [wXCoord]
    cp 18
    jp c, .closed
    cp 22 ; FIX-279: reciprocal Goldenrod south columns 18..21
    ret c
    jr .closed
.route35
    ld b, 20
    ld c, 36
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    jp nz, .regular
    ld a, [wYCoord]
    and a
    ret nz
    ld a, [wXCoord]
    cp 17 ; only Gold mature collision lane (Route35 x17 -> Route36 x17)
    ret z
    jp .closed
.route35Gate
    ld b, 10
    ld c, 8
    jp .regular
.route37
    ld b, 20
    ld c, 18
    jp .regular
.ecruteak
    ld b, 40
    ld c, 36
    jp .regular
.park
    ld b, 40
    ld c, 54
    jp .regular
.parkSouthGate
    ld b, 8
    ld c, 8
    jp .regular
.parkEastGate
    ld b, 10
    ld c, 8
    jp .regular
.smallGate
    ld b, 10
    ld c, 8
    jp .regular
.forest
    ld b, 30
    ld c, 54
.regular
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    jr z, .up
    cp PLAYER_DIR_DOWN
    jr z, .down
    cp PLAYER_DIR_LEFT
    jr z, .left
    cp PLAYER_DIR_RIGHT
    ret nz
    ld a, [wXCoord]
    inc a
    cp b
    jr nc, .closed
    ret
.up
    ld a, [wYCoord]
    and a
    jr z, .closed
    ret
.down
    ld a, [wYCoord]
    inc a
    cp c
    jr nc, .closed
    ret
.left
    ld a, [wXCoord]
    and a
    jr z, .closed
    ret
.closed
    ld e, 1
    ret
