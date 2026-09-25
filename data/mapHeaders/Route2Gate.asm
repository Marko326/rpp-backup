Route2Gate_h:
	db GATE ; tileset
	db ROUTE_2_GATE_HEIGHT, ROUTE_2_GATE_WIDTH ; dimensions (y, x)
	; MSP-5.43.00: use the shared text-box routine directly; redundant local MapScript wrapper removed.
	dw Route2GateBlocks, Route2GateTextPointers, EnableAutoTextBoxDrawing ; blocks, texts, scripts
	db $00 ; connections
	dw Route2GateObject ; objects
