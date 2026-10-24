SafariZoneSecretHouse_h:
	db LAB ; tileset
	db SAFARI_ZONE_SECRET_HOUSE_HEIGHT, SAFARI_ZONE_SECRET_HOUSE_WIDTH ; dimensions (y, x)
	; MSP-5.43.00: use the shared text-box routine directly; redundant local MapScript wrapper removed.
	dw SafariZoneSecretHouseBlocks, SafariZoneSecretHouseTextPointers, EnableAutoTextBoxDrawing ; blocks, texts, scripts
	db $00 ; connections
	dw SafariZoneSecretHouseObject ; objects
