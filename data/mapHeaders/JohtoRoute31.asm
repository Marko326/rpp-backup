; R31-5.62.147: single-route stage. No VioletCity / Gate connection.
JohtoRoute31_h:
	db JOHTO
	db JOHTO_ROUTE_31_HEIGHT, JOHTO_ROUTE_31_WIDTH
	dw JohtoRoute31Blocks, JohtoRoute31TextPointers, EnableAutoTextBoxDrawing
	db SOUTH
	SOUTH_MAP_CONNECTION JOHTO_ROUTE_31, JOHTO_ROUTE_30, 10, 0, JohtoRoute30Blocks
	dw JohtoRoute31Object
