; MAP-5.62.192: Gold cave warp 4 (17,3) to Route32 and warp 3
; (17,31) to Route33. B1F (5,19)/(3,33) stays sealed.
JohtoUnionCave1FObject:
	db $21 ; independent opaque, impassable border metatile
	db $02
	db 3, 17, 0, REGION_WARP_ESCAPE
	db 31, 17, 0, REGION_WARP_ESCAPE
	db $00 ; signs
	db $00 ; Gold trainers and items deferred
