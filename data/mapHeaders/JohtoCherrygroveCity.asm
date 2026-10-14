; P2-1: Gold Cherrygrove City layout (20 x 9 blocks).
; No north Route 30 connection until the next map is actually registered.
JohtoCherrygroveCity_h:
	db JOHTO
	db JOHTO_CHERRYGROVE_CITY_HEIGHT, JOHTO_CHERRYGROVE_CITY_WIDTH
	dw JohtoCherrygroveCityBlocks, JohtoCherrygroveCityTextPointers, EnableAutoTextBoxDrawing
	db EAST
	EAST_MAP_CONNECTION JOHTO_CHERRYGROVE_CITY, JOHTO_ROUTE_29, 0, 0, JohtoRoute29Blocks
	dw JohtoCherrygroveCityObject
