; Gold EcruteakCity has 15 Warp events; unfinished destinations remain sealed.
; Seven original BG signs are now interactive at their Gold (x,y) coordinates.
; Unfinished west/east gates are sealed by edge fences; no fake house facade.
JohtoEcruteakCityObject:
	db $05
	db $02 ; Gold west gate #14/#15 now opens via native Warp
	db 18, 0, 2, REGION_WARP_ESCAPE
	db 19, 0, 3, REGION_WARP_ESCAPE
	db $07 ; all 7 original city signs
	db 21, 15, 1 ; city: Gold (15,21), runtime (y,x)
	db 10, 38, 2 ; Tin Tower
	db 28, 8, 3  ; Gym
	db 21, 21, 4 ; Dance Theater
	db 10, 2, 5  ; Burned Tower
	db 27, 24, 6 ; Pokecenter
	db 21, 30, 7 ; Mart
	db $00 ; NPCs/hidden items and story deferred
