; MAP-300: Ecruteak east gate -> Route42 -> Mahogany Town outdoor chain.
; REF-315 adds the Gold Route43 outdoor slice in this same Bank $53. Its north/south
; connection strips are display previews only; Lake of Rage, ID66, Route44, Mt Mortar,
; Mahogany interiors, unported trainers/items/story and unregistered entrances stay closed.

JohtoRoute42EcruteakGateBlocks:: INCBIN "maps/johto_pilot/Route42EcruteakGate.runtime.blk"
ASSERT @ - JohtoRoute42EcruteakGateBlocks == JOHTO_ROUTE_42_ECRUTEAK_GATE_WIDTH * JOHTO_ROUTE_42_ECRUTEAK_GATE_HEIGHT
JohtoRoute42Blocks:: INCBIN "maps/johto_pilot/Route42.runtime.blk"
ASSERT @ - JohtoRoute42Blocks == JOHTO_ROUTE_42_WIDTH * JOHTO_ROUTE_42_HEIGHT
JohtoMahoganyBlocks:: INCBIN "maps/johto_pilot/MahoganyTown.runtime.blk"
ASSERT @ - JohtoMahoganyBlocks == JOHTO_MAHOGANY_TOWN_WIDTH * JOHTO_MAHOGANY_TOWN_HEIGHT

; Connection readers dereference pointers in the source map bank.
JohtoRoute42WestEcruteakMirror:: INCBIN "maps/johto_pilot/EcruteakCity.runtime.blk"
ASSERT @ - JohtoRoute42WestEcruteakMirror == JOHTO_ECRUTEAK_WIDTH * JOHTO_ECRUTEAK_HEIGHT

JohtoEastLocalScript::
    call EnableAutoTextBoxDrawing
    ret

JohtoRoute42EcruteakGateRuntimeHeader::
    db JOHTO_GATE
    db JOHTO_ROUTE_42_ECRUTEAK_GATE_HEIGHT, JOHTO_ROUTE_42_ECRUTEAK_GATE_WIDTH
    dw JohtoRoute42EcruteakGateBlocks
    dw JohtoRoute42EcruteakGateTextPointers
    dw JohtoEastLocalScript
    db 0 ; physical passage is four registered carpet Warps
    dw JohtoRoute42EcruteakGateRuntimeObjects
JohtoRoute42EcruteakGateHeaderEnd::
ASSERT JohtoRoute42EcruteakGateHeaderEnd - JohtoRoute42EcruteakGateRuntimeHeader == 12

JohtoRoute42RuntimeHeader::
    db JOHTO_PILOT
    db JOHTO_ROUTE_42_HEIGHT, JOHTO_ROUTE_42_WIDTH
    dw JohtoRoute42Blocks
    dw JohtoRoute42TextPointers
    dw JohtoEastLocalScript
    db WEST | EAST
    ; WEST Ecruteak preview, Gold offset -9 blocks. Travel remains gate-only.
    db JOHTO_RUNTIME_MAP_HANDLE
    dw JohtoRoute42WestEcruteakMirror + 9 * JOHTO_ECRUTEAK_WIDTH + JOHTO_ECRUTEAK_WIDTH - 3
    dw wOverworldMap + 3 * (JOHTO_ROUTE_42_WIDTH + 6)
    db JOHTO_ROUTE_42_HEIGHT
    db JOHTO_ECRUTEAK_WIDTH
    db 18
    db JOHTO_ECRUTEAK_WIDTH * 2 - 1
    dw wOverworldMap + 6 + 2 * JOHTO_ECRUTEAK_WIDTH
    ; EAST -> Mahogany west, Gold offset 0.
    db JOHTO_RUNTIME_MAP_HANDLE
    dw JohtoMahoganyBlocks
    dw wOverworldMap + 3 * (JOHTO_ROUTE_42_WIDTH + 6) + JOHTO_ROUTE_42_WIDTH + 3
    db JOHTO_MAHOGANY_TOWN_HEIGHT
    db JOHTO_MAHOGANY_TOWN_WIDTH
    db 0
    db 0
    dw wOverworldMap + 7 + JOHTO_MAHOGANY_TOWN_WIDTH
    dw JohtoRoute42RuntimeObjects
JohtoRoute42HeaderEnd::
ASSERT JohtoRoute42HeaderEnd - JohtoRoute42RuntimeHeader == 34

