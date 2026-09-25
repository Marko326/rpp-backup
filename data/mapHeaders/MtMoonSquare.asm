MtMoonSquare_h:
	db OVERWORLD ; tileset
	db MT_MOON_SQUARE_HEIGHT, MT_MOON_SQUARE_WIDTH ; dimensions (y, x)
	; MSP-5.43.00: use the shared text-box routine directly; redundant local MapScript wrapper removed.
	dw MtMoonSquareBlocks, MtMoonSquareTextPointers, EnableAutoTextBoxDrawing ; blocks, texts, scripts
	db $00 ; connections
	dw MtMoonSquareObject ; objects
