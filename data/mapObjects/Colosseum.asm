ColosseumObject:
	db $e ; border block

	db $0 ; warps

	db $0 ; signs

	db $1 ; objects
	object VAR_SPRITE_1, $2, $2, STAY, $0, $1 ; linked opponent; set during handshake
