; Gate-5.62.151: coordinate/order cross-checked against pokegold Route31VioletGate.
; RPP warp records: Y, X, destination warp index (zero-based), destination map.
; Gold left edge (0,4)/(0,5) -> VioletCity Gold warp 8/9 (RPP slots 0/1).
; Gold right edge (9,4)/(9,5) -> Route31 Gold warp 1/2 (RPP slots 0/1).
JohtoRoute31VioletGateObject:
	db $0a ; existing RPP GATE border metatile
	db $04 ; warps
	db 4, 0, 0, JOHTO_VIOLET_CITY
	db 5, 0, 1, JOHTO_VIOLET_CITY
	db 4, 9, 0, JOHTO_ROUTE_31
	db 5, 9, 1, JOHTO_ROUTE_31
	db $00 ; signs
	db $00 ; NPCs/objects (Gold's two officers/trainers deferred)
