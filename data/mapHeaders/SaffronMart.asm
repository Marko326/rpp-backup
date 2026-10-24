SaffronMart_h:
	db MART ; tileset
	db SAFFRON_MART_HEIGHT, SAFFRON_MART_WIDTH ; dimensions (y, x)
	; MSP-5.43.00: use the shared text-box routine directly; redundant local MapScript wrapper removed.
	dw SaffronMartBlocks, SaffronMartTextPointers, EnableAutoTextBoxDrawing ; blocks, texts, scripts
	db $00 ; connections
	dw SaffronMartObject ; objects
