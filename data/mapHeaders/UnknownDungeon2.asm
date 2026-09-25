UnknownDungeon2_h:
	db CAVERN ; tileset
	db UNKNOWN_DUNGEON_2_HEIGHT, UNKNOWN_DUNGEON_2_WIDTH ; dimensions (y, x)
	; MSP-5.43.00: use the shared text-box routine directly; redundant local MapScript wrapper removed.
	dw UnknownDungeon2Blocks, UnknownDungeon2TextPointers, EnableAutoTextBoxDrawing ; blocks, texts, scripts
	db $00 ; connections
	dw UnknownDungeon2Object ; objects
