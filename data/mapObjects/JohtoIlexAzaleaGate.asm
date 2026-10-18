; ILEX-5.62.212: east slots 0/1 are unchanged; Gold west warps #1/#2 are RPP 2/3.
JohtoIlexAzaleaGateObject:
	db $0d ; same black border metatile as the approved Route31 gate
	db $04
	db 4, 9, 0, REGION_WARP_ESCAPE
	db 5, 9, 1, REGION_WARP_ESCAPE
	; ILEX-5.62.212: Gold west warp #1/#2 mapped to native Forest pair #2/#3.
	db 4, 0, 0, REGION_WARP_ESCAPE
	db 5, 0, 1, REGION_WARP_ESCAPE
	db $00 ; no signs
	db $00 ; Gold officer/granny dialogues deferred
