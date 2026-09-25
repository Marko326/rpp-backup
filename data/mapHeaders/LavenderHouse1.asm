LavenderHouse1_h:
	db HOUSE ; tileset
	db LAVENDER_HOUSE_1_HEIGHT, LAVENDER_HOUSE_1_WIDTH ; dimensions (y, x)
	; MSP-5.43.00: use the shared text-box routine directly; redundant local MapScript wrapper removed.
	dw LavenderHouse1Blocks, LavenderHouse1TextPointers, EnableAutoTextBoxDrawing ; blocks, texts, scripts
	db $00 ; connections
	dw LavenderHouse1Object ; objects
