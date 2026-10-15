; R32-5.62.165: Gold coordinates use 16x16 (Y, X), not .blk blocks.
; PC (11,73), Ruins Gate (4,2)/(4,3), Union Cave (6,79) do not
; have valid destination maps yet: NO Warp entries or substitute targets.
JohtoRoute32Object:
	db $05 ; Johto outdoor border
	db $00 ; all four indoor Warps disabled
	db $04 ; four original Gold visible signs, (Y, X, text ID)
	db  5, 13, 1 ; Route32 sign
	db  1,  9, 2 ; Ruins direction sign
	db 84, 10, 3 ; Union Cave direction sign
	db 73, 12, 4 ; Pokemon Center sign
	db $00 ; Gold trainers, events, scripted blockade and items deferred
