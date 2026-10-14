; GT-5.62.153: display Violet City on Route31's west border, but retain
; the Route31VioletGate indoor Warp and the x=0 collision fence.  The Gold
; -9 ROW offset is converted to an explicitly bounded 9-row strip.  Do NOT
; use WEST_MAP_CONNECTION with -9: its parameters have different semantics.
JohtoRoute31_h:
	db JOHTO
	db JOHTO_ROUTE_31_HEIGHT, JOHTO_ROUTE_31_WIDTH
	dw JohtoRoute31Blocks, JohtoRoute31TextPointers, EnableAutoTextBoxDrawing
	db SOUTH | WEST
	SOUTH_MAP_CONNECTION JOHTO_ROUTE_31, JOHTO_ROUTE_30, 10, 0, JohtoRoute30Blocks
	; WEST: current Route31 (20x9), neighbor Violet City (20x18).
	; Gold offset = -9: Violet rows 9..17 overlap Route31 rows 0..8.
	; Copy only the easternmost 3 block columns of each overlapping row.
	db JOHTO_VIOLET_CITY
	dw JohtoVioletCityBlocks + JOHTO_VIOLET_CITY_WIDTH * 9 + JOHTO_VIOLET_CITY_WIDTH - 3
	dw wOverworldMap + 3 * (JOHTO_ROUTE_31_WIDTH + 6)
	db JOHTO_ROUTE_31_HEIGHT ; exactly 9 source rows
	db JOHTO_VIOLET_CITY_WIDTH
	db 18 ; destination Y = Route31 Y + 18
	db JOHTO_VIOLET_CITY_WIDTH * 2 - 1 ; west arrival X=39
	dw wOverworldMap + 6 + 2 * JOHTO_VIOLET_CITY_WIDTH
	dw JohtoRoute31Object
