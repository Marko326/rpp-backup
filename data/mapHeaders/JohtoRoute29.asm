; P2 pilot: link Route 29 west to Cherrygrove without changing the
; verified Route 29 .blk, ledge handling, ferry, or north Route 46 gate.
JohtoRoute29_h:
	db JOHTO
	db JOHTO_ROUTE_29_HEIGHT, JOHTO_ROUTE_29_WIDTH
	dw JohtoRoute29Blocks, JohtoRoute29TextPointers, EnableAutoTextBoxDrawing
	db WEST | EAST
	WEST_MAP_CONNECTION JOHTO_ROUTE_29, JOHTO_CHERRYGROVE_CITY, 0, 0, JohtoCherrygroveCityBlocks
	EAST_MAP_CONNECTION JOHTO_ROUTE_29, NEW_BARK_TOWN, 0, 0, NewBarkTownBlocks
	dw JohtoRoute29Object
