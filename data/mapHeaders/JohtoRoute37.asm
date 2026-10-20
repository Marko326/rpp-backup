; Gold Route37 10x9 original Johto terrain, local ID 21. North Ecruteak now open.
JohtoRoute37_h:
	db JOHTO
	db JOHTO_ROUTE_37_HEIGHT, JOHTO_ROUTE_37_WIDTH
	dw JohtoRoute37Blocks, JohtoRoute37TextPointers, EnableAutoTextBoxDrawing
	db NORTH | SOUTH
	; Gold Route37 north -> EcruteakCity south, offset -5 blocks.
	db REGION_NATIVE_MAP_SLOT
	dw JohtoEcruteakCityBlocks + JOHTO_ECRUTEAK_CITY_WIDTH * (JOHTO_ECRUTEAK_CITY_HEIGHT - 3) + 5
	dw wOverworldMap + 3
	db JOHTO_ROUTE_37_WIDTH
	db JOHTO_ECRUTEAK_CITY_WIDTH
	db JOHTO_ECRUTEAK_CITY_HEIGHT * 2 - 1
	db 10
	dw wOverworldMap + 1 + JOHTO_ECRUTEAK_CITY_HEIGHT * (JOHTO_ECRUTEAK_CITY_WIDTH + 6)
	; Gold Route37 south -> Route36 north, offset -10 blocks.
	; Source Route36 columns 10..19; the exact overlap is 10 blocks.
	db REGION_NATIVE_MAP_SLOT
	dw JohtoRoute36Blocks + 10
	dw wOverworldMap + (JOHTO_ROUTE_37_HEIGHT + 3) * (JOHTO_ROUTE_37_WIDTH + 6) + 3
	db JOHTO_ROUTE_37_WIDTH
	db JOHTO_ROUTE_36_WIDTH
	db 0
	db 20
	dw wOverworldMap + 7 + JOHTO_ROUTE_36_WIDTH
	dw JohtoRoute37Object