JohtoMahoganyRuntimeHeader::
    db JOHTO_PILOT
    db JOHTO_MAHOGANY_TOWN_HEIGHT, JOHTO_MAHOGANY_TOWN_WIDTH
    dw JohtoMahoganyBlocks
    dw JohtoMahoganyTextPointers
    dw JohtoEastLocalScript
    db WEST
    ; WEST -> Route42 east, Gold offset 0.
    db JOHTO_RUNTIME_MAP_HANDLE
    dw JohtoRoute42Blocks + JOHTO_ROUTE_42_WIDTH - 3
    dw wOverworldMap + 3 * (JOHTO_MAHOGANY_TOWN_WIDTH + 6)
    db JOHTO_MAHOGANY_TOWN_HEIGHT
    db JOHTO_ROUTE_42_WIDTH
    db 0
    db JOHTO_ROUTE_42_WIDTH * 2 - 1
    dw wOverworldMap + 6 + 2 * JOHTO_ROUTE_42_WIDTH
    dw JohtoMahoganyRuntimeObjects
JohtoMahoganyHeaderEnd::
ASSERT JohtoMahoganyHeaderEnd - JohtoMahoganyRuntimeHeader == 23

ASSERT BANK(JohtoRoute42EcruteakGateRuntimeHeader) == BANK(JohtoRoute42EcruteakGateBlocks)
ASSERT BANK(JohtoRoute42RuntimeHeader) == BANK(JohtoRoute42Blocks)
ASSERT BANK(JohtoMahoganyRuntimeHeader) == BANK(JohtoMahoganyBlocks)

JohtoRoute42EcruteakGateRuntimeObjects::
    db $0d
    db 4
    db 4, 0, 2, JOHTO_REGISTERED_WARP_SELECTOR ; west -> Ecruteak east upper
    db 5, 0, 3, JOHTO_REGISTERED_WARP_SELECTOR ; west -> Ecruteak east lower
    db 4, 9, 0, JOHTO_REGISTERED_WARP_SELECTOR ; east -> Route42 upper
    db 5, 9, 1, JOHTO_REGISTERED_WARP_SELECTOR ; east -> Route42 lower
    db 0 ; signs
    db 1 ; Gold Route42EcruteakGate Officer at (5,2), facing down
    object SPRITE_JOHTO_OFFICER, 5, 2, STAY, DOWN, $1

JohtoRoute42RuntimeObjects::
    db $05
    db 2 ; west gate only; all three Mt Mortar cave entries stay sealed
    db 8, 0, 2, JOHTO_REGISTERED_WARP_SELECTOR
    db 9, 0, 3, JOHTO_REGISTERED_WARP_SELECTOR
    db 4
    db 10, 4, 1
    db 5, 7, 2
    db 9, 45, 3
    db 8, 54, 4
    db 0

JohtoMahoganyRuntimeObjects::
    db $05
    db 1 ; Gold north gate only; four indoor doors still closed
    db 1, 9, 0, JOHTO_REGISTERED_WARP_SELECTOR ; Mahogany Gold #5 -> Gate south #3
    db 4
    db 5, 1, 1
    db 7, 9, 2
    db 13, 3, 3
    db 13, 16, 4
    db 0

JohtoRoute42EcruteakGateTextPointers:
    dw JohtoRoute42EcruteakGateOfficerText
JohtoRoute42EcruteakGateOfficerText:
    ; Gold Route42EcruteakGateOfficerScript, adapted to the RBY text engine.
    text "MOUNT MORTAR is"
    line "like a maze."
    para "Be careful. Don't"
    line "get lost in there."
    done
    db "@"

ASSERT BANK(JohtoRoute42EcruteakGateRuntimeHeader) == BANK(JohtoRoute42EcruteakGateRuntimeObjects)
ASSERT BANK(JohtoRoute42EcruteakGateRuntimeHeader) == BANK(JohtoRoute42EcruteakGateTextPointers)
ASSERT BANK(JohtoRoute42EcruteakGateRuntimeHeader) == BANK(JohtoRoute42EcruteakGateOfficerText)

JohtoRoute42TextPointers:
    dw JohtoRoute42SignText
    dw JohtoMtMortarSignText
    dw JohtoMtMortarSignText
    dw JohtoRoute42SignText
