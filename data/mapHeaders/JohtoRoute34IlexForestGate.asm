; ILEX-5.62.215: Gold NorthSouthGate 5x4, exact compact JOHTO_GATE pixels.
JohtoRoute34IlexForestGate_h:
	db JOHTO_GATE
	db 4, 5
	dw JohtoRoute34IlexForestGateBlocks, JohtoRoute34IlexForestGateTextPointers, EnableAutoTextBoxDrawing
	db $00 ; both sides use collision-only Warp, no map connections
	dw JohtoRoute34IlexForestGateObject
