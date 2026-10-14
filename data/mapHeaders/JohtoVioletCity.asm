; GT-5.62.153: render the Route31 gatehouse beyond Violet City's east edge.
; A connection for border DRAWING does not open the closed exterior edge:
; JohtoVioletCityCollisionFence still rejects walking past x=39.  The actual
; route remains Violet City <-> indoor gate <-> Route31 via existing Warps.
JohtoVioletCity_h:
	db JOHTO
	db JOHTO_VIOLET_CITY_HEIGHT, JOHTO_VIOLET_CITY_WIDTH
	dw JohtoVioletCityBlocks, JohtoVioletCityTextPointers, EnableAutoTextBoxDrawing
	db EAST
	; EAST: current Violet City (20x18), neighbor Route31 (20x9).
	; Gold offset = +9: Route31 rows 0..8 overlap Violet rows 9..17.
	; Copy only the westernmost 3 block columns of each overlapping row.
	db JOHTO_ROUTE_31
	dw JohtoRoute31Blocks
	dw wOverworldMap + (9 + 3) * (JOHTO_VIOLET_CITY_WIDTH + 6) + JOHTO_VIOLET_CITY_WIDTH + 3
	db JOHTO_ROUTE_31_HEIGHT ; exactly 9 source rows
	db JOHTO_ROUTE_31_WIDTH
	db -18 ; destination Y = Violet City Y - 18
	db 0 ; east arrival X
	dw wOverworldMap + 7 + JOHTO_ROUTE_31_WIDTH
	dw JohtoVioletCityObject
