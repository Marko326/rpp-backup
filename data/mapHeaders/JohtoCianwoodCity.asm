; Gold Cianwood City 15x27, Route41 east. Indoor services deferred.
JohtoCianwoodCity_h:
 db JOHTO
 db JOHTO_CIANWOOD_CITY_HEIGHT, JOHTO_CIANWOOD_CITY_WIDTH
 dw JohtoCianwoodCityBlocks, JohtoCianwoodCityTextPointers, EnableAutoTextBoxDrawing
 db EAST
 ; East -> Route41 west, Gold offset 0.
 db REGION_NATIVE_MAP_SLOT
 dw JohtoRoute41Blocks
 dw wOverworldMap + 3 * (JOHTO_CIANWOOD_CITY_WIDTH + 6) + JOHTO_CIANWOOD_CITY_WIDTH + 3
 db JOHTO_ROUTE_41_HEIGHT
 db JOHTO_ROUTE_41_WIDTH
 db 0
 db 0
 dw wOverworldMap + 7 + JOHTO_ROUTE_41_WIDTH
 dw JohtoCianwoodCityObject
