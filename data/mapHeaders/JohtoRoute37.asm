; Gold Route37 10x9 original Johto terrain, local ID 21. North Ecruteak deferred.
JohtoRoute37_h:
	db JOHTO
	db JOHTO_ROUTE_37_HEIGHT, JOHTO_ROUTE_37_WIDTH
	dw JohtoRoute37Blocks, JohtoRoute37TextPointers, EnableAutoTextBoxDrawing
	db SOUTH
	; Gold Route37 south -> Route36 north, offset -10 blocks.
	; Source Route36 columns 10..19; the exact overlap is 10 blocks.
	db REGION_NATIVE_MAP_SLOT
	dw JohtoRoute36Blocks + 10
	dw wOverworldMap + (JOHTO_ROUTE_37_HEIGHT + 3) * (JOHTO_ROUTE_37_WIDTH + 6) + 3
	db JOHTO_ROUTE_37_WIDTH
	db JOHTO_ROUTE_36_WIDTH
	db 0
	db 20
	dw wOverworldMap + 7 + JOHTO_ROUTE_36_WIDTH
	dw JohtoRoute37Object
