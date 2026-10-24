SSAnne1_h:
	db SHIP ; tileset
	db SS_ANNE_1_HEIGHT, SS_ANNE_1_WIDTH ; dimensions (y, x)
	; MSP-5.43.00: use the shared text-box routine directly; redundant local MapScript wrapper removed.
	dw SSAnne1Blocks, SSAnne1TextPointers, EnableAutoTextBoxDrawing ; blocks, texts, scripts
	db $00 ; connections
	dw SSAnne1Object ; objects
