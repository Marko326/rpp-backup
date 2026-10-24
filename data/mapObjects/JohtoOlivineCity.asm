; Gold OlivineCity has three unlocked ordinary houses; other entrances remain sealed.
; Rival scene and town NPCs are deferred rather than faked with global flags.
JohtoOlivineCityObject:
 db $05
 db $03 ; three Gold-proven ordinary houses; other entrances sealed
 db 11, 29, 0, REGION_WARP_ESCAPE ; Gold outside Warp #5 -> inside Warp #1
 db 11, 25, 0, REGION_WARP_ESCAPE ; Gold OlivineTimsHouse entry -> indoor Warp #1
 db 15, 13, 0, REGION_WARP_ESCAPE ; Gold OlivineGoodRodHouse entry -> indoor Warp #1
 db $06 ; six Gold BGEVENT_READ signs, runtime (y,x)
 db 11, 17, 1 ; OlivineCity sign
 db 24, 20, 2 ; Port sign
 db 11, 7, 3 ; Gym
 db 28, 30, 4 ; Lighthouse
 db 21, 14, 5 ; Pokecenter
 db 17, 20, 6 ; Mart
 db $00
