LanceObject:
	db $3 ; border block

	db $3 ; warps
	db $10, $18, $2, AGATHAS_ROOM
	db $0, $5, $0, CHAMPIONS_ROOM
	db $0, $6, $0, CHAMPIONS_ROOM

	db $0 ; signs

	db $1 ; objects
	object SPRITE_LANCE, $6, $1, STAY, DOWN, $1, OPP_LANCE, $1
