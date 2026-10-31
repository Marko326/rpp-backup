; P2-005 / P3-001: executable-format graphics and blocks for the two-map pilot,
; isolated from untouched, byte-authentic Gold source data in bank $42.
; The adjusted runtime blocks use the Johto metatile mapping, never legacy Kanto IDs.
DEF JOHTO_PILOT_RUNTIME_RECORD_SIZE EQU 7
DEF JOHTO_PILOT_TILESET_ID EQU JOHTO_PILOT
ASSERT JOHTO_PILOT == 28
; P5-002 activates five source-audited outdoor maps; other stable IDs remain gated.
ASSERT JOHTO_NEW_BARK_LOCAL_ID == 0
ASSERT JOHTO_ROUTE_29_LOCAL_ID == 1
ASSERT NUM_JOHTO_ACTIVE_MAPS == 28

JohtoPilot_GFX:: INCBIN "gfx/tilesets/johto.2bpp"
JohtoPilot_Block:: INCBIN "gfx/blocksets/johto.bst"
; New block $8D: clone source Gold $63 but replace only the bottom-left
; 16x16 CUT_TREE with ordinary FLOOR tile $05. Bottom-right HEADBUTT
; pixels stay exactly unchanged. Never alter the original 141-block bst.
JohtoPilotVioletCutClearedBlock::
	db $05, $05, $05, $05, $05, $05, $05, $05
	db $05, $05, $1e, $1f, $05, $05, $3e, $3f
; ROUTES-251: three single-quadrant Cut replacements. Every other 8x8
; tile is byte-identical to Gold. $05 is the existing ordinary FLOOR art.
; Block $8E: original $67, Route30 top-left CUT_TREE -> FLOOR
JohtoPilotCutClearedBlock8E::
	db $05, $05, $05, $05, $05, $05, $05, $05
	db $1e, $1f, $05, $05, $3e, $3f, $05, $05
; Block $8F: original $5F, Route31 bottom-right CUT_TREE -> FLOOR
JohtoPilotCutClearedBlock8F::
	db $05, $05, $1e, $1f, $05, $05, $3e, $3f
	db $05, $05, $05, $05, $05, $05, $05, $05
; Block $90: original $5B, Route31 top-right CUT_TREE -> FLOOR
JohtoPilotCutClearedBlock90::
	db $1e, $1f, $05, $05, $3e, $3f, $05, $05
	db $05, $05, $05, $05, $05, $05, $05, $05
JohtoPilot_BlockEnd::
ASSERT JohtoPilot_BlockEnd - JohtoPilot_Block == 145 * 16

; P6-INDOOR-005: JohtoPilot_Coll now lives in ROM0 (home.asm).
; Switchable-bank pointers were unsafe for unbanked collision readers.
ASSERT BANK(JohtoPilot_Coll) == 0

JohtoPilotNewBarkRuntimeBlocks::
    INCBIN "maps/johto_pilot/NewBarkTown.runtime.blk"
JohtoPilotNewBarkRuntimeBlocksEnd::
ASSERT JohtoPilotNewBarkRuntimeBlocksEnd - JohtoPilotNewBarkRuntimeBlocks == 10 * 9

JohtoPilotRoute29RuntimeBlocks::
    INCBIN "maps/johto_pilot/Route29.runtime.blk"
JohtoPilotRoute29RuntimeBlocksEnd::
ASSERT JohtoPilotRoute29RuntimeBlocksEnd - JohtoPilotRoute29RuntimeBlocks == 30 * 9

JohtoPilotCherrygroveRuntimeBlocks::
    INCBIN "maps/johto_pilot/CherrygroveCity.runtime.blk"
JohtoPilotCherrygroveRuntimeBlocksEnd::
ASSERT JohtoPilotCherrygroveRuntimeBlocksEnd - JohtoPilotCherrygroveRuntimeBlocks == JOHTO_CHERRYGROVE_WIDTH * JOHTO_CHERRYGROVE_HEIGHT

JohtoPilotRoute30RuntimeBlocks::
    INCBIN "maps/johto_pilot/Route30.runtime.blk"
JohtoPilotRoute30RuntimeBlocksEnd::
ASSERT JohtoPilotRoute30RuntimeBlocksEnd - JohtoPilotRoute30RuntimeBlocks == JOHTO_ROUTE_30_WIDTH * JOHTO_ROUTE_30_HEIGHT
JohtoPilotRoute31RuntimeBlocks::
    INCBIN "maps/johto_pilot/Route31.runtime.blk"
