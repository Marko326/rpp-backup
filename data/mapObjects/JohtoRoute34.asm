; Gold Route34 north-gate pair; Day-Care and other unimplemented doors closed.
JohtoRoute34Object:
	db $05 ; original outdoor border tile, water/trees controlled by Gold mask
	db $02
	db 37, 13, 0, REGION_WARP_ESCAPE
	db 37, 14, 1, REGION_WARP_ESCAPE
	db $00 ; signs deferred
	db $00 ; trainers, daycare and scripted objects deferred