JohtoRoute42SignText:
    text "ROUTE 42"
    para "ECRUTEAK CITY -"
    line "MAHOGANY TOWN"
    done
    db "@"
JohtoMtMortarSignText:
    text "MOUNT MORTAR"
    para "WATERFALL CAVE"
    line "Inside"
    done
    db "@"

JohtoMahoganyTextPointers:
    dw JohtoMahoganySignText
    dw JohtoMahoganyCandyText
    dw JohtoMahoganyGymText
    dw JohtoMahoganyCenterText
JohtoMahoganySignText:
    text "MAHOGANY TOWN"
    para "Home of the Ninja"
    done
    db "@"
JohtoMahoganyCandyText:
    text "TRY A"
    line "RAGECANDYBAR!"
    done
    db "@"
JohtoMahoganyGymText:
    text "MAHOGANY TOWN"
    line "#MON GYM"
    para "LEADER: PRYCE"
    done
    db "@"
JohtoMahoganyCenterText:
    text "#MON CENTER"
    done
    db "@"

; Exact mature 16x16 role grids: 0=floor, 1=blocked, 2=Gold WATER.
JohtoRoute42EcruteakGateRoles:: INCBIN "maps/johto_pilot/Route42EcruteakGate.roles.bin"
ASSERT @ - JohtoRoute42EcruteakGateRoles == 10 * 8
JohtoRoute42Roles:: INCBIN "maps/johto_pilot/Route42.roles.bin"
ASSERT @ - JohtoRoute42Roles == 60 * 18
JohtoMahoganyRoles:: INCBIN "maps/johto_pilot/MahoganyTown.roles.bin"
ASSERT @ - JohtoMahoganyRoles == 20 * 18
; REF-315: full Gold 20x54 role-grid, 72 WATER cells.
; REF-317: north ID66 WARP_CARPET_DOWN is Gold LAND_TILE, but the coarse role
; grid stays blocked; exact BeforeStep rows allow only y30/down re-entry and
; the paired lateral lane switch. AfterStep E=3 is not a collision Warp.
JohtoRoute43Roles:: INCBIN "maps/johto_pilot/Route43.roles.bin"
ASSERT @ - JohtoRoute43Roles == JOHTO_ROUTE_43_WIDTH * 2 * JOHTO_ROUTE_43_HEIGHT * 2
; REF-318: exact Gold 40x36 quadrant roles, including 300 WATER cells.
JohtoLakeOfRageRoles:: INCBIN "maps/johto_pilot/LakeOfRage.roles.bin"
ASSERT @ - JohtoLakeOfRageRoles == JOHTO_LAKE_OF_RAGE_WIDTH * 2 * JOHTO_LAKE_OF_RAGE_HEIGHT * 2

; E=0/1/2 for recognized maps, E=3 otherwise. Off-map is floor here because
; JohtoEastIsKnownClosedEdge owns the exact seamless Route42/Mahogany lanes.
JohtoEastSpatialRoleAhead::
    ld e, 3
    ld a, [wCurMap]
    cp JOHTO_RUNTIME_MAP_HANDLE
    ret nz
    ld a, [wCurRegion]
    cp MAP_REGION_JOHTO
    ret nz
    ld a, [wCurLocalMapID]
    cp JOHTO_ROUTE_42_ECRUTEAK_GATE_LOCAL_ID
    jr z, .gate
    cp JOHTO_ROUTE_42_LOCAL_ID
    jr z, .route42
    cp JOHTO_MAHOGANY_TOWN_LOCAL_ID
    jr z, .mahogany
    cp JOHTO_ROUTE_43_LOCAL_ID
    jr z, .route43
    cp JOHTO_LAKE_OF_RAGE_LOCAL_ID
    ret nz
    ld hl, JohtoLakeOfRageRoles
    ld b, JOHTO_LAKE_OF_RAGE_WIDTH * 2
    ld c, JOHTO_LAKE_OF_RAGE_HEIGHT * 2
    jr .common
.route43
    ld hl, JohtoRoute43Roles
    ld b, JOHTO_ROUTE_43_WIDTH * 2
    ld c, JOHTO_ROUTE_43_HEIGHT * 2
    jr .common
.mahogany
    ld hl, JohtoMahoganyRoles
    ld b, 20
    ld c, 18
    jr .common
.gate
    ld hl, JohtoRoute42EcruteakGateRoles
    ld b, 10
    ld c, 8
    jr .common
