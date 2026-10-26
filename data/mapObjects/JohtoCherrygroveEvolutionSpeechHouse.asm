; Gold CherrygroveEvolutionSpeechHouse: indoor (2,7)/(3,7) -> outdoor (31,11), city Warp slot 2.
JohtoCherrygroveEvolutionSpeechHouseObject:
 db $0c ; shared House1 NPC VRAM sprite set
 db $02
 db 7, 2, 2, REGION_WARP_ESCAPE
 db 7, 3, 2, REGION_WARP_ESCAPE
 db $00 ; background events postponed (display-only milestone)
 db $02 ; Gold people only, no NPC scripts, gifts, trades, or flags
 object SPRITE_JOHTO_LASS_GREEN, 3, 5, STAY, LEFT, 1 ; Gold object #1
 object SPRITE_JOHTO_YOUNGSTER_RED, 2, 5, STAY, RIGHT, 2 ; Gold object #2
