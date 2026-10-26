; MAP-5.62.139 P2-2: Gold Route 30 (10 x 27); north Route 31 remains disconnected.
JohtoRoute30_h:
	db JOHTO
	db JOHTO_ROUTE_30_HEIGHT, JOHTO_ROUTE_30_WIDTH
	dw JohtoRoute30Blocks, JohtoRoute30TextPointers, EnableAutoTextBoxDrawing
	db NORTH | SOUTH
	; R31-5.62.148: Gold's -10 map offset is NOT a safe NORTH_MAP_CONNECTION
	; strip-movement argument in RPP: that macro would copy 23 blocks per row,
	; starting seven bytes before wOverworldMap and reading out of the .blk.
	; Only Route31 x=10..19 overlaps Route30 x=0..9.  Copy exactly those
	; ten blocks from each of the last three Route31 rows into the north
	; border.  Keep the existing +20 tile (16x16) X coordinate alignment.
	db JOHTO_ROUTE_31
	dw JohtoRoute31Blocks + JOHTO_ROUTE_31_WIDTH * (JOHTO_ROUTE_31_HEIGHT - 3) + 10
	dw wOverworldMap + 3
	db JOHTO_ROUTE_30_WIDTH ; bounded connection-strip width (10 blocks)
	db JOHTO_ROUTE_31_WIDTH ; connected map width (20 blocks)
	db JOHTO_ROUTE_31_HEIGHT * 2 - 1 ; arrival Y = 17
	db 20 ; arrival X = Route30 X + 20 (Gold -10 block offset)
	dw wOverworldMap + 1 + JOHTO_ROUTE_31_HEIGHT * (JOHTO_ROUTE_31_WIDTH + 6)
	; CONN-5.62.223: Gold -5 moves the target five source columns east;
	; the legacy SOUTH macro copies 15 columns from the wrong start.
	db REGION_NATIVE_MAP_SLOT
	dw JohtoCherrygroveCityBlocks + 5
	dw wOverworldMap + (JOHTO_ROUTE_30_HEIGHT + 3) * (JOHTO_ROUTE_30_WIDTH + 6) + 3
	db JOHTO_ROUTE_30_WIDTH
	db JOHTO_CHERRYGROVE_CITY_WIDTH
	db 0
	db 10 ; arrival X = Route30 X + 10 (Gold -5 offset)
	dw wOverworldMap + 7 + JOHTO_CHERRYGROVE_CITY_WIDTH
	dw JohtoRoute30Object
