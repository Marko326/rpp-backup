; REG-5.62.118: a physical map is identified by (region, local map ID).
; These are not Town Map landmark or Fly destination indices.
DEF MAP_REGION_KANTO EQU 0
DEF MAP_REGION_JOHTO EQU 1

; Only New Bark is registered in this first Johto region index.
; NEW_BARK_TOWN ($E7) remains the legacy save/warp alias for now.
DEF JOHTO_NEW_BARK_LOCAL_ID EQU 0
DEF NUM_JOHTO_MAPS EQU 1

; REG-5.62.119: signature written beside the saved region bytes.
; Old saves have no defined region state. These markers are currently written,
; not checked; legacy map IDs populate the compatibility fields on map load.
DEF REGION_STATE_MAGIC0 EQU $52
DEF REGION_STATE_MAGIC1 EQU $4a

; REG-5.62.120: opt-in escape in an ordinary warp destination byte.
; Only routes explicitly registered in ExplicitWarpRegionTargets may use it.
; $FF remains LAST_MAP; $FE is outside the existing legacy map table.
DEF REGION_WARP_ESCAPE EQU $fe
ASSERT REGION_WARP_ESCAPE >= NUM_LEGACY_MAPS
ASSERT REGION_WARP_ESCAPE != $ff
