; REF-315: first playable Gold Route43 outdoor slice. Gold exact 10x27 blocks.
; REF-318: the existing exact Gold Lake preview is now also ID68's runtime block source.
; ID65/ID66 Warp behavior remains unchanged; Route43 north uses the audited Gold seam.
JohtoRoute43Blocks:: INCBIN "maps/johto_pilot/Route43.runtime.blk"
ASSERT @ - JohtoRoute43Blocks == JOHTO_ROUTE_43_WIDTH * JOHTO_ROUTE_43_HEIGHT

JohtoRoute43Script::
    call EnableAutoTextBoxDrawing
    ret

; The 360-byte Gold Lake source is shared by Route43's north connection and
; Lake of Rage ID68 itself. One copy only: both headers stay in Bank $53.
JohtoLakeOfRageBlocks::
JohtoRoute43LakeOfRagePreviewBlocks:: INCBIN "maps/johto_pilot/LakeOfRage.preview.blk"
ASSERT @ - JohtoRoute43LakeOfRagePreviewBlocks == JOHTO_LAKE_OF_RAGE_WIDTH * JOHTO_LAKE_OF_RAGE_HEIGHT

JohtoRoute43RuntimeHeader::
    db JOHTO_PILOT
    db JOHTO_ROUTE_43_HEIGHT, JOHTO_ROUTE_43_WIDTH
    dw JohtoRoute43Blocks
    dw JohtoRoute43TextPointers
    dw JohtoRoute43Script
    db NORTH | SOUTH
    ; NORTH: Gold Lake of Rage, offset -5. REF-318 opens only the exact shared walkable seam lanes.
    db JOHTO_RUNTIME_MAP_HANDLE
    dw JohtoRoute43LakeOfRagePreviewBlocks + 2 + JOHTO_LAKE_OF_RAGE_WIDTH * (JOHTO_LAKE_OF_RAGE_HEIGHT - 3)
    dw wOverworldMap
    db JOHTO_ROUTE_43_WIDTH + 3
    db JOHTO_LAKE_OF_RAGE_WIDTH
    db JOHTO_LAKE_OF_RAGE_HEIGHT * 2 - 1
    db 10
    dw wOverworldMap + 1 + JOHTO_LAKE_OF_RAGE_HEIGHT * (JOHTO_LAKE_OF_RAGE_WIDTH + 6)
    ; SOUTH: Gold Mahogany Town preview, offset 0. ID65 remains the physical exit.
    db JOHTO_RUNTIME_MAP_HANDLE
    dw JohtoMahoganyBlocks
    dw wOverworldMap + (JOHTO_ROUTE_43_HEIGHT + 3) * (JOHTO_ROUTE_43_WIDTH + 6) + 3
    db JOHTO_ROUTE_43_WIDTH
    db JOHTO_MAHOGANY_TOWN_WIDTH
    db 0
    db 0
    dw wOverworldMap + 7 + JOHTO_MAHOGANY_TOWN_WIDTH
    dw JohtoRoute43RuntimeObjects
JohtoRoute43HeaderEnd::
ASSERT JohtoRoute43HeaderEnd - JohtoRoute43RuntimeHeader == 34
ASSERT BANK(JohtoRoute43RuntimeHeader) == BANK(JohtoRoute43Blocks)
ASSERT BANK(JohtoRoute43RuntimeHeader) == BANK(JohtoRoute43LakeOfRagePreviewBlocks)
ASSERT BANK(JohtoRoute43RuntimeHeader) == BANK(JohtoMahoganyBlocks)
ASSERT BANK(JohtoRoute43RuntimeHeader) == BANK(JohtoRoute43Script)
ASSERT BANK(JohtoRoute43RuntimeHeader) == BANK(JohtoRoute43RuntimeObjects)

JohtoRoute43RuntimeObjects::
    db $05 ; Gold Johto border block
    db 5 ; Gold Route43 warps #1..#5 in original order
    db 51, 9, 2, JOHTO_REGISTERED_WARP_SELECTOR ; Gold #1 -> ID65 #3
    db 51, 10, 3, JOHTO_REGISTERED_WARP_SELECTOR ; Gold #2 -> ID65 #4
    db 35, 17, 2, JOHTO_REGISTERED_WARP_SELECTOR ; Gold #3 DOOR -> ID66 south #3
    db 31, 17, 0, JOHTO_REGISTERED_WARP_SELECTOR ; Gold #4 DOWN carpet -> ID66 north #1
    db 31, 18, 1, JOHTO_REGISTERED_WARP_SELECTOR ; Gold #5 DOWN carpet -> ID66 north #2
    db 3 ; Gold Route43 signs; trainers/items remain unregistered
    db 3, 13, 1
    db 49, 11, 2
    db 38, 16, 3
    db 0 ; no dynamic NPC until their battle and scene scripts are ported

JohtoRoute43TextPointers:
    dw JohtoRoute43NorthSignText
    dw JohtoRoute43SouthSignText
    dw JohtoRoute43TipsText
JohtoRoute43NorthSignText:
    text "ROUTE 43"
    para "LAKE OF RAGE -"
    line "MAHOGANY TOWN"
    done
    db "@"
JohtoRoute43SouthSignText:
    text "ROUTE 43"
    para "LAKE OF RAGE -"
    line "MAHOGANY TOWN"
    done
    db "@"
JohtoRoute43TipsText:
    text "TRAINER TIPS"
    para "All #MON have"
    line "pros and cons"
    para "depending on their"
    line "types."
    para "If their types"
    line "differ, a higher-"
    para "level #MON may"
    line "lose in battle."
    para "Learn which types"
    line "are strong and"
    para "weak against your"
    line "#MON's type."
    done
    db "@"
