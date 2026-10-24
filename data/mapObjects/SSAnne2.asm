SSAnne2Object:
	db $c ; border block

	db $9 ; warps
	db $b, $9, $0, SS_ANNE_9
	db $b, $d, $2, SS_ANNE_9
	db $b, $11, $4, SS_ANNE_9
	db $b, $15, $6, SS_ANNE_9
	db $b, $19, $8, SS_ANNE_9
	db $b, $1d, $a, SS_ANNE_9
	db $4, $2, $8, SS_ANNE_1
	db $c, $2, $1, SS_ANNE_3
	db $4, $24, $0, SS_ANNE_7

	db $0 ; signs

	db $2 ; objects
	object SPRITE_WAITER, $3, $7, WALK, $1, $1 ; person
	object SPRITE_BLUE, $24, $4, STAY, DOWN, $2, OPP_SONY1, $1
