; EAST-Route42: Gold route 30x9, west EcruteakCity -9 blocks; east remains
; disconnected until MahoganyTown is registered.
JohtoRoute42_h:
	db JOHTO
	db JOHTO_ROUTE_42_HEIGHT, JOHTO_ROUTE_42_WIDTH
	dw JohtoRoute42Blocks, JohtoRoute42TextPointers, EnableAutoTextBoxDrawing
	db WEST | EAST
	; EcruteakCity west reciprocal: Gold -9; 9 shared source rows.
	db REGION_NATIVE_MAP_SLOT
	dw JohtoEcruteakCityBlocks + 9 * JOHTO_ECRUTEAK_CITY_WIDTH + JOHTO_ECRUTEAK_CITY_WIDTH - 3
	dw wOverworldMap + 3 * (JOHTO_ROUTE_42_WIDTH + 6)
	db JOHTO_ROUTE_42_HEIGHT
	db JOHTO_ECRUTEAK_CITY_WIDTH
	db 18
	db JOHTO_ECRUTEAK_CITY_WIDTH * 2 - 1
	dw wOverworldMap + 6 + 2 * JOHTO_ECRUTEAK_CITY_WIDTH
	; Gold Route42 east -> MahoganyTown west, offset 0.
	db REGION_NATIVE_MAP_SLOT
	dw JohtoMahoganyTownBlocks
	dw wOverworldMap + 3 * (JOHTO_ROUTE_42_WIDTH + 6) + JOHTO_ROUTE_42_WIDTH + 3
	db JOHTO_MAHOGANY_TOWN_HEIGHT
	db JOHTO_MAHOGANY_TOWN_WIDTH
	db 0
	db 0
	dw wOverworldMap + 7 + JOHTO_MAHOGANY_TOWN_WIDTH
	dw JohtoRoute42Object
