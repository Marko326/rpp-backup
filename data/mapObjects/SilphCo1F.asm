SilphCo1Object:
	db $2e ; border block

	db $5 ; warps
	db $11, $a, $5, $ff
	db $11, $b, $5, $ff
	db $0, $1a, $0, SILPH_CO_2F
	db $0, $14, $0, SILPH_CO_ELEVATOR
	db $a, $10, $6, SILPH_CO_3F

	db $0 ; signs

	db $1 ; objects
	object SPRITE_GREETER, $4, $2, STAY, DOWN, $1 ; person
