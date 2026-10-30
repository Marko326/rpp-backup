; ALPH-SOUTH-002: Gold-sourced 32 -> EastWestGate -> Ruins outside.
; These two maps live in an independent expansion ROM bank; no ROM0 additions.
JohtoPilotAlphOutsideRuntimeBlocks::
    INCBIN "maps/johto_pilot/RuinsOfAlphOutside.runtime.blk"
JohtoPilotAlphOutsideRuntimeBlocksEnd::
ASSERT JohtoPilotAlphOutsideRuntimeBlocksEnd - JohtoPilotAlphOutsideRuntimeBlocks == JOHTO_RUINS_OF_ALPH_WIDTH * JOHTO_RUINS_OF_ALPH_HEIGHT

JohtoPilotAlphSouthGateRuntimeBlocks::
    INCBIN "maps/johto_pilot/Route32RuinsOfAlphGate.runtime.blk"
JohtoPilotAlphSouthGateRuntimeBlocksEnd::
ASSERT JohtoPilotAlphSouthGateRuntimeBlocksEnd - JohtoPilotAlphSouthGateRuntimeBlocks == JOHTO_ROUTE32_RUINS_GATE_WIDTH * JOHTO_ROUTE32_RUINS_GATE_HEIGHT

JohtoPilotAlphSouthGateRuntimeHeader::
    db JOHTO_GATE
    db JOHTO_ROUTE32_RUINS_GATE_HEIGHT, JOHTO_ROUTE32_RUINS_GATE_WIDTH
    dw JohtoPilotAlphSouthGateRuntimeBlocks
    dw JohtoPilotAlphSouthGateTextPointers
    dw JohtoPilotAlphSouthGateMapScript
    db 0 ; four directional edge carpets, no outdoor seam
    dw JohtoPilotAlphSouthGateRuntimeObjects
JohtoPilotAlphSouthGateRuntimeHeaderEnd::
ASSERT JohtoPilotAlphSouthGateRuntimeHeaderEnd - JohtoPilotAlphSouthGateRuntimeHeader == 12
ASSERT BANK(JohtoPilotAlphSouthGateRuntimeHeader) == BANK(JohtoPilotAlphSouthGateRuntimeBlocks)
JohtoPilotAlphSouthGateMapScript::
    call EnableAutoTextBoxDrawing
    ret
JohtoPilotAlphSouthGateTextPointers:
JohtoPilotAlphSouthGateRuntimeObjects::
    db $0d ; same EastWestGate border as the accepted Route31/Violet gate
    db 4
    db 4, 0, 0, JOHTO_REGISTERED_WARP_SELECTOR ; LEFT -> Ruins x13,y20
    db 5, 0, 1, JOHTO_REGISTERED_WARP_SELECTOR ; LEFT -> Ruins x13,y21
    db 4, 9, 0, JOHTO_REGISTERED_WARP_SELECTOR ; RIGHT -> Route32 x4,y2
    db 5, 9, 1, JOHTO_REGISTERED_WARP_SELECTOR ; RIGHT -> Route32 x4,y3
    db 0 ; Gold NPC / scripted dialogue postponed
    db 0

JohtoPilotAlphOutsideRuntimeHeader::
    db JOHTO_PILOT
    db JOHTO_RUINS_OF_ALPH_HEIGHT, JOHTO_RUINS_OF_ALPH_WIDTH
    dw JohtoPilotAlphOutsideRuntimeBlocks
    dw JohtoPilotAlphOutsideTextPointers
    dw JohtoPilotAlphOutsideMapScript
    db 0 ; no north Route36 connection until that map becomes playable
    dw JohtoPilotAlphOutsideRuntimeObjects
JohtoPilotAlphOutsideRuntimeHeaderEnd::
ASSERT JohtoPilotAlphOutsideRuntimeHeaderEnd - JohtoPilotAlphOutsideRuntimeHeader == 12
ASSERT BANK(JohtoPilotAlphOutsideRuntimeHeader) == BANK(JohtoPilotAlphOutsideRuntimeBlocks)
JohtoPilotAlphOutsideMapScript::
    call EnableAutoTextBoxDrawing
    ret
JohtoPilotAlphOutsideTextPointers:
JohtoPilotAlphOutsideRuntimeObjects::
    db $05 ; Gold outdoor border
    db 2 ; only Gold warp ordinals 9,10 enabled; other nine intentionally absent
    db 20, 13, 0, JOHTO_REGISTERED_WARP_SELECTOR ; rightward west gate exit
    db 21, 13, 1, JOHTO_REGISTERED_WARP_SELECTOR
    db 0 ; no signs yet
    db 0 ; no NPC/hidden events
