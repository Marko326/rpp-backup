DayCareM_h:
	db HOUSE ; tileset
	db DAYCAREM_HEIGHT, DAYCAREM_WIDTH ; dimensions (y, x)
	; MSP-5.43.00: use the shared text-box routine directly; redundant local MapScript wrapper removed.
	dw DayCareMBlocks, DayCareMTextPointers, EnableAutoTextBoxDrawing ; blocks, texts, scripts
	db $00 ; connections
	dw DayCareMObject ; objects
