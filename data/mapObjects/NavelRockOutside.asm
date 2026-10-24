NavelRockOutsideObject:
	db $43 ; border block

	db $3 ; warps
	db $5, $8, $0, NAVEL_ROCK_CAVE_1
	db $b, $9, $0, NAVEL_ROCK_FERRY_DOCK
	db $b, $a, $1, NAVEL_ROCK_FERRY_DOCK

	db $1 ; signs
	db $0, $0, $1 ; NavelRockSignText

	db $0 ; people
