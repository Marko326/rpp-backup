; Original Gold west pair -> Ruins outside #10/#11; east -> Route32 #2/#3.
; RPP destination indexes are 0-based: outside gate 1/2, Route32 gate 1/2.
JohtoRoute32RuinsOfAlphGateObject:
	db $00
	db $04
	db 4, 0, 1, REGION_WARP_ESCAPE
	db 5, 0, 2, REGION_WARP_ESCAPE
	db 4, 9, 1, REGION_WARP_ESCAPE
	db 5, 9, 2, REGION_WARP_ESCAPE
	db $00 ; Gold gate NPC scripts deferred
	db $00