.route42
    ld hl, JohtoRoute42Roles
    ld b, 60
    ld c, 18
.common
    push hl
    ld a, [wXCoord]
    ld e, a
    ld a, [wYCoord]
    ld d, a
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    jr z, .north
    cp PLAYER_DIR_DOWN
    jr z, .south
    cp PLAYER_DIR_LEFT
    jr z, .west
    cp PLAYER_DIR_RIGHT
    jr nz, .bad
    inc e
    jr .bounds
.north
    dec d
    jr .bounds
.south
    inc d
    jr .bounds
.west
    dec e
.bounds
    ld a, e
    cp b
    jr nc, .offMap
    ld a, d
    cp c
    jr nc, .offMap
    ld hl, 0
.row
    ld a, d
    and a
    jr z, .index
    push de
    ld d, 0
    ld e, b
    add hl, de
    pop de
    dec d
    jr .row
.index
    ld d, 0
    add hl, de
    pop de
    add hl, de
    ld e, [hl]
    ret
.offMap
    pop hl
    ld e, 0
    ret
.bad
    pop hl
    ld e, 1
    ret

JohtoEastSpatialStep::
    ; FIX-302: mature masks mark the edge carpets solid. Permit all exact
    ; *inbound* steps to x0/x9,y4/y5 (from adjacent floor AND between carpets).
    ; Outward collision-Warps still belong to JohtoEastPortalCollisionExit.
    call JohtoGateHorizontalCarpetInbound303
    ret c
    call JohtoEastSpatialRoleAhead
    ld a, e
    cp 2
    jr z, .water
    and a
    jr z, .allow
    cp 1
    jr nz, .block
    call JohtoEastCutClearedAhead300
    jr c, .allow
    jr .block
.water
    ld a, [wWalkBikeSurfState]
    cp 2
    jr z, .allow
.block
    ld e, 1
    ret
.allow
    ld e, 0
    ret

; REF-303: single data-driven inbound-carpet engine for both Ecruteak
; horizontal gatehouses. Keep this in roomy Bank $53: West calls it with
; callab; East calls it locally. No ROM0 growth or new Bank $4E data.
; Records: stable local map ID, left X, right X, upper Y, lower Y.
; These are runtime movement profiles, NOT Warp destinations/permissions.
JohtoGateHorizontalCarpetProfiles303::
    db JOHTO_ROUTE_38_ECRUTEAK_GATE_LOCAL_ID, 0, 9, 4, 5
    db JOHTO_ROUTE_42_ECRUTEAK_GATE_LOCAL_ID, 0, 9, 4, 5
    db $ff

; In: live player coordinate and facing. Out: E=0/Carry=1 only when the
; immediately adjacent *target* is a registered carpet of the current gate.
; Otherwise E=1/Carry=0; caller uses its unchanged collision-mask fallback.
; No edge or Warp transfer is performed here. This routine is invoked only
; for the active Johto local-map collision paths.
JohtoGateHorizontalCarpetInbound303::
    ld a, [wCurLocalMapID]
    ld b, a
    ld hl, JohtoGateHorizontalCarpetProfiles303
.find
    ld a, [hli]
    cp $ff
    jr z, .no
    cp b
    jr z, .found
    ld de, 4
    add hl, de
    jr .find
.found
    ld a, [wXCoord]
    ld b, a
    ld a, [wYCoord]
    ld c, a
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    jr z, .up
    cp PLAYER_DIR_DOWN
    jr z, .down
    cp PLAYER_DIR_LEFT
    jr z, .left
    cp PLAYER_DIR_RIGHT
    jr nz, .no
    inc b
    jr .target
.up
    dec c
    jr .target
.down
    inc c
    jr .target
.left
    dec b
.target
    ld a, [hli] ; left carpet X
    cp b
    jr z, .skipRightX
    ld a, [hli] ; right carpet X
    cp b
    jr nz, .no
    jr .checkY
.skipRightX
    inc hl
.checkY
    ld a, [hli] ; upper carpet Y
    cp c
    jr z, .yes
    ld a, [hl]  ; lower carpet Y
    cp c
    jr z, .yes
.no
    ld e, 1
    and a
    ret
.yes
    ld e, 0
    scf
    ret

