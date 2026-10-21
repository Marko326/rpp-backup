; ECR-5.62.225: Gold EcruteakCity 20x18, local 22, JOHTO tileset.
; Only south -> Route37 is currently open. Gold west/east and indoor warps
; await independently reviewed destinations; do not fake direct gate maps.
JohtoEcruteakCity_h:
	db JOHTO
	db JOHTO_ECRUTEAK_CITY_HEIGHT, JOHTO_ECRUTEAK_CITY_WIDTH
	dw JohtoEcruteakCityBlocks, JohtoEcruteakCityTextPointers, EnableAutoTextBoxDrawing
	db SOUTH | WEST
	; Gold EcruteakCity south -> Route37 north, offset +5 blocks.
	db REGION_NATIVE_MAP_SLOT
	dw JohtoRoute37Blocks
	dw wOverworldMap + (JOHTO_ECRUTEAK_CITY_HEIGHT + 3) * (JOHTO_ECRUTEAK_CITY_WIDTH + 6) + 3 + 5
	db JOHTO_ROUTE_37_WIDTH
	db JOHTO_ROUTE_37_WIDTH
	db 0
	db -10
	dw wOverworldMap + 7 + JOHTO_ROUTE_37_WIDTH
	; Gold City west <- Route38 east, City Y5..13 to Route38 Y0..8.
	db REGION_NATIVE_MAP_SLOT
	dw JohtoRoute38Blocks + JOHTO_ROUTE_38_WIDTH - 3
	dw wOverworldMap + (5 + 3) * (JOHTO_ECRUTEAK_CITY_WIDTH + 6)
	db JOHTO_ROUTE_38_HEIGHT
	db JOHTO_ROUTE_38_WIDTH
	db -10 ; arrival Y = City Y - 10
	db JOHTO_ROUTE_38_WIDTH * 2 - 1
	dw wOverworldMap + 6 + 2 * JOHTO_ROUTE_38_WIDTH
	dw JohtoEcruteakCityObject
