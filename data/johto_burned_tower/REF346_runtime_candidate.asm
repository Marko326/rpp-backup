; REF-346 UNLINKED candidate; do not INCLUDE until PIT + role logic is tested.
; Exact Gold art and blockset: two distinct DAY tilesets, not Union Cave NITE.

JohtoBurnedTower1F_GFX:: INCBIN "gfx/tilesets/johto_burned_tower_1f.2bpp"
JohtoBurnedTower1F_Block:: INCBIN "gfx/blocksets/johto_burned_tower_1f.bst"
JohtoBurnedTower1F_BlockEnd::
ASSERT JohtoBurnedTower1F_BlockEnd - JohtoBurnedTower1F_Block == 64 * 16
JohtoBurnedTower1FRuntimeBlocks:: INCBIN "maps/johto_pilot/BurnedTower1F.runtime.blk"
JohtoBurnedTower1FRuntimeBlocksEnd::
ASSERT JohtoBurnedTower1FRuntimeBlocksEnd - JohtoBurnedTower1FRuntimeBlocks == 10 * 9
JohtoBurnedTower1FRuntimeHeader::
    db JOHTO_BURNED_TOWER_1F ; proposed tileset index; not yet registered
    db 9, 10
    dw JohtoBurnedTower1FRuntimeBlocks
    dw JohtoBurnedTower1FTextPointers
    dw JohtoBurnedTower1FScript
    db 0 ; no cardinal map connection
    dw JohtoBurnedTower1FRuntimeObjects
JohtoBurnedTower1FRuntimeHeaderEnd::
ASSERT JohtoBurnedTower1FRuntimeHeaderEnd - JohtoBurnedTower1FRuntimeHeader == 12
ASSERT BANK(JohtoBurnedTower1FRuntimeHeader) == BANK(JohtoBurnedTower1FRuntimeBlocks)
JohtoBurnedTower1FScript::
    call EnableAutoTextBoxDrawing
    ret
JohtoBurnedTower1FTextPointers:
JohtoBurnedTower1FRuntimeObjects::
    db $00 ; Gold border metatile
    db 14 ; preserve all Gold ordinals
    db 15, 9, 5, JOHTO_REGISTERED_WARP_SELECTOR ; ordinal 0: WARP_CARPET_DOWN
    db 15, 10, 5, JOHTO_REGISTERED_WARP_SELECTOR ; ordinal 1: WARP_CARPET_DOWN
    db 4, 5, 0, JOHTO_REGISTERED_WARP_SELECTOR ; ordinal 2: PIT
    db 5, 5, 0, JOHTO_REGISTERED_WARP_SELECTOR ; ordinal 3: PIT
    db 6, 5, 0, JOHTO_REGISTERED_WARP_SELECTOR ; ordinal 4: PIT
    db 6, 4, 0, JOHTO_REGISTERED_WARP_SELECTOR ; ordinal 5: PIT
    db 4, 15, 1, JOHTO_REGISTERED_WARP_SELECTOR ; ordinal 6: PIT
    db 5, 15, 1, JOHTO_REGISTERED_WARP_SELECTOR ; ordinal 7: PIT
    db 7, 10, 2, JOHTO_REGISTERED_WARP_SELECTOR ; ordinal 8: PIT
    db 14, 5, 3, JOHTO_REGISTERED_WARP_SELECTOR ; ordinal 9: PIT
    db 14, 4, 3, JOHTO_REGISTERED_WARP_SELECTOR ; ordinal 10: PIT
    db 14, 14, 4, JOHTO_REGISTERED_WARP_SELECTOR ; ordinal 11: PIT
    db 14, 15, 4, JOHTO_REGISTERED_WARP_SELECTOR ; ordinal 12: PIT
    db 15, 7, 5, JOHTO_REGISTERED_WARP_SELECTOR ; ordinal 13: LADDER
    db 0 ; deferred signs/NPC dialogue
    db 0

JohtoBurnedTowerB1F_GFX:: INCBIN "gfx/tilesets/johto_burned_tower_b1f.2bpp"
JohtoBurnedTowerB1F_Block:: INCBIN "gfx/blocksets/johto_burned_tower_b1f.bst"
JohtoBurnedTowerB1F_BlockEnd::
ASSERT JohtoBurnedTowerB1F_BlockEnd - JohtoBurnedTowerB1F_Block == 64 * 16
JohtoBurnedTowerB1FRuntimeBlocks:: INCBIN "maps/johto_pilot/BurnedTowerB1F.runtime.blk"
JohtoBurnedTowerB1FRuntimeBlocksEnd::
ASSERT JohtoBurnedTowerB1FRuntimeBlocksEnd - JohtoBurnedTowerB1FRuntimeBlocks == 10 * 9
JohtoBurnedTowerB1FRuntimeHeader::
    db JOHTO_BURNED_TOWER_B1F ; proposed tileset index; not yet registered
    db 9, 10
    dw JohtoBurnedTowerB1FRuntimeBlocks
    dw JohtoBurnedTowerB1FTextPointers
    dw JohtoBurnedTowerB1FScript
    db 0 ; no cardinal map connection
    dw JohtoBurnedTowerB1FRuntimeObjects
JohtoBurnedTowerB1FRuntimeHeaderEnd::
ASSERT JohtoBurnedTowerB1FRuntimeHeaderEnd - JohtoBurnedTowerB1FRuntimeHeader == 12
ASSERT BANK(JohtoBurnedTowerB1FRuntimeHeader) == BANK(JohtoBurnedTowerB1FRuntimeBlocks)
JohtoBurnedTowerB1FScript::
    call EnableAutoTextBoxDrawing
    ret
JohtoBurnedTowerB1FTextPointers:
JohtoBurnedTowerB1FRuntimeObjects::
    db $09 ; Gold border metatile
    db 6 ; preserve all Gold ordinals
    db 3, 3, 2, JOHTO_REGISTERED_WARP_SELECTOR ; ordinal 0: ARRIVAL ONLY; never register as source
    db 7, 17, 6, JOHTO_REGISTERED_WARP_SELECTOR ; ordinal 1: ARRIVAL ONLY; never register as source
    db 8, 10, 8, JOHTO_REGISTERED_WARP_SELECTOR ; ordinal 2: ARRIVAL ONLY; never register as source
    db 13, 3, 9, JOHTO_REGISTERED_WARP_SELECTOR ; ordinal 3: ARRIVAL ONLY; never register as source
    db 14, 17, 11, JOHTO_REGISTERED_WARP_SELECTOR ; ordinal 4: ARRIVAL ONLY; never register as source
    db 15, 7, 13, JOHTO_REGISTERED_WARP_SELECTOR ; ordinal 5: LADDER
    db 0 ; deferred signs/NPC dialogue
    db 1 ; Gold (17,4) Strength boulder, existing RBY engine
    object SPRITE_BOULDER, 17, 4, STAY, BOULDER_MOVEMENT_BYTE_2, $1
