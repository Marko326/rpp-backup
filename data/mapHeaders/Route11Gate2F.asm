Route11GateUpstairs_h:
	db GATE ; tileset
	db ROUTE_11_GATE_2F_HEIGHT, ROUTE_11_GATE_2F_WIDTH ; dimensions (y, x)
	; MSP-5.43.00: use the shared text-box routine directly; redundant local MapScript wrapper removed.
	dw Route11GateUpstairsBlocks, Route11GateUpstairsTextPointers, DisableAutoTextBoxDrawing ; blocks, texts, scripts
	db $00 ; connections
	dw Route11GateUpstairsObject ; objects
