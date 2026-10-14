; P2-1: original Gold outdoor sign coordinates; interiors and events deferred.
JohtoCherrygroveCityObject:
	db $05 ; forest border, same background as New Bark / Route 29
	db $00 ; no building warps (all interiors deferred)
	db $04 ; four Gold exterior signs (y, x, text ID)
	db $08, $1e, $01 ; x=30 y=8: Cherrygrove City
	db $09, $17, $02 ; x=23 y=9: guide's house
	db $03, $18, $03 ; x=24 y=3: Mart
	db $03, $1e, $04 ; x=30 y=3: Pokemon Center
	db $00 ; no NPCs or event scripts yet; no Gold scripts transplanted