; Static role grids keep Cut cells blocked after the visible metatile is swapped.
; Re-open only source-authentic Cut coordinates whose live block now equals the
; known cleared clone. This same Bank $53 helper covers Route42, Route43 and Lake.
JohtoRoute42CutClearedAhead300: ; legacy label retained for older audits
JohtoEastCutClearedAhead300:
    ld a, [wCurLocalMapID]
    ld b, a
    ld a, [wXCoord]
    ld e, a
    ld a, [wYCoord]
    ld d, a
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    jr z, .cu
    cp PLAYER_DIR_DOWN
    jr z, .cd
    cp PLAYER_DIR_LEFT
    jr z, .cl
    cp PLAYER_DIR_RIGHT
    jr nz, .no
    inc e
    jr .target
.cu
    dec d
    jr .target
.cd
    inc d
    jr .target
.cl
    dec e
.target
    ld hl, JohtoEastClearedCutCells300
.scan
    ld a, [hli]
    cp $ff
    jr z, .no
    cp b
    jr nz, .skip3
    ld a, [hli] ; y
    cp d
    jr nz, .skip2
    ld a, [hli] ; x
    cp e
    jr nz, .skip1
    ld a, [hl] ; expected cleared visible block
    push af
    jr .lookupLiveBlock
.skip3
    inc hl
.skip2
    inc hl
.skip1
    inc hl
    jr .scan
.lookupLiveBlock
    ; Same visible-block lookup used by the established Route42 helper.
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
    jr z, .fDown
    cp SPRITE_FACING_UP
    jr z, .fUp
    cp SPRITE_FACING_LEFT
    jr z, .fLeft
    ld a, [wXBlockCoord]
    and a
    jr z, .center
    jr .fRight
.fDown
    ld a, [wYBlockCoord]
    and a
    jr z, .center
    jr .below
.fUp
    ld a, [wYBlockCoord]
    and a
    jr z, .above
    jr .center
.fLeft
    ld a, [wXBlockCoord]
    and a
    jr z, .left
    jr .center
.below
    add hl, bc
.center
    add hl, bc
.above
    ld de, 2
    add hl, de
    jr .read
.left
    ld de, 1
    add hl, bc
    add hl, de
    jr .read
.fRight
    ld de, 3
    add hl, bc
    add hl, de
.read
    ld b, [hl]
    pop af
    cp b
    jr z, .yes
.no
    and a
    ret
.yes
    scf
    ret

; map, y, x, cleared runtime block. $63->$8D, $67->$8E, $5B->$90.
JohtoEastClearedCutCells300:
    db JOHTO_ROUTE_42_LOCAL_ID, 13, 24, $8d
    db JOHTO_ROUTE_43_LOCAL_ID, 28, 2, $8e
    db JOHTO_LAKE_OF_RAGE_LOCAL_ID, 4, 23, $90
    db JOHTO_LAKE_OF_RAGE_LOCAL_ID, 9, 18, $8d
    db JOHTO_LAKE_OF_RAGE_LOCAL_ID, 12, 11, $90
    db JOHTO_LAKE_OF_RAGE_LOCAL_ID, 14, 5, $90
    db JOHTO_LAKE_OF_RAGE_LOCAL_ID, 21, 6, $8d
    db $ff

; East/west-gate carpets are collision Warps, not ordinary STEP_ON doors.
; These guards mirror the proven west-corridor contract while keeping every
; non-portal tile fail-closed.  In particular Ecruteak has *two* independent
; horizontal portals: west at x0/y18-19 and east at x35/y26-27.
JohtoEastPortalBeforeStep::
    ld e, 0
    ld a, [wCurLocalMapID]
    cp JOHTO_ECRUTEAK_CITY_LOCAL_ID
    jr z, .cityBefore
    cp JOHTO_ROUTE_42_LOCAL_ID
    jr z, .routeBefore
    cp JOHTO_ROUTE_42_ECRUTEAK_GATE_LOCAL_ID
    ret nz
    ld a, [wYCoord]
    cp 4
    jr z, .gateBeforeLane
    cp 5
    ret nz
.gateBeforeLane
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_LEFT
    jr z, .gateBeforeLeft
    cp PLAYER_DIR_RIGHT
    ret nz
    ld a, [wXCoord]
    cp 8
    jr z, .yes
    ret
.gateBeforeLeft
    ld a, [wXCoord]
    cp 1
    jr z, .yes
    ret
