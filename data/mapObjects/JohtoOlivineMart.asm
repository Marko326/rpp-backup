JohtoOlivineMartObject:
	db $0a ; Gold black border block
	db $02 ; two outdoor exits
	db 7, 2, 5, REGION_WARP_ESCAPE
	db 7, 3, 5, REGION_WARP_ESCAPE
	db $00 ; no BG events; shopping deferred
	db $03
	object SPRITE_JOHTO_CLERK, 1, 3, STAY, RIGHT, 1
	object SPRITE_JOHTO_COOLTRAINER_F, 6, 2, WALK, 2, 2
	object SPRITE_JOHTO_LASS, 1, 6, STAY, LEFT, 3
