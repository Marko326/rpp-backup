; DEV-319: Gold Route43Gate ID66 (5x4 NorthSouthGate) transit foundation.
; Gold 1000-yen Rocket toll/scene and Officer TM36 are NOT ported here.
; Do not present this transit-only gate as a completed Gold story event.
JohtoRoute43GateBlocks:: INCBIN "maps/johto_pilot/Route43Gate.runtime.blk"
ASSERT @ - JohtoRoute43GateBlocks == JOHTO_ROUTE43_GATE_WIDTH * JOHTO_ROUTE43_GATE_HEIGHT

JohtoRoute43GateScript::
    call EnableAutoTextBoxDrawing
    ret

JohtoRoute43GateRuntimeHeader::
    db JOHTO_GATE
    db JOHTO_ROUTE43_GATE_HEIGHT, JOHTO_ROUTE43_GATE_WIDTH
    dw JohtoRoute43GateBlocks
    dw JohtoRoute43GateTextPointers
    dw JohtoRoute43GateScript
    db 0 ; enclosed gatehouse, Warp-only exits
    dw JohtoRoute43GateRuntimeObjects
JohtoRoute43GateHeaderEnd::
ASSERT JohtoRoute43GateHeaderEnd - JohtoRoute43GateRuntimeHeader == 12
ASSERT BANK(JohtoRoute43GateRuntimeHeader) == BANK(JohtoRoute43GateBlocks)
ASSERT BANK(JohtoRoute43GateRuntimeHeader) == BANK(JohtoRoute43GateScript)
ASSERT BANK(JohtoRoute43GateRuntimeHeader) == BANK(JohtoRoute43GateRuntimeObjects)

JohtoRoute43GateTextPointers:
JohtoRoute43GateRuntimeObjects::
    db $0d ; same NorthSouthGate artwork as ID65
    db 4 ; Gold #1/#2 top DOORs -> Route43 north carpets #4/#5
    db 0, 4, 3, JOHTO_REGISTERED_WARP_SELECTOR
    db 0, 5, 4, JOHTO_REGISTERED_WARP_SELECTOR
    db 7, 4, 2, JOHTO_REGISTERED_WARP_SELECTOR ; bottom carpets -> Gold Route43 #3
    db 7, 5, 2, JOHTO_REGISTERED_WARP_SELECTOR
    db 0 ; signs
    db 0 ; Rocket and Officer events require separate story-state port
