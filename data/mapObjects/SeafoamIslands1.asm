SeafoamIslands1Object:
	db 46 ; border block

	db $7 ; warps
	db $11, $4, $0, $ff
	db $11, $5, $0, $ff
	db $11, $1a, $1, $ff
	db $11, $1b, $1, $ff
	db $5, $7, $1, SEAFOAM_ISLANDS_2
	db $3, $19, $6, SEAFOAM_ISLANDS_2
	db $f, $17, $4, SEAFOAM_ISLANDS_2

	db $0 ; signs

	db $2 ; objects
	object SPRITE_BOULDER, $12, $a, STAY, BOULDER_MOVEMENT_BYTE_2, $1 ; person
	object SPRITE_BOULDER, $1a, $7, STAY, BOULDER_MOVEMENT_BYTE_2, $2 ; person
