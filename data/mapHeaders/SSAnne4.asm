SSAnne4_h:
	db SHIP ; tileset
	db SS_ANNE_4_HEIGHT, SS_ANNE_4_WIDTH ; dimensions (y, x)
	; MSP-5.43.00: use the shared text-box routine directly; redundant local MapScript wrapper removed.
	dw SSAnne4Blocks, SSAnne4TextPointers, EnableAutoTextBoxDrawing ; blocks, texts, scripts
	db $00 ; connections
	dw SSAnne4Object ; objects
