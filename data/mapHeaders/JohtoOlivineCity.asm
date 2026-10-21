; Gold OlivineCity 20x18, Route39 north connected; Route40 west is not built.
JohtoOlivineCity_h:
 db JOHTO
 db JOHTO_OLIVINE_CITY_HEIGHT, JOHTO_OLIVINE_CITY_WIDTH
 dw JohtoOlivineCityBlocks, JohtoOlivineCityTextPointers, EnableAutoTextBoxDrawing
 db NORTH
 ; Gold north -> Route39 south, +5 blocks: road columns 0..9 align city 5..14.
 db REGION_NATIVE_MAP_SLOT
 dw JohtoRoute39Blocks + JOHTO_ROUTE_39_WIDTH * (JOHTO_ROUTE_39_HEIGHT - 3)
 dw wOverworldMap + 3 + 5
 db JOHTO_ROUTE_39_WIDTH
 db JOHTO_ROUTE_39_WIDTH
 db JOHTO_ROUTE_39_HEIGHT * 2 - 1
 db -10
 dw wOverworldMap + 1 + JOHTO_ROUTE_39_HEIGHT * (JOHTO_ROUTE_39_WIDTH + 6)
 dw JohtoOlivineCityObject
