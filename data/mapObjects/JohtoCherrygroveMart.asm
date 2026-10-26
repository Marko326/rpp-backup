; Gold CherrygroveMart, no shop scripts/services; RPP warp #3 in city.
JohtoCherrygroveMartObject:
 db $0a ; shared Gold Mart border block
 db $02
 db 7, 2, 3, REGION_WARP_ESCAPE
 db 7, 3, 3, REGION_WARP_ESCAPE
 db $00 ; no BG events
 db $03
 object SPRITE_JOHTO_CLERK, 1, 3, STAY, RIGHT, 1
 object SPRITE_JOHTO_COOLTRAINER_M, 7, 6, WALK, 2, 2
 object SPRITE_JOHTO_YOUNGSTER_RED, 2, 5, STAY, DOWN, 3
