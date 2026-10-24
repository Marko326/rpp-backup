UnknownDungeon1_h:
	db CAVERN ; tileset
	db UNKNOWN_DUNGEON_1_HEIGHT, UNKNOWN_DUNGEON_1_WIDTH ; dimensions (y, x)
	; MSP-5.43.00: use the shared text-box routine directly; redundant local MapScript wrapper removed.
	dw UnknownDungeon1Blocks, UnknownDungeon1TextPointers, EnableAutoTextBoxDrawing ; blocks, texts, scripts
	db $00 ; connections
	dw UnknownDungeon1Object ; objects
