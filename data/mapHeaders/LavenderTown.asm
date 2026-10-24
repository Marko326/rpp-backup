LavenderTown_h:
	db OVERWORLD ; tileset
	db LAVENDER_TOWN_HEIGHT, LAVENDER_TOWN_WIDTH ; dimensions (y, x)
	; MSP-5.43.00: use the shared text-box routine directly; redundant local MapScript wrapper removed.
	dw LavenderTownBlocks, LavenderTownTextPointers, EnableAutoTextBoxDrawing ; blocks, texts, scripts
	db NORTH | SOUTH | WEST ; connections
	NORTH_MAP_CONNECTION LAVENDER_TOWN, ROUTE_10, 2, 0, Route10Blocks
	SOUTH_MAP_CONNECTION LAVENDER_TOWN, ROUTE_12, 2, 0, Route12Blocks, 1
	WEST_MAP_CONNECTION LAVENDER_TOWN, ROUTE_8, 0, 0, Route8Blocks
	dw LavenderTownObject ; objects
