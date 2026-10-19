; GATE-5.62.224: original Gold Route35GoldenrodGate 5x4 NorthSouthGate.
; Reuse accepted JOHTO_GATE art and collision rules, no direct route-city seam.
JohtoRoute35GoldenrodGate_h:
	db JOHTO_GATE
	db 4, 5
	dw JohtoRoute35GoldenrodGateBlocks, JohtoRoute35GoldenrodGateTextPointers, EnableAutoTextBoxDrawing
	db 0 ; Warp-only gate, no outdoor map connection
	dw JohtoRoute35GoldenrodGateObject
