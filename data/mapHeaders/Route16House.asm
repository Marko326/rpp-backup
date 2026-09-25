Route16House_h:
	db HOUSE ; tileset
	db ROUTE_16_HOUSE_HEIGHT, ROUTE_16_HOUSE_WIDTH ; dimensions (y, x)
	; MSP-5.43.00: use the shared text-box routine directly; redundant local MapScript wrapper removed.
	dw Route16HouseBlocks, Route16HouseTextPointers, EnableAutoTextBoxDrawing ; blocks, texts, scripts
	db $00 ; connections
	dw Route16HouseObject ; objects
