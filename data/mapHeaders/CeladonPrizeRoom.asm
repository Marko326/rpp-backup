CeladonPrizeRoom_h:
	db LOBBY ; tileset
	db CELADON_PRIZE_ROOM_HEIGHT, CELADON_PRIZE_ROOM_WIDTH ; dimensions (y, x)
	; MSP-5.43.00: use the shared text-box routine directly; redundant local MapScript wrapper removed.
	dw CeladonPrizeRoomBlocks, CeladonPrizeRoomTextPointers, EnableAutoTextBoxDrawing ; blocks, texts, scripts
	db $00 ; connections
	dw CeladonPrizeRoomObject ; objects
