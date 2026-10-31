; P2-004: source-authentic Gold pilot map geometry, NOT live Kanto mapconst IDs.
; These immutable source records preserve the original Gold map blocks. The
; twelve directed source-authentic connections feed the region-aware four-direction
; dispatcher (the Route31/Violet outdoor seam is preview-only; the gate uses
; registered Warps). Runtime blocks and headers remain separate in bank $43.
; Format: region (1), stable ID (1), width (1), height (1), source .blk ptr (2), ROM bank (1).
DEF JOHTO_PILOT_SOURCE_COUNT EQU 21
DEF JOHTO_PILOT_SOURCE_RECORD_BYTES EQU 7
DEF JOHTO_PILOT_SOURCE_CONNECTION_COUNT EQU 16
DEF JOHTO_PILOT_CONNECTION_BYTES EQU 5
DEF JOHTO_PILOT_SOURCE_BANK EQU $42
ASSERT NUM_JOHTO_ACTIVE_MAPS == JOHTO_PILOT_SOURCE_COUNT
ASSERT JOHTO_NEW_BARK_LOCAL_ID == 0
ASSERT JOHTO_ROUTE_29_LOCAL_ID == 1

JohtoSouthAzaleaTownGoldBlocks::
    INCBIN "maps/johto_pilot/AzaleaTown.gold.blk"
JohtoSouthIlexForestAzaleaGateGoldBlocks::
    INCBIN "maps/johto_pilot/IlexForestAzaleaGate.gold.blk"
JohtoSouthIlexForestGoldBlocks::
    INCBIN "maps/johto_pilot/IlexForest.gold.blk"
JohtoSouthRoute34IlexForestGateGoldBlocks::
    INCBIN "maps/johto_pilot/Route34IlexForestGate.gold.blk"
JohtoSouthRoute34GoldBlocks::
    INCBIN "maps/johto_pilot/Route34.gold.blk"
JohtoSouthGoldenrodCityGoldBlocks::
    INCBIN "maps/johto_pilot/GoldenrodCity.gold.blk"

