; Top x4/5 -> Route36 x47/48,y13; bottom x4/5 -> Ruins x7,y5.
; Gold's bottom pair merges to ONE outside Warp index 0.
JohtoRoute36RuinsGateObject:
	db $0d ; isolated solid black border, same as accepted north gate
	db $04
	db 0, 4, 0, REGION_WARP_ESCAPE
	db 0, 5, 1, REGION_WARP_ESCAPE
	db 7, 4, 0, REGION_WARP_ESCAPE
	db 7, 5, 0, REGION_WARP_ESCAPE
	db $00 ; dialogue NPCs deferred
	db $00
