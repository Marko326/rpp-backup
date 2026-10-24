JohtoOlivineCafeObject:
	db $0a ; Gold black border block
	db $02 ; two outdoor exits
	db 7, 2, 4, REGION_WARP_ESCAPE
	db 7, 3, 4, REGION_WARP_ESCAPE
	db $00 ; no BG events; Strength gift deferred
	db $02
	object SPRITE_JOHTO_SAILOR, 4, 3, STAY, LEFT, 1
	object SPRITE_JOHTO_FISHING_GURU_BLUE, 1, 5, WALK, 1, 2
