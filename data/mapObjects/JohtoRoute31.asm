; Gold Route31: static signs only; all three cave/gate warps disabled.
; Do not introduce any outdoor shortcut between Route31 and VioletCity.
JohtoRoute31Object:
	db $05 ; Johto forest edge
	db $00 ; no warps: Gate (2), Dark Cave (1) deferred
	db $02 ; two original Route31 signs, Y / X / text ID
	db $05, $07, $01 ; Route31 sign
	db $05, $1f, $02 ; Dark Cave direction sign
	db $00 ; no NPCs/items/trainers yet
