VermilionFerryDock_h:
	db FERRY ; tileset
	db VERMILION_FERRY_DOCK_HEIGHT, VERMILION_FERRY_DOCK_WIDTH ; dimensions (y, x)
	; MSP-5.43.00: use the shared text-box routine directly; redundant local MapScript wrapper removed.
	dw VermilionFerryBlocks, VermilionFerryTextPointers, EnableAutoTextBoxDrawing ; blocks, texts, scripts
	db $00 ; connections
	dw VermilionFerryObject ; objects
