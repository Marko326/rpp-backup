; Sparse map -> wild data table. Maps without an entry use NoMons.
; Keeping only maps with encounters saves space versus a 248-entry pointer table.
; Entries must remain sorted by Map ID so Pokedex location results preserve map order.
; Duplicate Map IDs are not allowed; lookups stop at the first matching entry.
wild_data: MACRO
	assert (\1) < $ff
	db \1
	dw \2
ENDM

WildDataTable:
	wild_data ROUTE_1, Route1Mons
	wild_data ROUTE_2, Route2Mons
	wild_data ROUTE_3, Route3Mons
	wild_data ROUTE_4, Route4Mons
	wild_data ROUTE_5, Route5Mons
	wild_data ROUTE_6, Route6Mons
	wild_data ROUTE_7, Route7Mons
	wild_data ROUTE_8, Route8Mons
	wild_data ROUTE_9, Route9Mons
	wild_data ROUTE_10, Route10Mons
	wild_data ROUTE_11, Route11Mons
	wild_data ROUTE_12, Route12Mons
	wild_data ROUTE_13, Route13Mons
	wild_data ROUTE_14, Route14Mons
	wild_data ROUTE_15, Route15Mons
	wild_data ROUTE_16, Route16Mons
	wild_data ROUTE_17, Route17Mons
	wild_data ROUTE_18, Route18Mons
	wild_data ROUTE_19, WaterMons
	wild_data ROUTE_20, WaterMons
	wild_data ROUTE_21, Route21Mons
	wild_data ROUTE_22, Route22Mons
	wild_data ROUTE_23, Route23Mons
	wild_data ROUTE_24, Route24Mons
	wild_data ROUTE_25, Route25Mons
	wild_data VIRIDIAN_FOREST, ForestMons
	wild_data MT_MOON_1, MoonMons1
	wild_data MT_MOON_2, MoonMonsB1
	wild_data MT_MOON_3, MoonMonsB2
	wild_data ROCK_TUNNEL_1, TunnelMonsB1
	wild_data POWER_PLANT, PowerPlantMons
	wild_data MT_MOON_SQUARE, MtMoonSquareMons
	wild_data VICTORY_ROAD_1, PlateauMons1
	wild_data POKEMONTOWER_1, TowerMons1
	wild_data POKEMONTOWER_2, TowerMons2
	wild_data POKEMONTOWER_3, TowerMons3
	wild_data POKEMONTOWER_4, TowerMons4
	wild_data POKEMONTOWER_5, TowerMons5
	wild_data POKEMONTOWER_6, TowerMons6
	wild_data POKEMONTOWER_7, TowerMons7
	wild_data SEAFOAM_ISLANDS_2, IslandMonsB1
	wild_data SEAFOAM_ISLANDS_3, IslandMonsB2
	wild_data SEAFOAM_ISLANDS_4, IslandMonsB3
	wild_data SEAFOAM_ISLANDS_5, IslandMonsB4
	wild_data MANSION_1, MansionMons1
	wild_data SEAFOAM_ISLANDS_1, IslandMons1
	wild_data VICTORY_ROAD_2, PlateauMons2
	wild_data DIGLETTS_CAVE, CaveMons
	wild_data VICTORY_ROAD_3, PlateauMons3
	wild_data MANSION_2, MansionMons2
	wild_data MANSION_3, MansionMons3
	wild_data MANSION_4, MansionMonsB1
	wild_data SAFARI_ZONE_EAST, ZoneMons1
	wild_data SAFARI_ZONE_NORTH, ZoneMons2
	wild_data SAFARI_ZONE_WEST, ZoneMons3
	wild_data SAFARI_ZONE_CENTER, ZoneMonsCenter
	wild_data UNKNOWN_DUNGEON_2, DungeonMons2
	wild_data UNKNOWN_DUNGEON_3, DungeonMonsB1
	wild_data UNKNOWN_DUNGEON_1, DungeonMons1
	wild_data ROCK_TUNNEL_2, TunnelMonsB2
	db $ff

