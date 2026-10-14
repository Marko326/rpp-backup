; Gate-5.62.151: Gold Route31VioletGate footprint is 5x4 blocks (W x H).
; RPP GATE art used only as an engine-compatible visual adapter, not pixel-exact Gold.
JohtoRoute31VioletGate_h:
	db GATE
	db JOHTO_ROUTE31_VIOLET_GATE_HEIGHT, JOHTO_ROUTE31_VIOLET_GATE_WIDTH
	dw JohtoRoute31VioletGateBlocks, JohtoRoute31VioletGateTextPointers, EnableAutoTextBoxDrawing
	db $00 ; independent indoor room, no edge map connections
	dw JohtoRoute31VioletGateObject