JohtoPilotRoute31RuntimeBlocksEnd::
ASSERT JohtoPilotRoute31RuntimeBlocksEnd - JohtoPilotRoute31RuntimeBlocks == JOHTO_ROUTE_31_WIDTH * JOHTO_ROUTE_31_HEIGHT

JohtoPilotRoute32RuntimeBlocks::
    INCBIN "maps/johto_pilot/Route32.runtime.blk"
JohtoPilotRoute32RuntimeBlocksEnd::
ASSERT JohtoPilotRoute32RuntimeBlocksEnd - JohtoPilotRoute32RuntimeBlocks == JOHTO_ROUTE_32_WIDTH * JOHTO_ROUTE_32_HEIGHT

JohtoPilotVioletRuntimeBlocks::
    INCBIN "maps/johto_pilot/VioletCity.runtime.blk"
JohtoPilotVioletRuntimeBlocksEnd::
ASSERT JohtoPilotVioletRuntimeBlocksEnd - JohtoPilotVioletRuntimeBlocks == JOHTO_VIOLET_CITY_WIDTH * JOHTO_VIOLET_CITY_HEIGHT

; Stable physical ID, registered tileset ID, width, height, block pointer, block bank.
; Not a map Header: no event, connection, Warp, sprite or collision fence
; may be enabled merely because a resource row appears here.
JohtoPilotRuntimeResourceDescriptors::
JohtoPilotNewBarkRuntimeDescriptor::
    db JOHTO_NEW_BARK_LOCAL_ID, JOHTO_PILOT_TILESET_ID, 10, 9
    dw JohtoPilotNewBarkRuntimeBlocks
    db BANK(JohtoPilotNewBarkRuntimeBlocks)
JohtoPilotRoute29RuntimeDescriptor::
    db JOHTO_ROUTE_29_LOCAL_ID, JOHTO_PILOT_TILESET_ID, 30, 9
    dw JohtoPilotRoute29RuntimeBlocks
    db BANK(JohtoPilotRoute29RuntimeBlocks)
JohtoPilotCherrygroveRuntimeDescriptor::
    db JOHTO_CHERRYGROVE_LOCAL_ID, JOHTO_PILOT_TILESET_ID, 20, 9
    dw JohtoPilotCherrygroveRuntimeBlocks
    db BANK(JohtoPilotCherrygroveRuntimeBlocks)
JohtoPilotRoute30RuntimeDescriptor::
    db JOHTO_ROUTE_30_LOCAL_ID, JOHTO_PILOT_TILESET_ID, JOHTO_ROUTE_30_WIDTH, JOHTO_ROUTE_30_HEIGHT
    dw JohtoPilotRoute30RuntimeBlocks
    db BANK(JohtoPilotRoute30RuntimeBlocks)
JohtoPilotRoute31RuntimeDescriptor::
    db JOHTO_ROUTE_31_LOCAL_ID, JOHTO_PILOT_TILESET_ID, JOHTO_ROUTE_31_WIDTH, JOHTO_ROUTE_31_HEIGHT
    dw JohtoPilotRoute31RuntimeBlocks
    db BANK(JohtoPilotRoute31RuntimeBlocks)
JohtoGuideGentsHouseRuntimeDescriptor::
    db JOHTO_GUIDE_GENTS_HOUSE_LOCAL_ID, JOHTO_HOUSE, JOHTO_GUIDE_GENTS_HOUSE_WIDTH, JOHTO_GUIDE_GENTS_HOUSE_HEIGHT
    dw JohtoGuideGentsHouseRuntimeBlocks
    db BANK(JohtoGuideGentsHouseRuntimeBlocks)
JohtoPilotVioletRuntimeDescriptor::
    db JOHTO_VIOLET_CITY_LOCAL_ID, JOHTO_PILOT_TILESET_ID, JOHTO_VIOLET_CITY_WIDTH, JOHTO_VIOLET_CITY_HEIGHT
    dw JohtoPilotVioletRuntimeBlocks
    db BANK(JohtoPilotVioletRuntimeBlocks)
JohtoPilotVioletGateRuntimeDescriptor::
    db JOHTO_ROUTE31_VIOLET_GATE_LOCAL_ID, JOHTO_GATE, JOHTO_ROUTE31_VIOLET_GATE_WIDTH, JOHTO_ROUTE31_VIOLET_GATE_HEIGHT
    dw JohtoPilotVioletGateRuntimeBlocks
    db BANK(JohtoPilotVioletGateRuntimeBlocks)
