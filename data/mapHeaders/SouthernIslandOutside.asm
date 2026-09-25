SouthernIslandOutside_h:
	db FERRY ; tileset
	db SOUTHERN_ISLAND_OUTSIDE_HEIGHT, SOUTHERN_ISLAND_OUTSIDE_WIDTH ; dimensions (y, x)
	; MSP-5.43.00: use the shared text-box routine directly; redundant local MapScript wrapper removed.
	dw SouthernIslandOutsideBlocks, SouthernIslandOutsideTextPointers, EnableAutoTextBoxDrawing ; blocks, texts, scripts
	db $00 ; connections
	dw SouthernIslandOutsideObject ; objects
