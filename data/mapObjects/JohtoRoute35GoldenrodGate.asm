; Gold gate warp #1/#2 -> Route35 #1/#2;
; warp #3/#4 -> BOTH GoldenrodCity #13 (RPP city only active warp #0).
; RPP records: Y, X, zero-based destination warp, $FE native escape.
JohtoRoute35GoldenrodGateObject:
	db $0d ; solid black border, as accepted NorthSouthGate
	db 4
	db 0, 4, 0, REGION_WARP_ESCAPE
	db 0, 5, 1, REGION_WARP_ESCAPE
	db 7, 4, 0, REGION_WARP_ESCAPE
	db 7, 5, 0, REGION_WARP_ESCAPE
	db 0 ; no Gold dialogue/signs until separate script review
	db 0 ; Randy/Kenya, trainer and events deliberately deferred
