FuchsiaMeetingRoom_h:
	db LAB ; tileset
	db FUCHSIA_MEETING_ROOM_HEIGHT, FUCHSIA_MEETING_ROOM_WIDTH ; dimensions (y, x)
	; MSP-5.43.00: use the shared text-box routine directly; redundant local MapScript wrapper removed.
	dw FuchsiaMeetingRoomBlocks, FuchsiaMeetingRoomTextPointers, EnableAutoTextBoxDrawing ; blocks, texts, scripts
	db $00 ; connections
	dw FuchsiaMeetingRoomObject ; objects
