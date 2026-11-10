; P2-004: source-authentic Gold pilot map geometry, NOT live Kanto mapconst IDs.
; These immutable source records preserve the original Gold map blocks. The
; twelve directed source-authentic connections feed the region-aware four-direction
; dispatcher (the Route31/Violet outdoor seam is preview-only; the gate uses
; registered Warps). Runtime blocks and headers remain separate in bank $43.
; Format: region (1), stable ID (1), width (1), height (1), source .blk ptr (2), ROM bank (1).
DEF JOHTO_PILOT_SOURCE_COUNT EQU 65
DEF JOHTO_PILOT_SOURCE_RECORD_BYTES EQU 7
DEF JOHTO_PILOT_SOURCE_CONNECTION_COUNT EQU 52
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

JohtoNorthRoute35GoldenrodGateGoldBlocks::
    INCBIN "maps/johto_pilot/Route35GoldenrodGate.gold.blk"
JohtoNorthRoute35GoldBlocks::
    INCBIN "maps/johto_pilot/Route35.gold.blk"
ASSERT JohtoNorthRoute35GoldBlocks - JohtoNorthRoute35GoldenrodGateGoldBlocks == 20

JohtoParkGoldBlocks:: INCBIN "maps/johto_pilot/NationalPark.gold.blk"
JohtoParkSouthGateGoldBlocks:: INCBIN "maps/johto_pilot/Route35NationalParkGate.gold.blk"
JohtoParkEastGateGoldBlocks:: INCBIN "maps/johto_pilot/Route36NationalParkGate.gold.blk"
JohtoRoute37GoldBlocks:: INCBIN "maps/johto_pilot/Route37.gold.blk"
JohtoEcruteakGoldBlocks:: INCBIN "maps/johto_pilot/EcruteakCity.gold.blk"
JohtoRoute38EcruteakGateGoldBlocks:: INCBIN "maps/johto_pilot/Route38EcruteakGate.gold.blk"
JohtoRoute38GoldBlocks:: INCBIN "maps/johto_pilot/Route38.gold.blk"
JohtoRoute39GoldBlocks:: INCBIN "maps/johto_pilot/Route39.gold.blk"
JohtoOlivineGoldBlocks:: INCBIN "maps/johto_pilot/OlivineCity.gold.blk"
JohtoRoute40GoldBlocks:: INCBIN "maps/johto_pilot/Route40.gold.blk"
JohtoRoute41GoldBlocks:: INCBIN "maps/johto_pilot/Route41.gold.blk"
JohtoCianwoodGoldBlocks:: INCBIN "maps/johto_pilot/CianwoodCity.gold.blk"
JohtoRoute42EcruteakGateGoldBlocks:: INCBIN "maps/johto_pilot/Route42EcruteakGate.gold.blk"
JohtoRoute42GoldBlocks:: INCBIN "maps/johto_pilot/Route42.gold.blk"
JohtoMahoganyGoldBlocks:: INCBIN "maps/johto_pilot/MahoganyTown.gold.blk"
JohtoRoute43MahoganyGateGoldBlocks:: INCBIN "maps/johto_pilot/Route43MahoganyGate.gold.blk"
ASSERT @ - JohtoRoute43MahoganyGateGoldBlocks == 20
JohtoRoute43GoldBlocks:: INCBIN "maps/johto_pilot/Route43.gold.blk"
ASSERT @ - JohtoRoute43GoldBlocks == JOHTO_ROUTE_43_WIDTH * JOHTO_ROUTE_43_HEIGHT
; Gold Route43Gate and Route43MahoganyGate share NorthSouthGate (5x4).
JohtoRoute43GateGoldBlocks:: INCBIN "maps/johto_pilot/Route43Gate.gold.blk"
ASSERT @ - JohtoRoute43GateGoldBlocks == JOHTO_ROUTE43_GATE_WIDTH * JOHTO_ROUTE43_GATE_HEIGHT
JohtoLakeOfRageGoldBlocks:: INCBIN "maps/johto_pilot/LakeOfRage.gold.blk"
ASSERT @ - JohtoLakeOfRageGoldBlocks == JOHTO_LAKE_OF_RAGE_WIDTH * JOHTO_LAKE_OF_RAGE_HEIGHT
JohtoRoute44GoldBlocks:: INCBIN "maps/johto_pilot/Route44.gold.blk"
ASSERT @ - JohtoRoute44GoldBlocks == JOHTO_ROUTE_44_WIDTH * JOHTO_ROUTE_44_HEIGHT
JohtoBlackthornGoldBlocks:: INCBIN "maps/johto_pilot/BlackthornCity.gold.blk"
ASSERT @ - JohtoBlackthornGoldBlocks == JOHTO_BLACKTHORN_CITY_WIDTH * JOHTO_BLACKTHORN_CITY_HEIGHT
JohtoRoute45GoldBlocks:: INCBIN "maps/johto_pilot/Route45.gold.blk"
JohtoRoute46GoldBlocks:: INCBIN "maps/johto_pilot/Route46.gold.blk"
JohtoRoute29Route46GateGoldBlocks:: INCBIN "maps/johto_pilot/Route29Route46Gate.gold.blk"
ASSERT @ - JohtoRoute29Route46GateGoldBlocks == 5 * 4
JohtoCherrygrovePokecenterGoldBlocks::
    INCBIN "maps/johto_pilot/CherrygrovePokecenter1F.gold.blk"
