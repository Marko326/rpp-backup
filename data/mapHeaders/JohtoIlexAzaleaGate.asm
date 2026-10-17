; GATE-5.62.197: Gold EastWestGate visual reused, native ID 11.
; West (Forest) is sealed until forest assets, events and safe return exist.
JohtoIlexAzaleaGate_h:
	db JOHTO_GATE
	db 4, 5
	dw JohtoIlexAzaleaGateBlocks, JohtoIlexAzaleaGateTextPointers, EnableAutoTextBoxDrawing
	db $00 ; indoor gate, no outdoor connections
	dw JohtoIlexAzaleaGateObject
