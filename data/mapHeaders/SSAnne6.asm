SSAnne6_h:
	db SHIP ; tileset
	db SS_ANNE_6_HEIGHT, SS_ANNE_6_WIDTH ; dimensions (y, x)
	; MSP-5.43.00: use the shared text-box routine directly; redundant local MapScript wrapper removed.
	dw SSAnne6Blocks, SSAnne6TextPointers, EnableAutoTextBoxDrawing ; blocks, texts, scripts
	db $00 ; connections
	dw SSAnne6Object ; objects
