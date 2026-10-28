; P2-004: source-authentic Gold pilot map geometry, NOT live Kanto mapconst IDs.
; These immutable source records preserve the original Gold map blocks. The
; eight directed source-authentic connections feed the region-aware four-direction
; dispatcher; runtime blocks and headers remain separate in bank $43.
; Format: region (1), stable ID (1), width (1), height (1), source .blk ptr (2), ROM bank (1).
DEF JOHTO_PILOT_SOURCE_COUNT EQU 8
DEF JOHTO_PILOT_SOURCE_RECORD_BYTES EQU 7
DEF JOHTO_PILOT_SOURCE_CONNECTION_COUNT EQU 10
DEF JOHTO_PILOT_CONNECTION_BYTES EQU 5
DEF JOHTO_PILOT_SOURCE_BANK EQU $42
ASSERT NUM_JOHTO_ACTIVE_MAPS == JOHTO_PILOT_SOURCE_COUNT
ASSERT JOHTO_NEW_BARK_LOCAL_ID == 0
ASSERT JOHTO_ROUTE_29_LOCAL_ID == 1

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
JohtoPilotSourceRecordsEnd::
ASSERT JohtoPilotSourceRecordsEnd - JohtoPilotSourceRecords == JOHTO_PILOT_SOURCE_COUNT * JOHTO_PILOT_SOURCE_RECORD_BYTES

; Region-aware adjacency registry, valid for WEST/EAST/NORTH/SOUTH.
; One row: source region, source local ID (Kanto mapconst for Kanto), direction,
; target region, target local ID. Four bidirectional seams are active.
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
