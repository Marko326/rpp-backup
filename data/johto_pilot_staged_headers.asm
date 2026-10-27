; P2-005C: independent Gen1-format outdoor headers (staging only).
; These use the actual runtime tileset and block addresses in Bank $43.
; No warp/connection/script/NPC is active: ALL identifiers stay unregistered.
; A later release must add sealed boundaries, events, music and native
; connected-map IDs together before exposing any of these via the live table.
ASSERT NUM_JOHTO_ACTIVE_MAPS == 0
ASSERT JOHTO_NEW_BARK_LOCAL_ID == 0
ASSERT JOHTO_ROUTE_29_LOCAL_ID == 1
ASSERT BANK(JohtoPilotNewBarkRuntimeBlocks) == BANK(JohtoPilotRoute29RuntimeBlocks)
ASSERT BANK(JohtoPilotNewBarkRuntimeBlocks) == BANK(JohtoPilot_GFX)

JohtoPilotNewBarkStagedHeader::
    db JOHTO_PILOT
    db 9, 10 ; height, width in 4x4 blocks
    dw JohtoPilotNewBarkRuntimeBlocks
    dw JohtoPilotUnusedTextPointers
    dw JohtoPilotNoOpMapScript
    db 0 ; connections DISABLED until native IDs/borders implemented
    dw JohtoPilotNewBarkStagedObjects
JohtoPilotNewBarkStagedHeaderEnd::
ASSERT JohtoPilotNewBarkStagedHeaderEnd - JohtoPilotNewBarkStagedHeader == 12

JohtoPilotRoute29StagedHeader::
    db JOHTO_PILOT
    db 9, 30
    dw JohtoPilotRoute29RuntimeBlocks
    dw JohtoPilotUnusedTextPointers
    dw JohtoPilotNoOpMapScript
    db 0 ; Route 29 west/north and New Bark east not yet connected
    dw JohtoPilotRoute29StagedObjects
JohtoPilotRoute29StagedHeaderEnd::
ASSERT JohtoPilotRoute29StagedHeaderEnd - JohtoPilotRoute29StagedHeader == 12

; The object stream begins with border block, followed by three counts.
; Real Gold signs, buildings, exits and trainers require audited conversion.
JohtoPilotNewBarkStagedObjects::
    db $05, 0, 0, 0 ; border, no warps, no signs, no sprites
JohtoPilotRoute29StagedObjects::
    db $05, 0, 0, 0
JohtoPilotUnusedTextPointers::
    dw 0 ; cannot be dereferenced: no signs or sprites
JohtoPilotNoOpMapScript::
    ret

ASSERT BANK(JohtoPilotNewBarkStagedHeader) == BANK(JohtoPilotNewBarkRuntimeBlocks)
ASSERT BANK(JohtoPilotRoute29StagedHeader) == BANK(JohtoPilotRoute29RuntimeBlocks)
ASSERT BANK(JohtoPilotNewBarkStagedHeader) == BANK(JohtoPilotNoOpMapScript)
