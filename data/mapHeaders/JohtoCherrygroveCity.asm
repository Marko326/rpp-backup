; MAP-5.62.139 P2-2: Gold Cherrygrove City layout (20 x 9 blocks).
; Route 30 now connects at the north passage (Gold offset +5).
JohtoCherrygroveCity_h:
	db JOHTO
	db JOHTO_CHERRYGROVE_CITY_HEIGHT, JOHTO_CHERRYGROVE_CITY_WIDTH
	dw JohtoCherrygroveCityBlocks, JohtoCherrygroveCityTextPointers, EnableAutoTextBoxDrawing
	db NORTH | EAST
	NORTH_MAP_CONNECTION JOHTO_CHERRYGROVE_CITY, JOHTO_ROUTE_30, 5, 0, JohtoRoute30Blocks
	EAST_MAP_CONNECTION JOHTO_CHERRYGROVE_CITY, JOHTO_ROUTE_29, 0, 0, JohtoRoute29Blocks
	dw JohtoCherrygroveCityObject
