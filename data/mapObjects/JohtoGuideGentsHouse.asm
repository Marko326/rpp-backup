; Gold GuideGentsHouse: indoor (2,7)/(3,7) -> outdoor (25,9), city Warp slot 1.
JohtoGuideGentsHouseObject:
 db $0c ; shared House1 NPC VRAM sprite set
 db $02
 db 7, 2, 1, REGION_WARP_ESCAPE
 db 7, 3, 1, REGION_WARP_ESCAPE
 db $00 ; background events postponed (display-only milestone)
 db $01 ; Gold people only, no NPC scripts, gifts, trades, or flags
 object SPRITE_JOHTO_GRAMPS, 2, 3, STAY, RIGHT, 1 ; Gold object #1
