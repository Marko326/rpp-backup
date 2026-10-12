; JHT-5.62.110: original Gold New Bark layout, without Gen 2 map scripts.
NewBarkTown_h:
	db JOHTO ; isolated Johto tileset
	db NEW_BARK_TOWN_HEIGHT, NEW_BARK_TOWN_WIDTH ; dimensions (y, x)
	dw NewBarkTownBlocks, NewBarkTownTextPointers, EnableAutoTextBoxDrawing
	db $00 ; no connections until other Johto routes exist
	dw NewBarkTownObject
