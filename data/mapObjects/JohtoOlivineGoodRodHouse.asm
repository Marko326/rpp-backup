; Gold OlivineGoodRodHouse uses (2,7)/(3,7), exits to OlivineCity Gold Warp #6.
; RPP city uses compacted outdoor Warp #2 (0-based).
JohtoOlivineGoodRodHouseObject:
 db $0c
 db $02
 db 7, 2, 2, REGION_WARP_ESCAPE
 db 7, 3, 2, REGION_WARP_ESCAPE
 db $00 ; Gold no BG events
 db $01 ; Gold Fishing Guru, image/movement/collision only. No Good Rod grant.
 object SPRITE_JOHTO_FISHING_GURU_GREEN, 2, 3, STAY, DOWN, 1 ; Gold STANDING_DOWN
