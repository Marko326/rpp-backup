; R36-5.62.218: Gold Route36 30x9, original JOHTO tileset.
; Route37 and two gate interiors stay sealed; Route35 south seam is now open.
JohtoRoute36_h:
	db JOHTO
	db JOHTO_ROUTE_36_HEIGHT, JOHTO_ROUTE_36_WIDTH
	dw JohtoRoute36Blocks, JohtoRoute36TextPointers, EnableAutoTextBoxDrawing
	db SOUTH | EAST
	; R35-5.62.223: Gold Route36 south -> Route35 north, aligned at x=0.
	db REGION_NATIVE_MAP_SLOT
	dw JohtoRoute35Blocks
	dw wOverworldMap + (JOHTO_ROUTE_36_HEIGHT + 3) * (JOHTO_ROUTE_36_WIDTH + 6) + 3
	db JOHTO_ROUTE_35_WIDTH
	db JOHTO_ROUTE_35_WIDTH
	db 0
	db 0
	dw wOverworldMap + 7 + JOHTO_ROUTE_35_WIDTH
	; Gold Route36 east -> Violet City west, row offset zero.
	; Route36 9 rows correspond to Violet City rows 0..8.
	db JOHTO_VIOLET_CITY
	dw JohtoVioletCityBlocks
	dw wOverworldMap + 3 * (JOHTO_ROUTE_36_WIDTH + 6) + JOHTO_ROUTE_36_WIDTH + 3
	db JOHTO_ROUTE_36_HEIGHT
	db JOHTO_VIOLET_CITY_WIDTH
	db 0
	db 0 ; Violet west arrival X=0
	dw wOverworldMap + 7 + JOHTO_VIOLET_CITY_WIDTH
	dw JohtoRoute36Object
