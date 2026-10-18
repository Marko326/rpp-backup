; ILEX-5.62.212: Gold Ilex Forest 15x27 blocks, no northern connection.
JohtoIlexForest_h:
	db JOHTO_ILEX_FOREST
	db JOHTO_ILEX_FOREST_HEIGHT, JOHTO_ILEX_FOREST_WIDTH
	dw JohtoIlexForestBlocks, JohtoIlexForestTextPointers, EnableAutoTextBoxDrawing
	db $00 ; original Route34 gate is not implemented
	dw JohtoIlexForestObject
