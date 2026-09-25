CeladonMansion5_h:
	db HOUSE ; tileset
	db CELADON_MANSION_5_HEIGHT, CELADON_MANSION_5_WIDTH ; dimensions (y, x)
	; MSP-5.43.00: use the shared text-box routine directly; redundant local MapScript wrapper removed.
	dw CeladonMansion5Blocks, CeladonMansion5TextPointers, EnableAutoTextBoxDrawing ; blocks, texts, scripts
	db $00 ; connections
	dw CeladonMansion5Object ; objects
