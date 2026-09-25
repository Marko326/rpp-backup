Route12Gate_h:
	db GATE ; tileset
	db ROUTE_12_GATE_1F_HEIGHT, ROUTE_12_GATE_1F_WIDTH ; dimensions (y, x)
	; MSP-5.43.00: use the shared text-box routine directly; redundant local MapScript wrapper removed.
	dw Route12GateBlocks, Route12GateTextPointers, EnableAutoTextBoxDrawing ; blocks, texts, scripts
	db $00 ; connections
	dw Route12GateObject ; objects
