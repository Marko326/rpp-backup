Route8GateObject:
	db $a ; border block

	db $4 ; warps
	db $3, $0, $0, $ff
	db $4, $0, $1, $ff
	db $3, $5, $2, $ff
	db $4, $5, $3, $ff

	db $0 ; signs

	db $1 ; objects
	object SPRITE_GUARD, $2, $1, STAY, DOWN, $1 ; person
