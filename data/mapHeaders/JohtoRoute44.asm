; Gold Route44 W Mahogany (offset0), E Blackthorn (offset -9).
JohtoRoute44_h:
 db JOHTO
 db JOHTO_ROUTE_44_HEIGHT, JOHTO_ROUTE_44_WIDTH
 dw JohtoRoute44Blocks, JohtoRoute44TextPointers, EnableAutoTextBoxDrawing
 db WEST | EAST
 db REGION_NATIVE_MAP_SLOT
 dw JohtoMahoganyTownBlocks + JOHTO_MAHOGANY_TOWN_WIDTH - 3
 dw wOverworldMap + 3 * (JOHTO_ROUTE_44_WIDTH + 6)
 db JOHTO_ROUTE_44_HEIGHT
 db JOHTO_MAHOGANY_TOWN_WIDTH
 db 0
 db JOHTO_MAHOGANY_TOWN_WIDTH * 2 - 1
 dw wOverworldMap + 6 + 2 * JOHTO_MAHOGANY_TOWN_WIDTH
 db REGION_NATIVE_MAP_SLOT
 dw JohtoBlackthornCityBlocks + 9 * JOHTO_BLACKTHORN_CITY_WIDTH
 dw wOverworldMap + 3 * (JOHTO_ROUTE_44_WIDTH + 6) + JOHTO_ROUTE_44_WIDTH + 3
 db JOHTO_ROUTE_44_HEIGHT
 db JOHTO_BLACKTHORN_CITY_WIDTH
 db 18
 db 0
 dw wOverworldMap + 7 + JOHTO_BLACKTHORN_CITY_WIDTH
 dw JohtoRoute44Object
