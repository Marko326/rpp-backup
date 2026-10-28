; P6-001: source-verified Gold GuideGentsHouse indoor runtime.
; Physical stable ID 125, tileset runtime ID 29, dense slot 5.
; Kept in expansion ROMX $46 to avoid ROM0 and crowded $1C/$3D.
JohtoHouse_GFX:: INCBIN "gfx/tilesets/johto_house.2bpp"
JohtoHouse_Block:: INCBIN "gfx/blocksets/johto_house.bst"
JohtoHouse_BlockEnd::
ASSERT JohtoHouse_BlockEnd - JohtoHouse_Block == 13 * 16
; P6-INDOOR-005: JohtoHouse_Coll now lives in ROM0 (home.asm) so that
; player/NPC passability remains independent of the active graphics bank.
ASSERT BANK(JohtoHouse_Coll) == 0

JohtoGuideGentsHouseRuntimeBlocks::
    INCBIN "maps/johto_pilot/GuideGentsHouse.runtime.blk"
JohtoGuideGentsHouseRuntimeBlocksEnd::
ASSERT JohtoGuideGentsHouseRuntimeBlocksEnd - JohtoGuideGentsHouseRuntimeBlocks == JOHTO_GUIDE_GENTS_HOUSE_WIDTH * JOHTO_GUIDE_GENTS_HOUSE_HEIGHT

; P6-001: first real indoor Gold map. Header + blocks + script + objects
; live together in ROMX $46. No outdoor connections; two registered exits.
JohtoGuideGentsHouseRuntimeHeader::
    db JOHTO_HOUSE
    db JOHTO_GUIDE_GENTS_HOUSE_HEIGHT, JOHTO_GUIDE_GENTS_HOUSE_WIDTH
    dw JohtoGuideGentsHouseRuntimeBlocks
    dw JohtoGuideGentsHouseTextPointers
    dw JohtoGuideGentsHouseMapScript
    db 0
    dw JohtoGuideGentsHouseRuntimeObjects
JohtoGuideGentsHouseRuntimeHeaderEnd::
ASSERT JohtoGuideGentsHouseRuntimeHeaderEnd - JohtoGuideGentsHouseRuntimeHeader == 12
ASSERT BANK(JohtoGuideGentsHouseRuntimeHeader) == BANK(JohtoGuideGentsHouseRuntimeBlocks)

JohtoGuideGentsHouseMapScript::
    call EnableAutoTextBoxDrawing
    ret

JohtoGuideGentsHouseTextPointers:
    ; No story NPCs or scripts in the map-only milestone.

JohtoGuideGentsHouseRuntimeObjects::
    db $0c ; original reference house border metatile
    db 2
    db 7, 2, 0, JOHTO_REGISTERED_WARP_SELECTOR
    db 7, 3, 0, JOHTO_REGISTERED_WARP_SELECTOR
    db 0 ; no text/sign events
    db 0 ; no NPC events yet

