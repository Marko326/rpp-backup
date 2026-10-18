; ILEX-5.62.215: Gold Route34 10x27, original modern shared graphics.
; Gold north (Goldenrod) and east (Azalea) connections remain sealed.
JohtoRoute34_h:
	db JOHTO_MODERN
	db JOHTO_ROUTE_34_HEIGHT, JOHTO_ROUTE_34_WIDTH
	dw JohtoRoute34Blocks, JohtoRoute34TextPointers, EnableAutoTextBoxDrawing
	db $00
	dw JohtoRoute34Object
