; Gold Route40 10x18, active west sea chain. Both source connections open.
JohtoRoute40_h:
 db JOHTO
 db JOHTO_ROUTE_40_HEIGHT, JOHTO_ROUTE_40_WIDTH
 dw JohtoRoute40Blocks, JohtoRoute40TextPointers, EnableAutoTextBoxDrawing
 db SOUTH | EAST
 ; South -> Route41 north, Gold offset -15: Route40 x0 maps Route41 x15.
 db REGION_NATIVE_MAP_SLOT
 dw JohtoRoute41Blocks + 15
 dw wOverworldMap + (JOHTO_ROUTE_40_HEIGHT + 3) * (JOHTO_ROUTE_40_WIDTH + 6) + 3
 db JOHTO_ROUTE_40_WIDTH
 db JOHTO_ROUTE_41_WIDTH
 db 0
 db 30
 dw wOverworldMap + 7 + JOHTO_ROUTE_41_WIDTH
 ; East -> Olivine west, Gold offset -9: route row0 is city row9.
 db REGION_NATIVE_MAP_SLOT
 dw JohtoOlivineCityBlocks + JOHTO_OLIVINE_CITY_WIDTH * 9
 dw wOverworldMap + 3 * (JOHTO_ROUTE_40_WIDTH + 6) + JOHTO_ROUTE_40_WIDTH + 3
 db 9
 db JOHTO_OLIVINE_CITY_WIDTH
 db 18
 db 0
 dw wOverworldMap + 7 + JOHTO_OLIVINE_CITY_WIDTH
 dw JohtoRoute40Object
