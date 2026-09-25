SafariZoneRestHouse2_h:
	db GATE ; tileset
	db SAFARI_ZONE_REST_HOUSE_2_HEIGHT, SAFARI_ZONE_REST_HOUSE_2_WIDTH ; dimensions (y, x)
	; MSP-5.43.00: use the shared text-box routine directly; redundant local MapScript wrapper removed.
	dw SafariZoneRestHouse2Blocks, SafariZoneRestHouse2TextPointers, EnableAutoTextBoxDrawing ; blocks, texts, scripts
	db $00 ; connections
	dw SafariZoneRestHouse2Object ; objects
