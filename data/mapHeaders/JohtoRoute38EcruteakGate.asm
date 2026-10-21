; Gold Route38EcruteakGate 5x4, exact EastWestGate bitmap.
; Both sides connected using native (region,stable-ID) Warp resolution.
JohtoRoute38EcruteakGate_h:
	db JOHTO_GATE
	db JOHTO_ROUTE_38_ECRUTEAK_GATE_HEIGHT, JOHTO_ROUTE_38_ECRUTEAK_GATE_WIDTH
	dw JohtoRoute38EcruteakGateBlocks, JohtoRoute38EcruteakGateTextPointers, EnableAutoTextBoxDrawing
	db 0 ; warp-only interior, no ordinary connections
	dw JohtoRoute38EcruteakGateObject
