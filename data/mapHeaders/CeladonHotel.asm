CeladonHotel_h:
	db POKECENTER ; tileset
	db CELADON_HOTEL_HEIGHT, CELADON_HOTEL_WIDTH ; dimensions (y, x)
	; MSP-5.43.00: use the shared text-box routine directly; redundant local MapScript wrapper removed.
	dw CeladonHotelBlocks, CeladonHotelTextPointers, EnableAutoTextBoxDrawing ; blocks, texts, scripts
	db $00 ; connections
	dw CeladonHotelObject ; objects
