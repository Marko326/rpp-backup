; R33-5.62.191: native Route33 local $09; Gold 10x9 map with north Route32 only.
; The modern tileset is independent. West Azalea stays closed; cave Warp is open.
JohtoRoute33_h:
	db JOHTO_MODERN
	db JOHTO_ROUTE_33_HEIGHT, JOHTO_ROUTE_33_WIDTH
	dw JohtoRoute33Blocks, JohtoRoute33TextPointers, EnableAutoTextBoxDrawing
	db NORTH
	; Neighbor Route32 south 3 rows, 10 block columns, Gold offset 0.
	db JOHTO_ROUTE_32
	dw JohtoRoute32Blocks + JOHTO_ROUTE_32_WIDTH * (JOHTO_ROUTE_32_HEIGHT - 3)
	dw wOverworldMap + 3
	db JOHTO_ROUTE_33_WIDTH
	db JOHTO_ROUTE_32_WIDTH
	db JOHTO_ROUTE_32_HEIGHT * 2 - 1
	db 0
	dw wOverworldMap + 1 + JOHTO_ROUTE_32_HEIGHT * (JOHTO_ROUTE_32_WIDTH + 6)
	dw JohtoRoute33Object
