SSAnne3_h:
	db SHIP ; tileset
	db SS_ANNE_3_HEIGHT, SS_ANNE_3_WIDTH ; dimensions (y, x)
	; MSP-5.43.00: use the shared text-box routine directly; redundant local MapScript wrapper removed.
	dw SSAnne3Blocks, SSAnne3TextPointers, EnableAutoTextBoxDrawing ; blocks, texts, scripts
	db $00 ; connections
	dw SSAnne3Object ; objects
