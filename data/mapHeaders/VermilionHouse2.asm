VermilionHouse2_h:
	db HOUSE ; tileset
	db VERMILION_HOUSE_2_HEIGHT, VERMILION_HOUSE_2_WIDTH ; dimensions (y, x)
	; MSP-5.43.00: use the shared text-box routine directly; redundant local MapScript wrapper removed.
	dw VermilionHouse2Blocks, VermilionHouse2TextPointers, EnableAutoTextBoxDrawing ; blocks, texts, scripts
	db $00 ; connections
	dw VermilionHouse2Object ; objects
