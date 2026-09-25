FuchsiaCity_h:
	db OVERWORLD ; tileset
	db FUCHSIA_CITY_HEIGHT, FUCHSIA_CITY_WIDTH ; dimensions (y, x)
	; MSP-5.43.00: use the shared text-box routine directly; redundant local MapScript wrapper removed.
	dw FuchsiaCityBlocks, FuchsiaCityTextPointers, EnableAutoTextBoxDrawing ; blocks, texts, scripts
	db SOUTH | WEST | EAST ; connections
	SOUTH_MAP_CONNECTION FUCHSIA_CITY, ROUTE_19, 5, 0, Route19Blocks
	WEST_MAP_CONNECTION FUCHSIA_CITY, ROUTE_18, 4, 0, Route18Blocks
	EAST_MAP_CONNECTION FUCHSIA_CITY, ROUTE_15, 4, 0, Route15Blocks
	dw FuchsiaCityObject ; objects
