; MAP-283: Route35 and its Goldenrod Gate. Gold sources preserved separately;
; only source-authentic exterior door/carpet Warps are activated. Other
; Route35 indoor doors, National Park gate and Route36 seam stay CLOSED.
JohtoNorthRoute35GoldenrodGateBlocks:: INCBIN "maps/johto_pilot/Route35GoldenrodGate.mature.blk"
JohtoNorthRoute35GoldenrodGateBlocksEnd::
ASSERT JohtoNorthRoute35GoldenrodGateBlocksEnd - JohtoNorthRoute35GoldenrodGateBlocks == 20
JohtoNorthRoute35GoldenrodGateRuntimeHeader::
    db JOHTO_GATE
    db JOHTO_ROUTE35_GATE_HEIGHT, JOHTO_ROUTE35_GATE_WIDTH
    dw JohtoNorthRoute35GoldenrodGateBlocks
    dw JohtoNorthRoute35GoldenrodGateTextPointers
    dw JohtoSouthScript
    db 0 ; do not silently connect a gate to adjacent roads
    dw JohtoNorthRoute35GoldenrodGateRuntimeObjects
JohtoNorthRoute35GoldenrodGateHeaderEnd::
ASSERT JohtoNorthRoute35GoldenrodGateHeaderEnd - JohtoNorthRoute35GoldenrodGateRuntimeHeader == 12
ASSERT BANK(JohtoNorthRoute35GoldenrodGateRuntimeHeader) == BANK(JohtoNorthRoute35GoldenrodGateBlocks)
JohtoNorthRoute35GoldenrodGateTextPointers:
JohtoNorthRoute35GoldenrodGateRuntimeObjects::
    db $0d ; vetted JOHTO_GATE black outer border
    db 4
    db 0, 4, 0, JOHTO_REGISTERED_WARP_SELECTOR ; Gold gate #1 -> Route35 #1
    db 0, 5, 1, JOHTO_REGISTERED_WARP_SELECTOR ; Gold gate #2 -> Route35 #2
    db 7, 4, 0, JOHTO_REGISTERED_WARP_SELECTOR ; Gold gate #3 -> GoldenrodCity #13
    db 7, 5, 0, JOHTO_REGISTERED_WARP_SELECTOR ; Gold gate #4 -> GoldenrodCity #13
    db 0 ; unregistered events disabled
    db 0 ; unregistered NPC/story disabled

JohtoNorthRoute35Blocks:: INCBIN "maps/johto_pilot/Route35.runtime.blk"
JohtoNorthRoute35BlocksEnd::
ASSERT JohtoNorthRoute35BlocksEnd - JohtoNorthRoute35Blocks == JOHTO_ROUTE35_WIDTH * JOHTO_ROUTE35_HEIGHT
; SEAM-289: same-bank Route36 source for Route35 NORTH strip copy.
JohtoRoute35NorthRoute36Mirror::
    INCBIN "maps/johto_pilot/Route36.runtime.blk"
ASSERT @ - JohtoRoute35NorthRoute36Mirror == JOHTO_ROUTE_36_WIDTH * JOHTO_ROUTE_36_HEIGHT

JohtoNorthRoute35RuntimeHeader::
    db JOHTO_PILOT ; Gold TILESET_JOHTO, NOT JOHTO_MODERN
    db JOHTO_ROUTE35_HEIGHT, JOHTO_ROUTE35_WIDTH
    dw JohtoNorthRoute35Blocks
    dw JohtoNorthRoute35TextPointers
    dw JohtoSouthScript
    db NORTH ; Gold north -> existing Route36, offset 0
    db JOHTO_RUNTIME_MAP_HANDLE
    dw JohtoRoute35NorthRoute36Mirror + JOHTO_ROUTE_36_WIDTH * (JOHTO_ROUTE_36_HEIGHT - 3)
    dw wOverworldMap + 3
    ; FIX-290: keep three extra right-side screen-preview columns from Route36.
    ; Route35 is 10 blocks wide; the visible north strip needs 10+MAP_BORDER
    ; (13), while the actual legal exit still remains x=17 only.
    db JOHTO_ROUTE35_WIDTH + MAP_BORDER ; 13 visible columns, not 10
    db JOHTO_ROUTE_36_WIDTH
    db JOHTO_ROUTE_36_HEIGHT * 2 - 1
    db 0
    dw wOverworldMap + 1 + JOHTO_ROUTE_36_HEIGHT * (JOHTO_ROUTE_36_WIDTH + 6)
    dw JohtoNorthRoute35RuntimeObjects
JohtoNorthRoute35HeaderEnd::
ASSERT JohtoNorthRoute35HeaderEnd - JohtoNorthRoute35RuntimeHeader == 23
ASSERT BANK(JohtoRoute35NorthRoute36Mirror) == BANK(JohtoNorthRoute35RuntimeHeader)
ASSERT BANK(JohtoNorthRoute35RuntimeHeader) == BANK(JohtoNorthRoute35Blocks)
JohtoNorthRoute35TextPointers:
JohtoNorthRoute35RuntimeObjects::
    db $05 ; Gold wooded road edge
    db 3
    db 33, 9, 0, JOHTO_REGISTERED_WARP_SELECTOR ; Gold #1 -> gate #1
    db 33, 10, 1, JOHTO_REGISTERED_WARP_SELECTOR ; Gold #2 -> gate #2
    db 5, 3, 2, JOHTO_REGISTERED_WARP_SELECTOR ; Gold #3 -> park south gate #3
    db 0 ; signs deferred
    db 0 ; trainer and scripted events disabled
