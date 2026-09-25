FuchsiaHouse2_h:
	db LAB ; tileset
	db FUCHSIA_HOUSE_2_HEIGHT, FUCHSIA_HOUSE_2_WIDTH ; dimensions (y, x)
	; MSP-5.43.00: use the shared text-box routine directly; redundant local MapScript wrapper removed.
	dw FuchsiaHouse2Blocks, FuchsiaHouse2TextPointers, EnableAutoTextBoxDrawing ; blocks, texts, scripts
	db $00 ; connections
	dw FuchsiaHouse2Object ; objects
