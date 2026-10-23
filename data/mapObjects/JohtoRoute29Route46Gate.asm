; Gold indoor north (4/5,0) -> Route46 warp 1/2;
; south (4/5,7) -> the SAME Route29 warp 1, do not split the single exit.
JohtoRoute29Route46GateObject:
 db $0d ; Gold NorthSouthGate black border
 db 4
 db 0, 4, 0, REGION_WARP_ESCAPE
 db 0, 5, 1, REGION_WARP_ESCAPE
 db 7, 4, 0, REGION_WARP_ESCAPE
 db 7, 5, 0, REGION_WARP_ESCAPE
 db 0 ; officer/youngster Gold NPC scripts deferred
 db 0