JohtoPilotRoute32RuntimeDescriptor::
    db JOHTO_ROUTE_32_LOCAL_ID, JOHTO_PILOT_TILESET_ID, JOHTO_ROUTE_32_WIDTH, JOHTO_ROUTE_32_HEIGHT
    dw JohtoPilotRoute32RuntimeBlocks
    db BANK(JohtoPilotRoute32RuntimeBlocks)
JohtoPilotAlphSouthGateRuntimeDescriptor::
    db JOHTO_ROUTE_32_RUINS_OF_ALPH_GATE_LOCAL_ID, JOHTO_GATE, JOHTO_ROUTE32_RUINS_GATE_WIDTH, JOHTO_ROUTE32_RUINS_GATE_HEIGHT
    dw JohtoPilotAlphSouthGateRuntimeBlocks
    db BANK(JohtoPilotAlphSouthGateRuntimeBlocks)
JohtoPilotAlphOutsideRuntimeDescriptor::
    db JOHTO_RUINS_OF_ALPH_LOCAL_ID, JOHTO_PILOT_TILESET_ID, JOHTO_RUINS_OF_ALPH_WIDTH, JOHTO_RUINS_OF_ALPH_HEIGHT
    dw JohtoPilotAlphOutsideRuntimeBlocks
    db BANK(JohtoPilotAlphOutsideRuntimeBlocks)
JohtoPilotAlphNorthGateRuntimeDescriptor::
    db JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID, JOHTO_GATE, JOHTO_ROUTE36_RUINS_GATE_WIDTH, JOHTO_ROUTE36_RUINS_GATE_HEIGHT
    dw JohtoPilotAlphNorthGateRuntimeBlocks
    db BANK(JohtoPilotAlphNorthGateRuntimeBlocks)
JohtoPilotRoute36RuntimeDescriptor::
    db JOHTO_ROUTE_36_LOCAL_ID, JOHTO_PILOT_TILESET_ID, JOHTO_ROUTE_36_WIDTH, JOHTO_ROUTE_36_HEIGHT
    dw JohtoPilotRoute36RuntimeBlocks
    db BANK(JohtoPilotRoute36RuntimeBlocks)
JohtoUnionCave1FRuntimeDescriptor::
    db JOHTO_UNION_CAVE_1F_LOCAL_ID, JOHTO_UNION_CAVE, JOHTO_UNION_CAVE_1F_WIDTH, JOHTO_UNION_CAVE_1F_HEIGHT
    dw JohtoUnionCave1FRuntimeBlocks
    db BANK(JohtoUnionCave1FRuntimeBlocks)
JohtoRoute33RuntimeDescriptor::
    db JOHTO_ROUTE_33_LOCAL_ID, JOHTO_MODERN, JOHTO_ROUTE_33_WIDTH, JOHTO_ROUTE_33_HEIGHT
    dw JohtoRoute33RuntimeBlocks
    db BANK(JohtoRoute33RuntimeBlocks)
JohtoSouthAzaleaTownDescriptor::
    db JOHTO_AZALEA_TOWN_LOCAL_ID, JOHTO_MODERN, 20, 9
    dw JohtoSouthAzaleaTownBlocks
    db BANK(JohtoSouthAzaleaTownBlocks)
JohtoSouthIlexForestAzaleaGateDescriptor::
    db JOHTO_ILEX_AZALEA_GATE_LOCAL_ID, JOHTO_GATE, 5, 4
    dw JohtoSouthIlexForestAzaleaGateBlocks
    db BANK(JohtoSouthIlexForestAzaleaGateBlocks)
JohtoSouthIlexForestDescriptor::
    db JOHTO_ILEX_FOREST_LOCAL_ID, JOHTO_ILEX_FOREST, 15, 27
    dw JohtoSouthIlexForestBlocks
    db BANK(JohtoSouthIlexForestBlocks)
JohtoSouthRoute34IlexForestGateDescriptor::
    db JOHTO_ROUTE34_ILEX_GATE_LOCAL_ID, JOHTO_GATE, 5, 4
    dw JohtoSouthRoute34IlexForestGateBlocks
    db BANK(JohtoSouthRoute34IlexForestGateBlocks)
JohtoSouthRoute34Descriptor::
    db JOHTO_ROUTE_34_LOCAL_ID, JOHTO_MODERN, 10, 27
    dw JohtoSouthRoute34Blocks
    db BANK(JohtoSouthRoute34Blocks)
JohtoSouthGoldenrodCityDescriptor::
    db JOHTO_GOLDENROD_CITY_LOCAL_ID, JOHTO_MODERN, 20, 18
    dw JohtoSouthGoldenrodCityBlocks
    db BANK(JohtoSouthGoldenrodCityBlocks)
