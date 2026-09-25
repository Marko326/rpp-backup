CopycatsHouse2F_h:
	db REDS_HOUSE_1 ; tileset
	db COPYCATS_HOUSE_2F_HEIGHT, COPYCATS_HOUSE_2F_WIDTH ; dimensions (y, x)
	; MSP-5.43.00: use the shared text-box routine directly; redundant local MapScript wrapper removed.
	dw CopycatsHouse2FBlocks, CopycatsHouse2FTextPointers, EnableAutoTextBoxDrawing ; blocks, texts, scripts
	db $00 ; connections
	dw CopycatsHouse2FObject ; objects
