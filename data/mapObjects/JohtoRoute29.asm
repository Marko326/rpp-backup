; MAP-5.62.126: authentic sign/NPC coordinates; non-ported events
; (fruit tree, item ball, catching tutorial, trainers) remain disabled.
JohtoRoute29Object:
	db $05 ; original Gold forest border block

	db $01 ; Gold Route29 north single solid DOOR (27,1)
	db 1, 27, 2, REGION_WARP_ESCAPE ; Gate bottom #3 (RPP 0-based #2)

	db $02 ; original Route29 road signs only
	db $07, $33, $05 ; original eastern Route 29 sign (x=51, y=7)
	db $05, $03, $06 ; original western Route 29 sign (x=3, y=5)

	db $04 ; existing Gen 1 stand-ins at original Gold NPC coordinates
	object SPRITE_GAMBLER,     $32, $0c, STAY, DOWN,  $01 ; catching-tutorial guide
	object SPRITE_BUG_CATCHER, $1b, $10, STAY, DOWN,  $02 ; youngster
	object SPRITE_LASS,        $0f, $0b, STAY, LEFT,  $03 ; teacher
	object SPRITE_FISHER,      $19, $03, STAY, DOWN,  $04 ; fisherman
