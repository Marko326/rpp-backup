; RUINS-5.62.224: original Gold Ruins of Alph Outside 10x18, no map connections.
; All buildings/caves except the north gate stay visually present but unenterable.
JohtoRuinsOfAlphOutside_h:
	db JOHTO
	db JOHTO_RUINS_OF_ALPH_HEIGHT, JOHTO_RUINS_OF_ALPH_WIDTH
	dw JohtoRuinsOfAlphOutsideBlocks, JohtoRuinsOfAlphOutsideTextPointers, EnableAutoTextBoxDrawing
	db $00
	dw JohtoRuinsOfAlphOutsideObject
