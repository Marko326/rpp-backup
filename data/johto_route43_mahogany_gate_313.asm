; DEV-313: Gold ID65 Route43MahoganyGate, conservative first live north-gate slice.
; Gold source = NorthSouthGate 5x4, mapped via previously proven RPP Gate block IDs.
; REF-315 also opens the two north DOORs to the Gold Route43 south carpets.
; Threshold/arrival/edge behavior is configured in data/johto_vertical_gate_runtime_314.asm.
JohtoRoute43MahoganyGateBlocks:: INCBIN "maps/johto_pilot/Route43MahoganyGate.runtime.blk"
ASSERT @ - JohtoRoute43MahoganyGateBlocks == JOHTO_ROUTE43_MAHOGANY_GATE_WIDTH * JOHTO_ROUTE43_MAHOGANY_GATE_HEIGHT

JohtoRoute43MahoganyGateScript::
    call EnableAutoTextBoxDrawing
    ret

JohtoRoute43MahoganyGateRuntimeHeader::
    db JOHTO_GATE
    db JOHTO_ROUTE43_MAHOGANY_GATE_HEIGHT, JOHTO_ROUTE43_MAHOGANY_GATE_WIDTH
    dw JohtoRoute43MahoganyGateBlocks
    dw JohtoRoute43MahoganyGateTextPointers
    dw JohtoRoute43MahoganyGateScript
    db 0 ; no direct outdoor connections (only explicit registered south Warps)
    dw JohtoRoute43MahoganyGateRuntimeObjects
JohtoRoute43MahoganyGateHeaderEnd::
ASSERT JohtoRoute43MahoganyGateHeaderEnd - JohtoRoute43MahoganyGateRuntimeHeader == 12
ASSERT BANK(JohtoRoute43MahoganyGateRuntimeHeader) == BANK(JohtoRoute43MahoganyGateBlocks)
ASSERT BANK(JohtoRoute43MahoganyGateRuntimeHeader) == BANK(JohtoRoute43MahoganyGateScript)

JohtoRoute43MahoganyGateTextPointers:
JohtoRoute43MahoganyGateRuntimeObjects::
    db $0d ; Johto Gate outer frame
    db 4 ; Gold lower 2 carpets + upper 2 DOORs, Route43 (ID67) now active
    db 7, 4, 0, JOHTO_REGISTERED_WARP_SELECTOR ; lower-left -> Mahogany Gold door #5
    db 7, 5, 0, JOHTO_REGISTERED_WARP_SELECTOR ; lower-right -> same Gold door #5
    db 0, 4, 0, JOHTO_REGISTERED_WARP_SELECTOR ; upper-left DOOR -> Route43 Gold #1
    db 0, 5, 1, JOHTO_REGISTERED_WARP_SELECTOR ; upper-right DOOR -> Route43 Gold #2
    db 0 ; no signs
    db 0 ; Gold conditional Officer intentionally deferred
