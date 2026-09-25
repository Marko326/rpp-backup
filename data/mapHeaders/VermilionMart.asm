VermilionMart_h:
	db MART ; tileset
	db VERMILION_MART_HEIGHT, VERMILION_MART_WIDTH ; dimensions (y, x)
	; MSP-5.43.00: use the shared text-box routine directly; redundant local MapScript wrapper removed.
	dw VermilionMartBlocks, VermilionMartTextPointers, EnableAutoTextBoxDrawing ; blocks, texts, scripts
	db $00 ; connections
	dw VermilionMartObject ; objects
