; P2-004: source-authentic Gold pilot map geometry, NOT live Kanto mapconst IDs.
; Descriptors here are SOURCE records for the two-map pilot. They are not
; JohtoHeaderDescriptors (which remain empty while NUM_JOHTO_ACTIVE_MAPS=0).
; Format: region (1), stable ID (1), width (1), height (1), source .blk ptr (2), ROM bank (1).
; Native Johto map headers, events and boundary/warp dispatch must be ported
; together before activating a map; do not route the engine to this table.
DEF JOHTO_PILOT_SOURCE_COUNT EQU 2
DEF JOHTO_PILOT_SOURCE_RECORD_BYTES EQU 7
DEF JOHTO_PILOT_SOURCE_BANK EQU $42
ASSERT NUM_JOHTO_ACTIVE_MAPS == 0
ASSERT JOHTO_NEW_BARK_LOCAL_ID == 0
ASSERT JOHTO_ROUTE_29_LOCAL_ID == 1

JohtoPilotSourceRecords::
    db MAP_REGION_JOHTO, JOHTO_NEW_BARK_LOCAL_ID, 10, 9
    dw JohtoPilotNewBarkGoldBlocks
    db BANK(JohtoPilotNewBarkGoldBlocks)
    db MAP_REGION_JOHTO, JOHTO_ROUTE_29_LOCAL_ID, 30, 9
    dw JohtoPilotRoute29GoldBlocks
    db BANK(JohtoPilotRoute29GoldBlocks)
JohtoPilotSourceRecordsEnd::
ASSERT JohtoPilotSourceRecordsEnd - JohtoPilotSourceRecords == JOHTO_PILOT_SOURCE_COUNT * JOHTO_PILOT_SOURCE_RECORD_BYTES

; Source-native east/west adjacency (NO old $E7/$F4 aliases).
; Format: source stable ID, exit direction (WEST/EAST), target stable ID.
JohtoPilotSourceConnections::
    db JOHTO_NEW_BARK_LOCAL_ID, WEST, JOHTO_ROUTE_29_LOCAL_ID
    db JOHTO_ROUTE_29_LOCAL_ID, EAST, JOHTO_NEW_BARK_LOCAL_ID
JohtoPilotSourceConnectionsEnd::
ASSERT JohtoPilotSourceConnectionsEnd - JohtoPilotSourceConnections == 2 * 3

JohtoPilotNewBarkGoldBlocks::
    INCBIN "maps/johto_pilot/NewBarkTown.gold.blk"
JohtoPilotNewBarkGoldBlocksEnd::
ASSERT JohtoPilotNewBarkGoldBlocksEnd - JohtoPilotNewBarkGoldBlocks == 10 * 9
JohtoPilotRoute29GoldBlocks::
    INCBIN "maps/johto_pilot/Route29.gold.blk"
JohtoPilotRoute29GoldBlocksEnd::
ASSERT JohtoPilotRoute29GoldBlocksEnd - JohtoPilotRoute29GoldBlocks == 30 * 9

; Original GSC Johto 4x4-tile metatiles: kept intact for later gfx mapping.
; This is NOT the RGBDS/RPP tileset header, collision or sprite implementation.
JohtoPilotGoldMetatiles::
    INCBIN "data/johto_pilot/johto_metatiles.gold.bin"
JohtoPilotGoldMetatilesEnd::
ASSERT JohtoPilotGoldMetatilesEnd - JohtoPilotGoldMetatiles == $800
ASSERT BANK(JohtoPilotNewBarkGoldBlocks) == JOHTO_PILOT_SOURCE_BANK
ASSERT BANK(JohtoPilotRoute29GoldBlocks) == JOHTO_PILOT_SOURCE_BANK
