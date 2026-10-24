PalletTownObject:
	db $f ; border block

	db $3 ; warps
	db $5, $5, $0, REDS_HOUSE_1F
	db $5, $d, $0, BLUES_HOUSE
	db $b, $c, $1, OAKS_LAB

	db $4 ; signs
	db $d, $d, $4 ; PalletTownText4
	db $9, $7, $5 ; PalletTownText5
	db $5, $3, $6 ; PalletTownText6
	db $5, $b, $7 ; PalletTownText7

	db $3 ; objects
	object SPRITE_OAK, $8, $5, STAY, NONE, $1 ; person
	object SPRITE_GIRL, $3, $8, WALK, $0, $2 ; person
	object SPRITE_FISHER2, $b, $e, WALK, $0, $3 ; person
