; R32-5.62.165: Gold coordinates use 16x16 (Y, X), not .blk blocks.
; PC (11,73) remains deferred; Ruins Gate (4,2)/(4,3) is open using original Gold carpets.
; Use Gold's real cave doorway at (6,79), not the approach at (6,80).
; Only the approach (6,80) may move north through its solid graphic.
JohtoRoute32Object:
	db $05 ; Johto outdoor border
	db $03 ; cave slot0 unchanged; Route32 west carpets are slots1/2
	db 79, 6, 0, REGION_WARP_ESCAPE
	db 2, 4, 2, REGION_WARP_ESCAPE
	db 3, 4, 3, REGION_WARP_ESCAPE
	db $04 ; four original Gold visible signs, (Y, X, text ID)
	db  5, 13, 1 ; Route32 sign
	db  1,  9, 2 ; Ruins direction sign
	db 84, 10, 3 ; Union Cave direction sign
	db 73, 12, 4 ; Pokemon Center sign
	db $00 ; Gold trainers, events, scripted blockade and items deferred
