NavelRockCave1_h:
	db CAVERN ; tileset
	db NAVEL_ROCK_CAVE_1_HEIGHT, NAVEL_ROCK_CAVE_1_WIDTH ; dimensions (y, x)
	; MSP-5.43.00: use the shared text-box routine directly; redundant local MapScript wrapper removed.
	dw NavelRockCave1Blocks, NavelRockCave1TextPointers, EnableAutoTextBoxDrawing ; blocks, texts, scripts
	db $00 ; connections
	dw NavelRockCave1Object ; objects
