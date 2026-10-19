; Gold outside Warp #9 (7,5) alone is live; the other ten (chambers,
; lab, Union Cave B1F and east Route32 gate) stay impassable, not fake warps.
JohtoRuinsOfAlphOutsideObject:
	db $05 ; outdoor border
	db $01
	db 5, 7, 2, REGION_WARP_ESCAPE ; north gate bottom-left warp #3 -> RPP 2
	db $03 ; Gold original readable signs, no story triggers
	db 8, 16, 1
	db 16, 12, 2
	db 12, 18, 3
	db $00 ; NPCs/trainer/coord events deferred
