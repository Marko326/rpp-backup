; UNION-260: Union Cave 1F first active CAVE map (stable ID 8, slot 13).
; Gold map art and warp positions were checked against the supplied handoff.
JohtoUnionCave_GFX:: INCBIN "gfx/tilesets/johto_union_cave.2bpp"
JohtoUnionCave_Block:: INCBIN "gfx/blocksets/johto_union_cave.bst"
JohtoUnionCave_BlockEnd::
ASSERT JohtoUnionCave_BlockEnd - JohtoUnionCave_Block == 41 * 16
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
    db $21 ; preserve opaque, impassable cave border
    db 4 ; Gold north/south exits and two stairs to B1F
    db 3, 17, 2, JOHTO_REGISTERED_WARP_SELECTOR ; Route32
    db 31, 17, 0, JOHTO_REGISTERED_WARP_SELECTOR ; Route33
    db 19, 5, 2, JOHTO_REGISTERED_WARP_SELECTOR ; Gold stair at (5,19) -> B1F warp2
    db 33, 3, 3, JOHTO_REGISTERED_WARP_SELECTOR ; Gold stair at (3,33) -> B1F warp3
    db 0 ; signs, trainers and items deferred
    db 0

; REF-340 B2F pilot: B1F Ruins carpets ordinal0/1 remain inactive.
; Only Gold ordinal4 is newly opened to B2F; NPCs/items/events remain deferred.
JohtoUnionCaveB1FRuntimeBlocks::
    INCBIN "maps/johto_pilot/UnionCaveB1F.runtime.blk"
JohtoUnionCaveB1FRuntimeBlocksEnd::
ASSERT JohtoUnionCaveB1FRuntimeBlocksEnd - JohtoUnionCaveB1FRuntimeBlocks == JOHTO_UNION_CAVE_1F_WIDTH * JOHTO_UNION_CAVE_1F_HEIGHT

JohtoUnionCaveB1FRuntimeHeader::
    db JOHTO_UNION_CAVE
    db JOHTO_UNION_CAVE_1F_HEIGHT, JOHTO_UNION_CAVE_1F_WIDTH
    dw JohtoUnionCaveB1FRuntimeBlocks
    dw JohtoUnionCaveB1FTextPointers
    dw JohtoUnionCaveB1FScript
    db 0 ; no adjacent seams
    dw JohtoUnionCaveB1FRuntimeObjects
JohtoUnionCaveB1FRuntimeHeaderEnd::
ASSERT JohtoUnionCaveB1FRuntimeHeaderEnd - JohtoUnionCaveB1FRuntimeHeader == 12
ASSERT BANK(JohtoUnionCaveB1FRuntimeHeader) == BANK(JohtoUnionCaveB1FRuntimeBlocks)
JohtoUnionCaveB1FScript::
    call EnableAutoTextBoxDrawing
    ret
JohtoUnionCaveB1FTextPointers:
JohtoUnionCaveB1FRuntimeObjects::
    db $21 ; same opaque cave border as 1F
    db 5 ; Ruins ordinals0/1 remain closed; 2/3 return to 1F; 4 opens B2F
    db 3, 3, 3, JOHTO_REGISTERED_WARP_SELECTOR ; ordinal 0: inert Ruins north carpet
    db 11, 3, 4, JOHTO_REGISTERED_WARP_SELECTOR ; ordinal 1: inert Ruins south carpet
    db 19, 7, 2, JOHTO_REGISTERED_WARP_SELECTOR ; ordinal 2: 1F east stair
    db 33, 3, 3, JOHTO_REGISTERED_WARP_SELECTOR ; ordinal 3: 1F west stair
    db 31, 17, 0, JOHTO_REGISTERED_WARP_SELECTOR ; ordinal 4: B2F stair
    db 0 ; item/Strength/trainer events deferred
    db 0

JohtoUnionCaveB2FRuntimeBlocks::
    INCBIN "maps/johto_pilot/UnionCaveB2F.runtime.blk"
JohtoUnionCaveB2FRuntimeBlocksEnd::
ASSERT JohtoUnionCaveB2FRuntimeBlocksEnd - JohtoUnionCaveB2FRuntimeBlocks == JOHTO_UNION_CAVE_1F_WIDTH * JOHTO_UNION_CAVE_1F_HEIGHT

JohtoUnionCaveB2FRuntimeHeader::
    db JOHTO_UNION_CAVE
    db JOHTO_UNION_CAVE_1F_HEIGHT, JOHTO_UNION_CAVE_1F_WIDTH
    dw JohtoUnionCaveB2FRuntimeBlocks
    dw JohtoUnionCaveB2FTextPointers
    dw JohtoUnionCaveB2FScript
    db 0 ; no adjacent outdoor connections
    dw JohtoUnionCaveB2FRuntimeObjects
JohtoUnionCaveB2FRuntimeHeaderEnd::
ASSERT JohtoUnionCaveB2FRuntimeHeaderEnd - JohtoUnionCaveB2FRuntimeHeader == 12
ASSERT BANK(JohtoUnionCaveB2FRuntimeHeader) == BANK(JohtoUnionCaveB2FRuntimeBlocks)
JohtoUnionCaveB2FScript::
    call EnableAutoTextBoxDrawing
    ret
