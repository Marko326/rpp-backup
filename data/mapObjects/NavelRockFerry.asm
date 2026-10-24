NavelRockFerryObject:
	db $0 ; border block

	db $3 ; warps
	db $0, $5, $1, NAVEL_ROCK_OUTSIDE
	db $0, $6, $2, NAVEL_ROCK_OUTSIDE
	db $5, $6, $0, INSIDE_FERRY

	db $0 ; signs

	db $1 ; people
	db SPRITE_SAILOR, $5 + 4, $5 + 4, $ff, $d1, $1 ; person
