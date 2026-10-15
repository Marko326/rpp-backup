; R32-5.62.165: original Gold Route32, Violet City north passage only.
; Unbuilt Route33, indoor maps, and all other exterior edges remain closed.
JohtoRoute32_h:
	db JOHTO
	db JOHTO_ROUTE_32_HEIGHT, JOHTO_ROUTE_32_WIDTH
	dw JohtoRoute32Blocks, JohtoRoute32TextPointers, EnableAutoTextBoxDrawing
	db NORTH
	; R32-5.62.165: Gold north offset 0, Violet is 20 columns wide.
	; Copy exactly the southern 3 rows x 10 columns, no 20-wide overflow.
	db JOHTO_VIOLET_CITY
	dw JohtoVioletCityBlocks + JOHTO_VIOLET_CITY_WIDTH * (JOHTO_VIOLET_CITY_HEIGHT - 3)
	dw wOverworldMap + 3
	db JOHTO_ROUTE_32_WIDTH
	db JOHTO_VIOLET_CITY_WIDTH
	db JOHTO_VIOLET_CITY_HEIGHT * 2 - 1 ; arrival at city's south edge
	db 0 ; Gold offset 0, X unchanged
	dw wOverworldMap + 1 + JOHTO_VIOLET_CITY_HEIGHT * (JOHTO_VIOLET_CITY_WIDTH + 6)
	dw JohtoRoute32Object
