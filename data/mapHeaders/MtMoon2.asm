MtMoon2_h:
	db CAVERN ; tileset
	db MT_MOON_2_HEIGHT, MT_MOON_2_WIDTH ; dimensions (y, x)
	; MSP-5.43.00: use the shared text-box routine directly; redundant local MapScript wrapper removed.
	dw MtMoon2Blocks, MtMoon2TextPointers, EnableAutoTextBoxDrawing ; blocks, texts, scripts
	db $00 ; connections
	dw MtMoon2Object ; objects
