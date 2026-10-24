JohtoOlivinePokecenter1FObject:
	db $0f ; Gold black border block
	db $02 ; two outdoor exits; Gold 2F stair deliberately not registered
	db 7, 3, 3, REGION_WARP_ESCAPE
	db 7, 4, 3, REGION_WARP_ESCAPE
	db $00 ; no BG events; no fake healing/PC events
	db $04
	object SPRITE_JOHTO_NURSE, 3, 1, STAY, DOWN, 1
	object SPRITE_JOHTO_FISHING_GURU_BLUE, 8, 4, WALK, 1, 2
	object SPRITE_JOHTO_FISHER, 2, 3, STAY, DOWN, 3
	object SPRITE_JOHTO_TEACHER, 7, 1, STAY, DOWN, 4
