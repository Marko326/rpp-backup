; Gold 16x16: only Route32 (17,3) is enabled. B1F (5,19)/(3,33)
; and Route33 (17,31) stay unregistered until those maps exist.
JohtoUnionCave1FObject:
	db $21 ; independent opaque, impassable border metatile
	db $01
	db 3, 17, 0, REGION_WARP_ESCAPE
	db $00 ; signs
	db $00 ; Gold trainers and items deferred
