Route7GateObject:
	db $a ; border block

	db $4 ; warps
	db $3, $0, $3, $ff
	db $4, $0, $3, $ff
	db $3, $5, $0, $ff
	db $4, $5, $1, $ff

	db $0 ; signs

	db $1 ; objects
	object SPRITE_GUARD, $3, $1, STAY, DOWN, $1 ; person
