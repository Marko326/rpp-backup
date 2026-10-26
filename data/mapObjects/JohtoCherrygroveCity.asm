; P2-1: original Gold outdoor sign coordinates; interiors and events deferred.
JohtoCherrygroveCityObject:
	db $05 ; forest border, same background as New Bark / Route 29
	db $05 ; Three houses plus Gold Mart and Pokecenter
	db 7, 17, 0, REGION_WARP_ESCAPE ; Gold city warp #3 -> GymSpeechHouse
	db 9, 25, 0, REGION_WARP_ESCAPE ; Gold city warp #4 -> GuideGentsHouse
	db 11, 31, 0, REGION_WARP_ESCAPE ; Gold city warp #5 -> EvolutionSpeechHouse
 db 3, 23, 0, REGION_WARP_ESCAPE ; Gold city warp #1 -> Mart (RPP #3)
 db 3, 29, 0, REGION_WARP_ESCAPE ; Gold city warp #2 -> Pokecenter (RPP #4)
	db $04 ; four Gold exterior signs (y, x, text ID)
	db $08, $1e, $01 ; x=30 y=8: Cherrygrove City
	db $09, $17, $02 ; x=23 y=9: guide's house
	db $03, $18, $03 ; x=24 y=3: Mart
	db $03, $1e, $04 ; x=30 y=3: Pokemon Center
	db $00 ; no NPCs or event scripts yet; no Gold scripts transplanted
