; P2-005 / P3-001: executable-format graphics and blocks for the two-map pilot,
; isolated from untouched, byte-authentic Gold source data in bank $42.
; The adjusted runtime blocks use the Johto metatile mapping, never legacy Kanto IDs.
DEF JOHTO_PILOT_RUNTIME_RECORD_SIZE EQU 7
DEF JOHTO_PILOT_TILESET_ID EQU JOHTO_PILOT
ASSERT JOHTO_PILOT == 28
; P3-001 activates only the two fully described pilot headers; other stable IDs remain gated.
ASSERT JOHTO_NEW_BARK_LOCAL_ID == 0
ASSERT JOHTO_ROUTE_29_LOCAL_ID == 1
ASSERT NUM_JOHTO_ACTIVE_MAPS == 3

JohtoPilot_GFX:: INCBIN "gfx/tilesets/johto.2bpp"
JohtoPilot_Block:: INCBIN "gfx/blocksets/johto.bst"
JohtoPilot_BlockEnd::
ASSERT JohtoPilot_BlockEnd - JohtoPilot_Block == 141 * 16

JohtoPilot_Coll:: INCBIN "gfx/tilesets/johto.tilecoll"
JohtoPilot_CollEnd::
ASSERT JohtoPilot_CollEnd - JohtoPilot_Coll == 7

JohtoPilotNewBarkRuntimeBlocks::
    INCBIN "maps/johto_pilot/NewBarkTown.runtime.blk"
JohtoPilotNewBarkRuntimeBlocksEnd::
ASSERT JohtoPilotNewBarkRuntimeBlocksEnd - JohtoPilotNewBarkRuntimeBlocks == 10 * 9

JohtoPilotRoute29RuntimeBlocks::
    INCBIN "maps/johto_pilot/Route29.runtime.blk"
JohtoPilotRoute29RuntimeBlocksEnd::
ASSERT JohtoPilotRoute29RuntimeBlocksEnd - JohtoPilotRoute29RuntimeBlocks == 30 * 9

JohtoPilotCherrygroveRuntimeBlocks::
    INCBIN "maps/johto_pilot/CherrygroveCity.runtime.blk"
JohtoPilotCherrygroveRuntimeBlocksEnd::
ASSERT JohtoPilotCherrygroveRuntimeBlocksEnd - JohtoPilotCherrygroveRuntimeBlocks == JOHTO_CHERRYGROVE_WIDTH * JOHTO_CHERRYGROVE_HEIGHT

; Stable physical ID, registered tileset ID, width, height, block pointer, block bank.
; Not a map Header: no event, connection, Warp, sprite or collision fence
; may be enabled merely because a resource row appears here.
JohtoPilotRuntimeResourceDescriptors::
JohtoPilotNewBarkRuntimeDescriptor::
    db JOHTO_NEW_BARK_LOCAL_ID, JOHTO_PILOT_TILESET_ID, 10, 9
    dw JohtoPilotNewBarkRuntimeBlocks
    db BANK(JohtoPilotNewBarkRuntimeBlocks)
JohtoPilotRoute29RuntimeDescriptor::
    db JOHTO_ROUTE_29_LOCAL_ID, JOHTO_PILOT_TILESET_ID, 30, 9
    dw JohtoPilotRoute29RuntimeBlocks
    db BANK(JohtoPilotRoute29RuntimeBlocks)
JohtoPilotCherrygroveRuntimeDescriptor::
    db JOHTO_CHERRYGROVE_LOCAL_ID, JOHTO_PILOT_TILESET_ID, 20, 9
    dw JohtoPilotCherrygroveRuntimeBlocks
    db BANK(JohtoPilotCherrygroveRuntimeBlocks)
JohtoPilotRuntimeResourceDescriptorsEnd::
ASSERT JohtoPilotRuntimeResourceDescriptorsEnd - JohtoPilotRuntimeResourceDescriptors == 3 * JOHTO_PILOT_RUNTIME_RECORD_SIZE

; Read-only descriptor selector. Input E=stable physical Johto local ID.
; Success: D=ROM bank, HL=descriptor in D; failure: D=0/HL=0.
; A/flags are not outputs through callab; this does NOT activate a map.
JohtoPilotGetRuntimeResourceDescriptor::
    ld a, e
    cp JOHTO_NEW_BARK_LOCAL_ID
    jr z, .newBark
    cp JOHTO_ROUTE_29_LOCAL_ID
    jr z, .route29
    cp JOHTO_CHERRYGROVE_LOCAL_ID
    jr z, .cherrygrove
    ld d, 0
    ld hl, 0
    ret
.newBark
    ld hl, JohtoPilotNewBarkRuntimeDescriptor
    jr .valid
.route29
    ld hl, JohtoPilotRoute29RuntimeDescriptor
    jr .valid
.cherrygrove
    ld hl, JohtoPilotCherrygroveRuntimeDescriptor
.valid
    ld d, BANK(JohtoPilotRuntimeResourceDescriptors)
    ret
