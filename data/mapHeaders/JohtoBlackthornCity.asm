; Gold BlackthornCity: W Route44 (Gold offset +9), S Route45 (0).
JohtoBlackthornCity_h:
 db JOHTO
 db JOHTO_BLACKTHORN_CITY_HEIGHT, JOHTO_BLACKTHORN_CITY_WIDTH
 dw JohtoBlackthornCityBlocks, JohtoBlackthornCityTextPointers, EnableAutoTextBoxDrawing
 db SOUTH | WEST
 db REGION_NATIVE_MAP_SLOT
 dw JohtoRoute45Blocks
 dw wOverworldMap + (JOHTO_BLACKTHORN_CITY_HEIGHT + 3) * (JOHTO_BLACKTHORN_CITY_WIDTH + 6) + 3
 db JOHTO_ROUTE_45_WIDTH
 db JOHTO_ROUTE_45_WIDTH
 db 0
 db 0
 dw wOverworldMap + 7 + JOHTO_ROUTE_45_WIDTH
 db REGION_NATIVE_MAP_SLOT
 dw JohtoRoute44Blocks + JOHTO_ROUTE_44_WIDTH - 3
 dw wOverworldMap + (3 + 9) * (JOHTO_BLACKTHORN_CITY_WIDTH + 6)
 db JOHTO_ROUTE_44_HEIGHT
 db JOHTO_ROUTE_44_WIDTH
 db -18
 db JOHTO_ROUTE_44_WIDTH * 2 - 1
 dw wOverworldMap + 6 + 2 * JOHTO_ROUTE_44_WIDTH
 dw JohtoBlackthornCityObject
