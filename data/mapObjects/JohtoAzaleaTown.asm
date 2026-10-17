; GATE-5.62.202: open only Gold warp #7/#8 to the registered south gate.
; Gold's six other interior/Well Warps remain unregistered and solid.
JohtoAzaleaTownObject:
	db $05 ; outdoor border
	db $02 ; (2,10)/(2,11), native gate east slots 0/1
	db 10, 2, 0, REGION_WARP_ESCAPE
	db 11, 2, 1, REGION_WARP_ESCAPE
	db $01 ; Gold Azalea Town sign (x=19,y=9)
	db 9, 19, 1
	db $00 ; no NPCs, trainers or scripted events yet
