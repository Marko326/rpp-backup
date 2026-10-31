Tilesets:
	tileset Overworld_Block,   Overworld_GFX,   Overworld_Coll,   $FF,$FF,$FF, $52, OUTDOOR
	tileset RedsHouse1_Block,  RedsHouse1_GFX,  RedsHouse1_Coll,  $FF,$FF,$FF, $FF, INDOOR
	tileset Mart_Block,        Mart_GFX,        Mart_Coll,        32,49,255, 255, 0
	tileset Forest_Block,      Forest_GFX,      Forest_Coll,      $FF,$FF,$FF, $20, CAVE
	tileset RedsHouse2_Block,  RedsHouse2_GFX,  RedsHouse2_Coll,  $FF,$FF,$FF, $FF, INDOOR
	tileset OakTS_Block,       OakTS_GFX,       OakTS_Coll,       255,255,255, 255, 0
	tileset Pokecenter_Block,  Pokecenter_GFX,  Pokecenter_Coll,  92,75,255, 255, 0
	tileset Gym_Block,         Gym_GFX,         Gym_Coll,         $3A,$FF,$FF, $FF, OUTDOOR
	tileset House_Block,       House_GFX,       House_Coll,       54,255,255, 255, 0
	tileset ForestGate_Block,  ForestGate_GFX,  ForestGate_Coll,  $17,$32,$FF, $FF, INDOOR
	tileset Museum_Block,      Museum_GFX,      Museum_Coll,      64,81,255, 255, 0
	tileset Underground_Block, Underground_GFX, Underground_Coll, $FF,$FF,$FF, $FF, INDOOR
	tileset Gate_Block,        Gate_GFX,        Gate_Coll,        69,52,255, 255, 0
	tileset Ship_Block,        Ship_GFX,        Ship_Coll,        $FF,$FF,$FF, $FF, CAVE
	tileset ShipPort_Block,    ShipPort_GFX,    ShipPort_Coll,    $FF,$FF,$FF, $FF, CAVE
	tileset Cemetery_Block,    Cemetery_GFX,    Cemetery_Coll,    $12,$FF,$FF, $FF, INDOOR
	tileset Interior_Block,    Interior_GFX,    Interior_Coll,    $FF,$FF,$FF, $FF, INDOOR
	tileset Cavern_Block,      Cavern_GFX,      Cavern_Coll,      $FF,$FF,$FF, $FF, CAVE
	tileset Lobby_Block,       Lobby_GFX,       Lobby_Coll,       21,18,255, 255, 0
	tileset Mansion_Block,     Mansion_GFX,     Mansion_Coll,     $FF,$FF,$FF, $FF, INDOOR
	tileset Lab_Block,         Lab_GFX,         Lab_Coll,         $FF,$FF,$FF, $FF, INDOOR
	tileset Club_Block,        Club_GFX,        Club_Coll,        $07,$17,$FF, $FF, INDOOR
	tileset Facility_Block,    Facility_GFX,    Facility_Coll,    $12,$FF,$FF, $FF, CAVE
	tileset Plateau_Block,     Plateau_GFX,     Plateau_Coll,     $FF,$FF,$FF, $45, CAVE
	tileset Safari_Block,      Safari_GFX,      Safari_Coll,      $FF,$FF,$FF, $20, CAVE
	tileset Ferry_Block,       Ferry_GFX,       Ferry_Coll,       255,255,255, 19, OUTDOOR
	tileset Cavern_Block,      Ice_Cavern_GFX,  Cavern_Coll,      $FF,$FF,$FF, $FF, CAVE
	tileset Museum2_Block,     Museum2_GFX,     Museum_Coll,	  64,81,255, 255, 0
	; Johto graphics/blocks stay in ROMX; the unbanked collision readers require
	; a ROM0 passability pointer. Original Kanto tileset records stay untouched.
	tileset JohtoPilot_Block, JohtoPilot_GFX, JohtoPilot_Coll, $FF,$FF,$FF, $04, OUTDOOR
	; Gold house keeps separate graphics/blocks; collisions are in ROM0 too.
	tileset JohtoHouse_Block, JohtoHouse_GFX, JohtoHouse_Coll, $FF,$FF,$FF, $FF, INDOOR
	; Reuse the RPP Kanto gate collision vocabulary; dedicated Gold art/blocks.
	tileset JohtoGate_Block, JohtoGate_GFX, Gate_Coll, $FF,$FF,$FF, $FF, INDOOR
	; Gold CAVE environment, independent compact art and always-readable ROM0 collision.
	tileset JohtoUnionCave_Block, JohtoUnionCave_GFX, JohtoUnionCave_Coll, $FF,$FF,$FF, $FF, CAVE
	tileset JohtoModern_Block, JohtoModern_GFX, JohtoModern_Coll, $FF,$FF,$FF, $04, OUTDOOR
	tileset JohtoSouthForestBlocks, JohtoSouthForestGFX, JohtoIlexForest_Coll, $FF,$FF,$FF, $FF, CAVE
	tileset JohtoSouthGateBlocks, JohtoSouthGateGFX, Gate_Coll, $FF,$FF,$FF, $FF, INDOOR
	tileset JohtoPark_Block, JohtoPark_GFX, JohtoPilot_Coll, $FF,$FF,$FF, $04, OUTDOOR ; FIX-288: Gold Park tall grass
	tileset JohtoParkGate_Block, JohtoParkGate_GFX, Gate_Coll, $FF,$FF,$FF, $FF, INDOOR
TilesetsEnd::
ASSERT TilesetsEnd - Tilesets == (JOHTO_PARK_GATE + 1) * 12
ASSERT JOHTO_PILOT == 28
ASSERT JOHTO_HOUSE == 29
ASSERT JOHTO_GATE == 30
ASSERT JOHTO_UNION_CAVE == 31
ASSERT JOHTO_MODERN == 32
ASSERT BANK(JohtoModern_Block) == BANK(JohtoModern_GFX)
ASSERT BANK(JohtoIlexForest_Coll) == 0
ASSERT BANK(JohtoModern_Coll) == 0
ASSERT BANK(JohtoUnionCave_Block) == BANK(JohtoUnionCave_GFX)
ASSERT BANK(JohtoUnionCave_Coll) == 0
ASSERT BANK(JohtoGate_Block) == BANK(JohtoGate_GFX)
ASSERT BANK(JohtoHouse_Block) == BANK(JohtoHouse_GFX)
ASSERT BANK(JohtoHouse_Coll) == 0
ASSERT BANK(JohtoPilot_Block) == BANK(JohtoPilot_GFX)
ASSERT BANK(JohtoPilot_Coll) == 0
