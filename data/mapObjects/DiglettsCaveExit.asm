DiglettsCaveRoute2Object:
	db $7d ; border block

	db $3 ; warps
	db $7, $2, $0, $ff
	db $7, $3, $0, $ff
	db $4, $4, $0, DIGLETTS_CAVE

	db $0 ; signs

	db $1 ; objects
	object SPRITE_BUG_CATCHER, $3, $3, STAY, NONE, $1 ; person
