LavenderHouse2_h:
	db HOUSE ; tileset
	db LAVENDER_HOUSE_2_HEIGHT, LAVENDER_HOUSE_2_WIDTH ; dimensions (y, x)
	; MSP-5.43.00: use the shared text-box routine directly; redundant local MapScript wrapper removed.
	dw LavenderHouse2Blocks, LavenderHouse2TextPointers, EnableAutoTextBoxDrawing ; blocks, texts, scripts
	db $00 ; connections
	dw LavenderHouse2Object ; objects
