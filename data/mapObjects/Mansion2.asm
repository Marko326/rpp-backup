Mansion2Object:
	db $1 ; border block

	db $4 ; warps
	db $a, $5, $4, MANSION_1
	db $a, $7, $0, MANSION_3
	db $e, $19, $2, MANSION_3
	db $1, $6, $1, MANSION_3

	db $0 ; signs

	db $4 ; objects
	object SPRITE_BLACK_HAIR_BOY_2, $3, $11, WALK, $2, $1, OPP_BURGLAR, $7
	object SPRITE_BALL, $1c, $b, STAY, NONE, $2, OLD_SEA_MAP
	object SPRITE_BOOK, $12, $2, STAY, NONE, $3 ; person
	object SPRITE_BOOK, $3, $16, STAY, NONE, $4 ; person
