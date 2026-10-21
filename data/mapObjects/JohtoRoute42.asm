; B-ID63: Gold Route42 (30x9 blocks, 60x18 cells), Y,X coordinates.
; Gold warp slots 1/2: (0,8)/(0,9) -> Gate slots 3/4.
; Gold warp slots 3/4/5: Mt Mortar (10,5)/(28,9)/(46,7) ->
; MountMortar1FOutside slots 1/2/3. ALL five are dormant because C has
; not yet registered those destinations; no dummy entrances may be opened.
JohtoRoute42Object:
	db $05 ; existing JOHTO impassable outdoor border
	db $02 ; the west Gate pair is now reachable; Mt Mortar stays sealed
	db 8, 0, 2, REGION_WARP_ESCAPE ; Gold #1 -> Gate east #3
	db 9, 0, 3, REGION_WARP_ESCAPE ; Gold #2 -> Gate east #4
	; db 8, 0, 2, REGION_WARP_ESCAPE ; Gold #1 -> Gate #3
	; db 9, 0, 3, REGION_WARP_ESCAPE ; Gold #2 -> Gate #4
	; db 5, 10, 0, REGION_WARP_ESCAPE ; Gold #3 -> Mt Mortar #1
	; db 9, 28, 1, REGION_WARP_ESCAPE ; Gold #4 -> Mt Mortar #2
	; db 7, 46, 2, REGION_WARP_ESCAPE ; Gold #5 -> Mt Mortar #3
	; Keep cave entrances sealed until Mt Mortar is a separately accepted map.
	db $04 ; four original readable signs, Gold bg_event READ
	db 10,  4, 1 ; Route42 sign (x=4,y=10)
	db  5,  7, 2 ; Mt Mortar west sign (x=7,y=5)
	db  9, 45, 3 ; Mt Mortar east sign (x=45,y=9)
	db  8, 54, 4 ; Route42 east sign (x=54,y=8)
	db $00 ; 3 trainers, 3 fruit trees and 2 itemballs deferred
	; Hidden Max Potion at (16,11): global item/event logic also deferred.
