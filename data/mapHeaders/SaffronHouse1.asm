SaffronHouse1_h:
	db HOUSE ; tileset
	db SAFFRON_HOUSE_1_HEIGHT, SAFFRON_HOUSE_1_WIDTH ; dimensions (y, x)
	; MSP-5.43.00: use the shared text-box routine directly; redundant local MapScript wrapper removed.
	dw SaffronHouse1Blocks, SaffronHouse1TextPointers, EnableAutoTextBoxDrawing ; blocks, texts, scripts
	db $00 ; connections
	dw SaffronHouse1Object ; objects
