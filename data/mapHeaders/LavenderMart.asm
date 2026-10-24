LavenderMart_h:
	db MART ; tileset
	db LAVENDER_MART_HEIGHT, LAVENDER_MART_WIDTH ; dimensions (y, x)
	; MSP-5.43.00: use the shared text-box routine directly; redundant local MapScript wrapper removed.
	dw LavenderMartBlocks, LavenderMartTextPointers, EnableAutoTextBoxDrawing ; blocks, texts, scripts
	db $00 ; connections
	dw LavenderMartObject ; objects
