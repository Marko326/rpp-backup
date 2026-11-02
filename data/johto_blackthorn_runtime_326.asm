; DEV-326 / REF-322: Gold Blackthorn City OUTDOOR ONLY. Houses, IcePath, Route45 closed.
; JohtoBlackthornBlocks aliases the verified Route44 east preview in the same bank.
JohtoBlackthornSouthRoute45Preview:: INCBIN "maps/johto_pilot/Route45.south_preview.blk"
ASSERT @ - JohtoBlackthornSouthRoute45Preview == 10 * 45
JohtoBlackthornRoles:: INCBIN "maps/johto_pilot/BlackthornCity.roles.bin"
ASSERT @ - JohtoBlackthornRoles == JOHTO_BLACKTHORN_CITY_WIDTH * 2 * JOHTO_BLACKTHORN_CITY_HEIGHT * 2

JohtoBlackthornScript::
    call EnableAutoTextBoxDrawing
    ret
JohtoBlackthornRuntimeHeader::
    db JOHTO_PILOT
    db JOHTO_BLACKTHORN_CITY_HEIGHT, JOHTO_BLACKTHORN_CITY_WIDTH
    dw JohtoBlackthornBlocks
    dw JohtoBlackthornTextPointers
    dw JohtoBlackthornScript
    db SOUTH | WEST ; Gold Route45 and Route44 seams physically active
    ; SOUTH -> active Route45 north strip, source previously audited as preview.
    db JOHTO_RUNTIME_MAP_HANDLE
    dw JohtoBlackthornSouthRoute45Preview
    dw wOverworldMap + (JOHTO_BLACKTHORN_CITY_HEIGHT + 3) * (JOHTO_BLACKTHORN_CITY_WIDTH + 6) + 3
    db 10 ; Route45 width
    db 10
    db 0
    db 0
    dw wOverworldMap + 7 + 10
    ; WEST -> Gold Route44 east, offset +9 blocks.
    db JOHTO_RUNTIME_MAP_HANDLE
    dw JohtoRoute44Blocks + JOHTO_ROUTE_44_WIDTH - 3
    dw wOverworldMap + (3 + 9) * (JOHTO_BLACKTHORN_CITY_WIDTH + 6)
    db JOHTO_ROUTE_44_HEIGHT
    db JOHTO_ROUTE_44_WIDTH
    db -18
    db JOHTO_ROUTE_44_WIDTH * 2 - 1
    dw wOverworldMap + 6 + 2 * JOHTO_ROUTE_44_WIDTH
    dw JohtoBlackthornRuntimeObjects
JohtoBlackthornHeaderEnd::
ASSERT JohtoBlackthornHeaderEnd - JohtoBlackthornRuntimeHeader == 34
ASSERT BANK(JohtoBlackthornRuntimeHeader) == BANK(JohtoBlackthornBlocks)
ASSERT BANK(JohtoBlackthornRuntimeHeader) == BANK(JohtoRoute44Blocks)
ASSERT BANK(JohtoBlackthornRuntimeHeader) == BANK(JohtoBlackthornSouthRoute45Preview)
JohtoBlackthornRuntimeObjects::
    db $71 ; Gold BlackthornCity map_attributes border: rock, not $05 trees
    db 0 ; houses, IcePath cave and Dragon's Den are sealed (no Warps)
    db 0 ; no signs
    db 0 ; no people, scripted scenes or plot
JohtoBlackthornTextPointers:
    dw JohtoBlackthornUnusedText
JohtoBlackthornUnusedText:
    text "BLACKTHORN CITY"
    done
    db "@"
