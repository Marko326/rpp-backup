; Source: Gold OlivinePunishmentSpeechHouse (2,7)/(3,7) -> OlivineCity Gold #5.
; RPP registered only ONE Olivine exterior Warp; both exits target its index 0.
JohtoOlivinePunishmentSpeechHouseObject:
 db $0c ; compacted all-black, collision-impassable border block
 db $02
 db 7, 2, 0, REGION_WARP_ESCAPE
 db 7, 3, 0, REGION_WARP_ESCAPE
 db $02 ; bookshelves (Gold BG events y1/x0 and y1/x1)
 db 1, 0, 3
 db 1, 1, 4
 db $02 ; Gold NPC sprites with authentic palette; Gold position/order unchanged
 object SPRITE_JOHTO_POKEFAN_M, 1, 2, STAY, NONE, 1 ; Gold SPINRANDOM_SLOW: turn in place
 object SPRITE_JOHTO_LASS, 5, 5, WALK, 2, 2 ; Gold Lass WALK_LEFT_RIGHT; JOHTO_HOUSE passable-floor IDs required