JohtoPilotSourceRecords::
    db MAP_REGION_JOHTO, JOHTO_NEW_BARK_LOCAL_ID, 10, 9
    dw JohtoPilotNewBarkGoldBlocks
    db BANK(JohtoPilotNewBarkGoldBlocks)
    db MAP_REGION_JOHTO, JOHTO_ROUTE_29_LOCAL_ID, 30, 9
    dw JohtoPilotRoute29GoldBlocks
    db BANK(JohtoPilotRoute29GoldBlocks)
    db MAP_REGION_JOHTO, JOHTO_CHERRYGROVE_LOCAL_ID, 20, 9
    dw JohtoPilotCherrygroveGoldBlocks
    db BANK(JohtoPilotCherrygroveGoldBlocks)
    db MAP_REGION_JOHTO, JOHTO_ROUTE_30_LOCAL_ID, JOHTO_ROUTE_30_WIDTH, JOHTO_ROUTE_30_HEIGHT
    dw JohtoPilotRoute30GoldBlocks
    db BANK(JohtoPilotRoute30GoldBlocks)
    db MAP_REGION_JOHTO, JOHTO_ROUTE_31_LOCAL_ID, JOHTO_ROUTE_31_WIDTH, JOHTO_ROUTE_31_HEIGHT
    dw JohtoPilotRoute31GoldBlocks
    db BANK(JohtoPilotRoute31GoldBlocks)
    ; Source verified against provided reference branch: Gold GuideGentsHouse, 4x4.
    db MAP_REGION_JOHTO, JOHTO_GUIDE_GENTS_HOUSE_LOCAL_ID, JOHTO_GUIDE_GENTS_HOUSE_WIDTH, JOHTO_GUIDE_GENTS_HOUSE_HEIGHT
    dw JohtoGuideGentsHouseSourceBlocks
    db BANK(JohtoGuideGentsHouseSourceBlocks)
    db MAP_REGION_JOHTO, JOHTO_VIOLET_CITY_LOCAL_ID, JOHTO_VIOLET_CITY_WIDTH, JOHTO_VIOLET_CITY_HEIGHT
    dw JohtoPilotVioletGoldBlocks
    db BANK(JohtoPilotVioletGoldBlocks)
    db MAP_REGION_JOHTO, JOHTO_ROUTE31_VIOLET_GATE_LOCAL_ID, JOHTO_ROUTE31_VIOLET_GATE_WIDTH, JOHTO_ROUTE31_VIOLET_GATE_HEIGHT
    dw JohtoPilotVioletGateGoldBlocks
    db BANK(JohtoPilotVioletGateGoldBlocks)
    db MAP_REGION_JOHTO, JOHTO_ROUTE_32_LOCAL_ID, JOHTO_ROUTE_32_WIDTH, JOHTO_ROUTE_32_HEIGHT
    dw JohtoPilotRoute32GoldBlocks
    db BANK(JohtoPilotRoute32GoldBlocks)
    db MAP_REGION_JOHTO, JOHTO_ROUTE_32_RUINS_OF_ALPH_GATE_LOCAL_ID, JOHTO_ROUTE32_RUINS_GATE_WIDTH, JOHTO_ROUTE32_RUINS_GATE_HEIGHT
    dw JohtoPilotAlphSouthGateGoldBlocks
    db BANK(JohtoPilotAlphSouthGateGoldBlocks)
    db MAP_REGION_JOHTO, JOHTO_RUINS_OF_ALPH_LOCAL_ID, JOHTO_RUINS_OF_ALPH_WIDTH, JOHTO_RUINS_OF_ALPH_HEIGHT
    dw JohtoPilotAlphOutsideGoldBlocks
    db BANK(JohtoPilotAlphOutsideGoldBlocks)
    db MAP_REGION_JOHTO, JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID, JOHTO_ROUTE36_RUINS_GATE_WIDTH, JOHTO_ROUTE36_RUINS_GATE_HEIGHT
    dw JohtoPilotAlphNorthGateGoldBlocks
    db BANK(JohtoPilotAlphNorthGateGoldBlocks)
    db MAP_REGION_JOHTO, JOHTO_ROUTE_36_LOCAL_ID, JOHTO_ROUTE_36_WIDTH, JOHTO_ROUTE_36_HEIGHT
    dw JohtoPilotRoute36GoldBlocks
    db BANK(JohtoPilotRoute36GoldBlocks)
    ; Gold original bytes must not be confused with the compact runtime block indexes.
    db MAP_REGION_JOHTO, JOHTO_UNION_CAVE_1F_LOCAL_ID, JOHTO_UNION_CAVE_1F_WIDTH, JOHTO_UNION_CAVE_1F_HEIGHT
    dw JohtoUnionCave1FGoldBlocks
    db BANK(JohtoUnionCave1FGoldBlocks)
    db MAP_REGION_JOHTO, JOHTO_ROUTE_33_LOCAL_ID, JOHTO_ROUTE_33_WIDTH, JOHTO_ROUTE_33_HEIGHT
    dw JohtoRoute33GoldBlocks
    db BANK(JohtoRoute33GoldBlocks)
    db MAP_REGION_JOHTO, JOHTO_AZALEA_TOWN_LOCAL_ID, 20, 9
    dw JohtoSouthAzaleaTownGoldBlocks
    db BANK(JohtoSouthAzaleaTownGoldBlocks)
    db MAP_REGION_JOHTO, JOHTO_ILEX_AZALEA_GATE_LOCAL_ID, 5, 4
    dw JohtoSouthIlexForestAzaleaGateGoldBlocks
    db BANK(JohtoSouthIlexForestAzaleaGateGoldBlocks)
    db MAP_REGION_JOHTO, JOHTO_ILEX_FOREST_LOCAL_ID, 15, 27
    dw JohtoSouthIlexForestGoldBlocks
    db BANK(JohtoSouthIlexForestGoldBlocks)
    db MAP_REGION_JOHTO, JOHTO_ROUTE34_ILEX_GATE_LOCAL_ID, 5, 4
    dw JohtoSouthRoute34IlexForestGateGoldBlocks
    db BANK(JohtoSouthRoute34IlexForestGateGoldBlocks)
    db MAP_REGION_JOHTO, JOHTO_ROUTE_34_LOCAL_ID, 10, 27
    dw JohtoSouthRoute34GoldBlocks
    db BANK(JohtoSouthRoute34GoldBlocks)
    db MAP_REGION_JOHTO, JOHTO_GOLDENROD_CITY_LOCAL_ID, 20, 18
    dw JohtoSouthGoldenrodCityGoldBlocks
    db BANK(JohtoSouthGoldenrodCityGoldBlocks)
