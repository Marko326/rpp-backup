; JHT-5.62.110: keep all four building doors closed, and block Route 29.
NewBarkTownObject:
	db $05 ; Gold Johto forest border block

	db $01 ; warps
	db $08, $11, $00, INSIDE_FERRY ; ferry boarding, eastern shoreline

	db $04 ; signs
	db $08, $08, $05 ; town sign
	db $05, $0b, $06 ; player's home sign
	db $03, $03, $07 ; Elm's lab sign
	db $0d, $09, $08 ; Elm's house sign

	db $04 ; people
	object SPRITE_SAILOR,      $10, $07, STAY, RIGHT, $01 ; ferry
	object SPRITE_LASS,        $06, $08, STAY, LEFT,  $02 ; teacher
	object SPRITE_FISHER,      $0c, $09, STAY, DOWN,  $03 ; fisher
	object SPRITE_BUG_CATCHER, $03, $02, STAY, RIGHT, $04 ; visitor near Elm's lab
