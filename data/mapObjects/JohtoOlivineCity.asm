; Gold OlivineCity 11 Warps remain sealed until interiors/port are built.
; Rival scene and town NPCs are deferred rather than faked with global flags.
JohtoOlivineCityObject:
 db $05
 db $00 ; no active Warp to unregistered buildings or port
 db $06 ; six Gold BGEVENT_READ signs, runtime (y,x)
 db 11, 17, 1 ; OlivineCity sign
 db 24, 20, 2 ; Port sign
 db 11, 7, 3 ; Gym
 db 28, 30, 4 ; Lighthouse
 db 21, 14, 5 ; Pokecenter
 db 17, 20, 6 ; Mart
 db $00
