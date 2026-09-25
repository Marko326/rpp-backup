CeladonMansion3_h:
	db MANSION ; tileset
	db CELADON_MANSION_3_HEIGHT, CELADON_MANSION_3_WIDTH ; dimensions (y, x)
	; MSP-5.43.00: use the shared text-box routine directly; redundant local MapScript wrapper removed.
	dw CeladonMansion3Blocks, CeladonMansion3TextPointers, EnableAutoTextBoxDrawing ; blocks, texts, scripts
	db $00 ; connections
	dw CeladonMansion3Object ; objects
