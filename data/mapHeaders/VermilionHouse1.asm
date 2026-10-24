VermilionHouse1_h:
	db HOUSE ; tileset
	db VERMILION_HOUSE_1_HEIGHT, VERMILION_HOUSE_1_WIDTH ; dimensions (y, x)
	; MSP-5.43.00: use the shared text-box routine directly; redundant local MapScript wrapper removed.
	dw VermilionHouse1Blocks, VermilionHouse1TextPointers, EnableAutoTextBoxDrawing ; blocks, texts, scripts
	db $00 ; connections
	dw VermilionHouse1Object ; objects
