; MAP-286: Gold National Park, Route35 and Route36 park gates.
; Source blk and tile art are preserved exactly. Trainer and bug contest
; script events are deliberately not activated by this map-only rollout.
JohtoPark_GFX:: INCBIN "gfx/tilesets/johto_park.2bpp"
JohtoPark_Block:: INCBIN "gfx/blocksets/johto_park.bst"
JohtoParkGate_GFX:: INCBIN "gfx/tilesets/johto_park_gate.2bpp"
JohtoParkGate_Block:: INCBIN "gfx/blocksets/johto_park_gate.bst"
ASSERT BANK(JohtoPark_GFX) == BANK(JohtoPark_Block)
ASSERT BANK(JohtoParkGate_GFX) == BANK(JohtoParkGate_Block)

JohtoParkBlocks:: INCBIN "maps/johto_pilot/NationalPark.runtime.blk"
JohtoParkBlocksEnd::
ASSERT JohtoParkBlocksEnd - JohtoParkBlocks == 540
JohtoParkRuntimeHeader::
    db JOHTO_PARK
    db JOHTO_NATIONAL_PARK_HEIGHT, JOHTO_NATIONAL_PARK_WIDTH
    dw JohtoParkBlocks
    dw JohtoParkTextPointers
    dw JohtoParkLocalScript
    db 0
    dw JohtoParkRuntimeObjects
JohtoParkRuntimeHeaderEnd::
ASSERT JohtoParkRuntimeHeaderEnd - JohtoParkRuntimeHeader == 12
JohtoParkTextPointers:
JohtoParkRuntimeObjects::
    db $00 ; original Gold park border
    db 4
    db 18, 33, 0, JOHTO_REGISTERED_WARP_SELECTOR ; west -> east gate #1
    db 19, 33, 1, JOHTO_REGISTERED_WARP_SELECTOR ; west -> east gate #2
    db 47, 10, 0, JOHTO_REGISTERED_WARP_SELECTOR ; south -> south gate #1
    db 47, 11, 1, JOHTO_REGISTERED_WARP_SELECTOR ; south -> south gate #2
    db 0 ; signs pending separate text conversion
    db 0 ; NPC/contest events pending

JohtoParkSouthGateBlocks:: INCBIN "maps/johto_pilot/Route35NationalParkGate.runtime.blk"
JohtoParkSouthGateBlocksEnd::
ASSERT JohtoParkSouthGateBlocksEnd - JohtoParkSouthGateBlocks == 16
JohtoParkSouthGateRuntimeHeader::
    db JOHTO_PARK_GATE
    db JOHTO_ROUTE35_PARK_GATE_HEIGHT, JOHTO_ROUTE35_PARK_GATE_WIDTH
    dw JohtoParkSouthGateBlocks
    dw JohtoParkSouthGateTextPointers
    dw JohtoParkLocalScript
    db 0
    dw JohtoParkSouthGateRuntimeObjects
JohtoParkSouthGateRuntimeHeaderEnd::
ASSERT JohtoParkSouthGateRuntimeHeaderEnd - JohtoParkSouthGateRuntimeHeader == 12
JohtoParkSouthGateTextPointers:
JohtoParkSouthGateRuntimeObjects::
    db $00
    db 4
    db 0, 3, 2, JOHTO_REGISTERED_WARP_SELECTOR ; Gold #1 park #3
    db 0, 4, 3, JOHTO_REGISTERED_WARP_SELECTOR ; Gold #2 park #4
    db 7, 3, 2, JOHTO_REGISTERED_WARP_SELECTOR ; Gold #3 Route35 #3
    db 7, 4, 2, JOHTO_REGISTERED_WARP_SELECTOR ; Gold #4 Route35 #3
    db 0
    db 0

JohtoParkEastGateBlocks:: INCBIN "maps/johto_pilot/Route36NationalParkGate.runtime.blk"
JohtoParkEastGateBlocksEnd::
ASSERT JohtoParkEastGateBlocksEnd - JohtoParkEastGateBlocks == 20
JohtoParkEastGateRuntimeHeader::
    db JOHTO_PARK_GATE
    db JOHTO_ROUTE36_PARK_GATE_HEIGHT, JOHTO_ROUTE36_PARK_GATE_WIDTH
    dw JohtoParkEastGateBlocks
    dw JohtoParkEastGateTextPointers
    dw JohtoParkLocalScript
    db 0
    dw JohtoParkEastGateRuntimeObjects
JohtoParkEastGateHeaderEnd::
ASSERT JohtoParkEastGateHeaderEnd - JohtoParkEastGateRuntimeHeader == 12
JohtoParkEastGateTextPointers:
JohtoParkEastGateRuntimeObjects::
    db $00
    db 4
    db 4, 0, 0, JOHTO_REGISTERED_WARP_SELECTOR ; west -> Park #1
    db 5, 0, 1, JOHTO_REGISTERED_WARP_SELECTOR ; west -> Park #2
    db 4, 9, 2, JOHTO_REGISTERED_WARP_SELECTOR ; east -> Route36 #1
    db 5, 9, 3, JOHTO_REGISTERED_WARP_SELECTOR ; east -> Route36 #2
    db 0
    db 0

; FIX-287: RunMapScript jumps to the map script using the active map's bank.
; Three Park headers are in ROMX $50, so their script MUST live in $50,
; not in the $4C JohtoSouthScript section.  Called routines are in ROM0.
JohtoParkLocalScript::
    call EnableAutoTextBoxDrawing
    ret
ASSERT BANK(JohtoParkLocalScript) == BANK(JohtoParkRuntimeHeader)
ASSERT BANK(JohtoParkLocalScript) == BANK(JohtoParkSouthGateRuntimeHeader)
ASSERT BANK(JohtoParkLocalScript) == BANK(JohtoParkEastGateRuntimeHeader)
