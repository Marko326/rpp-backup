; R36-5.62.218: Gold Route36 30x9, original JOHTO tileset.
; Route37 north and Route35 south open; two unbuilt gate interiors stay sealed.
JohtoRoute36_h:
	db JOHTO
	db JOHTO_ROUTE_36_HEIGHT, JOHTO_ROUTE_36_WIDTH
	dw JohtoRoute36Blocks, JohtoRoute36TextPointers, EnableAutoTextBoxDrawing
	db NORTH | SOUTH | EAST
	; Gold Route36 north -> Route37 south, offset +10 blocks.
	; Copy only the 10-block neighbor overlap into cols 10..19.
	db REGION_NATIVE_MAP_SLOT
	dw JohtoRoute37Blocks + JOHTO_ROUTE_37_WIDTH * (JOHTO_ROUTE_37_HEIGHT - 3)
	dw wOverworldMap + 3 + 10
	db JOHTO_ROUTE_37_WIDTH
	db JOHTO_ROUTE_37_WIDTH
	db JOHTO_ROUTE_37_HEIGHT * 2 - 1
	db -20
	dw wOverworldMap + 1 + JOHTO_ROUTE_37_HEIGHT * (JOHTO_ROUTE_37_WIDTH + 6)
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
