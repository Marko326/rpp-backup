; MAP-5.62.126: keep buildings closed; west path now reaches Route 29.
NewBarkTownObject:
	db $05 ; Gold Johto forest border block

	db $01 ; warps
	db $08, $11, $00, INSIDE_FERRY ; ferry boarding, eastern shoreline

	db $04 ; signs
	db $08, $08, $05 ; town sign
	db $05, $0b, $06 ; player's home sign
	db $03, $03, $07 ; Elm's lab sign
	db $0d, $09, $08 ; Elm's house sign

	db $04 ; people: MAP-5.62.130 temporary Route 29 NPC side-by-side test
	object SPRITE_SAILOR,      $10, $07, STAY, RIGHT, $01 ; ferry, unchanged
	object SPRITE_GAMBLER,     $06, $08, STAY, DOWN,  $02 ; Route 29 guide graphic test
	object SPRITE_BUG_CATCHER, $0c, $09, STAY, DOWN,  $03 ; Route 29 youngster graphic test
	object SPRITE_LASS,        $03, $02, STAY, DOWN,  $04 ; Route 29 teacher graphic test
; Testing only: dialogues keep their existing town text IDs. Route 29
; NPC objects remain untouched for same-ROM scenery comparison.
