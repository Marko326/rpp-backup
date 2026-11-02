; DEV-328 geometry-only Gold Route45 -> Route46 -> Route29/46 Gate.
JohtoRoute45Blocks:: INCBIN "maps/johto_pilot/Route45.runtime.blk"
ASSERT @ - JohtoRoute45Blocks == JOHTO_ROUTE_45_WIDTH * JOHTO_ROUTE_45_HEIGHT
JohtoRoute46Blocks:: INCBIN "maps/johto_pilot/Route46.runtime.blk"
ASSERT @ - JohtoRoute46Blocks == JOHTO_ROUTE_46_WIDTH * JOHTO_ROUTE_46_HEIGHT
JohtoRoute29Route46GateBlocks:: INCBIN "maps/johto_pilot/Route29Route46Gate.runtime.blk"
ASSERT @ - JohtoRoute29Route46GateBlocks == 5 * 4
JohtoRoute29Mirror:: INCBIN "maps/johto_pilot/Route29.south_route46_mirror.blk"
ASSERT @ - JohtoRoute29Mirror == JOHTO_ROUTE_29_WIDTH * JOHTO_ROUTE_29_HEIGHT
JohtoRoute45Roles:: INCBIN "maps/johto_pilot/Route45.roles.bin"
ASSERT @ - JohtoRoute45Roles == 20 * 90
JohtoRoute46Roles:: INCBIN "maps/johto_pilot/Route46.roles.bin"
ASSERT @ - JohtoRoute46Roles == 20 * 36

JohtoSouthernScript::
    call EnableAutoTextBoxDrawing
    ret

JohtoRoute45RuntimeHeader::
    db JOHTO_PILOT
    db JOHTO_ROUTE_45_HEIGHT, JOHTO_ROUTE_45_WIDTH
    dw JohtoRoute45Blocks
    dw JohtoRoute45TextPointers
    dw JohtoSouthernScript
    db NORTH | WEST
    ; NORTH: Blackthorn southern three rows, Gold x0..9.
    db JOHTO_RUNTIME_MAP_HANDLE
    dw JohtoBlackthornBlocks + JOHTO_BLACKTHORN_CITY_WIDTH * (JOHTO_BLACKTHORN_CITY_HEIGHT - 3)
    dw wOverworldMap + 3
    db JOHTO_ROUTE_45_WIDTH
    db JOHTO_BLACKTHORN_CITY_WIDTH
    db JOHTO_BLACKTHORN_CITY_HEIGHT * 2 - 1
    db 0
    dw wOverworldMap + 1 + JOHTO_BLACKTHORN_CITY_HEIGHT * (JOHTO_BLACKTHORN_CITY_WIDTH + 6)
    ; WEST: Route46 right edge, Gold offset +36 blocks.
    db JOHTO_RUNTIME_MAP_HANDLE
    dw JohtoRoute46Blocks + JOHTO_ROUTE_46_WIDTH - 3
    dw wOverworldMap + (3 + 36) * (JOHTO_ROUTE_45_WIDTH + 6)
    db JOHTO_ROUTE_45_HEIGHT - 36
    db JOHTO_ROUTE_46_WIDTH
    db -72
    db JOHTO_ROUTE_46_WIDTH * 2 - 1
    dw wOverworldMap + 6 + 2 * JOHTO_ROUTE_46_WIDTH
    dw JohtoRoute45RuntimeObjects
JohtoRoute45HeaderEnd::
ASSERT JohtoRoute45HeaderEnd - JohtoRoute45RuntimeHeader == 34

JohtoRoute46RuntimeHeader::
    db JOHTO_PILOT
    db JOHTO_ROUTE_46_HEIGHT, JOHTO_ROUTE_46_WIDTH
    dw JohtoRoute46Blocks
    dw JohtoRoute46TextPointers
    dw JohtoSouthernScript
    db SOUTH | EAST
    ; SOUTH: Gold Route29 x10..19, preview ONLY; both physical edges are walls.
    db JOHTO_RUNTIME_MAP_HANDLE
    dw JohtoRoute29Mirror + 10
    dw wOverworldMap + (JOHTO_ROUTE_46_HEIGHT + 3) * (JOHTO_ROUTE_46_WIDTH + 6) + 3
    db JOHTO_ROUTE_46_WIDTH
    db JOHTO_ROUTE_29_WIDTH
    db 0
    db 20
    dw wOverworldMap + 7 + JOHTO_ROUTE_29_WIDTH
    ; EAST: Route45 left edge, Gold -36 offset.
    db JOHTO_RUNTIME_MAP_HANDLE
    dw JohtoRoute45Blocks + JOHTO_ROUTE_45_WIDTH * 36
    dw wOverworldMap + 3 * (JOHTO_ROUTE_46_WIDTH + 6) + JOHTO_ROUTE_46_WIDTH + 3
    db JOHTO_ROUTE_45_HEIGHT - 36
    db JOHTO_ROUTE_45_WIDTH
    db 72
    db 0
    dw wOverworldMap + 7 + JOHTO_ROUTE_45_WIDTH
    dw JohtoRoute46RuntimeObjects
JohtoRoute46HeaderEnd::
ASSERT JohtoRoute46HeaderEnd - JohtoRoute46RuntimeHeader == 34

JohtoRoute29Route46GateRuntimeHeader::
    db JOHTO_GATE
    db 4, 5
    dw JohtoRoute29Route46GateBlocks
    dw JohtoRoute29Route46GateTextPointers
    dw JohtoSouthernScript
    db 0 ; enclosed, Warp-only
    dw JohtoRoute29Route46GateRuntimeObjects
JohtoRoute29Route46GateHeaderEnd::
ASSERT JohtoRoute29Route46GateHeaderEnd - JohtoRoute29Route46GateRuntimeHeader == 12

JohtoRoute45RuntimeObjects::
    db $71 ; Gold rock border
    db 0 ; Dark Cave remains closed
    db 0
    db 0
JohtoRoute46RuntimeObjects::
    db $05 ; Gold Route46 trees
    db 2 ; Gold Route46 -> Gate north pair, other cave stays closed
    db 33, 7, 0, JOHTO_REGISTERED_WARP_SELECTOR
    db 33, 8, 1, JOHTO_REGISTERED_WARP_SELECTOR
    db 0
    db 0
JohtoRoute29Route46GateRuntimeObjects::
    db $0d ; Gold 5x4 shared gate
    db 4 ; Gold top pair -> Route46; bottom pair -> Route29
    db 0, 4, 0, JOHTO_REGISTERED_WARP_SELECTOR
    db 0, 5, 1, JOHTO_REGISTERED_WARP_SELECTOR
    db 7, 4, 0, JOHTO_REGISTERED_WARP_SELECTOR
    db 7, 5, 0, JOHTO_REGISTERED_WARP_SELECTOR
    db 0
    db 0 ; dialogue deferred, gate traversable
JohtoRoute45TextPointers:
JohtoRoute46TextPointers:
JohtoRoute29Route46GateTextPointers:
ASSERT BANK(JohtoRoute45RuntimeHeader) == BANK(JohtoRoute45Blocks)
ASSERT BANK(JohtoRoute46RuntimeHeader) == BANK(JohtoRoute46Blocks)
ASSERT BANK(JohtoRoute29Route46GateRuntimeHeader) == BANK(JohtoRoute29Route46GateBlocks)
ASSERT BANK(JohtoRoute45RuntimeHeader) == BANK(JohtoSouthernScript)
