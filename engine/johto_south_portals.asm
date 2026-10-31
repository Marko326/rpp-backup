; MAP-268: exact Gold southern gate and forest approaches. Return E=0/1/2.
; E=2 only for STEP_ON solid DOOR, E=1 for carpet (collision-only).
; Called via callab only for stable IDs 10..15, never for Kanto.
JohtoSouthPortalAfterStep::
    ld e, 0
    ld a, [wCurLocalMapID]
    cp JOHTO_AZALEA_TOWN_LOCAL_ID
    jp z, .azalea
    cp JOHTO_ILEX_AZALEA_GATE_LOCAL_ID
    jp z, .southGate
    cp JOHTO_ILEX_FOREST_LOCAL_ID
    jp z, .forest
    cp JOHTO_ROUTE34_ILEX_GATE_LOCAL_ID
    jp z, .northGate
    cp JOHTO_ROUTE_34_LOCAL_ID
    jp z, .route34
    cp JOHTO_GOLDENROD_CITY_LOCAL_ID
    jp z, .goldenrod
    cp JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID
    jp z, .route35Gate
    cp JOHTO_ROUTE_35_LOCAL_ID
    jp z, .route35
    cp JOHTO_NATIONAL_PARK_LOCAL_ID
    jp z, .park
    cp JOHTO_ROUTE_35_NATIONAL_PARK_GATE_LOCAL_ID
    jp z, .parkSouthGate
    cp JOHTO_ROUTE_36_NATIONAL_PARK_GATE_LOCAL_ID
    jp z, .parkEastGate
    ret
.azalea
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_LEFT
    ret nz
    ld a, [wXCoord]
    cp 2
    ret nz
    ld a, [wYCoord]
    cp 10
    jp z, .carpet
    cp 11
    jp z, .carpet
    ret
.southGate
    ld a, [wYCoord]
    cp 4
    jp z, .horizontalGate
    cp 5
    ret nz
.horizontalGate
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_LEFT
    jp z, .westGate
    cp PLAYER_DIR_RIGHT
    ret nz
    ld a, [wXCoord]
    cp 9
    jp z, .carpet
    ret
.westGate
    ld a, [wXCoord]
    and a
    jp z, .carpet
    ret
.forest
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    jp z, .forestDoor
    cp PLAYER_DIR_RIGHT
    ret nz
    ld a, [wXCoord]
    cp 3
    ret nz
    ld a, [wYCoord]
    cp 42
    jp z, .carpet
    cp 43
    jp z, .carpet
    ret
.forestDoor
    ld a, [wXCoord]
    cp 1
    ret nz
    ld a, [wYCoord]
    cp 5
    jp z, .door
    ret
.northGate
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    jp z, .northGateDoor
    cp PLAYER_DIR_DOWN
    ret nz
    ld a, [wYCoord]
    cp 7
    jp nz, .no
    jp .northGateXCarpet
.northGateDoor
    ld a, [wYCoord]
    and a
    ret nz
    ld a, [wXCoord]
    cp 4
    jp z, .door
    cp 5
    jp z, .door
    ret
.northGateXCarpet
    ld a, [wXCoord]
    cp 4
    jp z, .carpet
    cp 5
    jp z, .carpet
    ret
.route34
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_DOWN
    ret nz
    ld a, [wYCoord]
    cp 37
    ret nz
    ld a, [wXCoord]
    cp 13
    jp z, .carpet
    cp 14
    jp z, .carpet
    ret
.goldenrod
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    ret nz
    ld a, [wXCoord]
    cp 19
    ret nz
    ld a, [wYCoord]
    cp 1
    jp z, .door
    ret
.route35Gate
    jp .northGate
.route35
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    jr nz, .route35South
    ld a, [wXCoord]
    cp 3
    ret nz
    ld a, [wYCoord]
    cp 5
    jp z, .door
    ret
.route35South
    cp PLAYER_DIR_DOWN
    ret nz
    ld a, [wYCoord]
    cp 33
    ret nz
    ld a, [wXCoord]
    cp 9
    jp z, .carpet
    cp 10
    jp z, .carpet
    ret
