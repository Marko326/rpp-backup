; Gold NorthSouthGate: top pair -> Route34 #1/#2, bottom pair -> Forest #1.
; RPP records use Y,X,0-based destination; two southern mouths merge into one.
JohtoRoute34IlexForestGateObject:
	db $0d ; original solid black border, not a walkable door
	db $04
	db 0, 4, 0, REGION_WARP_ESCAPE
	db 0, 5, 1, REGION_WARP_ESCAPE
	db 7, 4, 2, REGION_WARP_ESCAPE
	db 7, 5, 2, REGION_WARP_ESCAPE
	db $00 ; no Gold NPC story in map-expansion stage
	db $00
