; MAP-294: source-audited 37 -> Ecruteak corridor, all non-road doors CLOSED.
; Bank $51 local scripts: RunMapScript performs jp hl in this bank.
JohtoRoute37Blocks:: INCBIN "maps/johto_pilot/Route37.runtime.blk"
ASSERT @ - JohtoRoute37Blocks == JOHTO_ROUTE37_WIDTH * JOHTO_ROUTE37_HEIGHT
JohtoEcruteakBlocks:: INCBIN "maps/johto_pilot/EcruteakCity.runtime.blk"
ASSERT @ - JohtoEcruteakBlocks == JOHTO_ECRUTEAK_WIDTH * JOHTO_ECRUTEAK_HEIGHT
; Connection strip reader runs in the source map's bank, never the target bank.
JohtoRoute37SouthRoute36Mirror:: INCBIN "maps/johto_pilot/Route36.runtime.blk"
ASSERT @ - JohtoRoute37SouthRoute36Mirror == JOHTO_ROUTE_36_WIDTH * JOHTO_ROUTE_36_HEIGHT
JohtoRoute37NorthEcruteakMirror:: INCBIN "maps/johto_pilot/EcruteakCity.runtime.blk"
ASSERT @ - JohtoRoute37NorthEcruteakMirror == JOHTO_ECRUTEAK_WIDTH * JOHTO_ECRUTEAK_HEIGHT
JohtoEcruteakSouthRoute37Mirror:: INCBIN "maps/johto_pilot/Route37.runtime.blk"
ASSERT @ - JohtoEcruteakSouthRoute37Mirror == JOHTO_ROUTE37_WIDTH * JOHTO_ROUTE37_HEIGHT

JohtoCorridorLocalScript::
    call EnableAutoTextBoxDrawing
    ret

JohtoRoute37RuntimeHeader::
    db JOHTO_PILOT
    db JOHTO_ROUTE37_HEIGHT, JOHTO_ROUTE37_WIDTH
    dw JohtoRoute37Blocks
    dw JohtoRoute37TextPointers
    dw JohtoCorridorLocalScript
    db NORTH | SOUTH
    ; NORTH (Gold -5): source city starts at column 5. Include +3 preview.
    db JOHTO_RUNTIME_MAP_HANDLE
    dw JohtoRoute37NorthEcruteakMirror + JOHTO_ECRUTEAK_WIDTH * (JOHTO_ECRUTEAK_HEIGHT - 3) + 5
    dw wOverworldMap + 3
    db JOHTO_ROUTE37_WIDTH + MAP_BORDER ; Gold north preview
    db JOHTO_ECRUTEAK_WIDTH
    db JOHTO_ECRUTEAK_HEIGHT * 2 - 1
    db 10 ; Route37 X +10 tile units -> city
    dw wOverworldMap + 1 + JOHTO_ECRUTEAK_HEIGHT * (JOHTO_ECRUTEAK_WIDTH + 6)
    ; SOUTH (Gold -10): Route37 column 0 aligns to Route36 column 10.
    db JOHTO_RUNTIME_MAP_HANDLE
    dw JohtoRoute37SouthRoute36Mirror + 10
    dw wOverworldMap + (JOHTO_ROUTE37_HEIGHT + 3) * (JOHTO_ROUTE37_WIDTH + 6) + 3
    db JOHTO_ROUTE37_WIDTH + MAP_BORDER ; Gold south preview
    db JOHTO_ROUTE_36_WIDTH
    db 0
    db 20 ; Route37 X+20 tile units -> Route36
    dw wOverworldMap + 7 + JOHTO_ROUTE_36_WIDTH
    dw JohtoRoute37RuntimeObjects
JohtoRoute37HeaderEnd::
ASSERT JohtoRoute37HeaderEnd - JohtoRoute37RuntimeHeader == 34
JohtoRoute37TextPointers:
JohtoRoute37RuntimeObjects::
    db $05
    db 0 ; no unimplemented buildings, hidden items or scripted NPCs
    db 0
    db 0

