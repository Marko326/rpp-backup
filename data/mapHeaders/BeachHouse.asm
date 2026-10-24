BeachHouse_h:
	db HOUSE ; tileset
	db BEACH_HOUSE_HEIGHT, BEACH_HOUSE_WIDTH ; dimensions (y, x)
	; MSP-5.43.00: use the shared text-box routine directly; redundant local MapScript wrapper removed.
	dw BeachHouseBlocks, BeachHouseTextPointers, EnableAutoTextBoxDrawing ; blocks, texts, scripts
	db $00 ; connections
	dw BeachHouseObject ; objects
