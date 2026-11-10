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
    db 3   ; Gold indices: Route31=0, Blackthorn=1, Route46=2
    db 15, 3, 2, JOHTO_REGISTERED_WARP_SELECTOR
    db 1, 17, 1, JOHTO_REGISTERED_WARP_SELECTOR ; Gold #2 CAVE STEP_IN to Blackthorn #2
    db 33, 35, 2, JOHTO_REGISTERED_WARP_SELECTOR ; Gold Route46 warp #3
    db 0 ; no signs/NPCs/items until later
    db 0

; REF-365: Blackthorn side is the same cave FLOOR, not a B1F.
JohtoDarkCaveBlackthornGoldRoles:: INCBIN "data/johto_dark_cave_stage/DarkCaveBlackthornEntrance.roles.bin"
ASSERT @ - JohtoDarkCaveBlackthornGoldRoles == 30 * 36
JohtoDarkCaveBlackthornRuntimeBlocks:: INCBIN "maps/johto_pilot/DarkCaveBlackthornEntrance.runtime.blk"
ASSERT @ - JohtoDarkCaveBlackthornRuntimeBlocks == JOHTO_DARK_CAVE_BLACKTHORN_WIDTH * JOHTO_DARK_CAVE_BLACKTHORN_HEIGHT
JohtoDarkCaveBlackthornRuntimeHeader::
    db JOHTO_DARK_CAVE
    db JOHTO_DARK_CAVE_BLACKTHORN_HEIGHT, JOHTO_DARK_CAVE_BLACKTHORN_WIDTH
    dw JohtoDarkCaveBlackthornRuntimeBlocks
    dw JohtoDarkCaveBlackthornTextPointers
    dw JohtoDarkCaveBlackthornScript
    db 0
    dw JohtoDarkCaveBlackthornObjects
JohtoDarkCaveBlackthornRuntimeHeaderEnd::
ASSERT JohtoDarkCaveBlackthornRuntimeHeaderEnd - JohtoDarkCaveBlackthornRuntimeHeader == 12
ASSERT BANK(JohtoDarkCaveBlackthornRuntimeHeader) == BANK(JohtoDarkCaveBlackthornRuntimeBlocks)
JohtoDarkCaveBlackthornScript::
    call EnableAutoTextBoxDrawing
    ret
JohtoDarkCaveBlackthornTextPointers:
JohtoDarkCaveBlackthornObjects:
    db $09 ; Gold cave border
    db 2 ; Route45 #1 / Violet-side cave #2, zero-based ordinals 0 and 1
    db 3, 23, 0, JOHTO_REGISTERED_WARP_SELECTOR
    db 25, 3, 1, JOHTO_REGISTERED_WARP_SELECTOR
    db 0 ; no signs or Rock Smash objects in REF-365
    db 0 ; no NPCs, items or wild encounter events
