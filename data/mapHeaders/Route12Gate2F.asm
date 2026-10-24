Route12GateUpstairs_h:
	db GATE ; tileset
	db ROUTE_12_GATE_2F_HEIGHT, ROUTE_12_GATE_2F_WIDTH ; dimensions (y, x)
	; MSP-5.43.00: use the shared text-box routine directly; redundant local MapScript wrapper removed.
	dw Route12GateUpstairsBlocks, Route12GateUpstairsTextPointers, DisableAutoTextBoxDrawing ; blocks, texts, scripts
	db $00 ; connections
	dw Route12GateUpstairsObject ; objects