JohtoNorthRoute35GoldenrodGateDescriptor::
    db JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID, JOHTO_GATE, JOHTO_ROUTE35_GATE_WIDTH, JOHTO_ROUTE35_GATE_HEIGHT
    dw JohtoNorthRoute35GoldenrodGateBlocks
    db BANK(JohtoNorthRoute35GoldenrodGateBlocks)
JohtoNorthRoute35Descriptor::
    db JOHTO_ROUTE_35_LOCAL_ID, JOHTO_PILOT, JOHTO_ROUTE35_WIDTH, JOHTO_ROUTE35_HEIGHT
    dw JohtoNorthRoute35Blocks
    db BANK(JohtoNorthRoute35Blocks)
JohtoParkDescriptor::
    db JOHTO_NATIONAL_PARK_LOCAL_ID, JOHTO_PARK, JOHTO_NATIONAL_PARK_WIDTH, JOHTO_NATIONAL_PARK_HEIGHT
    dw JohtoParkBlocks
    db BANK(JohtoParkBlocks)
JohtoParkSouthGateDescriptor::
    db JOHTO_ROUTE_35_NATIONAL_PARK_GATE_LOCAL_ID, JOHTO_PARK_GATE, JOHTO_ROUTE35_PARK_GATE_WIDTH, JOHTO_ROUTE35_PARK_GATE_HEIGHT
    dw JohtoParkSouthGateBlocks
    db BANK(JohtoParkSouthGateBlocks)
JohtoParkEastGateDescriptor::
    db JOHTO_ROUTE_36_NATIONAL_PARK_GATE_LOCAL_ID, JOHTO_PARK_GATE, JOHTO_ROUTE36_PARK_GATE_WIDTH, JOHTO_ROUTE36_PARK_GATE_HEIGHT
    dw JohtoParkEastGateBlocks
    db BANK(JohtoParkEastGateBlocks)
JohtoRoute37RuntimeDescriptor::
    db JOHTO_ROUTE_37_LOCAL_ID, JOHTO_PILOT, JOHTO_ROUTE37_WIDTH, JOHTO_ROUTE37_HEIGHT
    dw JohtoRoute37Blocks
    db BANK(JohtoRoute37Blocks)
JohtoEcruteakRuntimeDescriptor::
    db JOHTO_ECRUTEAK_CITY_LOCAL_ID, JOHTO_PILOT, JOHTO_ECRUTEAK_WIDTH, JOHTO_ECRUTEAK_HEIGHT
    dw JohtoEcruteakBlocks
    db BANK(JohtoEcruteakBlocks)
JohtoPilotRuntimeResourceDescriptorsEnd::
ASSERT JohtoPilotRuntimeResourceDescriptorsEnd - JohtoPilotRuntimeResourceDescriptors == NUM_JOHTO_ACTIVE_MAPS * JOHTO_PILOT_RUNTIME_RECORD_SIZE

; Read-only descriptor selector. Input E=stable physical Johto local ID.
; Success: D=ROM bank, HL=descriptor in D; failure: D=0/HL=0.
; A/flags are not outputs through callab; this does NOT activate a map.
JohtoPilotGetRuntimeResourceDescriptor::
    ld a, e
    cp JOHTO_NEW_BARK_LOCAL_ID
    jp z, .newBark
    cp JOHTO_ROUTE_29_LOCAL_ID
    jp z, .route29
    cp JOHTO_CHERRYGROVE_LOCAL_ID
    jp z, .cherrygrove
    cp JOHTO_ROUTE_30_LOCAL_ID
    jp z, .route30
    cp JOHTO_ROUTE_31_LOCAL_ID
    jp z, .route31
    cp JOHTO_GUIDE_GENTS_HOUSE_LOCAL_ID
    jp z, .guideHouse
    cp JOHTO_VIOLET_CITY_LOCAL_ID
    jp z, .violet
    cp JOHTO_ROUTE31_VIOLET_GATE_LOCAL_ID
    jp z, .gate
    cp JOHTO_ROUTE_32_LOCAL_ID
    jp z, .route32
    cp JOHTO_ROUTE_32_RUINS_OF_ALPH_GATE_LOCAL_ID
    jp z, .alphGate
    cp JOHTO_RUINS_OF_ALPH_LOCAL_ID
    jp z, .alphOutside
    cp JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID
    jr z, .alphNorthGate
    cp JOHTO_ROUTE_36_LOCAL_ID
    jp z, .route36
    cp JOHTO_UNION_CAVE_1F_LOCAL_ID
    jr z, .unionCave
    cp JOHTO_ROUTE_33_LOCAL_ID
    jp z, .route33
    cp JOHTO_AZALEA_TOWN_LOCAL_ID
    jp z, .southAzaleaTown
    cp JOHTO_ILEX_AZALEA_GATE_LOCAL_ID
    jp z, .southIlexForestAzaleaGate
    cp JOHTO_ILEX_FOREST_LOCAL_ID
    jp z, .southIlexForest
    cp JOHTO_ROUTE34_ILEX_GATE_LOCAL_ID
    jp z, .southRoute34IlexForestGate
    cp JOHTO_ROUTE_34_LOCAL_ID
    jp z, .southRoute34
    cp JOHTO_GOLDENROD_CITY_LOCAL_ID
    jp z, .southGoldenrodCity
    cp JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID
    jp z, .route35GoldenrodGate
    cp JOHTO_ROUTE_35_LOCAL_ID
    jp z, .route35
    cp JOHTO_ROUTE_37_LOCAL_ID
    jp z, .route37
    cp JOHTO_ECRUTEAK_CITY_LOCAL_ID
    jp z, .ecruteak
    cp JOHTO_NATIONAL_PARK_LOCAL_ID
    jp z, .park
    cp JOHTO_ROUTE_35_NATIONAL_PARK_GATE_LOCAL_ID
    jp z, .parkSouthGate
    cp JOHTO_ROUTE_36_NATIONAL_PARK_GATE_LOCAL_ID
    jp z, .parkEastGate
    ld d, 0
    ld hl, 0
    ret
