; ALPH-NORTH-001: Gold sourced north gate & Route36; edges to incomplete maps closed.
; Route36 and north gate have no direct outdoor seam, only registered Warps.
JohtoPilotAlphNorthGateRuntimeBlocks::
    INCBIN "maps/johto_pilot/Route36RuinsOfAlphGate.runtime.blk"
JohtoPilotAlphNorthGateRuntimeBlocksEnd::
ASSERT JohtoPilotAlphNorthGateRuntimeBlocksEnd - JohtoPilotAlphNorthGateRuntimeBlocks == JOHTO_ROUTE36_RUINS_GATE_WIDTH * JOHTO_ROUTE36_RUINS_GATE_HEIGHT
JohtoPilotRoute36RuntimeBlocks::
    INCBIN "maps/johto_pilot/Route36.runtime.blk"
JohtoPilotRoute36RuntimeBlocksEnd::
ASSERT JohtoPilotRoute36RuntimeBlocksEnd - JohtoPilotRoute36RuntimeBlocks == JOHTO_ROUTE_36_WIDTH * JOHTO_ROUTE_36_HEIGHT

JohtoPilotAlphNorthGateRuntimeHeader::
    db JOHTO_GATE
    db JOHTO_ROUTE36_RUINS_GATE_HEIGHT, JOHTO_ROUTE36_RUINS_GATE_WIDTH
    dw JohtoPilotAlphNorthGateRuntimeBlocks
    dw JohtoPilotAlphNorthGateTextPointers
    dw JohtoPilotAlphNorthGateScript
    db 0 ; no seam
    dw JohtoPilotAlphNorthGateRuntimeObjects
JohtoPilotAlphNorthGateRuntimeHeaderEnd::
ASSERT JohtoPilotAlphNorthGateRuntimeHeaderEnd - JohtoPilotAlphNorthGateRuntimeHeader == 12
ASSERT BANK(JohtoPilotAlphNorthGateRuntimeHeader) == BANK(JohtoPilotAlphNorthGateRuntimeBlocks)
JohtoPilotAlphNorthGateScript::
    call EnableAutoTextBoxDrawing
    ret
JohtoPilotAlphNorthGateTextPointers:
JohtoPilotAlphNorthGateRuntimeObjects::
    db $0d
    db 4
    db 0, 4, 0, JOHTO_REGISTERED_WARP_SELECTOR ; UP door -> Route36 first carpet
    db 0, 5, 1, JOHTO_REGISTERED_WARP_SELECTOR ; UP door -> Route36 second carpet
    db 7, 4, 2, JOHTO_REGISTERED_WARP_SELECTOR ; DOWN carpet -> Ruins door
    db 7, 5, 2, JOHTO_REGISTERED_WARP_SELECTOR ; DOWN carpet -> same Ruins door
    db 0 ; no NPC until Gold scripted event implementation
    db 0

JohtoPilotRoute36RuntimeHeader::
    db JOHTO_PILOT
    db JOHTO_ROUTE_36_HEIGHT, JOHTO_ROUTE_36_WIDTH
    dw JohtoPilotRoute36RuntimeBlocks
    dw JohtoPilotRoute36TextPointers
    dw JohtoPilotRoute36Script
    db 0 ; Park/Violet/Route35/Route37 edges not yet certified; fail closed
    dw JohtoPilotRoute36RuntimeObjects
JohtoPilotRoute36RuntimeHeaderEnd::
ASSERT JohtoPilotRoute36RuntimeHeaderEnd - JohtoPilotRoute36RuntimeHeader == 12
ASSERT BANK(JohtoPilotRoute36RuntimeHeader) == BANK(JohtoPilotRoute36RuntimeBlocks)
JohtoPilotRoute36Script::
    call EnableAutoTextBoxDrawing
    ret
JohtoPilotRoute36TextPointers:
JohtoPilotRoute36RuntimeObjects::
    db $05
    db 2 ; Only Gold Route36 Warps #3/#4; National Park #1/#2 closed.
    db 13, 47, 0, JOHTO_REGISTERED_WARP_SELECTOR ; DOWN carpet -> North Gate top left
    db 13, 48, 1, JOHTO_REGISTERED_WARP_SELECTOR ; DOWN carpet -> North Gate top right
    db 0 ; defer signs and original NPC/Sudowoodo events
    db 0
