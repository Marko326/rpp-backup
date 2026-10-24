CeladonMansion5Object:
	db $a ; border block

	db $2 ; warps
	db $7, $2, $2, CELADON_MANSION_4
	db $7, $3, $2, CELADON_MANSION_4

	db $0 ; signs

	db $2 ; objects
	object SPRITE_HIKER, $2, $2, STAY, DOWN, $1 ; person
	object SPRITE_BALL, $4, $3, STAY, NONE, $2 ; person
