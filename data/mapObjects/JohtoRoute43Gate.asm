; Gold Route43Gate: top two -> Route43 north carpets #4/#5;
; bottom two -> one Route43 south solid door #3.
JohtoRoute43GateObject:
 db $0d
 db $04
 db 0, 4, 3, REGION_WARP_ESCAPE
 db 0, 5, 4, REGION_WARP_ESCAPE
 db 7, 4, 2, REGION_WARP_ESCAPE
 db 7, 5, 2, REGION_WARP_ESCAPE
 db 0
 db 0 ; Rocket toll scene and Officer TM36 intentionally deferred
