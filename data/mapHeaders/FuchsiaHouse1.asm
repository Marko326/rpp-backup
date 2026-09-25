FuchsiaHouse1_h:
	db HOUSE ; tileset
	db FUCHSIA_HOUSE_1_HEIGHT, FUCHSIA_HOUSE_1_WIDTH ; dimensions (y, x)
	; MSP-5.43.00: use the shared text-box routine directly; redundant local MapScript wrapper removed.
	dw FuchsiaHouse1Blocks, FuchsiaHouse1TextPointers, EnableAutoTextBoxDrawing ; blocks, texts, scripts
	db $00 ; connections
	dw FuchsiaHouse1Object ; objects
