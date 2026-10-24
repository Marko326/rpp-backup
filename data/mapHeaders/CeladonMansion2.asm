CeladonMansion2_h:
	db MANSION ; tileset
	db CELADON_MANSION_2_HEIGHT, CELADON_MANSION_2_WIDTH ; dimensions (y, x)
	; MSP-5.43.00: use the shared text-box routine directly; redundant local MapScript wrapper removed.
	dw CeladonMansion2Blocks, CeladonMansion2TextPointers, EnableAutoTextBoxDrawing ; blocks, texts, scripts
	db $00 ; connections
	dw CeladonMansion2Object ; objects
