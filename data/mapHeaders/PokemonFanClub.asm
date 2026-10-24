FanClub_h:
	db INTERIOR ; tileset
	db POKEMON_FAN_CLUB_HEIGHT, POKEMON_FAN_CLUB_WIDTH ; dimensions (y, x)
	; MSP-5.43.00: use the shared text-box routine directly; redundant local MapScript wrapper removed.
	dw FanClubBlocks, FanClubTextPointers, EnableAutoTextBoxDrawing ; blocks, texts, scripts
	db $00 ; connections
	dw FanClubObject ; objects
