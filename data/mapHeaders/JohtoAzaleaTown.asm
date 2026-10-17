; GATE-5.62.202: terrain and Route33 east unchanged; open exact Ilex south
; gate x=2/y=10,11 Warp only. Route34 and all other buildings/Well remain shut.
JohtoAzaleaTown_h:
	db JOHTO_MODERN
	db JOHTO_AZALEA_TOWN_HEIGHT, JOHTO_AZALEA_TOWN_WIDTH
	dw JohtoAzaleaTownBlocks, JohtoAzaleaTownTextPointers, EnableAutoTextBoxDrawing
	db EAST
	; Gold offset 0: copy Route33 west three columns, 9 rows.
	db REGION_NATIVE_MAP_SLOT
	dw JohtoRoute33Blocks
	dw wOverworldMap + 3 * (JOHTO_AZALEA_TOWN_WIDTH + 6) + JOHTO_AZALEA_TOWN_WIDTH + 3
	db JOHTO_ROUTE_33_HEIGHT
	db JOHTO_ROUTE_33_WIDTH
	db 0
	db 0
	dw wOverworldMap + 7 + JOHTO_ROUTE_33_WIDTH
	dw JohtoAzaleaTownObject
