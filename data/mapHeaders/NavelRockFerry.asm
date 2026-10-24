NavelRockFerryDock_h:
	db FERRY ; tileset
	db NAVEL_ROCK_FERRY_DOCK_HEIGHT, NAVEL_ROCK_FERRY_DOCK_WIDTH ; dimensions (y, x)
	; MSP-5.43.00: use the shared text-box routine directly; redundant local MapScript wrapper removed.
	dw NavelRockFerryBlocks, NavelRockFerryTextPointers, EnableAutoTextBoxDrawing ; blocks, texts, scripts
	db $00 ; connections
	dw NavelRockFerryObject ; objects
