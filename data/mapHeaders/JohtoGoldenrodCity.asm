; ILEX-5.62.216: Gold 20x18 GoldenrodCity exterior, unchanged modern blocks.
; South Route34 is the only active edge. North Route35 remains fenced.
JohtoGoldenrodCity_h:
	db JOHTO_MODERN
	db JOHTO_GOLDENROD_CITY_HEIGHT, JOHTO_GOLDENROD_CITY_WIDTH
	dw JohtoGoldenrodCityBlocks, JohtoGoldenrodCityTextPointers, EnableAutoTextBoxDrawing
	db SOUTH
	; Gold south offset +5: Route34 x0..9 aligns with city block x5..14.
	db REGION_NATIVE_MAP_SLOT
	dw JohtoRoute34Blocks
	dw wOverworldMap + (JOHTO_GOLDENROD_CITY_HEIGHT + 3) * (JOHTO_GOLDENROD_CITY_WIDTH + 6) + 3 + 5
	db JOHTO_ROUTE_34_WIDTH
	db JOHTO_ROUTE_34_WIDTH
	db 0
	db -10
	dw wOverworldMap + 7 + JOHTO_ROUTE_34_WIDTH
	dw JohtoGoldenrodCityObject