.cityBefore
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_RIGHT
    ret nz
    ld a, [wXCoord]
    cp 34
    ret nz
    ld a, [wYCoord]
    cp 26
    jr z, .yes
    cp 27
    ret nz
    jr .yes
.routeBefore
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_LEFT
    ret nz
    ld a, [wXCoord]
    cp 1
    ret nz
    ld a, [wYCoord]
    cp 8
    jr z, .yes
    cp 9
    ret nz
.yes
    ld e, 1
    ret

JohtoEastPortalAfterStep::
    ld e, 0 ; all east-corridor mouths are collision carpets
    ret

JohtoEastPortalArrivalStep::
    ld e, 0 ; remain on destination carpet for an immediate reverse exit
    ret

JohtoEastPortalCollisionExit::
    ld e, 0
    ld a, [wCurLocalMapID]
    cp JOHTO_ECRUTEAK_CITY_LOCAL_ID
    jr z, .cityExit
    cp JOHTO_ROUTE_42_LOCAL_ID
    jr z, .routeExit
    cp JOHTO_ROUTE_42_ECRUTEAK_GATE_LOCAL_ID
    ret nz
    ld a, [wYCoord]
    cp 4
    jr z, .gateExitLane
    cp 5
    ret nz
.gateExitLane
    ld a, [wXCoord]
    and a
    jr z, .gateWestExit
    cp 9
    ret nz
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_RIGHT
    jr z, .exitYes
    ret
.gateWestExit
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_LEFT
    jr z, .exitYes
    ret
.cityExit
    ld a, [wXCoord]
    cp 35
    ret nz
    ld a, [wYCoord]
    cp 26
    jr z, .cityFacing
    cp 27
    ret nz
.cityFacing
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_RIGHT
    jr z, .exitYes
    ret
.routeExit
    ld a, [wXCoord]
    and a
    ret nz
    ld a, [wYCoord]
    cp 8
    jr z, .routeFacing
    cp 9
    ret nz
.routeFacing
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_LEFT
    ret nz
.exitYes
    ld e, 1
    ret

; Exact east edge contract. Route42 west is preview-only/gate-only. Its east and
; Mahogany west share the two mature Gold corridors y4..7 and y9..17; y8 is wall.
JohtoEastIsKnownClosedEdge::
    ld e, 0
    ld a, [wCurLocalMapID]
    cp JOHTO_ROUTE_42_ECRUTEAK_GATE_LOCAL_ID
    jp z, .gate
    cp JOHTO_ROUTE_42_LOCAL_ID
    jp z, .route42
    cp JOHTO_MAHOGANY_TOWN_LOCAL_ID
    jp z, .mahogany
    cp JOHTO_ROUTE_43_LOCAL_ID
    jp z, .route43
    cp JOHTO_LAKE_OF_RAGE_LOCAL_ID
    jp z, .lakeOfRage
    ld e, 1
    ret
.route43
    ; Lake of Rage is the only physical north connection in REF-318. ID66 uses
    ; registered Warps; all other off-map preview lanes remain fail-closed.
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    jr z, .route43North
    cp PLAYER_DIR_DOWN
    jr z, .route43South
    cp PLAYER_DIR_LEFT
    jr z, .route43West
    cp PLAYER_DIR_RIGHT
    ret nz
    ld a, [wXCoord]
    cp JOHTO_ROUTE_43_WIDTH * 2 - 1
    jp nc, .closed
    ret
.route43North
    ld a, [wYCoord]
    and a
    ret nz
    ; Gold -5 block seam: Route43 x0 and x8..11 map to walkable
    ; Lake x10 and x18..21. Every other preview-border lane stays closed.
    ld a, [wXCoord]
    and a
    jp z, .open
    cp 8
    jp c, .closed
    cp 12
    jp c, .open
    jp .closed
.route43South
    ld a, [wYCoord]
    cp JOHTO_ROUTE_43_HEIGHT * 2 - 1
    jp nc, .closed
    ret
.route43West
    ld a, [wXCoord]
    and a
    jp z, .closed
    ret
.lakeOfRage
    ; Lake has only the Gold SOUTH connection in REF-318. North/west/east
    ; remain fail-closed; south opens only the reciprocal walkable overlap.
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_DOWN
    jr z, .lakeSouth
    cp PLAYER_DIR_UP
    jr z, .lakeNorth
    cp PLAYER_DIR_LEFT
    jr z, .lakeWest
    cp PLAYER_DIR_RIGHT
    ret nz
    ld a, [wXCoord]
    cp JOHTO_LAKE_OF_RAGE_WIDTH * 2 - 1
    jp nc, .closed
    ret
