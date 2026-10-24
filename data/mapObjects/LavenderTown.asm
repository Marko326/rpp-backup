LavenderTownObject:
	db $2c ; border block

	db $6 ; warps
	db  5,  7, $0, LAVENDER_POKECENTER
	db  5, 18, $0, POKEMONTOWER_1
	db  9, 11, $0, LAVENDER_HOUSE_1
	db 13, 19, $0, LAVENDER_MART
	db 13,  7, $0, LAVENDER_HOUSE_2
	db 13, 11, $0, NAME_RATERS_HOUSE

	db $6 ; signs
	db  9, 15, $4 ; LavenderTownText4
	db  3, 13, $5 ; LavenderTownText5
	db 13, 20, $6 ; MartSignText
	db  5,  8, $7 ; PokeCenterSignText
	db  9,  9, $8 ; LavenderTownText8
	db  7, 21, $9 ; LavenderTownText9

	db $3 ; objects
	object SPRITE_LITTLE_GIRL, 19, 9, WALK, $0, $1 ; person
	object SPRITE_BLACK_HAIR_BOY_1, 13, 10, STAY, NONE, $2 ; person
	object SPRITE_BLACK_HAIR_BOY_2, 12, 7, WALK, $2, $3 ; person