JohtoPilotSourceRecordsEnd::
ASSERT JohtoPilotSourceRecordsEnd - JohtoPilotSourceRecords == JOHTO_PILOT_SOURCE_COUNT * JOHTO_PILOT_SOURCE_RECORD_BYTES

; Region-aware adjacency registry, valid for WEST/EAST/NORTH/SOUTH.
; One row: source region, source local ID (Kanto mapconst for Kanto), direction,
; target region, target local ID. Six bidirectional pairs are registered,
; including the preview-only Route31/Violet outdoor seam.
; A future Kanto↔Johto seam must be explicitly registered both ways.
JohtoPilotSourceConnections::
    db MAP_REGION_JOHTO, JOHTO_NEW_BARK_LOCAL_ID, WEST, MAP_REGION_JOHTO, JOHTO_ROUTE_29_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_29_LOCAL_ID, EAST, MAP_REGION_JOHTO, JOHTO_NEW_BARK_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_29_LOCAL_ID, WEST, MAP_REGION_JOHTO, JOHTO_CHERRYGROVE_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_CHERRYGROVE_LOCAL_ID, EAST, MAP_REGION_JOHTO, JOHTO_ROUTE_29_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_CHERRYGROVE_LOCAL_ID, NORTH, MAP_REGION_JOHTO, JOHTO_ROUTE_30_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_30_LOCAL_ID, SOUTH, MAP_REGION_JOHTO, JOHTO_CHERRYGROVE_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_30_LOCAL_ID, NORTH, MAP_REGION_JOHTO, JOHTO_ROUTE_31_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_31_LOCAL_ID, SOUTH, MAP_REGION_JOHTO, JOHTO_ROUTE_30_LOCAL_ID
    ; Preview seam is structurally registered but direction-movement remains
    ; blocked by JohtoPilotIsClosedOutdoorEdge; passage uses gate collision Warps.
    db MAP_REGION_JOHTO, JOHTO_ROUTE_31_LOCAL_ID, WEST, MAP_REGION_JOHTO, JOHTO_VIOLET_CITY_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_VIOLET_CITY_LOCAL_ID, EAST, MAP_REGION_JOHTO, JOHTO_ROUTE_31_LOCAL_ID
    ; Gold south/north seam (offset 0); only lane x14/15 is traversable.
    db MAP_REGION_JOHTO, JOHTO_VIOLET_CITY_LOCAL_ID, SOUTH, MAP_REGION_JOHTO, JOHTO_ROUTE_32_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_32_LOCAL_ID, NORTH, MAP_REGION_JOHTO, JOHTO_VIOLET_CITY_LOCAL_ID
    ; Route33/Azalea and Route34/Goldenrod are same-tileset Gold seams.
    db MAP_REGION_JOHTO, JOHTO_ROUTE_33_LOCAL_ID, WEST, MAP_REGION_JOHTO, JOHTO_AZALEA_TOWN_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_AZALEA_TOWN_LOCAL_ID, EAST, MAP_REGION_JOHTO, JOHTO_ROUTE_33_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_34_LOCAL_ID, NORTH, MAP_REGION_JOHTO, JOHTO_GOLDENROD_CITY_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_GOLDENROD_CITY_LOCAL_ID, SOUTH, MAP_REGION_JOHTO, JOHTO_ROUTE_34_LOCAL_ID
