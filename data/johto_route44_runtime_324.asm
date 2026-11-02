; DEV-325 / REF-321: Route44 Gold outdoor movement + sealed east visual preview.
; No story/trainer/item/NPC objects. IcePath cave and later Blackthorn are unopened.
JohtoRoute44Blocks:: INCBIN "maps/johto_pilot/Route44.runtime.blk"
ASSERT @ - JohtoRoute44Blocks == JOHTO_ROUTE_44_WIDTH * JOHTO_ROUTE_44_HEIGHT

; DEV-325: Gold Blackthorn's west-edge three-column *visual* preview.
; DEV-326: Blackthorn uses the SAME bytes as an active outdoor map; no alternate preview copy,
; while IcePath, houses and Route45 physical exits stay closed.
; Copy the 20x18 source map to preserve Gold's original +9 row offset and stride.
JohtoRoute44EastBlackthornPreview::
JohtoBlackthornBlocks:: INCBIN "maps/johto_pilot/BlackthornCity.east_preview.blk"
ASSERT @ - JohtoRoute44EastBlackthornPreview == 20 * 18

JohtoRoute44Script::
    call EnableAutoTextBoxDrawing
    ret

JohtoRoute44RuntimeHeader::
    db JOHTO_PILOT
    db JOHTO_ROUTE_44_HEIGHT, JOHTO_ROUTE_44_WIDTH
    dw JohtoRoute44Blocks
    dw JohtoRoute44TextPointers
    dw JohtoRoute44Script
    db WEST | EAST ; DEV-326 Gold physical seam; IcePath cave still sealed
    ; WEST -> Mahogany Town east, Gold offset 0.
    db JOHTO_RUNTIME_MAP_HANDLE
    dw JohtoMahoganyBlocks + JOHTO_MAHOGANY_TOWN_WIDTH - 3
    dw wOverworldMap + 3 * (JOHTO_ROUTE_44_WIDTH + 6)
    db JOHTO_ROUTE_44_HEIGHT
    db JOHTO_MAHOGANY_TOWN_WIDTH
    db 0
    db JOHTO_MAHOGANY_TOWN_WIDTH * 2 - 1
    dw wOverworldMap + 6 + 2 * JOHTO_MAHOGANY_TOWN_WIDTH
    ; EAST -> Blackthorn west border. Gold offset -9: source rows 9..17.
    ; The outer three columns are painted; DEV-326 allows the Gold dry edge.
    db JOHTO_RUNTIME_MAP_HANDLE
    dw JohtoRoute44EastBlackthornPreview + 9 * 20
    dw wOverworldMap + 3 * (JOHTO_ROUTE_44_WIDTH + 6) + JOHTO_ROUTE_44_WIDTH + 3
    db JOHTO_ROUTE_44_HEIGHT
    db 20 ; Gold BlackthornCity width
    db 18 ; connection Y alignment for -9 block offset
    db 0  ; destination X alignment
    dw wOverworldMap + 7 + 20
    dw JohtoRoute44RuntimeObjects
JohtoRoute44HeaderEnd::
ASSERT JohtoRoute44HeaderEnd - JohtoRoute44RuntimeHeader == 34
ASSERT BANK(JohtoRoute44RuntimeHeader) == BANK(JohtoRoute44Blocks)
ASSERT BANK(JohtoRoute44RuntimeHeader) == BANK(JohtoMahoganyBlocks)
ASSERT BANK(JohtoRoute44RuntimeHeader) == BANK(JohtoRoute44EastBlackthornPreview)

JohtoRoute44RuntimeObjects::
    db $71 ; Gold Route44 map_attributes border: rock, not generic $05 trees
    db 0   ; IcePath cave entrance is closed until IcePath becomes active
    db 0   ; no signs required for geometry-only expansion
    db 0   ; no trainers/NPCs/items/story events in this phase

JohtoRoute44TextPointers:
    dw JohtoRoute44UnusedText
JohtoRoute44UnusedText:
    text "ROUTE 44"
    done
    db "@"
