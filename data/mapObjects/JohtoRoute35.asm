; R35-5.62.223: Gold border and two road signs; all three gate Warps and
; trainer/item/fruit-tree events are deferred pending separate reviews.
JohtoRoute35Object:
	db $05 ; Gold original outdoor border block
	db $03 ; Gold original three entrances: south pair plus park north
	db 33, 9, 0, REGION_WARP_ESCAPE
	db 33, 10, 1, REGION_WARP_ESCAPE
	db 5, 3, 2, REGION_WARP_ESCAPE ; northern park gate bottom source #3
	db $02
	db 7, 1, 1 ; Gold northern Route35 sign
	db 31, 11, 1 ; Gold southern Route35 sign
	db $00 ; do not spawn placeholder NPCs or blocking objects