.alphNorthGate
    ld hl, JohtoPilotAlphNorthGateRuntimeDescriptor
    jp .valid
.unionCave
    ld hl, JohtoUnionCave1FRuntimeDescriptor
    jp .valid
.southAzaleaTown
    ld hl, JohtoSouthAzaleaTownDescriptor
    jp .valid
.southIlexForestAzaleaGate
    ld hl, JohtoSouthIlexForestAzaleaGateDescriptor
    jp .valid
.southIlexForest
    ld hl, JohtoSouthIlexForestDescriptor
    jp .valid
.southRoute34IlexForestGate
    ld hl, JohtoSouthRoute34IlexForestGateDescriptor
    jp .valid
.southRoute34
    ld hl, JohtoSouthRoute34Descriptor
    jp .valid
.southGoldenrodCity
    ld hl, JohtoSouthGoldenrodCityDescriptor
    jp .valid
.route35GoldenrodGate
    ld hl, JohtoNorthRoute35GoldenrodGateDescriptor
    jp .valid
.route35
    ld hl, JohtoNorthRoute35Descriptor
    jp .valid
.route37
    ld hl, JohtoRoute37RuntimeDescriptor
    jp .valid
.ecruteak
    ld hl, JohtoEcruteakRuntimeDescriptor
    jp .valid
.park
    ld hl, JohtoParkDescriptor
    jp .valid
.parkSouthGate
    ld hl, JohtoParkSouthGateDescriptor
    jp .valid
.parkEastGate
    ld hl, JohtoParkEastGateDescriptor
    jp .valid
.route33
    ld hl, JohtoRoute33RuntimeDescriptor
    jr .valid
.route36
    ld hl, JohtoPilotRoute36RuntimeDescriptor
    jr .valid
.alphGate
    ld hl, JohtoPilotAlphSouthGateRuntimeDescriptor
    jr .valid
.alphOutside
    ld hl, JohtoPilotAlphOutsideRuntimeDescriptor
    jr .valid
.newBark
    ld hl, JohtoPilotNewBarkRuntimeDescriptor
    jr .valid
.route29
    ld hl, JohtoPilotRoute29RuntimeDescriptor
    jr .valid
.cherrygrove
    ld hl, JohtoPilotCherrygroveRuntimeDescriptor
    jr .valid
.route30
    ld hl, JohtoPilotRoute30RuntimeDescriptor
    jr .valid
.route31
    ld hl, JohtoPilotRoute31RuntimeDescriptor
    jr .valid
.guideHouse
    ld hl, JohtoGuideGentsHouseRuntimeDescriptor
    jr .valid
.violet
    ld hl, JohtoPilotVioletRuntimeDescriptor
    jr .valid
.gate
    ld hl, JohtoPilotVioletGateRuntimeDescriptor
    jr .valid
.route32
    ld hl, JohtoPilotRoute32RuntimeDescriptor
.valid
    ld d, BANK(JohtoPilotRuntimeResourceDescriptors)
    ret
