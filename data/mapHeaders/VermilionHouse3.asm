VermilionHouse3_h:
	db HOUSE ; tileset
	db VERMILION_HOUSE_3_HEIGHT, VERMILION_HOUSE_3_WIDTH ; dimensions (y, x)
	; MSP-5.43.00: use the shared text-box routine directly; redundant local MapScript wrapper removed.
	dw VermilionHouse3Blocks, VermilionHouse3TextPointers, EnableAutoTextBoxDrawing ; blocks, texts, scripts
	db $00 ; connections
	dw VermilionHouse3Object ; objects
