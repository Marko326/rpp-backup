SilphCo9Object:
	db $2e ; border block

	db $5 ; warps
	db $0, $e, $0, SILPH_CO_10F
	db $0, $10, $0, SILPH_CO_8F
	db $0, $12, $0, SILPH_CO_ELEVATOR
	db $3, $9, $7, SILPH_CO_3F
	db $f, $11, $4, SILPH_CO_5F

	db $0 ; signs

	db $4 ; objects
	object SPRITE_NURSE, $3, $e, STAY, DOWN, $1 ; person
	object SPRITE_ROCKET_F, $2, $4, STAY, UP, $2, OPP_ROCKET_F, $25
	object SPRITE_OAK_AIDE, $15, $d, STAY, DOWN, $3, OPP_SCIENTIST, $a
	object SPRITE_ROCKET_F, $d, $10, STAY, UP, $4, OPP_ROCKET_F, $26
