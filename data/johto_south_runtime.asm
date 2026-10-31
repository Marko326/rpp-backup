; MAP-268 South corridor, source-verified Gold map art and coordinate geometry.
JohtoSouthForestGFX:: INCBIN "gfx/tilesets/johto_ilex_forest.2bpp"
JohtoSouthForestBlocks:: INCBIN "gfx/blocksets/johto_ilex_forest.bst"
JohtoSouthGateGFX:: INCBIN "gfx/tilesets/johto_south_gold_gate.2bpp"
JohtoSouthGateBlocks:: INCBIN "gfx/blocksets/johto_south_gold_gate.bst"
ASSERT BANK(JohtoSouthForestGFX) == BANK(JohtoSouthForestBlocks)
ASSERT BANK(JohtoSouthGateGFX) == BANK(JohtoSouthGateBlocks)

JohtoSouthAzaleaTownBlocks:: INCBIN "maps/johto_pilot/AzaleaTown.runtime.blk"
JohtoSouthAzaleaTownBlocksEnd::
ASSERT JohtoSouthAzaleaTownBlocksEnd - JohtoSouthAzaleaTownBlocks == 180
JohtoSouthAzaleaTownRuntimeHeader::
    db JOHTO_MODERN
    db 9, 20
    dw JohtoSouthAzaleaTownBlocks
    dw JohtoSouthAzaleaTownTextPointers
    dw JohtoSouthScript
    db EAST ; east-west Route33 boundary, Gold offset 0
    db JOHTO_RUNTIME_MAP_HANDLE
    dw JohtoRoute33RuntimeBlocks
    dw wOverworldMap - 3 + (20 + 6) * 4
    db 9
    db 10
    db 0
    db 0
    dw wOverworldMap + 7 + 10
    dw JohtoSouthAzaleaTownRuntimeObjects
JohtoSouthAzaleaTownHeaderEnd::
ASSERT JohtoSouthAzaleaTownHeaderEnd - JohtoSouthAzaleaTownRuntimeHeader == 23
ASSERT BANK(JohtoSouthAzaleaTownRuntimeHeader) == BANK(JohtoSouthAzaleaTownBlocks)
JohtoSouthAzaleaTownTextPointers:
JohtoSouthAzaleaTownRuntimeObjects::
    db $05 ; NPC-243 accepted Gold Azalea outdoor forest border
    db 2
    db 10, 2, 2, JOHTO_REGISTERED_WARP_SELECTOR ; Gold #7 -> IlexForestAzaleaGate #3
    db 11, 2, 3, JOHTO_REGISTERED_WARP_SELECTOR ; Gold #8 -> IlexForestAzaleaGate #4
    db 0 ; unregistered signs excluded
    db 0 ; trainer/story encounters excluded

JohtoSouthIlexForestAzaleaGateBlocks:: INCBIN "maps/johto_pilot/IlexForestAzaleaGate.mature.blk"
JohtoSouthIlexForestAzaleaGateBlocksEnd::
ASSERT JohtoSouthIlexForestAzaleaGateBlocksEnd - JohtoSouthIlexForestAzaleaGateBlocks == 20
JohtoSouthIlexForestAzaleaGateRuntimeHeader::
    db JOHTO_GATE
    db 4, 5
    dw JohtoSouthIlexForestAzaleaGateBlocks
    dw JohtoSouthIlexForestAzaleaGateTextPointers
    dw JohtoSouthScript
    db 0 ; no map seams until reviewed/registered independently
    dw JohtoSouthIlexForestAzaleaGateRuntimeObjects
