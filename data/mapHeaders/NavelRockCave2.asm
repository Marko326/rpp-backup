NavelRockCave2_h:
	db CAVERN ; tileset
	db NAVEL_ROCK_CAVE_2_HEIGHT, NAVEL_ROCK_CAVE_2_WIDTH ; dimensions (y, x)
	; MSP-5.43.00: use the shared text-box routine directly; redundant local MapScript wrapper removed.
	dw NavelRockCave2Blocks, NavelRockCave2TextPointers, EnableAutoTextBoxDrawing ; blocks, texts, scripts
	db $00 ; connections
	dw NavelRockCave2Object ; objects
