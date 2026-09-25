PewterHouse1_h:
	db HOUSE ; tileset
	db PEWTER_HOUSE_1_HEIGHT, PEWTER_HOUSE_1_WIDTH ; dimensions (y, x)
	; MSP-5.43.00: use the shared text-box routine directly; redundant local MapScript wrapper removed.
	dw PewterHouse1Blocks, PewterHouse1TextPointers, EnableAutoTextBoxDrawing ; blocks, texts, scripts
	db $00 ; connections
	dw PewterHouse1Object ; objects
