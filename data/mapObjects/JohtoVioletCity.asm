; Only Route31VioletGate is enabled; buildings and other routes remain closed.
; Six regular sign locations kept; the seventh Gold bg event is an item.
JohtoVioletCityObject:
	db $05 ; Johto outdoor border style
	db $02 ; two outdoor gate entrance tiles
	db 24, 39, 0, JOHTO_ROUTE31_VIOLET_GATE
	db 25, 39, 1, JOHTO_ROUTE31_VIOLET_GATE
	db $06 ; signs (Y, X, text ID), Gold original coordinates
	db 20, 24, 1 ; Violet City sign
	db 17, 15, 2 ; Gym
	db  8, 24, 3 ; Sprout Tower
	db 17, 27, 4 ; Pokemon Academy
	db 25, 32, 5 ; Pokemon Center
	db 17, 10, 6 ; Mart
	db $00 ; no NPCs, hidden items, trainers or script objects
