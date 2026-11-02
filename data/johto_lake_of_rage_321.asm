; REF-318 / DEV-321: first playable Gold Lake of Rage outdoor map (stable ID68).
; The exact 20x18 block bytes live at JohtoLakeOfRageBlocks in the Route43 file
; so Route43 north preview and the live Lake never diverge or duplicate data.
; Only the Gold SOUTH connection to Route43 is active. The two house doors,
; Red Gyarados/Lance/trainers/items and later Route44/Blackthorn story remain closed.

JohtoLakeOfRageScript::
    call EnableAutoTextBoxDrawing
    ret

JohtoLakeOfRageRuntimeHeader::
    db JOHTO_PILOT
    db JOHTO_LAKE_OF_RAGE_HEIGHT, JOHTO_LAKE_OF_RAGE_WIDTH
    dw JohtoLakeOfRageBlocks
    dw JohtoLakeOfRageTextPointers
    dw JohtoLakeOfRageScript
    db SOUTH
    ; SOUTH -> Route43, Gold offset +5 blocks. Lake x10..29 overlaps Route43 x0..19.
    db JOHTO_RUNTIME_MAP_HANDLE
    dw JohtoRoute43Blocks
    dw wOverworldMap + (JOHTO_LAKE_OF_RAGE_HEIGHT + 3) * (JOHTO_LAKE_OF_RAGE_WIDTH + 6) + 3 + 5
    db JOHTO_ROUTE_43_WIDTH
    db JOHTO_ROUTE_43_WIDTH
    db 0
    db -10
    dw wOverworldMap + 7 + JOHTO_ROUTE_43_WIDTH
    dw JohtoLakeOfRageRuntimeObjects
JohtoLakeOfRageHeaderEnd::
ASSERT JohtoLakeOfRageHeaderEnd - JohtoLakeOfRageRuntimeHeader == 23
ASSERT BANK(JohtoLakeOfRageRuntimeHeader) == BANK(JohtoLakeOfRageBlocks)
ASSERT BANK(JohtoLakeOfRageRuntimeHeader) == BANK(JohtoRoute43Blocks)
ASSERT BANK(JohtoLakeOfRageRuntimeHeader) == BANK(JohtoLakeOfRageScript)
ASSERT BANK(JohtoLakeOfRageRuntimeHeader) == BANK(JohtoLakeOfRageRuntimeObjects)

JohtoLakeOfRageRuntimeObjects::
    db $05 ; Gold Johto border block
    db 0 ; house doors stay collision-solid until their indoor maps are audited/registered
    db 2 ; safe Gold signs only; hidden items/story BG events remain deferred
    db 27, 21, 1
    db 31, 25, 2
    db 0 ; Red Gyarados/Lance/trainers/items/story objects deferred

JohtoLakeOfRageTextPointers:
    dw JohtoLakeOfRageSignText
    dw JohtoLakeOfRageFishingGuruSignText
JohtoLakeOfRageSignText:
    text "LAKE OF RAGE"
    done
    db "@"
JohtoLakeOfRageFishingGuruSignText:
    text "FISHING GURU'S"
    line "HOUSE"
    done
    db "@"
