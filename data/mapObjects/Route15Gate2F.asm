Route15GateUpstairsObject:
	db $a ; border block

	db $1 ; warps
	db $7, $7, $4, ROUTE_15_GATE_1F

	db $1 ; signs
	db $2, $6, $2 ; Route15GateUpstairsText2

	db $1 ; objects
	object SPRITE_OAK_AIDE, $4, $2, STAY, DOWN, $1