JohtoSouthIlexForestAzaleaGateHeaderEnd::
ASSERT JohtoSouthIlexForestAzaleaGateHeaderEnd - JohtoSouthIlexForestAzaleaGateRuntimeHeader == 12
ASSERT BANK(JohtoSouthIlexForestAzaleaGateRuntimeHeader) == BANK(JohtoSouthIlexForestAzaleaGateBlocks)
JohtoSouthIlexForestAzaleaGateTextPointers:
JohtoSouthIlexForestAzaleaGateRuntimeObjects::
    db $0d ; NPC-243: black boundary metatile in shared JOHTO_GATE blocks
    db 4
    db 4, 0, 1, JOHTO_REGISTERED_WARP_SELECTOR ; Gold #1 -> IlexForest #2
    db 5, 0, 2, JOHTO_REGISTERED_WARP_SELECTOR ; Gold #2 -> IlexForest #3
    db 4, 9, 0, JOHTO_REGISTERED_WARP_SELECTOR ; Gold #3 -> AzaleaTown #7
    db 5, 9, 1, JOHTO_REGISTERED_WARP_SELECTOR ; Gold #4 -> AzaleaTown #8
    db 0 ; unregistered signs excluded
    db 0 ; trainer/story encounters excluded

JohtoSouthIlexForestBlocks:: INCBIN "maps/johto_pilot/IlexForest.runtime.blk"
JohtoSouthIlexForestBlocksEnd::
ASSERT JohtoSouthIlexForestBlocksEnd - JohtoSouthIlexForestBlocks == 405
JohtoSouthIlexForestRuntimeHeader::
    db JOHTO_ILEX_FOREST
    db 27, 15
    dw JohtoSouthIlexForestBlocks
    dw JohtoSouthIlexForestTextPointers
    dw JohtoSouthScript
    db 0 ; no map seams until reviewed/registered independently
    dw JohtoSouthIlexForestRuntimeObjects
JohtoSouthIlexForestHeaderEnd::
ASSERT JohtoSouthIlexForestHeaderEnd - JohtoSouthIlexForestRuntimeHeader == 12
ASSERT BANK(JohtoSouthIlexForestRuntimeHeader) == BANK(JohtoSouthIlexForestBlocks)
JohtoSouthIlexForestTextPointers:
JohtoSouthIlexForestRuntimeObjects::
    db $00 ; Gold map border, movement guarded by exact spatial mask
    db 3
    db 5, 1, 2, JOHTO_REGISTERED_WARP_SELECTOR ; Gold #1 -> Route34IlexForestGate #3
    db 42, 3, 0, JOHTO_REGISTERED_WARP_SELECTOR ; Gold #2 -> IlexForestAzaleaGate #1
    db 43, 3, 1, JOHTO_REGISTERED_WARP_SELECTOR ; Gold #3 -> IlexForestAzaleaGate #2
    db 0 ; unregistered signs excluded
    db 0 ; trainer/story encounters excluded

JohtoSouthRoute34IlexForestGateBlocks:: INCBIN "maps/johto_pilot/Route34IlexForestGate.mature.blk"
JohtoSouthRoute34IlexForestGateBlocksEnd::
ASSERT JohtoSouthRoute34IlexForestGateBlocksEnd - JohtoSouthRoute34IlexForestGateBlocks == 20
JohtoSouthRoute34IlexForestGateRuntimeHeader::
    db JOHTO_GATE
    db 4, 5
    dw JohtoSouthRoute34IlexForestGateBlocks
    dw JohtoSouthRoute34IlexForestGateTextPointers
    dw JohtoSouthScript
    db 0 ; no map seams until reviewed/registered independently
    dw JohtoSouthRoute34IlexForestGateRuntimeObjects
JohtoSouthRoute34IlexForestGateHeaderEnd::
ASSERT JohtoSouthRoute34IlexForestGateHeaderEnd - JohtoSouthRoute34IlexForestGateRuntimeHeader == 12
ASSERT BANK(JohtoSouthRoute34IlexForestGateRuntimeHeader) == BANK(JohtoSouthRoute34IlexForestGateBlocks)
JohtoSouthRoute34IlexForestGateTextPointers:
JohtoSouthRoute34IlexForestGateRuntimeObjects::
    db $0d ; NPC-243: black boundary metatile in shared JOHTO_GATE blocks
    db 4
    db 0, 4, 0, JOHTO_REGISTERED_WARP_SELECTOR ; Gold #1 -> Route34 #1
    db 0, 5, 1, JOHTO_REGISTERED_WARP_SELECTOR ; Gold #2 -> Route34 #2
    db 7, 4, 0, JOHTO_REGISTERED_WARP_SELECTOR ; Gold #3 -> IlexForest #1
    db 7, 5, 0, JOHTO_REGISTERED_WARP_SELECTOR ; Gold #4 -> IlexForest #1
    db 0 ; unregistered signs excluded
    db 0 ; trainer/story encounters excluded

