; B-ID62: Gold Route42EcruteakGate, EastWestGate 5x4.
; Private Gold geometry only. C registers stable $3E -> actual compact active slot,
; Bank/HEADER, both outdoor Warps, arrival/direction behavior and neutral gate name.
JohtoRoute42EcruteakGate_h:
	db JOHTO_GATE
	db JOHTO_ROUTE_42_ECRUTEAK_GATE_HEIGHT, JOHTO_ROUTE_42_ECRUTEAK_GATE_WIDTH
	dw JohtoRoute42EcruteakGateBlocks, JohtoRoute42EcruteakGateTextPointers, EnableAutoTextBoxDrawing
	db $00 ; gate uses four Warp events, NOT outdoor connections
	dw JohtoRoute42EcruteakGateObject
