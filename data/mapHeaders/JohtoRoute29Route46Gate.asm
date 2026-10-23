; GATE-5.62.240: Gold Route29Route46Gate, original 5x4 NorthSouthGate.
; Shared reviewed JOHTO_GATE art and Gold quadrant collision mask.
JohtoRoute29Route46Gate_h:
 db JOHTO_GATE
 db 4, 5
 dw JohtoRoute29Route46GateBlocks, JohtoRoute29Route46GateTextPointers, EnableAutoTextBoxDrawing
 db 0 ; one isolated interior, no direct outdoor connection
 dw JohtoRoute29Route46GateObject
