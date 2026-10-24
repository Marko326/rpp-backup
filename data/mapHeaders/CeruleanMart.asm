CeruleanMart_h:
	db MART ; tileset
	db CERULEAN_MART_HEIGHT, CERULEAN_MART_WIDTH ; dimensions (y, x)
	; MSP-5.43.00: use the shared text-box routine directly; redundant local MapScript wrapper removed.
	dw CeruleanMartBlocks, CeruleanMartTextPointers, EnableAutoTextBoxDrawing ; blocks, texts, scripts
	db $00 ; connections
	dw CeruleanMartObject ; objects
