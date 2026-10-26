; Gold CherrygroveGymSpeechHouse: indoor (2,7)/(3,7) -> outdoor (17,7), city Warp slot 0.
JohtoCherrygroveGymSpeechHouseObject:
 db $0c ; shared House1 NPC VRAM sprite set
 db $02
 db 7, 2, 0, REGION_WARP_ESCAPE
 db 7, 3, 0, REGION_WARP_ESCAPE
 db $00 ; background events postponed (display-only milestone)
 db $02 ; Gold people only, no NPC scripts, gifts, trades, or flags
 object SPRITE_JOHTO_POKEFAN_M, 2, 3, STAY, DOWN, 1 ; Gold object #1
 object SPRITE_JOHTO_BUG_CATCHER_RED, 5, 5, WALK, 2, 2 ; Gold object #2
