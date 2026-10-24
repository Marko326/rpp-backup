Route12House_h:
	db HOUSE ; tileset
	db ROUTE_12_HOUSE_HEIGHT, ROUTE_12_HOUSE_WIDTH ; dimensions (y, x)
	; MSP-5.43.00: use the shared text-box routine directly; redundant local MapScript wrapper removed.
	dw Route12HouseBlocks, Route12HouseTextPointers, EnableAutoTextBoxDrawing ; blocks, texts, scripts
	db $00 ; connections
	dw Route12HouseObject ; objects
