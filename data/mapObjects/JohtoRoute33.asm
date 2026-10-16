; MAP-5.62.192: Gold Route33 (11,9) north cave entrance now enabled.
; Azalea Town stays closed. Gold sign at (11,11) is available.
JohtoRoute33Object:
	db $05 ; outdoor border
	db $01 ; Union Cave 1F entry, explicit native target
	db 9, 11, 1, REGION_WARP_ESCAPE
	db $01 ; one route sign
	db 11, 11, 1
	db $00 ; trainer, tree, and scripted events deferred
