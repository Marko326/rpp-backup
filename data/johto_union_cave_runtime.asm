; UNION-260: Union Cave 1F first active CAVE map (stable ID 8, slot 13).
; Gold map art and warp positions were checked against the supplied handoff.
JohtoUnionCave_GFX:: INCBIN "gfx/tilesets/johto_union_cave.2bpp"
JohtoUnionCave_Block:: INCBIN "gfx/blocksets/johto_union_cave.bst"
JohtoUnionCave_BlockEnd::
ASSERT JohtoUnionCave_BlockEnd - JohtoUnionCave_Block == 34 * 16
ASSERT BANK(JohtoUnionCave_Coll) == 0
JohtoUnionCave1FRuntimeBlocks::
    INCBIN "maps/johto_pilot/UnionCave1F.runtime.blk"
JohtoUnionCave1FRuntimeBlocksEnd::
ASSERT JohtoUnionCave1FRuntimeBlocksEnd - JohtoUnionCave1FRuntimeBlocks == JOHTO_UNION_CAVE_1F_WIDTH * JOHTO_UNION_CAVE_1F_HEIGHT

JohtoUnionCave1FRuntimeHeader::
    db JOHTO_UNION_CAVE
    db JOHTO_UNION_CAVE_1F_HEIGHT, JOHTO_UNION_CAVE_1F_WIDTH
    dw JohtoUnionCave1FRuntimeBlocks
    dw JohtoUnionCave1FTextPointers
    dw JohtoUnionCave1FScript
    db 0 ; no adjacent outdoor connections
    dw JohtoUnionCave1FRuntimeObjects
JohtoUnionCave1FRuntimeHeaderEnd::
ASSERT JohtoUnionCave1FRuntimeHeaderEnd - JohtoUnionCave1FRuntimeHeader == 12
ASSERT BANK(JohtoUnionCave1FRuntimeHeader) == BANK(JohtoUnionCave1FRuntimeBlocks)
JohtoUnionCave1FScript::
    call EnableAutoTextBoxDrawing
    ret
JohtoUnionCave1FTextPointers:
JohtoUnionCave1FRuntimeObjects::
    db $21 ; Gold compact cave border (impassable)
    db 2 ; Gold north #4 / south #3, underground stairways still sealed
    db 3, 17, 2, JOHTO_REGISTERED_WARP_SELECTOR
    db 31, 17, 0, JOHTO_REGISTERED_WARP_SELECTOR ; south cave -> Route33 warp0
    db 0 ; other signs, cave trainers and items deferred
    db 0
