; GATE-5.62.159: original Gold Gate artwork and 5x4 layout, dedicated tileset.
; Route15-style door state and the existing four Warp destinations are unchanged.
JohtoRoute31VioletGate_h:
	db JOHTO_GATE
	db JOHTO_ROUTE31_VIOLET_GATE_HEIGHT, JOHTO_ROUTE31_VIOLET_GATE_WIDTH
	dw JohtoRoute31VioletGateBlocks, JohtoRoute31VioletGateTextPointers, EnableAutoTextBoxDrawing
	db $00 ; independent indoor room, no edge map connections
	dw JohtoRoute31VioletGateObject
