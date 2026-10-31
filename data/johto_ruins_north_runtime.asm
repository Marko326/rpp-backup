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

; SEAM-289: the blockmap-strip loader uses SwitchToMapRomBank (the
; *source* map's bank) while drawing connected neighbors. These full byte-
; identical mirrors are intentionally in Route36's Bank $4A; pointers into
; VioletCity's Bank $43 or Route35's Bank $4C would read the wrong ROM.
JohtoRoute36NorthRoute37Mirror::
    INCBIN "maps/johto_pilot/Route37.runtime.blk"
ASSERT @ - JohtoRoute36NorthRoute37Mirror == JOHTO_ROUTE37_WIDTH * JOHTO_ROUTE37_HEIGHT
JohtoRoute36SouthRoute35Mirror::
    INCBIN "maps/johto_pilot/Route35.runtime.blk"
ASSERT @ - JohtoRoute36SouthRoute35Mirror == JOHTO_ROUTE35_WIDTH * JOHTO_ROUTE35_HEIGHT
JohtoRoute36EastVioletMirror::
    INCBIN "maps/johto_pilot/VioletCity.runtime.blk"
ASSERT @ - JohtoRoute36EastVioletMirror == JOHTO_VIOLET_CITY_WIDTH * JOHTO_VIOLET_CITY_HEIGHT

JohtoPilotRoute36RuntimeHeader::
    db JOHTO_PILOT
    db JOHTO_ROUTE_36_HEIGHT, JOHTO_ROUTE_36_WIDTH
    dw JohtoPilotRoute36RuntimeBlocks
    dw JohtoPilotRoute36TextPointers
    dw JohtoPilotRoute36Script
    db NORTH | SOUTH | EAST ; Gold Route37 north; Route35 south; Violet east
    ; NORTH Gold +10: Route36 columns 10..19 overlap Route37 columns 0..9.
    db JOHTO_RUNTIME_MAP_HANDLE
    dw JohtoRoute36NorthRoute37Mirror + JOHTO_ROUTE37_WIDTH * (JOHTO_ROUTE37_HEIGHT - 3)
    dw wOverworldMap + 3 + 10
    db JOHTO_ROUTE37_WIDTH
    db JOHTO_ROUTE37_WIDTH
    db JOHTO_ROUTE37_HEIGHT * 2 - 1
    db -20 ; Route36 X-20 tile units -> Route37
    dw wOverworldMap + 1 + JOHTO_ROUTE37_HEIGHT * (JOHTO_ROUTE37_WIDTH + 6)
    ; SOUTH -> Route35 (offset 0). Only the neighbor's ten columns overlap.
    db JOHTO_RUNTIME_MAP_HANDLE
    dw JohtoRoute36SouthRoute35Mirror
    dw wOverworldMap + (JOHTO_ROUTE_36_HEIGHT + 3) * (JOHTO_ROUTE_36_WIDTH + 6) + 3
    db JOHTO_ROUTE35_WIDTH
    db JOHTO_ROUTE35_WIDTH
    db 0
    db 0
    dw wOverworldMap + 7 + JOHTO_ROUTE35_WIDTH
    ; EAST -> VioletCity (offset 0), y=0..8 are the overlapping source rows.
    db JOHTO_RUNTIME_MAP_HANDLE
    dw JohtoRoute36EastVioletMirror
    dw wOverworldMap + 3 * (JOHTO_ROUTE_36_WIDTH + 6) + JOHTO_ROUTE_36_WIDTH + 3
    db JOHTO_ROUTE_36_HEIGHT ; map rows (the border is refilled by 3 extra rows)
    db JOHTO_VIOLET_CITY_WIDTH
    db 0
    db 0
    dw wOverworldMap + 7 + JOHTO_VIOLET_CITY_WIDTH
    dw JohtoPilotRoute36RuntimeObjects
JohtoPilotRoute36RuntimeHeaderEnd::
ASSERT JohtoPilotRoute36RuntimeHeaderEnd - JohtoPilotRoute36RuntimeHeader == 45
ASSERT BANK(JohtoRoute36NorthRoute37Mirror) == BANK(JohtoPilotRoute36RuntimeHeader)
ASSERT BANK(JohtoRoute36SouthRoute35Mirror) == BANK(JohtoPilotRoute36RuntimeHeader)
ASSERT BANK(JohtoRoute36EastVioletMirror) == BANK(JohtoPilotRoute36RuntimeHeader)
ASSERT BANK(JohtoPilotRoute36RuntimeHeader) == BANK(JohtoPilotRoute36RuntimeBlocks)
JohtoPilotRoute36Script::
    call EnableAutoTextBoxDrawing
    ret
JohtoPilotRoute36TextPointers:
JohtoPilotRoute36RuntimeObjects::
    db $05
    db 4 ; Ruins #3/#4 retain ordinals0/1; Park #1/#2 append 2/3.
    db 13, 47, 0, JOHTO_REGISTERED_WARP_SELECTOR ; DOWN carpet -> North Gate top left
    db 13, 48, 1, JOHTO_REGISTERED_WARP_SELECTOR ; DOWN carpet -> North Gate top right
    db 8, 18, 2, JOHTO_REGISTERED_WARP_SELECTOR ; Gold #1 -> Park east gate #3
    db 9, 18, 3, JOHTO_REGISTERED_WARP_SELECTOR ; Gold #2 -> Park east gate #4
    db 0 ; defer signs and original NPC/Sudowoodo events
    db 0