JohtoPilotSourceConnectionsEnd::
ASSERT JohtoPilotSourceConnectionsEnd - JohtoPilotSourceConnections == JOHTO_PILOT_SOURCE_CONNECTION_COUNT * JOHTO_PILOT_CONNECTION_BYTES

JohtoPilotNewBarkGoldBlocks::
    INCBIN "maps/johto_pilot/NewBarkTown.gold.blk"
JohtoPilotNewBarkGoldBlocksEnd::
ASSERT JohtoPilotNewBarkGoldBlocksEnd - JohtoPilotNewBarkGoldBlocks == 10 * 9
JohtoPilotRoute29GoldBlocks::
    INCBIN "maps/johto_pilot/Route29.gold.blk"
JohtoPilotRoute29GoldBlocksEnd::
ASSERT JohtoPilotRoute29GoldBlocksEnd - JohtoPilotRoute29GoldBlocks == 30 * 9
JohtoPilotCherrygroveGoldBlocks::
    INCBIN "maps/johto_pilot/CherrygroveCity.gold.blk"
JohtoPilotCherrygroveGoldBlocksEnd::
ASSERT JohtoPilotCherrygroveGoldBlocksEnd - JohtoPilotCherrygroveGoldBlocks == 20 * 9
JohtoPilotRoute30GoldBlocks::
    INCBIN "maps/johto_pilot/Route30.gold.blk"
JohtoPilotRoute30GoldBlocksEnd::
ASSERT JohtoPilotRoute30GoldBlocksEnd - JohtoPilotRoute30GoldBlocks == JOHTO_ROUTE_30_WIDTH * JOHTO_ROUTE_30_HEIGHT
JohtoPilotRoute31GoldBlocks::
    INCBIN "maps/johto_pilot/Route31.gold.blk"
JohtoPilotRoute31GoldBlocksEnd::
ASSERT JohtoPilotRoute31GoldBlocksEnd - JohtoPilotRoute31GoldBlocks == JOHTO_ROUTE_31_WIDTH * JOHTO_ROUTE_31_HEIGHT

JohtoGuideGentsHouseSourceBlocks::
    INCBIN "maps/johto_pilot/GuideGentsHouse.reference.blk"
JohtoGuideGentsHouseSourceBlocksEnd::
JohtoPilotVioletGoldBlocks::
    INCBIN "maps/johto_pilot/VioletCity.gold.blk"
JohtoPilotVioletGoldBlocksEnd::
ASSERT JohtoPilotVioletGoldBlocksEnd - JohtoPilotVioletGoldBlocks == JOHTO_VIOLET_CITY_WIDTH * JOHTO_VIOLET_CITY_HEIGHT
JohtoPilotVioletGateGoldBlocks::
    INCBIN "maps/johto_pilot/Route31VioletGate.gold.blk"
JohtoPilotVioletGateGoldBlocksEnd::
JohtoPilotRoute32GoldBlocks::
    INCBIN "maps/johto_pilot/Route32.gold.blk"
JohtoPilotRoute32GoldBlocksEnd::
JohtoPilotAlphSouthGateGoldBlocks::
    INCBIN "maps/johto_pilot/Route32RuinsOfAlphGate.gold.blk"
JohtoPilotAlphSouthGateGoldBlocksEnd::
JohtoPilotAlphOutsideGoldBlocks::
    INCBIN "maps/johto_pilot/RuinsOfAlphOutside.gold.blk"
JohtoPilotAlphOutsideGoldBlocksEnd::
JohtoPilotAlphNorthGateGoldBlocks::
    INCBIN "maps/johto_pilot/Route36RuinsOfAlphGate.gold.blk"
