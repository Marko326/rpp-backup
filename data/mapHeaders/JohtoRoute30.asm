; MAP-5.62.139 P2-2: Gold Route 30 (10 x 27); north Route 31 remains disconnected.
JohtoRoute30_h:
	db JOHTO
	db JOHTO_ROUTE_30_HEIGHT, JOHTO_ROUTE_30_WIDTH
	dw JohtoRoute30Blocks, JohtoRoute30TextPointers, EnableAutoTextBoxDrawing
	db SOUTH
	SOUTH_MAP_CONNECTION JOHTO_ROUTE_30, JOHTO_CHERRYGROVE_CITY, -5, 0, JohtoCherrygroveCityBlocks
	dw JohtoRoute30Object
