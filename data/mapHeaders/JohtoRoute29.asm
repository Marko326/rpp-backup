; P2 pilot: link Route 29 west to Cherrygrove without changing the
; verified Route 29 .blk, ledge handling, ferry, or north Route 46 gate.
JohtoRoute29_h:
	db JOHTO
	db JOHTO_ROUTE_29_HEIGHT, JOHTO_ROUTE_29_WIDTH
	dw JohtoRoute29Blocks, JohtoRoute29TextPointers, EnableAutoTextBoxDrawing
	db NORTH | WEST | EAST
 ; Gold +10 block offset: Route29 x10..19 previews Route46 x0..9.
 ; Source Gold both border rows are WALL: collision fences remain sealed.
 db REGION_NATIVE_MAP_SLOT
 dw JohtoRoute46Blocks + JOHTO_ROUTE_46_WIDTH * (JOHTO_ROUTE_46_HEIGHT - 3)
 dw wOverworldMap + 3 + 10
 db JOHTO_ROUTE_46_WIDTH
 db JOHTO_ROUTE_46_WIDTH
 db JOHTO_ROUTE_46_HEIGHT * 2 - 1
 db -20
 dw wOverworldMap + 1 + JOHTO_ROUTE_46_HEIGHT * (JOHTO_ROUTE_46_WIDTH + 6)
	; Native Cherrygrove target ($FC), but retain its real dimensions for the strip.
	db REGION_NATIVE_MAP_SLOT
	dw JohtoCherrygroveCityBlocks + JOHTO_CHERRYGROVE_CITY_WIDTH - 3
	dw wOverworldMap + (JOHTO_ROUTE_29_WIDTH + 6) * 3
	db JOHTO_CHERRYGROVE_CITY_HEIGHT
	db JOHTO_CHERRYGROVE_CITY_WIDTH
	db 0
	db JOHTO_CHERRYGROVE_CITY_WIDTH * 2 - 1
	dw wOverworldMap + 6 + (2 * JOHTO_CHERRYGROVE_CITY_WIDTH)
	EAST_MAP_CONNECTION JOHTO_ROUTE_29, NEW_BARK_TOWN, 0, 0, NewBarkTownBlocks
	dw JohtoRoute29Object