.park
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_RIGHT
    jr nz, .parkSouth
    ld a, [wXCoord]
    cp 33
    ret nz
    ld a, [wYCoord]
    cp 18
    jp z, .carpet
    cp 19
    jp z, .carpet
    ret
.parkSouth
    cp PLAYER_DIR_DOWN
    ret nz
    ld a, [wYCoord]
    cp 47
    ret nz
    ld a, [wXCoord]
    cp 10
    jp z, .carpet
    cp 11
    jp z, .carpet
    ret
.parkSouthGate
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    jr nz, .parkSouthGateBottom
    ld a, [wYCoord]
    and a
    ret nz
    ld a, [wXCoord]
    cp 3
    jp z, .door
    cp 4
    jp z, .door
    ret
.parkSouthGateBottom
    cp PLAYER_DIR_DOWN
    ret nz
    ld a, [wYCoord]
    cp 7
    ret nz
    ld a, [wXCoord]
    cp 3
    jp z, .carpet
    cp 4
    jp z, .carpet
    ret
.parkEastGate
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_LEFT
    jr nz, .parkEastGateRight
    ld a, [wXCoord]
    and a
    ret nz
    ld a, [wYCoord]
    cp 4
    jp z, .carpet
    cp 5
    jp z, .carpet
    ret
.parkEastGateRight
    cp PLAYER_DIR_RIGHT
    ret nz
    ld a, [wXCoord]
    cp 9
    ret nz
    ld a, [wYCoord]
    cp 4
    jp z, .carpet
    cp 5
    jp z, .carpet
    ret
.door
    ld e, 2
    ret
.carpet
    ld e, 1
.no
    ret

; In collision path, only exact Gold carpets in exact outward direction
; can warp. Never use the STEP_ON DOOR override here.
JohtoSouthPortalCollisionExit::
    call JohtoSouthPortalAfterStep
    ld a, e
    cp 1
    jp z, .allowed
    ld e, 0
    ret
.allowed
    ld e, 1
    ret

; After landing on a true Gold DOOR, step down exactly once. For all
; carpet destinations the character remains stationary, facing original input.
JohtoSouthPortalArrivalStep::
    ld e, 0
    ld a, [wCurLocalMapID]
    cp JOHTO_ILEX_FOREST_LOCAL_ID
    jp z, .forest
    cp JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID
    jp z, .gateTop
    cp JOHTO_ROUTE_35_NATIONAL_PARK_GATE_LOCAL_ID
    jp z, .parkGateTop
    cp JOHTO_ROUTE_35_LOCAL_ID
    jp z, .route35ParkDoor
    cp JOHTO_GOLDENROD_CITY_LOCAL_ID
    jp z, .cityDoor
    cp JOHTO_ROUTE34_ILEX_GATE_LOCAL_ID
    ret nz
    ld a, [wYCoord]
    and a
    ret nz
    ld a, [wXCoord]
    cp 4
    jp z, .south
    cp 5
    jp z, .south
    ret
.parkGateTop
    ld a, [wYCoord]
    and a
    ret nz
    ld a, [wXCoord]
    cp 3
    jp z, .south
    cp 4
    jp z, .south
    ret
.route35ParkDoor
    ld a, [wXCoord]
    cp 3
    ret nz
    ld a, [wYCoord]
    cp 5
    jp z, .south
    ret
.gateTop
    ld a, [wYCoord]
    and a
    ret nz
    ld a, [wXCoord]
    cp 4
    jp z, .south
    cp 5
    jp z, .south
    ret
.cityDoor
    ld a, [wXCoord]
    cp 19
    ret nz
    ld a, [wYCoord]
    cp 1
    jp z, .south
    ret
.forest
    ld a, [wXCoord]
    cp 1
    ret nz
    ld a, [wYCoord]
    cp 5
    ret nz
.south
    ld e, D_DOWN
    ret

