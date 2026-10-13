; JHT-5.62.110: original Gold New Bark layout, without Gen 2 map scripts.
NewBarkTown_h:
	db JOHTO ; isolated Johto tileset
	db NEW_BARK_TOWN_HEIGHT, NEW_BARK_TOWN_WIDTH ; dimensions (y, x)
	dw NewBarkTownBlocks, NewBarkTownTextPointers, EnableAutoTextBoxDrawing
	db WEST ; MAP-5.62.126: west link to Route 29
	WEST_MAP_CONNECTION NEW_BARK_TOWN, JOHTO_ROUTE_29, 0, 0, JohtoRoute29Blocks
	dw NewBarkTownObject
