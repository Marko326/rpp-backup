; REF-349 stage3: Gold Violet cave; Route31 and Route46 exits active, Blackthorn sealed.
JohtoDarkCave_GFX:: INCBIN "gfx/tilesets/johto_dark_cave_violet_gold.2bpp"
; Makefile trims 31 trailing blank 8x8 tiles: 65 tiles remain (1040 bytes).
ASSERT @ - JohtoDarkCave_GFX == 65 * 16
JohtoDarkCave_Block:: INCBIN "gfx/blocksets/johto_dark_cave_violet_gold.bst"
ASSERT @ - JohtoDarkCave_Block == 64 * 16
JohtoDarkCaveGoldRoles:: INCBIN "data/johto_dark_cave_stage/DarkCaveVioletEntrance.roles.bin"
ASSERT @ - JohtoDarkCaveGoldRoles == 40 * 36
JohtoDarkCaveRuntimeBlocks:: INCBIN "maps/johto_pilot/DarkCaveVioletEntrance.runtime.blk"
ASSERT @ - JohtoDarkCaveRuntimeBlocks == JOHTO_DARK_CAVE_WIDTH * JOHTO_DARK_CAVE_HEIGHT
JohtoDarkCaveRuntimeHeader::
    db JOHTO_DARK_CAVE
    db JOHTO_DARK_CAVE_HEIGHT, JOHTO_DARK_CAVE_WIDTH
    dw JohtoDarkCaveRuntimeBlocks
    dw JohtoDarkCaveTextPointers
    dw JohtoDarkCaveScript
    db 0
    dw JohtoDarkCaveObjects
JohtoDarkCaveRuntimeHeaderEnd::
ASSERT JohtoDarkCaveRuntimeHeaderEnd - JohtoDarkCaveRuntimeHeader == 12
ASSERT BANK(JohtoDarkCaveRuntimeHeader) == BANK(JohtoDarkCaveRuntimeBlocks)
JohtoDarkCaveScript::
    call EnableAutoTextBoxDrawing
    ret
JohtoDarkCaveTextPointers:
JohtoDarkCaveObjects:
    db $09 ; original Gold cave border
    db 3   ; Gold indices: Route31=0, Blackthorn=1 (sealed), Route46=2
    db 15, 3, 2, JOHTO_REGISTERED_WARP_SELECTOR
    db $ff, $ff, 0, JOHTO_REGISTERED_WARP_SELECTOR ; unreachable sealed Blackthorn ordinal
    db 33, 35, 2, JOHTO_REGISTERED_WARP_SELECTOR ; Gold Route46 warp #3
    db 0 ; no signs/NPCs/items until later
    db 0
