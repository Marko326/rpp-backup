CeladonMansion4_h:
	db MANSION ; tileset
	db CELADON_MANSION_4_HEIGHT, CELADON_MANSION_4_WIDTH ; dimensions (y, x)
	; MSP-5.43.00: use the shared text-box routine directly; redundant local MapScript wrapper removed.
	dw CeladonMansion4Blocks, CeladonMansion4TextPointers, EnableAutoTextBoxDrawing ; blocks, texts, scripts
	db $00 ; connections
	dw CeladonMansion4Object ; objects
