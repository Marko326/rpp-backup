Route18GateUpstairs_h:
	db GATE ; tileset
	db ROUTE_18_GATE_2F_HEIGHT, ROUTE_18_GATE_2F_WIDTH ; dimensions (y, x)
	; MSP-5.43.00: use the shared text-box routine directly; redundant local MapScript wrapper removed.
	dw Route18GateUpstairsBlocks, Route18GateUpstairsTextPointers, DisableAutoTextBoxDrawing ; blocks, texts, scripts
	db $00 ; connections
	dw Route18GateUpstairsObject ; objects
