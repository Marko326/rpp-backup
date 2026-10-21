; Gold Route41 25x27, north Route40 and west Cianwood City.
JohtoRoute41_h:
 db JOHTO
 db JOHTO_ROUTE_41_HEIGHT, JOHTO_ROUTE_41_WIDTH
 dw JohtoRoute41Blocks, JohtoRoute41TextPointers, EnableAutoTextBoxDrawing
 db NORTH | WEST
 ; North -> Route40 south, Gold offset +15: Route41 x15..24 maps Route40 x0..9.
 db REGION_NATIVE_MAP_SLOT
 dw JohtoRoute40Blocks + JOHTO_ROUTE_40_WIDTH * (JOHTO_ROUTE_40_HEIGHT - 3)
 dw wOverworldMap + 3 + 15
 db JOHTO_ROUTE_40_WIDTH
 db JOHTO_ROUTE_40_WIDTH
 db JOHTO_ROUTE_40_HEIGHT * 2 - 1
 db -30
 dw wOverworldMap + 1 + JOHTO_ROUTE_40_HEIGHT * (JOHTO_ROUTE_40_WIDTH + 6)
 ; West -> Cianwood City east, Gold offset 0.
 db REGION_NATIVE_MAP_SLOT
 dw JohtoCianwoodCityBlocks + JOHTO_CIANWOOD_CITY_WIDTH - 3
 dw wOverworldMap + 3 * (JOHTO_ROUTE_41_WIDTH + 6)
 db JOHTO_ROUTE_41_HEIGHT
 db JOHTO_CIANWOOD_CITY_WIDTH
 db 0
 db JOHTO_CIANWOOD_CITY_WIDTH * 2 - 1
 dw wOverworldMap + 6 + 2 * JOHTO_CIANWOOD_CITY_WIDTH
 dw JohtoRoute41Object
