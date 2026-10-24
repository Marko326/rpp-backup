SafariZoneRestHouse4_h:
	db GATE ; tileset
	db SAFARI_ZONE_REST_HOUSE_4_HEIGHT, SAFARI_ZONE_REST_HOUSE_4_WIDTH ; dimensions (y, x)
	; MSP-5.43.00: use the shared text-box routine directly; redundant local MapScript wrapper removed.
	dw SafariZoneRestHouse4Blocks, SafariZoneRestHouse4TextPointers, EnableAutoTextBoxDrawing ; blocks, texts, scripts
	db $00 ; connections
	dw SafariZoneRestHouse4Object ; objects
