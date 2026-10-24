NavelRockOutside_h:
	db OVERWORLD ; tileset
	db NAVEL_ROCK_OUTSIDE_HEIGHT, NAVEL_ROCK_OUTSIDE_WIDTH ; dimensions (y, x)
	; MSP-5.43.00: use the shared text-box routine directly; redundant local MapScript wrapper removed.
	dw NavelRockOutsideBlocks, NavelRockOutsideTextPointers, EnableAutoTextBoxDrawing ; blocks, texts, scripts
	db $00 ; connections
	dw NavelRockOutsideObject ; objects