; wild pokemon data is divided into two parts.
; first part:  pokemon found in grass
; second part: pokemon found while surfing
; each part goes as follows:
    ; if first byte == 00, then
        ; no wild pokemon on this map
    ; if first byte != 00, then
        ; first byte is encounter rate
        ; followed by 20 bytes:
        ; level, species (ten times)

INCLUDE "data/wildPokemon/nomons.asm"
INCLUDE "data/wildPokemon/route1.asm"
INCLUDE "data/wildPokemon/route2.asm"
INCLUDE "data/wildPokemon/route22.asm"
INCLUDE "data/wildPokemon/viridianforest.asm"
INCLUDE "data/wildPokemon/route3.asm"
INCLUDE "data/wildPokemon/mtmoon1.asm"
INCLUDE "data/wildPokemon/mtmoonb1.asm"
INCLUDE "data/wildPokemon/mtmoonb2.asm"
INCLUDE "data/wildPokemon/route4.asm"
INCLUDE "data/wildPokemon/route24.asm"
INCLUDE "data/wildPokemon/route25.asm"
INCLUDE "data/wildPokemon/route9.asm"
INCLUDE "data/wildPokemon/route5.asm"
INCLUDE "data/wildPokemon/route6.asm"
INCLUDE "data/wildPokemon/route11.asm"
INCLUDE "data/wildPokemon/rocktunnel1.asm"
INCLUDE "data/wildPokemon/rocktunnel2.asm"
INCLUDE "data/wildPokemon/route10.asm"
INCLUDE "data/wildPokemon/route12.asm"
INCLUDE "data/wildPokemon/route8.asm"
INCLUDE "data/wildPokemon/route7.asm"
INCLUDE "data/wildPokemon/pokemontower1.asm"
INCLUDE "data/wildPokemon/pokemontower2.asm"
INCLUDE "data/wildPokemon/pokemontower3.asm"
INCLUDE "data/wildPokemon/pokemontower4.asm"
INCLUDE "data/wildPokemon/pokemontower5.asm"
INCLUDE "data/wildPokemon/pokemontower6.asm"
INCLUDE "data/wildPokemon/pokemontower7.asm"
INCLUDE "data/wildPokemon/route13.asm"
INCLUDE "data/wildPokemon/route14.asm"
INCLUDE "data/wildPokemon/route15.asm"
INCLUDE "data/wildPokemon/route16.asm"
INCLUDE "data/wildPokemon/route17.asm"
INCLUDE "data/wildPokemon/route18.asm"
INCLUDE "data/wildPokemon/safarizonecenter.asm"
INCLUDE "data/wildPokemon/safarizone1.asm"
INCLUDE "data/wildPokemon/safarizone2.asm"
INCLUDE "data/wildPokemon/safarizone3.asm"
INCLUDE "data/wildPokemon/waterpokemon.asm"
INCLUDE "data/wildPokemon/seafoamisland1.asm"
INCLUDE "data/wildPokemon/seafoamislandb1.asm"
INCLUDE "data/wildPokemon/seafoamislandb2.asm"
INCLUDE "data/wildPokemon/seafoamislandb3.asm"
INCLUDE "data/wildPokemon/seafoamislandb4.asm"
INCLUDE "data/wildPokemon/mansion1.asm"
INCLUDE "data/wildPokemon/mansion2.asm"
INCLUDE "data/wildPokemon/mansion3.asm"
INCLUDE "data/wildPokemon/mansionb1.asm"
INCLUDE "data/wildPokemon/route21.asm"
INCLUDE "data/wildPokemon/unknowndungeon1.asm"
INCLUDE "data/wildPokemon/unknowndungeon2.asm"
INCLUDE "data/wildPokemon/unknowndungeonb1.asm"
INCLUDE "data/wildPokemon/powerplant.asm"
INCLUDE "data/wildPokemon/route23.asm"
INCLUDE "data/wildPokemon/victoryroad2.asm"
INCLUDE "data/wildPokemon/victoryroad3.asm"
INCLUDE "data/wildPokemon/victoryroad1.asm"
INCLUDE "data/wildPokemon/diglettscave.asm"
INCLUDE "data/wildPokemon/mtmoonsquare.asm"
