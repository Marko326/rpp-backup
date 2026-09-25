FarawayIslandOutside_h:
	db FERRY ; tileset
	db FARAWAY_ISLAND_OUTSIDE_HEIGHT, FARAWAY_ISLAND_OUTSIDE_WIDTH ; dimensions (y, x)
	; MSP-5.43.00: use the shared text-box routine directly; redundant local MapScript wrapper removed.
	dw FarawayIslandOutsideBlocks, FarawayIslandOutsideTextPointers, EnableAutoTextBoxDrawing ; blocks, texts, scripts
	db $00 ; connections
	dw FarawayIslandOutsideObject ; objects
