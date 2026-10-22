; Gold Route45 N Blackthorn (0), W Route46 (Gold offset+36).
JohtoRoute45_h:
 db JOHTO
 db JOHTO_ROUTE_45_HEIGHT, JOHTO_ROUTE_45_WIDTH
 dw JohtoRoute45Blocks, JohtoRoute45TextPointers, EnableAutoTextBoxDrawing
 db NORTH | WEST
 db REGION_NATIVE_MAP_SLOT
 dw JohtoBlackthornCityBlocks + JOHTO_BLACKTHORN_CITY_WIDTH * (JOHTO_BLACKTHORN_CITY_HEIGHT - 3)
 dw wOverworldMap + 3
 db JOHTO_ROUTE_45_WIDTH
 db JOHTO_BLACKTHORN_CITY_WIDTH
 db JOHTO_BLACKTHORN_CITY_HEIGHT * 2 - 1
 db 0
 dw wOverworldMap + 1 + JOHTO_BLACKTHORN_CITY_HEIGHT * (JOHTO_BLACKTHORN_CITY_WIDTH + 6)
 db REGION_NATIVE_MAP_SLOT
 dw JohtoRoute46Blocks + JOHTO_ROUTE_46_WIDTH - 3
 dw wOverworldMap + (3 + 36) * (JOHTO_ROUTE_45_WIDTH + 6)
 db JOHTO_ROUTE_45_HEIGHT - 36
 db JOHTO_ROUTE_46_WIDTH
 db -72
 db JOHTO_ROUTE_46_WIDTH * 2 - 1
 dw wOverworldMap + 6 + 2 * JOHTO_ROUTE_46_WIDTH
 dw JohtoRoute45Object