ASSERT @ - JohtoCherrygrovePokecenterGoldBlocks == 5 * 4
JohtoRoute32PokecenterGoldBlocks:: INCBIN "maps/johto_pilot/Route32Pokecenter1F.gold.blk"
ASSERT @ - JohtoRoute32PokecenterGoldBlocks == 5 * 4
JohtoAzaleaPokecenterGoldBlocks:: INCBIN "maps/johto_pilot/AzaleaPokecenter1F.gold.blk"
ASSERT @ - JohtoAzaleaPokecenterGoldBlocks == 5 * 4
JohtoVioletPokecenterGoldBlocks:: INCBIN "maps/johto_pilot/VioletPokecenter1F.gold.blk"
ASSERT @ - JohtoVioletPokecenterGoldBlocks == 5 * 4
; Keep each ASSERT adjacent to its own 5x4 Gold block resource.
JohtoGoldenrodPokecenterGoldBlocks:: INCBIN "maps/johto_pilot/GoldenrodPokecenter1F.gold.blk"
ASSERT @ - JohtoGoldenrodPokecenterGoldBlocks == 5 * 4
JohtoMahoganyPokecenterGoldBlocks:: INCBIN "maps/johto_pilot/MahoganyPokecenter1F.gold.blk"
ASSERT @ - JohtoMahoganyPokecenterGoldBlocks == 5 * 4
JohtoCianwoodPokecenterGoldBlocks:: INCBIN "maps/johto_pilot/CianwoodPokecenter1F.gold.blk"
ASSERT @ - JohtoCianwoodPokecenterGoldBlocks == 5 * 4
JohtoOlivinePokecenterGoldBlocks:: INCBIN "maps/johto_pilot/OlivinePokecenter1F.gold.blk"
ASSERT @ - JohtoOlivinePokecenterGoldBlocks == 5 * 4
JohtoEcruteakPokecenterGoldBlocks:: INCBIN "maps/johto_pilot/EcruteakPokecenter1F.gold.blk"
ASSERT @ - JohtoEcruteakPokecenterGoldBlocks == 5 * 4
JohtoBlackthornPokecenterGoldBlocks:: INCBIN "maps/johto_pilot/BlackthornPokecenter1F.gold.blk"
ASSERT @ - JohtoBlackthornPokecenterGoldBlocks == 5 * 4
JohtoBurnedTower1FGoldBlocks:: INCBIN "maps/johto_pilot/BurnedTower1F.gold.blk"
ASSERT @ - JohtoBurnedTower1FGoldBlocks == 10 * 9
JohtoBurnedTowerB1FGoldBlocks:: INCBIN "maps/johto_pilot/BurnedTowerB1F.gold.blk"
ASSERT @ - JohtoBurnedTowerB1FGoldBlocks == JOHTO_BURNED_TOWER_B1F_WIDTH * JOHTO_BURNED_TOWER_B1F_HEIGHT
JohtoDarkCaveVioletGoldBlocks:: INCBIN "maps/johto_pilot/DarkCaveVioletEntrance.gold.blk"
ASSERT @ - JohtoDarkCaveVioletGoldBlocks == JOHTO_DARK_CAVE_WIDTH * JOHTO_DARK_CAVE_HEIGHT
JohtoDarkCaveBlackthornGoldBlocks:: INCBIN "maps/johto_pilot/DarkCaveBlackthornEntrance.gold.blk"
ASSERT @ - JohtoDarkCaveBlackthornGoldBlocks == JOHTO_DARK_CAVE_BLACKTHORN_WIDTH * JOHTO_DARK_CAVE_BLACKTHORN_HEIGHT
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
    db MAP_REGION_JOHTO, JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID, JOHTO_ROUTE35_GATE_WIDTH, JOHTO_ROUTE35_GATE_HEIGHT
    dw JohtoNorthRoute35GoldenrodGateGoldBlocks
    db BANK(JohtoNorthRoute35GoldenrodGateGoldBlocks)
    db MAP_REGION_JOHTO, JOHTO_ROUTE_35_LOCAL_ID, JOHTO_ROUTE35_WIDTH, JOHTO_ROUTE35_HEIGHT
    dw JohtoNorthRoute35GoldBlocks
    db BANK(JohtoNorthRoute35GoldBlocks)
    db MAP_REGION_JOHTO, JOHTO_NATIONAL_PARK_LOCAL_ID, JOHTO_NATIONAL_PARK_WIDTH, JOHTO_NATIONAL_PARK_HEIGHT
    dw JohtoParkGoldBlocks
    db BANK(JohtoParkGoldBlocks)
    db MAP_REGION_JOHTO, JOHTO_ROUTE_35_NATIONAL_PARK_GATE_LOCAL_ID, JOHTO_ROUTE35_PARK_GATE_WIDTH, JOHTO_ROUTE35_PARK_GATE_HEIGHT
    dw JohtoParkSouthGateGoldBlocks
    db BANK(JohtoParkSouthGateGoldBlocks)
    db MAP_REGION_JOHTO, JOHTO_ROUTE_36_NATIONAL_PARK_GATE_LOCAL_ID, JOHTO_ROUTE36_PARK_GATE_WIDTH, JOHTO_ROUTE36_PARK_GATE_HEIGHT
    dw JohtoParkEastGateGoldBlocks
    db BANK(JohtoParkEastGateGoldBlocks)
    db MAP_REGION_JOHTO, JOHTO_ROUTE_37_LOCAL_ID, JOHTO_ROUTE37_WIDTH, JOHTO_ROUTE37_HEIGHT
    dw JohtoRoute37GoldBlocks
    db BANK(JohtoRoute37GoldBlocks)
    db MAP_REGION_JOHTO, JOHTO_ECRUTEAK_CITY_LOCAL_ID, JOHTO_ECRUTEAK_WIDTH, JOHTO_ECRUTEAK_HEIGHT
    dw JohtoEcruteakGoldBlocks
    db BANK(JohtoEcruteakGoldBlocks)
    db MAP_REGION_JOHTO, JOHTO_ROUTE_38_ECRUTEAK_GATE_LOCAL_ID, JOHTO_ROUTE_38_ECRUTEAK_GATE_WIDTH, JOHTO_ROUTE_38_ECRUTEAK_GATE_HEIGHT
    dw JohtoRoute38EcruteakGateGoldBlocks
    db BANK(JohtoRoute38EcruteakGateGoldBlocks)
    db MAP_REGION_JOHTO, JOHTO_ROUTE_38_LOCAL_ID, JOHTO_ROUTE_38_WIDTH, JOHTO_ROUTE_38_HEIGHT
    dw JohtoRoute38GoldBlocks
    db BANK(JohtoRoute38GoldBlocks)
    db MAP_REGION_JOHTO, JOHTO_ROUTE_39_LOCAL_ID, JOHTO_ROUTE_39_WIDTH, JOHTO_ROUTE_39_HEIGHT
    dw JohtoRoute39GoldBlocks
    db BANK(JohtoRoute39GoldBlocks)
    db MAP_REGION_JOHTO, JOHTO_OLIVINE_CITY_LOCAL_ID, JOHTO_OLIVINE_CITY_WIDTH, JOHTO_OLIVINE_CITY_HEIGHT
    dw JohtoOlivineGoldBlocks
    db BANK(JohtoOlivineGoldBlocks)
    db MAP_REGION_JOHTO, JOHTO_ROUTE_40_LOCAL_ID, JOHTO_ROUTE_40_WIDTH, JOHTO_ROUTE_40_HEIGHT
    dw JohtoRoute40GoldBlocks
    db BANK(JohtoRoute40GoldBlocks)
    db MAP_REGION_JOHTO, JOHTO_ROUTE_41_LOCAL_ID, JOHTO_ROUTE_41_WIDTH, JOHTO_ROUTE_41_HEIGHT
    dw JohtoRoute41GoldBlocks
    db BANK(JohtoRoute41GoldBlocks)
    db MAP_REGION_JOHTO, JOHTO_CIANWOOD_CITY_LOCAL_ID, JOHTO_CIANWOOD_CITY_WIDTH, JOHTO_CIANWOOD_CITY_HEIGHT
    dw JohtoCianwoodGoldBlocks
    db BANK(JohtoCianwoodGoldBlocks)
    db MAP_REGION_JOHTO, JOHTO_ROUTE_42_ECRUTEAK_GATE_LOCAL_ID, JOHTO_ROUTE_42_ECRUTEAK_GATE_WIDTH, JOHTO_ROUTE_42_ECRUTEAK_GATE_HEIGHT
    dw JohtoRoute42EcruteakGateGoldBlocks
    db BANK(JohtoRoute42EcruteakGateGoldBlocks)
    db MAP_REGION_JOHTO, JOHTO_ROUTE_42_LOCAL_ID, JOHTO_ROUTE_42_WIDTH, JOHTO_ROUTE_42_HEIGHT
    dw JohtoRoute42GoldBlocks
    db BANK(JohtoRoute42GoldBlocks)
    db MAP_REGION_JOHTO, JOHTO_MAHOGANY_TOWN_LOCAL_ID, JOHTO_MAHOGANY_TOWN_WIDTH, JOHTO_MAHOGANY_TOWN_HEIGHT
    dw JohtoMahoganyGoldBlocks
    db BANK(JohtoMahoganyGoldBlocks)
    db MAP_REGION_JOHTO, JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID, JOHTO_ROUTE43_MAHOGANY_GATE_WIDTH, JOHTO_ROUTE43_MAHOGANY_GATE_HEIGHT
    dw JohtoRoute43MahoganyGateGoldBlocks
    db BANK(JohtoRoute43MahoganyGateGoldBlocks)
    db MAP_REGION_JOHTO, JOHTO_ROUTE_43_LOCAL_ID, JOHTO_ROUTE_43_WIDTH, JOHTO_ROUTE_43_HEIGHT
    dw JohtoRoute43GoldBlocks
    db BANK(JohtoRoute43GoldBlocks)
    db MAP_REGION_JOHTO, JOHTO_ROUTE_43_GATE_LOCAL_ID, JOHTO_ROUTE43_GATE_WIDTH, JOHTO_ROUTE43_GATE_HEIGHT
    dw JohtoRoute43GateGoldBlocks
    db BANK(JohtoRoute43GateGoldBlocks)
    db MAP_REGION_JOHTO, JOHTO_LAKE_OF_RAGE_LOCAL_ID, JOHTO_LAKE_OF_RAGE_WIDTH, JOHTO_LAKE_OF_RAGE_HEIGHT
    dw JohtoLakeOfRageGoldBlocks
    db BANK(JohtoLakeOfRageGoldBlocks)
    db MAP_REGION_JOHTO, JOHTO_ROUTE_44_LOCAL_ID, JOHTO_ROUTE_44_WIDTH, JOHTO_ROUTE_44_HEIGHT
    dw JohtoRoute44GoldBlocks
    db BANK(JohtoRoute44GoldBlocks)
    db MAP_REGION_JOHTO, JOHTO_BLACKTHORN_CITY_LOCAL_ID, JOHTO_BLACKTHORN_CITY_WIDTH, JOHTO_BLACKTHORN_CITY_HEIGHT
    dw JohtoBlackthornGoldBlocks
    db BANK(JohtoBlackthornGoldBlocks)
    db MAP_REGION_JOHTO, JOHTO_ROUTE_45_LOCAL_ID, 10, 45
    dw JohtoRoute45GoldBlocks
    db BANK(JohtoRoute45GoldBlocks)
    db MAP_REGION_JOHTO, JOHTO_ROUTE_46_LOCAL_ID, 10, 18
    dw JohtoRoute46GoldBlocks
    db BANK(JohtoRoute46GoldBlocks)
    db MAP_REGION_JOHTO, JOHTO_ROUTE_29_ROUTE_46_GATE_LOCAL_ID, 5, 4
    dw JohtoRoute29Route46GateGoldBlocks
    db BANK(JohtoRoute29Route46GateGoldBlocks)
    ; Gold 5x4 source layout; runtime uses the converted Johto 5x4 shared interior.
    db MAP_REGION_JOHTO, JOHTO_CHERRYGROVE_POKECENTER_1F_LOCAL_ID, 5, 4
    dw JohtoCherrygrovePokecenterGoldBlocks
    db BANK(JohtoCherrygrovePokecenterGoldBlocks)
    ; Gold Route32Pokecenter1F uses shared Pokecenter1F.blk byte-for-byte.
    ; Reuse the source Gold blocks (do not spend another ROMX copy).
    db MAP_REGION_JOHTO, JOHTO_ROUTE_32_POKECENTER_1F_LOCAL_ID, 5, 4
    dw JohtoRoute32PokecenterGoldBlocks
    db BANK(JohtoRoute32PokecenterGoldBlocks)
    ; Gold AzaleaPokecenter1F preserves its independent source-asset identity.
    ; The 5x4 runtime blocks are still shared across all three centers.
    db MAP_REGION_JOHTO, JOHTO_AZALEA_POKECENTER_1F_LOCAL_ID, 5, 4
    dw JohtoAzaleaPokecenterGoldBlocks
    db BANK(JohtoAzaleaPokecenterGoldBlocks)
    ; REF-335: VioletPokecenter1F uses Gold shared Pokecenter1F layout.
    db MAP_REGION_JOHTO, JOHTO_VIOLET_POKECENTER_1F_LOCAL_ID, 5, 4
    dw JohtoVioletPokecenterGoldBlocks
    db BANK(JohtoVioletPokecenterGoldBlocks)
    ; REF-335: GoldenrodPokecenter1F uses Gold shared Pokecenter1F layout.
    db MAP_REGION_JOHTO, JOHTO_GOLDENROD_POKECENTER_1F_LOCAL_ID, 5, 4
    dw JohtoGoldenrodPokecenterGoldBlocks
    db BANK(JohtoGoldenrodPokecenterGoldBlocks)
    ; REF-336: Ecruteak Center uses source-exact Gold 5x4 Pokecenter1F.
    db MAP_REGION_JOHTO, JOHTO_ECRUTEAK_POKECENTER_1F_LOCAL_ID, 5, 4
    dw JohtoEcruteakPokecenterGoldBlocks
    db BANK(JohtoEcruteakPokecenterGoldBlocks)
    ; REF-336: Olivine Center uses source-exact Gold 5x4 Pokecenter1F.
    db MAP_REGION_JOHTO, JOHTO_OLIVINE_POKECENTER_1F_LOCAL_ID, 5, 4
    dw JohtoOlivinePokecenterGoldBlocks
    db BANK(JohtoOlivinePokecenterGoldBlocks)
    ; REF-336: Cianwood Center uses source-exact Gold 5x4 Pokecenter1F.
    db MAP_REGION_JOHTO, JOHTO_CIANWOOD_POKECENTER_1F_LOCAL_ID, 5, 4
    dw JohtoCianwoodPokecenterGoldBlocks
    db BANK(JohtoCianwoodPokecenterGoldBlocks)
    ; REF-336: Mahogany Center uses source-exact Gold 5x4 Pokecenter1F.
    db MAP_REGION_JOHTO, JOHTO_MAHOGANY_POKECENTER_1F_LOCAL_ID, 5, 4
    dw JohtoMahoganyPokecenterGoldBlocks
    db BANK(JohtoMahoganyPokecenterGoldBlocks)
    ; REF-338: Gold Blackthorn Center is the same 5x4 source, unique stable ID85.
    db MAP_REGION_JOHTO, JOHTO_BLACKTHORN_POKECENTER_1F_LOCAL_ID, 5, 4
    dw JohtoBlackthornPokecenterGoldBlocks
    db BANK(JohtoBlackthornPokecenterGoldBlocks)
    db MAP_REGION_JOHTO, JOHTO_UNION_CAVE_B1F_LOCAL_ID, JOHTO_UNION_CAVE_1F_WIDTH, JOHTO_UNION_CAVE_1F_HEIGHT
    dw JohtoUnionCaveB1FGoldBlocks
    db BANK(JohtoUnionCaveB1FGoldBlocks)
    db MAP_REGION_JOHTO, JOHTO_UNION_CAVE_B2F_LOCAL_ID, JOHTO_UNION_CAVE_1F_WIDTH, JOHTO_UNION_CAVE_1F_HEIGHT
    dw JohtoUnionCaveB2FGoldBlocks
    db BANK(JohtoUnionCaveB2FGoldBlocks)
    db MAP_REGION_JOHTO, JOHTO_SLOWPOKE_WELL_B1F_LOCAL_ID, JOHTO_SLOWPOKE_WELL_B1F_WIDTH, JOHTO_SLOWPOKE_WELL_B1F_HEIGHT
    dw JohtoSlowpokeWellB1FGoldBlocks
    db BANK(JohtoSlowpokeWellB1FGoldBlocks)
    db MAP_REGION_JOHTO, JOHTO_SLOWPOKE_WELL_B2F_LOCAL_ID, JOHTO_SLOWPOKE_WELL_B2F_WIDTH, JOHTO_SLOWPOKE_WELL_B2F_HEIGHT
    dw JohtoSlowpokeWellB2FGoldBlocks
    db BANK(JohtoSlowpokeWellB2FGoldBlocks)
    db MAP_REGION_JOHTO, JOHTO_BURNED_TOWER_1F_LOCAL_ID, 10, 9
    dw JohtoBurnedTower1FGoldBlocks
    db BANK(JohtoBurnedTower1FGoldBlocks)
    db MAP_REGION_JOHTO, JOHTO_BURNED_TOWER_B1F_LOCAL_ID, JOHTO_BURNED_TOWER_B1F_WIDTH, JOHTO_BURNED_TOWER_B1F_HEIGHT
    dw JohtoBurnedTowerB1FGoldBlocks
    db BANK(JohtoBurnedTowerB1FGoldBlocks)
    db MAP_REGION_JOHTO, JOHTO_DARK_CAVE_VIOLET_ENTRANCE_LOCAL_ID, JOHTO_DARK_CAVE_WIDTH, JOHTO_DARK_CAVE_HEIGHT
    dw JohtoDarkCaveVioletGoldBlocks
    db BANK(JohtoDarkCaveVioletGoldBlocks)
    db MAP_REGION_JOHTO, JOHTO_DARK_CAVE_BLACKTHORN_ENTRANCE_LOCAL_ID, JOHTO_DARK_CAVE_BLACKTHORN_WIDTH, JOHTO_DARK_CAVE_BLACKTHORN_HEIGHT
    dw JohtoDarkCaveBlackthornGoldBlocks
    db BANK(JohtoDarkCaveBlackthornGoldBlocks)
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
    ; SEAM-289: verified Gold Route35/36 + Route36/Violet direct edges.
    db MAP_REGION_JOHTO, JOHTO_ROUTE_35_LOCAL_ID, NORTH, MAP_REGION_JOHTO, JOHTO_ROUTE_36_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_36_LOCAL_ID, SOUTH, MAP_REGION_JOHTO, JOHTO_ROUTE_35_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_36_LOCAL_ID, EAST, MAP_REGION_JOHTO, JOHTO_VIOLET_CITY_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_VIOLET_CITY_LOCAL_ID, WEST, MAP_REGION_JOHTO, JOHTO_ROUTE_36_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_36_LOCAL_ID, NORTH, MAP_REGION_JOHTO, JOHTO_ROUTE_37_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_37_LOCAL_ID, SOUTH, MAP_REGION_JOHTO, JOHTO_ROUTE_36_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_37_LOCAL_ID, NORTH, MAP_REGION_JOHTO, JOHTO_ECRUTEAK_CITY_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ECRUTEAK_CITY_LOCAL_ID, SOUTH, MAP_REGION_JOHTO, JOHTO_ROUTE_37_LOCAL_ID
    ; West corridor visual topology and direct outdoor movement seams.
    db MAP_REGION_JOHTO, JOHTO_ECRUTEAK_CITY_LOCAL_ID, WEST, MAP_REGION_JOHTO, JOHTO_ROUTE_38_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_38_LOCAL_ID, EAST, MAP_REGION_JOHTO, JOHTO_ECRUTEAK_CITY_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_38_LOCAL_ID, WEST, MAP_REGION_JOHTO, JOHTO_ROUTE_39_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_39_LOCAL_ID, EAST, MAP_REGION_JOHTO, JOHTO_ROUTE_38_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_39_LOCAL_ID, SOUTH, MAP_REGION_JOHTO, JOHTO_OLIVINE_CITY_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_OLIVINE_CITY_LOCAL_ID, NORTH, MAP_REGION_JOHTO, JOHTO_ROUTE_39_LOCAL_ID
    ; MAP-299: completed Gold sea chain, reciprocal and source-audited.
    db MAP_REGION_JOHTO, JOHTO_OLIVINE_CITY_LOCAL_ID, WEST, MAP_REGION_JOHTO, JOHTO_ROUTE_40_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_40_LOCAL_ID, EAST, MAP_REGION_JOHTO, JOHTO_OLIVINE_CITY_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_40_LOCAL_ID, SOUTH, MAP_REGION_JOHTO, JOHTO_ROUTE_41_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_41_LOCAL_ID, NORTH, MAP_REGION_JOHTO, JOHTO_ROUTE_40_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_41_LOCAL_ID, WEST, MAP_REGION_JOHTO, JOHTO_CIANWOOD_CITY_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_CIANWOOD_CITY_LOCAL_ID, EAST, MAP_REGION_JOHTO, JOHTO_ROUTE_41_LOCAL_ID
    ; MAP-300: east topology. Ecruteak/Route42 direct edge is preview-only; travel uses gate Warps.
    db MAP_REGION_JOHTO, JOHTO_ECRUTEAK_CITY_LOCAL_ID, EAST, MAP_REGION_JOHTO, JOHTO_ROUTE_42_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_42_LOCAL_ID, WEST, MAP_REGION_JOHTO, JOHTO_ECRUTEAK_CITY_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_42_LOCAL_ID, EAST, MAP_REGION_JOHTO, JOHTO_MAHOGANY_TOWN_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_MAHOGANY_TOWN_LOCAL_ID, WEST, MAP_REGION_JOHTO, JOHTO_ROUTE_42_LOCAL_ID
    ; DEV-321: Gold Route43 <-> Lake of Rage north/south seam, offsets -5/+5 blocks.
    db MAP_REGION_JOHTO, JOHTO_ROUTE_43_LOCAL_ID, NORTH, MAP_REGION_JOHTO, JOHTO_LAKE_OF_RAGE_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_LAKE_OF_RAGE_LOCAL_ID, SOUTH, MAP_REGION_JOHTO, JOHTO_ROUTE_43_LOCAL_ID
    ; DEV-324: Gold Mahogany EAST <-> Route44 WEST, offset 0.
    db MAP_REGION_JOHTO, JOHTO_MAHOGANY_TOWN_LOCAL_ID, EAST, MAP_REGION_JOHTO, JOHTO_ROUTE_44_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_44_LOCAL_ID, WEST, MAP_REGION_JOHTO, JOHTO_MAHOGANY_TOWN_LOCAL_ID
    ; DEV-326: Gold Route44 EAST <-> Blackthorn City WEST, +9 / -9 block offsets.
    db MAP_REGION_JOHTO, JOHTO_ROUTE_44_LOCAL_ID, EAST, MAP_REGION_JOHTO, JOHTO_BLACKTHORN_CITY_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_BLACKTHORN_CITY_LOCAL_ID, WEST, MAP_REGION_JOHTO, JOHTO_ROUTE_44_LOCAL_ID
    ; DEV-328: source-accurate southern physical routes and preview-only Route46/Route29.
    db MAP_REGION_JOHTO, JOHTO_BLACKTHORN_CITY_LOCAL_ID, SOUTH, MAP_REGION_JOHTO, JOHTO_ROUTE_45_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_45_LOCAL_ID, NORTH, MAP_REGION_JOHTO, JOHTO_BLACKTHORN_CITY_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_45_LOCAL_ID, WEST, MAP_REGION_JOHTO, JOHTO_ROUTE_46_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_46_LOCAL_ID, EAST, MAP_REGION_JOHTO, JOHTO_ROUTE_45_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_46_LOCAL_ID, SOUTH, MAP_REGION_JOHTO, JOHTO_ROUTE_29_LOCAL_ID
    db MAP_REGION_JOHTO, JOHTO_ROUTE_29_LOCAL_ID, NORTH, MAP_REGION_JOHTO, JOHTO_ROUTE_46_LOCAL_ID
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
JohtoUnionCaveB1FGoldBlocks::
    INCBIN "maps/johto_pilot/UnionCaveB1F.gold.blk"