JohtoEcruteakRuntimeHeader::
    db JOHTO_PILOT
    db JOHTO_ECRUTEAK_HEIGHT, JOHTO_ECRUTEAK_WIDTH
    dw JohtoEcruteakBlocks
    dw JohtoEcruteakTextPointers
    dw JohtoCorridorLocalScript
    db SOUTH ; WEST -> Route38 gate and EAST -> Route42 remain CLOSED
    db JOHTO_RUNTIME_MAP_HANDLE
    dw JohtoEcruteakSouthRoute37Mirror
    dw wOverworldMap + (JOHTO_ECRUTEAK_HEIGHT + 3) * (JOHTO_ECRUTEAK_WIDTH + 6) + 3 + 5
    db JOHTO_ROUTE37_WIDTH
    db JOHTO_ROUTE37_WIDTH
    db 0
    db -10 ; City X -10 tile units -> Route37
    dw wOverworldMap + 7 + JOHTO_ROUTE37_WIDTH
    dw JohtoEcruteakRuntimeObjects
JohtoEcruteakHeaderEnd::
ASSERT JohtoEcruteakHeaderEnd - JohtoEcruteakRuntimeHeader == 23
JohtoEcruteakTextPointers:
JohtoEcruteakRuntimeObjects::
    db $05
    db 0 ; all unreviewed Gold indoor and west/east gate warps CLOSED
    db 0
    db 0

ASSERT BANK(JohtoRoute37RuntimeHeader) == BANK(JohtoRoute37Blocks)
ASSERT BANK(JohtoRoute37RuntimeHeader) == BANK(JohtoRoute37NorthEcruteakMirror)
ASSERT BANK(JohtoRoute37RuntimeHeader) == BANK(JohtoRoute37SouthRoute36Mirror)
ASSERT BANK(JohtoRoute37RuntimeHeader) == BANK(JohtoCorridorLocalScript)
ASSERT BANK(JohtoEcruteakRuntimeHeader) == BANK(JohtoEcruteakBlocks)
ASSERT BANK(JohtoEcruteakRuntimeHeader) == BANK(JohtoCorridorLocalScript)

; Boundary contracts separate movement width from display strip width.
; Return E=1 only for an outside step not in the approved Gold corridor.
JohtoCorridor37Edge::
    ld e, 0
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    jr z, .north
    cp PLAYER_DIR_DOWN
    jr z, .south
    cp PLAYER_DIR_LEFT
    jr z, .west
    cp PLAYER_DIR_RIGHT
    ret nz
    ld a, [wXCoord]
    cp JOHTO_ROUTE37_WIDTH * 2 - 1
    ret c
    jr .closed
.west
    ld a, [wXCoord]
    and a
    ret nz
    jr .closed
.north
    ld a, [wYCoord]
    and a
    ret nz
    ld a, [wXCoord]
    cp 7
    jr z, .allowed
    cp 8
    jr z, .allowed
    jr .closed
.south
    ld a, [wYCoord]
    cp JOHTO_ROUTE37_HEIGHT * 2 - 1
    ret c
    ld a, [wXCoord]
    cp 5
    jr c, .closed
    cp 13 ; align with Route36 north x25..32
    jr nc, .closed
.allowed
    ret
.closed
    ld e, 1
    ret

JohtoCorridorEcruteakEdge::
    ld e, 0
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    jr z, .north
    cp PLAYER_DIR_DOWN
    jr z, .south
    cp PLAYER_DIR_LEFT
    jr z, .west
    cp PLAYER_DIR_RIGHT
    ret nz
    ld a, [wXCoord]
    cp JOHTO_ECRUTEAK_WIDTH * 2 - 1
    ret c
    jr .closed
.west
    ld a, [wXCoord]
    and a
    ret nz
    jr .closed
.north
    ld a, [wYCoord]
    and a
    ret nz
    jr .closed
.south
    ld a, [wYCoord]
    cp JOHTO_ECRUTEAK_HEIGHT * 2 - 1
    ret c
    ld a, [wXCoord]
    cp 17
    jr z, .allowed
    cp 18
    jr z, .allowed
    jr .closed
.allowed
    ret
.closed
    ld e, 1
    ret
