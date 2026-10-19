; ILEX-5.62.216: Gold Route34 original terrain, modern art and south gate
; unchanged. Open only the bounded north connection to Goldenrod.
; Unfinished eastern Azalea connection remains sealed.
JohtoRoute34_h:
	db JOHTO_MODERN
	db JOHTO_ROUTE_34_HEIGHT, JOHTO_ROUTE_34_WIDTH
	dw JohtoRoute34Blocks, JohtoRoute34TextPointers, EnableAutoTextBoxDrawing
	db NORTH
	; Gold north offset -5. City block x=5..14 aligns with Route34 x=0..9.
	db REGION_NATIVE_MAP_SLOT
	dw JohtoGoldenrodCityBlocks + JOHTO_GOLDENROD_CITY_WIDTH * (JOHTO_GOLDENROD_CITY_HEIGHT - 3) + 5
	dw wOverworldMap + 3
	db JOHTO_ROUTE_34_WIDTH
	db JOHTO_GOLDENROD_CITY_WIDTH
	db JOHTO_GOLDENROD_CITY_HEIGHT * 2 - 1
	db 10
	dw wOverworldMap + 1 + JOHTO_GOLDENROD_CITY_HEIGHT * (JOHTO_GOLDENROD_CITY_WIDTH + 6)
	dw JohtoRoute34Object