.lakeNorth
    ld a, [wYCoord]
    and a
    jp z, .closed
    ret
.lakeWest
    ld a, [wXCoord]
    and a
    jp z, .closed
    ret
.lakeSouth
    ld a, [wYCoord]
    cp JOHTO_LAKE_OF_RAGE_HEIGHT * 2 - 1
    ret c
    ld a, [wXCoord]
    cp 10
    jp z, .open
    cp 18
    jp c, .closed
    cp 22
    jp c, .open
    jp .closed
.gate
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_LEFT
    jr z, .leftGate
    cp PLAYER_DIR_RIGHT
    jr z, .rightGate
    cp PLAYER_DIR_UP
    jr z, .upGate
    cp PLAYER_DIR_DOWN
    ret nz
    ld a, [wYCoord]
    cp 7
    jp nc, .closed
    ret
.leftGate
    ld a, [wXCoord]
    and a
    jp z, .closed
    ret
.rightGate
    ld a, [wXCoord]
    cp 9
    jr nc, .closed
    ret
.upGate
    ld a, [wYCoord]
    and a
    jr z, .closed
    ret
.route42
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_RIGHT
    jr z, .route42East
    cp PLAYER_DIR_LEFT
    jr z, .route42West
    cp PLAYER_DIR_UP
    jr z, .route42North
    cp PLAYER_DIR_DOWN
    ret nz
    ld a, [wYCoord]
    cp 17
    jr nc, .closed
    ret
.route42West
    ld a, [wXCoord]
    and a
    jr z, .closed ; gate Warp only
    ret
.route42North
    ld a, [wYCoord]
    and a
    jr z, .closed
    ret
.route42East
    ld a, [wXCoord]
    cp 59
    ret c
    ld a, [wYCoord]
    jr .seamY
.mahogany
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_LEFT
    jr z, .mahoganyWest
    cp PLAYER_DIR_RIGHT
    jr z, .mahoganyEast
    cp PLAYER_DIR_UP
    jr z, .mahoganyNorth
    cp PLAYER_DIR_DOWN
    ret nz
    ld a, [wYCoord]
    cp 17
    jr nc, .closed
    ret
.mahoganyWest
    ld a, [wXCoord]
    and a
    ret nz
    ld a, [wYCoord]
.seamY
    cp 4
    jr c, .closed
    cp 8
    jr c, .open
    cp 9
    jr c, .closed
    cp 18
    jr c, .open
    jr .closed
.mahoganyEast
    ld a, [wXCoord]
    cp 19
    jr nc, .closed ; Route44 deferred
    ret
.mahoganyNorth
    ld a, [wYCoord]
    and a
    jr z, .closed ; Route43 deferred
    ret
.open
    ret
.closed
    ld e, 1
    ret

; Route42 WATER is wholly internal: no edge WATER quadrants.  These probes keep
; Surf decisions tied to the mature role grid rather than shared tile IDs.
JohtoEastGoldWaterProbe::
    push bc
    push de
    push hl
    call JohtoEastSpatialRoleAhead
    ld a, e
    cp 2
    jr z, .yes
    and a
    jr .done
.yes
    scf
.done
    pop hl
    pop de
    pop bc
    ret

JohtoEastGoldShoreProbe::
    push bc
    push de
    push hl
    call JohtoEastUnsafeSurfEdge
    jr c, .no
    call JohtoEastSpatialRoleAhead
    ld a, e
    and a
    jr nz, .no
    call JohtoEastSpatialStep
    ld a, e
    and a
    jr nz, .no
    scf
    jr .done
.no
    and a
.done
    pop hl
    pop de
    pop bc
    ret

JohtoEastUnsafeSurfEdge::
    ld a, [wCurLocalMapID]
    cp JOHTO_ROUTE_43_LOCAL_ID
    jp z, .route43
    cp JOHTO_LAKE_OF_RAGE_LOCAL_ID
    jp z, .lakeOfRageSurf
    cp JOHTO_ROUTE_42_LOCAL_ID
    jp nz, .no
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    jr z, .up
    cp PLAYER_DIR_DOWN
    jr z, .down
    cp PLAYER_DIR_LEFT
    jr z, .left
    cp PLAYER_DIR_RIGHT
    jp nz, .no
    ld a, [wXCoord]
    cp 59
    jp nc, .yes
    jp .no
