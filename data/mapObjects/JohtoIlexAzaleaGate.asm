; GATE-5.62.197: Gold east warps #3/#4 map to RPP slots 0/1.
; Gold west warps #1/#2 deliberately absent, with opaque border at x<0.
JohtoIlexAzaleaGateObject:
	db $0d ; same black border metatile as the approved Route31 gate
	db $02
	db 4, 9, 0, REGION_WARP_ESCAPE
	db 5, 9, 1, REGION_WARP_ESCAPE
	db $00 ; no signs
	db $00 ; Gold officer/granny dialogues deferred