JohtoUnionCaveB1FGoldBlocksEnd::
ASSERT JohtoUnionCaveB1FGoldBlocksEnd - JohtoUnionCaveB1FGoldBlocks == JOHTO_UNION_CAVE_1F_WIDTH * JOHTO_UNION_CAVE_1F_HEIGHT
JohtoUnionCaveB2FGoldBlocks::
    INCBIN "maps/johto_pilot/UnionCaveB2F.gold.blk"
JohtoUnionCaveB2FGoldBlocksEnd::
ASSERT JohtoUnionCaveB2FGoldBlocksEnd - JohtoUnionCaveB2FGoldBlocks == JOHTO_UNION_CAVE_1F_WIDTH * JOHTO_UNION_CAVE_1F_HEIGHT
JohtoSlowpokeWellB1FGoldBlocks::
    INCBIN "maps/johto_pilot/SlowpokeWellB1F.gold.blk"
JohtoSlowpokeWellB1FGoldBlocksEnd::
ASSERT JohtoSlowpokeWellB1FGoldBlocksEnd - JohtoSlowpokeWellB1FGoldBlocks == JOHTO_SLOWPOKE_WELL_B1F_WIDTH * JOHTO_SLOWPOKE_WELL_B1F_HEIGHT
JohtoSlowpokeWellB2FGoldBlocks::
    INCBIN "maps/johto_pilot/SlowpokeWellB2F.gold.blk"
JohtoSlowpokeWellB2FGoldBlocksEnd::
ASSERT JohtoSlowpokeWellB2FGoldBlocksEnd - JohtoSlowpokeWellB2FGoldBlocks == JOHTO_SLOWPOKE_WELL_B2F_WIDTH * JOHTO_SLOWPOKE_WELL_B2F_HEIGHT

; Gold source original Route33 uses JOHTO_MODERN, never JOHTO_PILOT.
JohtoRoute33GoldBlocks::
    INCBIN "maps/johto_pilot/Route33.gold.blk"
JohtoRoute33GoldBlocksEnd::
ASSERT JohtoRoute33GoldBlocksEnd - JohtoRoute33GoldBlocks == JOHTO_ROUTE_33_WIDTH * JOHTO_ROUTE_33_HEIGHT
