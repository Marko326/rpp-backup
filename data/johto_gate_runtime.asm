; P6-GATE-001: 5x4 EastWestGate, verified old RPP compact mapping.
; Source authentic Gold layout remains separate in Bank $42.
JohtoGate_GFX:: INCBIN "gfx/tilesets/johto_gate.2bpp"
JohtoGate_Block:: INCBIN "gfx/blocksets/johto_gate.bst"
JohtoGate_BlockEnd::
ASSERT JohtoGate_BlockEnd - JohtoGate_Block == 19 * 16
JohtoPilotVioletGateRuntimeBlocks::
    INCBIN "maps/johto_pilot/Route31VioletGate.runtime.blk"
JohtoPilotVioletGateRuntimeBlocksEnd::
ASSERT JohtoPilotVioletGateRuntimeBlocksEnd - JohtoPilotVioletGateRuntimeBlocks == JOHTO_ROUTE31_VIOLET_GATE_WIDTH * JOHTO_ROUTE31_VIOLET_GATE_HEIGHT
JohtoPilotVioletGateRuntimeHeader::
    db JOHTO_GATE
    db JOHTO_ROUTE31_VIOLET_GATE_HEIGHT, JOHTO_ROUTE31_VIOLET_GATE_WIDTH
    dw JohtoPilotVioletGateRuntimeBlocks
    dw JohtoPilotVioletGateTextPointers
    dw JohtoPilotVioletGateMapScript
    db 0 ; no outdoor seam: both sides exit via registered warps
    dw JohtoPilotVioletGateRuntimeObjects
JohtoPilotVioletGateRuntimeHeaderEnd::
ASSERT JohtoPilotVioletGateRuntimeHeaderEnd - JohtoPilotVioletGateRuntimeHeader == 12
ASSERT BANK(JohtoPilotVioletGateRuntimeHeader) == BANK(JohtoPilotVioletGateRuntimeBlocks)
ASSERT BANK(JohtoGate_GFX) == BANK(JohtoGate_Block)
JohtoPilotVioletGateMapScript::
    call EnableAutoTextBoxDrawing
    ret
ASSERT BANK(JohtoPilotVioletGateMapScript) == BANK(JohtoPilotVioletGateRuntimeHeader)
JohtoPilotVioletGateTextPointers:
    ; Two reference NPC dialogues are deliberately deferred in the map-only phase.
JohtoPilotVioletGateRuntimeObjects::
    db $0d ; original old RPP isolated black border block
    db 4
    db 4, 0, 0, JOHTO_REGISTERED_WARP_SELECTOR ; LEFT, Violet City y24
    db 5, 0, 1, JOHTO_REGISTERED_WARP_SELECTOR ; LEFT, Violet City y25
    db 4, 9, 0, JOHTO_REGISTERED_WARP_SELECTOR ; RIGHT, Route31 y6
    db 5, 9, 1, JOHTO_REGISTERED_WARP_SELECTOR ; RIGHT, Route31 y7
    db 0
    db 0
