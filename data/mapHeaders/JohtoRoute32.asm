; R32-5.62.165: original Gold Route32, Violet City north passage only.
; Route33 and every exterior edge except Violet City remain closed.
JohtoRoute32_h:
	db JOHTO
	db JOHTO_ROUTE_32_HEIGHT, JOHTO_ROUTE_32_WIDTH
	dw JohtoRoute32Blocks, JohtoRoute32TextPointers, EnableAutoTextBoxDrawing
	db NORTH | SOUTH
	; R32-5.62.223: only x=14/15 can cross into Violet; those two
	; reachable tiles can see the wider city past Route32 east edge.
	; Copy 10 overlap columns + 3 display-only columns within WRAM margin.
	db JOHTO_VIOLET_CITY
	dw JohtoVioletCityBlocks + JOHTO_VIOLET_CITY_WIDTH * (JOHTO_VIOLET_CITY_HEIGHT - 3)
	dw wOverworldMap + 3
	db JOHTO_ROUTE_32_WIDTH + 3 ; 10 overlap + 3 visual-only east columns
	db JOHTO_VIOLET_CITY_WIDTH
	db JOHTO_VIOLET_CITY_HEIGHT * 2 - 1 ; arrival at city's south edge
	db 0 ; Gold offset 0, X unchanged
	dw wOverworldMap + 1 + JOHTO_VIOLET_CITY_HEIGHT * (JOHTO_VIOLET_CITY_WIDTH + 6)
	; R33-5.62.191: 3-row border from north of Route33.
	db REGION_NATIVE_MAP_SLOT
	dw JohtoRoute33Blocks
	dw wOverworldMap + (JOHTO_ROUTE_32_HEIGHT + 3) * (JOHTO_ROUTE_32_WIDTH + 6) + 3
	db JOHTO_ROUTE_33_WIDTH
	db JOHTO_ROUTE_33_WIDTH
	db 0 ; arrive at Route33 north edge
	db 0 ; zero Gold horizontal offset
	dw wOverworldMap + 7 + JOHTO_ROUTE_33_WIDTH
	dw JohtoRoute32Object
