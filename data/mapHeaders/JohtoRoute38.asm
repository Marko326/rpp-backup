; Gold Route38 20x9, local ID 24. East Ecruteak display strip only;
; city access uses audited gate Warps, not a direct physical connection.
; West Route39 now active; east still enters Ecruteak through Gate only.
JohtoRoute38_h:
	db JOHTO
	db JOHTO_ROUTE_38_HEIGHT, JOHTO_ROUTE_38_WIDTH
	dw JohtoRoute38Blocks, JohtoRoute38TextPointers, EnableAutoTextBoxDrawing
	db WEST | EAST
 ; Gold Route38 west -> Route39 east, same Y positions for 9 shared rows.
 db REGION_NATIVE_MAP_SLOT
 dw JohtoRoute39Blocks + JOHTO_ROUTE_39_WIDTH - 3
 dw wOverworldMap + 3 * (JOHTO_ROUTE_38_WIDTH + 6)
 db JOHTO_ROUTE_38_HEIGHT
 db JOHTO_ROUTE_39_WIDTH
 db 0
 db JOHTO_ROUTE_39_WIDTH * 2 - 1
 dw wOverworldMap + 6 + 2 * JOHTO_ROUTE_39_WIDTH
	; Gold Route38 east -> EcruteakCity west, offset -5 blocks.
	; Route38 row 0 is beside Ecruteak row 5.
	db REGION_NATIVE_MAP_SLOT
	dw JohtoEcruteakCityBlocks + JOHTO_ECRUTEAK_CITY_WIDTH * 5
	dw wOverworldMap + 3 * (JOHTO_ROUTE_38_WIDTH + 6) + JOHTO_ROUTE_38_WIDTH + 3
	db JOHTO_ROUTE_38_HEIGHT
	db JOHTO_ECRUTEAK_CITY_WIDTH
	db 10 ; arrival Y = Route38 Y + 5 blocks
	db 0 ; east arrival X
	dw wOverworldMap + 7 + JOHTO_ECRUTEAK_CITY_WIDTH
	dw JohtoRoute38Object