; The before-step approach accepts only the audited adjacent square,
; direction and destination. No broad tile-class bypass on Kanto or Johto.
JohtoSouthPortalBeforeStep::
    ld e, 0
    ld a, [wCurLocalMapID]
    cp JOHTO_AZALEA_TOWN_LOCAL_ID
    jp z, .azalea
    cp JOHTO_ILEX_FOREST_LOCAL_ID
    jp z, .forest
    cp JOHTO_ROUTE34_ILEX_GATE_LOCAL_ID
    jp z, .northGate
    cp JOHTO_ROUTE_34_LOCAL_ID
    jp z, .route34
    cp JOHTO_GOLDENROD_CITY_LOCAL_ID
    jp z, .goldenrod
    cp JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID
    jp z, .route35Gate
    cp JOHTO_ROUTE_35_LOCAL_ID
    jp z, .route35
    cp JOHTO_NATIONAL_PARK_LOCAL_ID
    jp z, .park
    cp JOHTO_ROUTE_35_NATIONAL_PARK_GATE_LOCAL_ID
    jp z, .parkSouthGate
    cp JOHTO_ROUTE_36_NATIONAL_PARK_GATE_LOCAL_ID
    jp z, .parkEastGate
    ret
.azalea
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_LEFT
    ret nz
    ld a, [wXCoord]
    cp 3
    ret nz
    ld a, [wYCoord]
    cp 10
    jp z, .allow
    cp 11
    jp z, .allow
    ret
.forest
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    jp z, .forestDoor
    cp PLAYER_DIR_RIGHT
    ret nz
    ld a, [wXCoord]
    cp 2
    ret nz
    ld a, [wYCoord]
    cp 42
    jp z, .allow
    cp 43
    jp z, .allow
    ret
.forestDoor
    ld a, [wXCoord]
    cp 1
    ret nz
    ld a, [wYCoord]
    cp 6
    jp z, .allow
    ret
.northGate
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    ret nz
    ld a, [wYCoord]
    cp 1
    ret nz
    ld a, [wXCoord]
    cp 4
    jp z, .allow
    cp 5
    jp z, .allow
    ret
.route34
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_DOWN
    ret nz
    ld a, [wYCoord]
    cp 36
    ret nz
    ld a, [wXCoord]
    cp 13
    jp z, .allow
    cp 14
    jp z, .allow
    ret
.goldenrod
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    ret nz
    ld a, [wXCoord]
    cp 19
    ret nz
    ld a, [wYCoord]
    cp 2
    jp z, .allow
    ret
.route35Gate
    jp .northGate
.route35
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    jr nz, .route35South
    ld a, [wXCoord]
    cp 3
    ret nz
    ld a, [wYCoord]
    cp 6
    jp z, .allow
    ret
.route35South
    cp PLAYER_DIR_DOWN
    ret nz
    ld a, [wYCoord]
    cp 32
    ret nz
    ld a, [wXCoord]
    cp 9
    jp z, .allow
    cp 10
    jp z, .allow
    ret
.park
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_RIGHT
    jr nz, .parkSouth
    ld a, [wXCoord]
    cp 32
    ret nz
    ld a, [wYCoord]
    cp 18
    jp z, .allow
    cp 19
    jp z, .allow
    ret
.parkSouth
    cp PLAYER_DIR_DOWN
    ret nz
    ld a, [wYCoord]
    cp 46
    ret nz
    ld a, [wXCoord]
    cp 10
    jp z, .allow
    cp 11
    jp z, .allow
    ret
.parkSouthGate
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    jr nz, .parkSouthBottom
    ld a, [wYCoord]
    cp 1
    ret nz
    ld a, [wXCoord]
    cp 3
    jp z, .allow
    cp 4
    jp z, .allow
    ret
.parkSouthBottom
    cp PLAYER_DIR_DOWN
    ret nz
    ld a, [wYCoord]
    cp 6
    ret nz
    ld a, [wXCoord]
    cp 3
    jp z, .allow
    cp 4
    jp z, .allow
    ret
.parkEastGate
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_LEFT
    jr nz, .parkEastRight
    ld a, [wXCoord]
    cp 1
    ret nz
    ld a, [wYCoord]
    cp 4
    jp z, .allow
    cp 5
    jp z, .allow
    ret
.parkEastRight
    cp PLAYER_DIR_RIGHT
    ret nz
    ld a, [wXCoord]
    cp 8
    ret nz
    ld a, [wYCoord]
    cp 4
    jp z, .allow
    cp 5
    jp z, .allow
    ret
.allow
    ld e, 1
    ret