.up
    ld a, [wYCoord]
    and a
    jp z, .yes
    jp .no
.down
    ld a, [wYCoord]
    cp 17
    jp nc, .yes
    jp .no
.left
    ld a, [wXCoord]
    and a
    jp z, .yes
    jp .no
; Route43 is 20x54 cells, unlike Route42 60x18.
.route43
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    jp z, .route43Up
    cp PLAYER_DIR_DOWN
    jp z, .route43Down
    cp PLAYER_DIR_LEFT
    jp z, .route43Left
    cp PLAYER_DIR_RIGHT
    jp nz, .no
    ld a, [wXCoord]
    cp JOHTO_ROUTE_43_WIDTH * 2 - 1
    jp nc, .yes
    jp .no
.route43Up
    ld a, [wYCoord]
    and a
    jp nz, .no
    ld a, [wXCoord]
    and a
    jp z, .no
    cp 8
    jp c, .yes
    cp 12
    jp c, .no
    jp .yes
.route43Down
    ld a, [wYCoord]
    cp JOHTO_ROUTE_43_HEIGHT * 2 - 1
    jp nc, .yes
    jp .no
.route43Left
    ld a, [wXCoord]
    and a
    jp z, .yes
    jp .no
.lakeOfRageSurf
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_DOWN
    jr z, .lakeSurfSouth
    cp PLAYER_DIR_UP
    jr z, .lakeSurfNorth
    cp PLAYER_DIR_LEFT
    jr z, .lakeSurfWest
    cp PLAYER_DIR_RIGHT
    jp nz, .no
    ld a, [wXCoord]
    cp JOHTO_LAKE_OF_RAGE_WIDTH * 2 - 1
    jp nc, .yes
    jp .no
.lakeSurfNorth
    ld a, [wYCoord]
    and a
    jp z, .yes
    jp .no
.lakeSurfWest
    ld a, [wXCoord]
    and a
    jp z, .yes
    jp .no
.lakeSurfSouth
    ld a, [wYCoord]
    cp JOHTO_LAKE_OF_RAGE_HEIGHT * 2 - 1
    jp c, .no
    ld a, [wXCoord]
    cp 10
    jp z, .no
    cp 18
    jp c, .yes
    cp 22
    jp c, .no
    jp .yes
.no
    and a
    ret
.yes
    scf
    ret

; Display-only Route43 preview above Mahogany. Route43/ID67 is now active, but
; this writes only the three out-of-bounds border rows, never collision or Warps.
PatchJohtoMahoganyNorthBorder300::
    ld a, [wCurMap]
    cp JOHTO_RUNTIME_MAP_HANDLE
    ret nz
    ld a, [wCurRegion]
    cp MAP_REGION_JOHTO
    ret nz
    ld a, [wCurLocalMapID]
    cp JOHTO_MAHOGANY_TOWN_LOCAL_ID
    ret nz
    ld de, .row0
    ld hl, wOverworldMap + MAP_BORDER
    call .copyRow
    ld de, .row1
    ld hl, wOverworldMap + (JOHTO_MAHOGANY_TOWN_WIDTH + 2 * MAP_BORDER) + MAP_BORDER
    call .copyRow
    ld de, .row2
    ld hl, wOverworldMap + 2 * (JOHTO_MAHOGANY_TOWN_WIDTH + 2 * MAP_BORDER) + MAP_BORDER
.copyRow
    ld b, JOHTO_MAHOGANY_TOWN_WIDTH
.loop
    ld a, [de]
    inc de
    ld [hli], a
    dec b
    jr nz, .loop
    ret
.row0
    db $71, $71, $71, $69, $01, $78, $05, $05, $6a, $71
.row1
    db $71, $71, $71, $69, $0c, $0d, $05, $05, $68, $71
.row2
    db $71, $71, $71, $69, $08, $09, $05, $05, $68, $71

; Keep the historical south-border patch, then add the new Mahogany preview.
PatchJohtoBordersAfterBlockLoad300::
    callab PatchJohtoSouthBordersAfterBlockLoad
    jp PatchJohtoMahoganyNorthBorder300
