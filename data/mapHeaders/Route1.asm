Route1_h:
	db OVERWORLD ; tileset
	db ROUTE_1_HEIGHT, ROUTE_1_WIDTH ; dimensions (y, x)
	; MSP-5.43.00: use the shared text-box routine directly; redundant local MapScript wrapper removed.
	dw Route1Blocks, Route1TextPointers, EnableAutoTextBoxDrawing ; blocks, texts, scripts
	db NORTH | SOUTH ; connections
	NORTH_MAP_CONNECTION ROUTE_1, VIRIDIAN_CITY, -3, 2, ViridianCityBlocks
	SOUTH_MAP_CONNECTION ROUTE_1, PALLET_TOWN, 0, 0, PalletTownBlocks, 1
	dw Route1Object ; objects
