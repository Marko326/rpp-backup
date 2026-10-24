SafariZoneNorth_h:
	db SAFARI ; tileset
	db SAFARI_ZONE_NORTH_HEIGHT, SAFARI_ZONE_NORTH_WIDTH ; dimensions (y, x)
	; MSP-5.43.00: use the shared text-box routine directly; redundant local MapScript wrapper removed.
	dw SafariZoneNorthBlocks, SafariZoneNorthTextPointers, EnableAutoTextBoxDrawing ; blocks, texts, scripts
	db $00 ; connections
	dw SafariZoneNorthObject ; objects
