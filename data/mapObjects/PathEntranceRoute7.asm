UndergroundPathEntranceRoute7Object:
	db $a ; border block

	db $3 ; warps
	db $7, $3, $4, $ff
	db $7, $4, $4, $ff
	db $4, $4, $0, UNDERGROUND_PATH_WE

	db $0 ; signs

	db $1 ; objects
	object SPRITE_FAT_BALD_GUY, $2, $4, STAY, NONE, $1 ; person
