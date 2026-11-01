; MAP-300: Ecruteak east gate -> Route42 -> Mahogany Town outdoor chain.
; Gold source bytes and mature stage-77 collision roles are preserved. Mt Mortar,
; Route43/44, all Mahogany interiors, trainers/items/story remain fail-closed.

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
    db 0
    db 0

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
    db 0 ; Mart/house/Gym/Center/Route43 gate all intentionally closed
    db 4
    db 5, 1, 1
    db 7, 9, 2
    db 13, 3, 3
    db 13, 16, 4
    db 0

JohtoRoute42EcruteakGateTextPointers:
    ; NPCs remain deferred; keep no active text object.

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
    ret nz
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
    call JohtoEastGateCarpetLaneStep300
    ret c
    call JohtoEastSpatialRoleAhead
    ld a, e
    cp 2
    jr z, .water
    and a
    jr z, .allow
    cp 1
    jr nz, .block
    call JohtoRoute42CutClearedAhead300
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

; FIX-302: permit walking/biking ONTO each of the four live gate carpets.
; Only the exact adjacent inbound step to (0/9, 4/5) is accepted, whether
; from the inner corridor (x1/x8) or from y3/y6 or the other carpet.
; No off-map steps are accepted here; outward LEFT/RIGHT collision Warps remain
; protected by the existing direction-qualified portal exit guard.
; Carry=1/E=0: exact inbound carpet step. Carry=0: use mature collision grid.
JohtoEastGateCarpetLaneStep300::
    ld e, 0
    ld a, [wCurLocalMapID]
    cp JOHTO_ROUTE_42_ECRUTEAK_GATE_LOCAL_ID
    jr nz, .no
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    jr z, .up
    cp PLAYER_DIR_DOWN
    jr z, .down
    cp PLAYER_DIR_LEFT
    jr z, .left
    cp PLAYER_DIR_RIGHT
    jr z, .right
    jr .no
.up
    ld a, [wYCoord]
    cp 5
    jr z, .vertical
    cp 6
    jr z, .vertical
    jr .no
.down
    ld a, [wYCoord]
    cp 3
    jr z, .vertical
    cp 4
    jr z, .vertical
    jr .no
.vertical
    ld a, [wXCoord]
    and a
    jr z, .allow
    cp 9
    jr z, .allow
    jr .no
.left
    ld a, [wXCoord]
    cp 1
    jr nz, .no
    jr .checkY
.right
    ld a, [wXCoord]
    cp 8
    jr nz, .no
.checkY
    ld a, [wYCoord]
    cp 4
    jr z, .allow
    cp 5
    jr z, .allow
.no
    and a
    ret
.allow
    ld e, 0
    scf
    ret

; Route42's only Cut cell is Gold (x24,y13), source block $63 -> current clone $8D.
JohtoRoute42CutClearedAhead300:
    ld a, [wCurLocalMapID]
    cp JOHTO_ROUTE_42_LOCAL_ID
    jp nz, .no
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
    ld a, e
    cp 24
    jr nz, .no
    ld a, d
    cp 13
    jr nz, .no
    ; Same visible block lookup used by the established Johto Cut helper.
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
    ld a, [hl]
    cp $8d
    jr z, .yes
.no
    and a
    ret
.yes
    scf
    ret

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
    jr z, .gate
    cp JOHTO_ROUTE_42_LOCAL_ID
    jr z, .route42
    cp JOHTO_MAHOGANY_TOWN_LOCAL_ID
    jr z, .mahogany
    ld e, 1
    ret
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
    cp JOHTO_ROUTE_42_LOCAL_ID
    jr nz, .no
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    jr z, .up
    cp PLAYER_DIR_DOWN
    jr z, .down
    cp PLAYER_DIR_LEFT
    jr z, .left
    cp PLAYER_DIR_RIGHT
    jr nz, .no
    ld a, [wXCoord]
    cp 59
    jr nc, .yes
    jr .no
.up
    ld a, [wYCoord]
    and a
    jr z, .yes
    jr .no
.down
    ld a, [wYCoord]
    cp 17
    jr nc, .yes
    jr .no
.left
    ld a, [wXCoord]
    and a
    jr z, .yes
.no
    and a
    ret
.yes
    scf
    ret

; Display-only Route43 preview above Mahogany. Route43/ID67 stays inactive and
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
