; R33-5.62.191: native Route33 local $09; Gold 10x9 map with north Route32 only.
; The modern tileset is independent. West Azalea stays closed; cave Warp is open.
JohtoRoute33_h:
	db JOHTO_MODERN
	db JOHTO_ROUTE_33_HEIGHT, JOHTO_ROUTE_33_WIDTH
	dw JohtoRoute33Blocks, JohtoRoute33TextPointers, EnableAutoTextBoxDrawing
	db NORTH | WEST
	; Neighbor Route32 south 3 rows, 10 block columns, Gold offset 0.
	db JOHTO_ROUTE_32
	dw JohtoRoute32Blocks + JOHTO_ROUTE_32_WIDTH * (JOHTO_ROUTE_32_HEIGHT - 3)
	dw wOverworldMap + 3
	db JOHTO_ROUTE_33_WIDTH
	db JOHTO_ROUTE_32_WIDTH
	db JOHTO_ROUTE_32_HEIGHT * 2 - 1
	db 0
	dw wOverworldMap + 1 + JOHTO_ROUTE_32_HEIGHT * (JOHTO_ROUTE_32_WIDTH + 6)
	; MAP-5.62.195: Gold west offset 0, 3-column visual border, safe road y14/15.
	db REGION_NATIVE_MAP_SLOT
	dw JohtoAzaleaTownBlocks + JOHTO_AZALEA_TOWN_WIDTH - 3
	dw wOverworldMap + 3 * (JOHTO_ROUTE_33_WIDTH + 6)
	db JOHTO_ROUTE_33_HEIGHT
	db JOHTO_AZALEA_TOWN_WIDTH
	db 0
	db JOHTO_AZALEA_TOWN_WIDTH * 2 - 1
	dw wOverworldMap + 6 + 2 * JOHTO_AZALEA_TOWN_WIDTH
	dw JohtoRoute33Object
