; MAP-5.62.195: Gold Azalea Town terrain; only Route33 east entrance is open.
; Route34 west, all building/Well/forest-gate Warps remain closed.
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
