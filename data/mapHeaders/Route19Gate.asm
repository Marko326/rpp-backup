Route19Gate_h:
	db GATE ; tileset
	db ROUTE_19_GATE_HEIGHT, ROUTE_19_GATE_WIDTH ; dimensions (y, x)
	; MSP-5.43.00: use the shared text-box routine directly; redundant local MapScript wrapper removed.
	dw Route19GateBlocks, Route19GateTextPointers, EnableAutoTextBoxDrawing ; blocks, texts, scripts
	db $00 ; connections
	dw Route19GateObject ; objects
