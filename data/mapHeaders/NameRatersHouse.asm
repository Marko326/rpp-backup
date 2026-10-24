NameRater_h:
	db HOUSE ; tileset
	db NAME_RATERS_HOUSE_HEIGHT, NAME_RATERS_HOUSE_WIDTH ; dimensions (y, x)
	; MSP-5.43.00: use the shared text-box routine directly; redundant local MapScript wrapper removed.
	dw NameRaterBlocks, NameRaterTextPointers, EnableAutoTextBoxDrawing ; blocks, texts, scripts
	db $00 ; connections
	dw NameRaterObject ; objects
