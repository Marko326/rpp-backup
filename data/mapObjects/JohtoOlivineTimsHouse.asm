; Gold OlivineTimsHouse uses (2,7)/(3,7), exits to OlivineCity Gold Warp #3.
; RPP city uses compacted outdoor Warp #1 (0-based).
JohtoOlivineTimsHouseObject:
 db $0c
 db $02
 db 7, 2, 1, REGION_WARP_ESCAPE
 db 7, 3, 1, REGION_WARP_ESCAPE
 db $02 ; Gold (0,1) and (1,1) magazine bookshelves
 db 1, 0, 1
 db 1, 1, 2
 db $01 ; Gold Tim, image/movement/collision only. Trade is deliberately deferred.
 object SPRITE_JOHTO_FISHING_GURU_RED, 2, 3, STAY, NONE, 1 ; Gold SPINRANDOM_SLOW