JohtoPilotAlphNorthGateGoldBlocksEnd::
JohtoPilotRoute36GoldBlocks::
    INCBIN "maps/johto_pilot/Route36.gold.blk"
JohtoPilotRoute36GoldBlocksEnd::
ASSERT JohtoPilotAlphNorthGateGoldBlocksEnd - JohtoPilotAlphNorthGateGoldBlocks == 5 * 4
ASSERT JohtoPilotRoute36GoldBlocksEnd - JohtoPilotRoute36GoldBlocks == 30 * 9
ASSERT JohtoPilotAlphSouthGateGoldBlocksEnd - JohtoPilotAlphSouthGateGoldBlocks == JOHTO_ROUTE32_RUINS_GATE_WIDTH * JOHTO_ROUTE32_RUINS_GATE_HEIGHT
ASSERT JohtoPilotAlphOutsideGoldBlocksEnd - JohtoPilotAlphOutsideGoldBlocks == JOHTO_RUINS_OF_ALPH_WIDTH * JOHTO_RUINS_OF_ALPH_HEIGHT
ASSERT JohtoPilotRoute32GoldBlocksEnd - JohtoPilotRoute32GoldBlocks == JOHTO_ROUTE_32_WIDTH * JOHTO_ROUTE_32_HEIGHT
ASSERT JohtoPilotVioletGateGoldBlocksEnd - JohtoPilotVioletGateGoldBlocks == JOHTO_ROUTE31_VIOLET_GATE_WIDTH * JOHTO_ROUTE31_VIOLET_GATE_HEIGHT
ASSERT JohtoGuideGentsHouseSourceBlocksEnd - JohtoGuideGentsHouseSourceBlocks == JOHTO_GUIDE_GENTS_HOUSE_WIDTH * JOHTO_GUIDE_GENTS_HOUSE_HEIGHT
ASSERT BANK(JohtoGuideGentsHouseSourceBlocks) == JOHTO_PILOT_SOURCE_BANK

; Original GSC Johto 4x4-tile metatiles: kept intact for later gfx mapping.
; This is NOT the RGBDS/RPP tileset header, collision or sprite implementation.
JohtoPilotGoldMetatiles::
    INCBIN "data/johto_pilot/johto_metatiles.gold.bin"
JohtoPilotGoldMetatilesEnd::
ASSERT JohtoPilotGoldMetatilesEnd - JohtoPilotGoldMetatiles == $800
ASSERT BANK(JohtoPilotNewBarkGoldBlocks) == JOHTO_PILOT_SOURCE_BANK
ASSERT BANK(JohtoPilotRoute29GoldBlocks) == JOHTO_PILOT_SOURCE_BANK
ASSERT BANK(JohtoPilotCherrygroveGoldBlocks) == JOHTO_PILOT_SOURCE_BANK
ASSERT BANK(JohtoPilotRoute30GoldBlocks) == JOHTO_PILOT_SOURCE_BANK
ASSERT BANK(JohtoPilotRoute31GoldBlocks) == JOHTO_PILOT_SOURCE_BANK

JohtoUnionCave1FGoldBlocks::
    INCBIN "maps/johto_pilot/UnionCave1F.gold.blk"
JohtoUnionCave1FGoldBlocksEnd::
ASSERT JohtoUnionCave1FGoldBlocksEnd - JohtoUnionCave1FGoldBlocks == JOHTO_UNION_CAVE_1F_WIDTH * JOHTO_UNION_CAVE_1F_HEIGHT

; Gold source original Route33 uses JOHTO_MODERN, never JOHTO_PILOT.
JohtoRoute33GoldBlocks::
    INCBIN "maps/johto_pilot/Route33.gold.blk"
JohtoRoute33GoldBlocksEnd::
ASSERT JohtoRoute33GoldBlocksEnd - JohtoRoute33GoldBlocks == JOHTO_ROUTE_33_WIDTH * JOHTO_ROUTE_33_HEIGHT
