DiglettsCave_h:
	db CAVERN ; tileset
	db DIGLETTS_CAVE_HEIGHT, DIGLETTS_CAVE_WIDTH ; dimensions (y, x)
	; MSP-5.43.00: use the shared text-box routine directly; redundant local MapScript wrapper removed.
	dw DiglettsCaveBlocks, DiglettsCaveTextPointers, EnableAutoTextBoxDrawing ; blocks, texts, scripts
	db $00 ; connections
	dw DiglettsCaveObject ; objects
