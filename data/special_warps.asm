; Format: (size 2 bytes)
; 00: target map ID
; 01: which dungeon warp in the source map was used
DungeonWarpList:
	db SEAFOAM_ISLANDS_2,$01
	db SEAFOAM_ISLANDS_2,$02
	db SEAFOAM_ISLANDS_3,$01
	db SEAFOAM_ISLANDS_3,$02
	db SEAFOAM_ISLANDS_4,$01
	db SEAFOAM_ISLANDS_4,$02
	db SEAFOAM_ISLANDS_5,$01
	db SEAFOAM_ISLANDS_5,$02
	db VICTORY_ROAD_2,$02
	db MANSION_1,$01
	db MANSION_1,$02
	db MANSION_2,$03
	db $FF

DungeonWarpData:
	FLYWARP_DATA SEAFOAM_ISLANDS_2_WIDTH,7,18
	FLYWARP_DATA SEAFOAM_ISLANDS_2_WIDTH,7,23
	FLYWARP_DATA SEAFOAM_ISLANDS_3_WIDTH,7,19
	FLYWARP_DATA SEAFOAM_ISLANDS_3_WIDTH,7,22
	FLYWARP_DATA SEAFOAM_ISLANDS_4_WIDTH,7,18
	FLYWARP_DATA SEAFOAM_ISLANDS_4_WIDTH,7,19
	FLYWARP_DATA SEAFOAM_ISLANDS_5_WIDTH,14,4
	FLYWARP_DATA SEAFOAM_ISLANDS_5_WIDTH,14,5
	FLYWARP_DATA VICTORY_ROAD_2_WIDTH,16,22
	FLYWARP_DATA MANSION_1_WIDTH,14,16
	FLYWARP_DATA MANSION_1_WIDTH,14,16
	FLYWARP_DATA MANSION_2_WIDTH,14,18

;Format:
;	db Map_id
;	FLYWARP_DATA [Map Width][Y-pos][X-pos]
;	db Tileset_id
FirstMapSpec:
	db REDS_HOUSE_2F
	FLYWARP_DATA REDS_HOUSE_2F_WIDTH,6,3
	db REDS_HOUSE_2

TradeCenterSpec1:
	db TRADE_CENTER
	FLYWARP_DATA TRADE_CENTER_WIDTH,4,3
	db CLUB

TradeCenterSpec2:
	db TRADE_CENTER
	FLYWARP_DATA TRADE_CENTER_WIDTH,4,6
	db CLUB

ColosseumSpec1:
	db COLOSSEUM
	FLYWARP_DATA COLOSSEUM_WIDTH,4,3
	db CLUB

ColosseumSpec2:
	db COLOSSEUM
	FLYWARP_DATA COLOSSEUM_WIDTH,4,6
	db CLUB

FlyWarpDataPtr:
; [selector shown on Town Map], [actual destination map], [warp-data pointer]
; For normal cities/blackout destinations the first two bytes are identical.
; Extra Fly destinations can therefore share an outdoor map without breaking
; the existing Route 4/Route 10 Pokemon Center blackout/Teleport entries.
	db PALLET_TOWN, PALLET_TOWN
	dw PalletTownFlyWarp
	db VIRIDIAN_CITY, VIRIDIAN_CITY
	dw ViridianCityFlyWarp
	db PEWTER_CITY, PEWTER_CITY
	dw PewterCityFlyWarp
	db CERULEAN_CITY, CERULEAN_CITY
	dw CeruleanCityFlyWarp
	db LAVENDER_TOWN, LAVENDER_TOWN
	dw LavenderTownFlyWarp
	db VERMILION_CITY, VERMILION_CITY
	dw VermilionCityFlyWarp
	db CELADON_CITY, CELADON_CITY
	dw CeladonCityFlyWarp
	db FUCHSIA_CITY, FUCHSIA_CITY
	dw FuchsiaCityFlyWarp
	db CINNABAR_ISLAND, CINNABAR_ISLAND
	dw CinnabarIslandFlyWarp
	db INDIGO_PLATEAU, INDIGO_PLATEAU
	dw IndigoPlateauFlyWarp
	db SAFFRON_CITY, SAFFRON_CITY
	dw SaffronCityFlyWarp

	; Canonical route entries are retained for blackout/Teleport from the route
	; Pokemon Centers.
	db ROUTE_4, ROUTE_4
	dw Route4FlyWarp
	db ROUTE_10, ROUTE_10
	dw Route10FlyWarp

	; Extra Fly destinations. The first byte supplies the Town Map name/position; the
	; second byte is the map that is actually loaded after Fly.
	db MT_MOON_3, ROUTE_4
	dw Route4FlyWarp
	db MT_MOON_SQUARE, MT_MOON_SQUARE
	dw MtMoonSquareFlyWarp
	db ROCK_TUNNEL_1, ROUTE_10
	dw Route10FlyWarp
	db POWER_PLANT, ROUTE_10
	dw PowerPlantFlyWarp
	db SEAFOAM_ISLANDS_1, ROUTE_20
	dw SeafoamIslandsFlyWarp
	db UNKNOWN_DUNGEON_1, CERULEAN_CITY
	dw CeruleanCaveFlyWarp

; Original Format:
;   [Event Displacement][Y-block][X-block][Y-sub_block][X-sub_block]
; Macro Format:
;   FLYWARP_DATA [Map Width][Y-pos][X-pos]
PalletTownFlyWarp:
	FLYWARP_DATA PALLET_TOWN_WIDTH,      6,  5
ViridianCityFlyWarp:
	FLYWARP_DATA VIRIDIAN_CITY_WIDTH,   26, 23
PewterCityFlyWarp:
	FLYWARP_DATA PEWTER_CITY_WIDTH,     26, 13
CeruleanCityFlyWarp:
	FLYWARP_DATA CERULEAN_CITY_WIDTH,   18, 19
LavenderTownFlyWarp:
	FLYWARP_DATA LAVENDER_TOWN_WIDTH,    6,  7
VermilionCityFlyWarp:
	FLYWARP_DATA VERMILION_CITY_WIDTH,   4, 11
CeladonCityFlyWarp:
	FLYWARP_DATA CELADON_CITY_WIDTH,    10, 41
FuchsiaCityFlyWarp:
	FLYWARP_DATA FUCHSIA_CITY_WIDTH,    28, 19
CinnabarIslandFlyWarp:
	FLYWARP_DATA CINNABAR_ISLAND_WIDTH, 12, 11
IndigoPlateauFlyWarp:
	FLYWARP_DATA INDIGO_PLATEAU_WIDTH,   6,  9
SaffronCityFlyWarp:
	FLYWARP_DATA SAFFRON_CITY_WIDTH,    30,  9
Route4FlyWarp:
	FLYWARP_DATA ROUTE_4_WIDTH,          6, 11
Route10FlyWarp:
	FLYWARP_DATA ROUTE_10_WIDTH,        20, 11
MtMoonSquareFlyWarp:
	FLYWARP_DATA MT_MOON_SQUARE_WIDTH, 10, 19
PowerPlantFlyWarp:
	FLYWARP_DATA ROUTE_10_WIDTH,        40,  6
SeafoamIslandsFlyWarp:
	FLYWARP_DATA ROUTE_20_WIDTH,        10, 58
CeruleanCaveFlyWarp:
	FLYWARP_DATA CERULEAN_CITY_WIDTH,   12,  4
