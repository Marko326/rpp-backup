; Gold Route39 10x18, real Route38 east and OlivineCity south.
JohtoRoute39_h:
 db JOHTO
 db JOHTO_ROUTE_39_HEIGHT, JOHTO_ROUTE_39_WIDTH
 dw JohtoRoute39Blocks, JohtoRoute39TextPointers, EnableAutoTextBoxDrawing
 db SOUTH | EAST
 ; Gold south -> OlivineCity north, offset -5; city x10..19 matches road x0..9.
 db REGION_NATIVE_MAP_SLOT
 dw JohtoOlivineCityBlocks + 5
 dw wOverworldMap + (JOHTO_ROUTE_39_HEIGHT + 3) * (JOHTO_ROUTE_39_WIDTH + 6) + 3
 db JOHTO_ROUTE_39_WIDTH
 db JOHTO_OLIVINE_CITY_WIDTH
 db 0
 db 10
 dw wOverworldMap + 7 + JOHTO_OLIVINE_CITY_WIDTH
 ; Gold east -> Route38 west, zero row offset, 9 visible rows.
 db REGION_NATIVE_MAP_SLOT
 dw JohtoRoute38Blocks
 dw wOverworldMap + 3 * (JOHTO_ROUTE_39_WIDTH + 6) + JOHTO_ROUTE_39_WIDTH + 3
 db JOHTO_ROUTE_38_HEIGHT
 db JOHTO_ROUTE_38_WIDTH
 db 0
 db 0
 dw wOverworldMap + 7 + JOHTO_ROUTE_38_WIDTH
 dw JohtoRoute39Object