JohtoUnionCaveB2FTextPointers:
JohtoUnionCaveB2FRuntimeObjects::
    db $21 ; same Gold-textured, impassable cave border as 1F/B1F
    db 1 ; Gold B2F has one stair back to B1F
    db 3, 5, 4, JOHTO_REGISTERED_WARP_SELECTOR ; ordinal 0: B1F warp4
    db 0 ; trainers, item balls and Friday Lapras deferred
    db 0

; REF-344: reusable STANDARD_CAVE well with both floors; Union Cave is the
; single shared art/blockset/warp/land/surf adapter, not a second cave engine.
JohtoSlowpokeWellB1FRuntimeBlocks::
    INCBIN "maps/johto_pilot/SlowpokeWellB1F.runtime.blk"
JohtoSlowpokeWellB1FRuntimeBlocksEnd::
ASSERT JohtoSlowpokeWellB1FRuntimeBlocksEnd - JohtoSlowpokeWellB1FRuntimeBlocks == JOHTO_SLOWPOKE_WELL_B1F_WIDTH * JOHTO_SLOWPOKE_WELL_B1F_HEIGHT

JohtoSlowpokeWellB1FRuntimeHeader::
    db JOHTO_UNION_CAVE
    db JOHTO_SLOWPOKE_WELL_B1F_HEIGHT, JOHTO_SLOWPOKE_WELL_B1F_WIDTH
    dw JohtoSlowpokeWellB1FRuntimeBlocks
    dw JohtoSlowpokeWellB1FTextPointers
    dw JohtoSlowpokeWellB1FScript
    db 0
    dw JohtoSlowpokeWellB1FRuntimeObjects
JohtoSlowpokeWellB1FRuntimeHeaderEnd::
ASSERT JohtoSlowpokeWellB1FRuntimeHeaderEnd - JohtoSlowpokeWellB1FRuntimeHeader == 12
ASSERT BANK(JohtoSlowpokeWellB1FRuntimeHeader) == BANK(JohtoSlowpokeWellB1FRuntimeBlocks)
JohtoSlowpokeWellB1FScript::
    call EnableAutoTextBoxDrawing
    ret
JohtoSlowpokeWellB1FTextPointers:
JohtoSlowpokeWellB1FRuntimeObjects::
    db $21 ; Gold-textured, impassable cave border used by the audited cave adapter
    db 2 ; Gold #1 back to Azalea, Gold #2 down to B2F
    db 15, 17, 3, JOHTO_REGISTERED_WARP_SELECTOR ; Gold #1 -> Azalea runtime ordinal3
    db 11, 7, 0, JOHTO_REGISTERED_WARP_SELECTOR ; Gold #2 -> B2F Gold #1
    db 0 ; trainer/Slowpoke/item events still deferred
    db 1 ; Gold B1F (3,2) uses existing RBY Strength boulder movement
    object SPRITE_BOULDER, 3, 2, STAY, BOULDER_MOVEMENT_BYTE_2, $1


; REF-344: Gold Slowpoke Well B2F 10x9, one normal LADDER.
; No new cave tileset, palette policy, story actors, or HM implementation.
JohtoSlowpokeWellB2FRuntimeBlocks::
    INCBIN "maps/johto_pilot/SlowpokeWellB2F.runtime.blk"
JohtoSlowpokeWellB2FRuntimeBlocksEnd::
ASSERT JohtoSlowpokeWellB2FRuntimeBlocksEnd - JohtoSlowpokeWellB2FRuntimeBlocks == JOHTO_SLOWPOKE_WELL_B2F_WIDTH * JOHTO_SLOWPOKE_WELL_B2F_HEIGHT

JohtoSlowpokeWellB2FRuntimeHeader::
    db JOHTO_UNION_CAVE
    db JOHTO_SLOWPOKE_WELL_B2F_HEIGHT, JOHTO_SLOWPOKE_WELL_B2F_WIDTH
    dw JohtoSlowpokeWellB2FRuntimeBlocks
    dw JohtoSlowpokeWellB2FTextPointers
    dw JohtoSlowpokeWellB2FScript
    db 0
    dw JohtoSlowpokeWellB2FRuntimeObjects
JohtoSlowpokeWellB2FRuntimeHeaderEnd::
ASSERT JohtoSlowpokeWellB2FRuntimeHeaderEnd - JohtoSlowpokeWellB2FRuntimeHeader == 12
ASSERT BANK(JohtoSlowpokeWellB2FRuntimeHeader) == BANK(JohtoSlowpokeWellB2FRuntimeBlocks)
JohtoSlowpokeWellB2FScript::
    call EnableAutoTextBoxDrawing
    ret
JohtoSlowpokeWellB2FTextPointers:
JohtoSlowpokeWellB2FRuntimeObjects::
    db $21 ; same opaque Gold cave border as B1F
    db 1
    db 11, 9, 1, JOHTO_REGISTERED_WARP_SELECTOR ; Gold #1 -> B1F Gold #2
    db 0 ; signs
    db 0 ; Gym Guide and Rain Dance TM events deferred
