Route11Gate_h:
	db GATE ; tileset
	db ROUTE_11_GATE_1F_HEIGHT, ROUTE_11_GATE_1F_WIDTH ; dimensions (y, x)
	; MSP-5.43.00: use the shared text-box routine directly; redundant local MapScript wrapper removed.
	dw Route11GateBlocks, Route11GateTextPointers, EnableAutoTextBoxDrawing ; blocks, texts, scripts
	db $00 ; connections
	dw Route11GateObject ; objects
