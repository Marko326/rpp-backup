CeladonMansion1_h:
	db MANSION ; tileset
	db CELADON_MANSION_1_HEIGHT, CELADON_MANSION_1_WIDTH ; dimensions (y, x)
	; MSP-5.43.00: use the shared text-box routine directly; redundant local MapScript wrapper removed.
	dw CeladonMansion1Blocks, CeladonMansion1TextPointers, EnableAutoTextBoxDrawing ; blocks, texts, scripts
	db $00 ; connections
	dw CeladonMansion1Object ; objects
