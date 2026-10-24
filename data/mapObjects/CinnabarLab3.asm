Lab3Object:
	db $0 ; border block

	db $2 ; warps
	db $7, $2, $3, CINNABAR_LAB_1
	db $7, $3, $3, CINNABAR_LAB_1

	db $3 ; signs
	db $4, $0, $3 ; Lab3Text3
	db $4, $1, $4 ; Lab3Text4
	db $1, $2, $5 ; Lab3Text5

	db $2 ; objects
	object SPRITE_OAK_AIDE, $7, $2, STAY, DOWN, $1 ; person
	object SPRITE_OAK_AIDE, $2, $3, WALK, $2, $2 ; person
