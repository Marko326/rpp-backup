; ILEX-5.62.212: Only Gold south warp #2/#3. North x=1,y=5 remains solid.
; RPP rows are Y,X,0-based destination warp index, escape destination.
JohtoIlexForestObject:
	db $00 ; Gold forest blocking border metatile, not a new Warp
	db $02
	db 42, 3, 2, REGION_WARP_ESCAPE
	db 43, 3, 3, REGION_WARP_ESCAPE
	db $00 ; Gold signs/hidden items deferred
	db $00 ; Gold Farfetch'd, Cut and other NPCs deferred
