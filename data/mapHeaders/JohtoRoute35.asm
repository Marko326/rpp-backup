; R35-5.62.223: Gold Route35 10x18, JOHTO terrain; north Route36 only.
; South Goldenrod gate and National Park gate remain unregistered.
JohtoRoute35_h:
	db JOHTO
	db JOHTO_ROUTE_35_HEIGHT, JOHTO_ROUTE_35_WIDTH
	dw JohtoRoute35Blocks, JohtoRoute35TextPointers, EnableAutoTextBoxDrawing
	db NORTH
	; CONN-5.62.223: Gold's walkable overlap is 10 columns, but x=17
	; can see the neighboring Route36 x=10..12 in the east border.
	; Copy those three DISPLAY-ONLY columns in the 35 north margin;
	; this does not open any additional crossing tiles.
	db REGION_NATIVE_MAP_SLOT
	dw JohtoRoute36Blocks + JOHTO_ROUTE_36_WIDTH * (JOHTO_ROUTE_36_HEIGHT - 3)
	dw wOverworldMap + 3
	db JOHTO_ROUTE_35_WIDTH + 3 ; 10 walkable overlap + 3 east visual border
	db JOHTO_ROUTE_36_WIDTH
	db JOHTO_ROUTE_36_HEIGHT * 2 - 1
	db 0
	dw wOverworldMap + 1 + JOHTO_ROUTE_36_HEIGHT * (JOHTO_ROUTE_36_WIDTH + 6)
	dw JohtoRoute35Object
