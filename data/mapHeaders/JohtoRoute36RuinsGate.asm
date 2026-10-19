; RUINS-5.62.224: Gold NorthSouthGate 5x4, shared approved JOHTO_GATE art.
JohtoRoute36RuinsGate_h:
	db JOHTO_GATE
	db 4, 5
	dw JohtoRoute36RuinsGateBlocks, JohtoRoute36RuinsGateTextPointers, EnableAutoTextBoxDrawing
	db $00 ; two double collision/step-on warp pairs, no connections
	dw JohtoRoute36RuinsGateObject
