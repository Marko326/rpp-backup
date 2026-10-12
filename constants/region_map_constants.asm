; REG-5.62.118: a physical map is identified by (region, local map ID).
; These are not Town Map landmark or Fly destination indices.
DEF MAP_REGION_KANTO EQU 0
DEF MAP_REGION_JOHTO EQU 1

; Only New Bark is registered in this first Johto region index.
; NEW_BARK_TOWN ($E7) remains the legacy save/warp alias for now.
DEF JOHTO_NEW_BARK_LOCAL_ID EQU 0
DEF NUM_JOHTO_MAPS EQU 1
