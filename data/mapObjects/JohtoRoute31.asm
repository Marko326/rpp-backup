; Route31 Gate restored as a normal *indoor* transition. Dark Cave remains disabled.
JohtoRoute31Object:
	db $05 ; Johto forest edge
	db $02 ; Gate (two entrance tiles), no cave
	db 6, 4, 2, JOHTO_ROUTE31_VIOLET_GATE
	db 7, 4, 3, JOHTO_ROUTE31_VIOLET_GATE
	db $02 ; two original Route31 signs, Y / X / text ID
	db $05, $07, $01 ; Route31 sign
	db $05, $1f, $02 ; Dark Cave direction sign
	db $00 ; no NPCs/items/trainers yet
