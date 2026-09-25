CeruleanHouse2Object:
	db $a ; border block

	db $3 ; warps
	db $0, $2, $9, $ff
	db $7, $2, $8, $ff
	db $7, $3, $8, $ff

	db $0 ; signs

	db $1 ; objects
	object SPRITE_FAT_BALD_GUY, $5, $3, STAY, RIGHT, $1 ; person
