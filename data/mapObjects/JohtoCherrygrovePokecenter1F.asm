; Gold CherrygrovePokecenter1F: second-floor stair (0,7) stays blocked.
; Only two outdoor exits are registered; no treatment/storage/communication.
JohtoCherrygrovePokecenter1FObject:
 db $0f ; shared Gold Pokecenter border block
 db $02
 db 7, 3, 4, REGION_WARP_ESCAPE
 db 7, 4, 4, REGION_WARP_ESCAPE
 db $00 ; no BG events
 db $04
 object SPRITE_JOHTO_NURSE, 3, 1, STAY, DOWN, 1
 object SPRITE_JOHTO_FISHER_RED, 2, 3, STAY, UP, 2
 object SPRITE_JOHTO_GENTLEMAN, 8, 6, STAY, UP, 3
 object SPRITE_JOHTO_TEACHER_GREEN, 1, 6, STAY, RIGHT, 4
