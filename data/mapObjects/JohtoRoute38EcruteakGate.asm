; Gold west #1/#2 -> Route38 #1/#2, east #3/#4 -> city #14/#15.
; Record layout: y,x,destination 0-based Warp slot, native region escape.
JohtoRoute38EcruteakGateObject:
	db $0d
	db 4
	db 4, 0, 0, REGION_WARP_ESCAPE
	db 5, 0, 1, REGION_WARP_ESCAPE
	db 4, 9, 0, REGION_WARP_ESCAPE
	db 5, 9, 1, REGION_WARP_ESCAPE
	db 0 ; signs
	db 0 ; officer's script text preserved; NPC event implementation deferred
