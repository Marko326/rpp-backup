; ILEX-5.62.216: staged outdoor GoldenrodCity, Gold 15 interior warps
; and all story objects unregistered until each destination is developed.
JohtoGoldenrodCityObject:
	db $35 ; exact Gold GoldenrodCity border block (data/maps/attributes.asm)
	db $00 ; no active building/Route35 warps
	db $01 ; Gold Bike Shop exterior sign (28,30): safe bicycle pickup
	db 30, 28, 1
	db $00 ; NPCs and scripts deferred
