; GT-5.62.153: the east Route31 gatehouse is reached only through its Warps;
; border drawing does not bypass JohtoVioletCityCollisionFence at x=39.
; R36-5.62.218: Gold's west Route36 connection opens only at y=8/9.
JohtoVioletCity_h:
	db JOHTO
	db JOHTO_VIOLET_CITY_HEIGHT, JOHTO_VIOLET_CITY_WIDTH
	dw JohtoVioletCityBlocks, JohtoVioletCityTextPointers, EnableAutoTextBoxDrawing
	db SOUTH | WEST | EAST
	; R32-5.62.165: Gold south offset 0, Route32 is 10 columns wide.
	; Copy exactly 10 blocks across each of the three top Route32 rows.
	db JOHTO_ROUTE_32
	dw JohtoRoute32Blocks
	dw wOverworldMap + (JOHTO_VIOLET_CITY_HEIGHT + 3) * (JOHTO_VIOLET_CITY_WIDTH + 6) + 3
	db JOHTO_ROUTE_32_WIDTH
	db JOHTO_ROUTE_32_WIDTH
	db 0 ; arrive at Route32's north edge
	db 0 ; Gold offset 0, X unchanged
	dw wOverworldMap + 7 + JOHTO_ROUTE_32_WIDTH
	; R36-5.62.218: Gold west offset 0, Route36 30x9 occupies Violet
	; rows 0..8. Copy the eastern three Route36 block columns only.
	db REGION_NATIVE_MAP_SLOT
	dw JohtoRoute36Blocks + JOHTO_ROUTE_36_WIDTH - 3
	dw wOverworldMap + 3 * (JOHTO_VIOLET_CITY_WIDTH + 6)
	db JOHTO_ROUTE_36_HEIGHT
	db JOHTO_ROUTE_36_WIDTH
	db 0 ; same Gold row alignment
	db JOHTO_ROUTE_36_WIDTH * 2 - 1 ; west arrival X=59
	dw wOverworldMap + 6 + 2 * JOHTO_ROUTE_36_WIDTH
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
