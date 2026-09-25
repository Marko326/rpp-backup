CeruleanHouseTrashed_h:
	db HOUSE ; tileset
	db TRASHED_HOUSE_HEIGHT, TRASHED_HOUSE_WIDTH ; dimensions (y, x)
	; MSP-5.43.00: use the shared text-box routine directly; redundant local MapScript wrapper removed.
	dw CeruleanHouseTrashedBlocks, CeruleanHouseTrashedTextPointers, EnableAutoTextBoxDrawing ; blocks, texts, scripts
	db $00 ; connections
	dw CeruleanHouseTrashedObject ; objects
