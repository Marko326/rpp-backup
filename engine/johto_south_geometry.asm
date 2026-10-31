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
    ret
.AzaleaTown
    ld hl, JohtoSouthAzaleaTownRoles
    ld b, 40
    ld c, 18
    jp .common
.IlexForestAzaleaGate
    ld hl, JohtoSouthIlexForestAzaleaGateRoles
    ld b, 10
    ld c, 8
    jp .common
.IlexForest
    ld hl, JohtoSouthIlexForestRoles
    ld b, 30
    ld c, 54
    jp .common
.Route34IlexForestGate
    ld hl, JohtoSouthRoute34IlexForestGateRoles
    ld b, 10
    ld c, 8
    jp .common
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
    jr nz, .notClearedForestCut
    ld a, d
    cp 25
    jr nz, .notClearedForestCut
    ld a, e
    cp 8
    jr nz, .notClearedForestCut
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
    ld a, [hl]
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
    call JohtoSouthSpatialRoleAhead
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
; All 24 remaining targets lead to unregistered interiors and stay solid.
.closedDoorTargets
    db JOHTO_AZALEA_TOWN_LOCAL_ID, 9, 5
    db JOHTO_AZALEA_TOWN_LOCAL_ID, 21, 5
    db JOHTO_AZALEA_TOWN_LOCAL_ID, 15, 9
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
    db JOHTO_GOLDENROD_CITY_LOCAL_ID, 19, 1
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
    db JOHTO_GOLDENROD_CITY_LOCAL_ID, 15, 27
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
JohtoSouthIsKnownClosedEdge::
    ld e, 0
    ld a, [wCurLocalMapID]
    cp JOHTO_AZALEA_TOWN_LOCAL_ID
    jp z, .azalea
    cp JOHTO_ROUTE_34_LOCAL_ID
    jp z, .route34
    cp JOHTO_GOLDENROD_CITY_LOCAL_ID
    jp z, .goldenrod
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
    jr .closed
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
    jr .closed
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
