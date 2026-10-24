CeruleanHouse1_h:
	db HOUSE ; tileset
	db CERULEAN_HOUSE_1_HEIGHT, CERULEAN_HOUSE_1_WIDTH ; dimensions (y, x)
	; MSP-5.43.00: use the shared text-box routine directly; redundant local MapScript wrapper removed.
	dw CeruleanHouse1Blocks, CeruleanHouse1TextPointers, EnableAutoTextBoxDrawing ; blocks, texts, scripts
	db $00 ; connections
	dw CeruleanHouse1Object ; objects
