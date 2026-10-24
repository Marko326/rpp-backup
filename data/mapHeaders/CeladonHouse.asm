CeladonHouse_h:
	db MANSION ; tileset
	db CELADON_HOUSE_HEIGHT, CELADON_HOUSE_WIDTH ; dimensions (y, x)
	; MSP-5.43.00: use the shared text-box routine directly; redundant local MapScript wrapper removed.
	dw CeladonHouseBlocks, CeladonHouseTextPointers, EnableAutoTextBoxDrawing ; blocks, texts, scripts
	db $00 ; connections
	dw CeladonHouseObject ; objects
