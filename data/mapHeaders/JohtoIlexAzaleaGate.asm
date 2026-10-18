; GATE-5.62.197: Gold EastWestGate visual reused, native ID 11.
; ILEX-5.62.212: Forest side opens only through the audited west double collision Warp.
JohtoIlexAzaleaGate_h:
	db JOHTO_GATE
	db 4, 5
	dw JohtoIlexAzaleaGateBlocks, JohtoIlexAzaleaGateTextPointers, EnableAutoTextBoxDrawing
	db $00 ; indoor gate, no outdoor connections
	dw JohtoIlexAzaleaGateObject