JohtoSouthRoute34Blocks:: INCBIN "maps/johto_pilot/Route34.runtime.blk"
JohtoSouthRoute34BlocksEnd::
ASSERT JohtoSouthRoute34BlocksEnd - JohtoSouthRoute34Blocks == 270
JohtoSouthRoute34RuntimeHeader::
    db JOHTO_MODERN
    db 27, 10
    dw JohtoSouthRoute34Blocks
    dw JohtoSouthRoute34TextPointers
    dw JohtoSouthScript
    db NORTH
    db JOHTO_RUNTIME_MAP_HANDLE
    dw JohtoSouthGoldenrodCityBlocks + 20 * (18 - 3) + 5
    dw wOverworldMap + 3
    db 10
    db 20
    db 35
    db 10
    dw wOverworldMap + 1 + 18 * (20 + 6)
    dw JohtoSouthRoute34RuntimeObjects
JohtoSouthRoute34HeaderEnd::
ASSERT JohtoSouthRoute34HeaderEnd - JohtoSouthRoute34RuntimeHeader == 23
ASSERT BANK(JohtoSouthRoute34RuntimeHeader) == BANK(JohtoSouthRoute34Blocks)
JohtoSouthRoute34TextPointers:
JohtoSouthRoute34RuntimeObjects::
    db $05 ; FIX-279: Gold Route34 outdoor border is trees, not blank $00
    db 2
    db 37, 13, 0, JOHTO_REGISTERED_WARP_SELECTOR ; Gold #1 -> Route34IlexForestGate #1
    db 37, 14, 1, JOHTO_REGISTERED_WARP_SELECTOR ; Gold #2 -> Route34IlexForestGate #2
    db 0 ; unregistered signs excluded
    db 0 ; trainer/story encounters excluded

JohtoSouthGoldenrodCityBlocks:: INCBIN "maps/johto_pilot/GoldenrodCity.runtime.blk"
JohtoSouthGoldenrodCityBlocksEnd::
ASSERT JohtoSouthGoldenrodCityBlocksEnd - JohtoSouthGoldenrodCityBlocks == 360
JohtoSouthGoldenrodCityRuntimeHeader::
    db JOHTO_MODERN
    db 18, 20
    dw JohtoSouthGoldenrodCityBlocks
    dw JohtoSouthGoldenrodCityTextPointers
    dw JohtoSouthScript
    db SOUTH
    db JOHTO_RUNTIME_MAP_HANDLE
    dw JohtoSouthRoute34Blocks
    dw wOverworldMap + (18 + 3) * (20 + 6) + 3 + 5
    db 10
    db 10
    db 0
    db -10
    dw wOverworldMap + 7 + 10
    dw JohtoSouthGoldenrodCityRuntimeObjects
JohtoSouthGoldenrodCityHeaderEnd::
ASSERT JohtoSouthGoldenrodCityHeaderEnd - JohtoSouthGoldenrodCityRuntimeHeader == 23
ASSERT BANK(JohtoSouthGoldenrodCityRuntimeHeader) == BANK(JohtoSouthGoldenrodCityBlocks)
JohtoSouthGoldenrodCityTextPointers:
JohtoSouthGoldenrodCityRuntimeObjects::
    db $35 ; NPC-243 accepted Gold Goldenrod outdoor border
    db 1
    db 1, 19, 2, JOHTO_REGISTERED_WARP_SELECTOR ; Gold #13 -> Route35GoldenrodGate #3
    db 0 ; unregistered signs excluded
    db 0 ; trainer/story encounters excluded
JohtoSouthScript::
    call EnableAutoTextBoxDrawing
    ret
