; MAP-5.62.126: Gold Route 29, 30 x 9 blocks. Westward connection to
; Cherrygrove and northward connection to Route 46 are not yet built.
JohtoRoute29_h:
	db JOHTO
	db JOHTO_ROUTE_29_HEIGHT, JOHTO_ROUTE_29_WIDTH
	dw JohtoRoute29Blocks, JohtoRoute29TextPointers, EnableAutoTextBoxDrawing
	db EAST
	EAST_MAP_CONNECTION JOHTO_ROUTE_29, NEW_BARK_TOWN, 0, 0, NewBarkTownBlocks
	dw JohtoRoute29Object
