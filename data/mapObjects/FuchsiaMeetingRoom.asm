FuchsiaMeetingRoomObject:
	db $17 ; border block

	db $2 ; warps
	db $7, $4, $6, $ff
	db $7, $5, $6, $ff

	db $0 ; signs

	db $3 ; objects
	object SPRITE_WHITE_PLAYER, $4, $1, STAY, DOWN, $1 ; person
	object SPRITE_WHITE_PLAYER, $0, $2, STAY, UP, $2 ; person
	object SPRITE_WHITE_PLAYER, $a, $1, STAY, DOWN, $3 ; person
