; R32-245: first map of the southward migration. Legacy compact metatiles
; are byte-identical to the source reference's JohtoRoute32.blk. No cave,
; Pokecenter, ruins gate, or Route33 destinations are live yet.
JohtoPilotRoute32RuntimeHeader::
    db JOHTO_PILOT
    db JOHTO_ROUTE_32_HEIGHT, JOHTO_ROUTE_32_WIDTH
    dw JohtoPilotRoute32RuntimeBlocks
    dw JohtoPilotRoute32TextPointers
    dw JohtoPilotMapScript
    db NORTH
    db JOHTO_RUNTIME_MAP_HANDLE
    dw JohtoPilotVioletRuntimeBlocks + JOHTO_VIOLET_CITY_WIDTH * (JOHTO_VIOLET_CITY_HEIGHT - 3)
    dw wOverworldMap + 3
    db JOHTO_ROUTE_32_WIDTH + 3 ; visual margin needed for city beyond Route32 east edge
    db JOHTO_VIOLET_CITY_WIDTH
    db JOHTO_VIOLET_CITY_HEIGHT * 2 - 1
    db 0
    dw wOverworldMap + 1 + JOHTO_VIOLET_CITY_HEIGHT * (JOHTO_VIOLET_CITY_WIDTH + 6)
    dw JohtoPilotRoute32RuntimeObjects
JohtoPilotRoute32RuntimeHeaderEnd::
ASSERT JohtoPilotRoute32RuntimeHeaderEnd - JohtoPilotRoute32RuntimeHeader == 23
ASSERT BANK(JohtoPilotRoute32RuntimeHeader) == BANK(JohtoPilotRoute32RuntimeBlocks)
ASSERT BANK(JohtoPilotRoute32RuntimeHeader) == BANK(JohtoPilotVioletRuntimeBlocks)

JohtoPilotRoute32TextPointers:
    dw JohtoPilotRoute32Sign
    dw JohtoPilotRoute32Ruins
    dw JohtoPilotRoute32Cave
    dw JohtoPilotRoute32Center
JohtoPilotRoute32Sign:
    text "ROUTE 32"
    para "VIOLET CITY -"
    line "AZALEA TOWN"
    done
    db "@"
JohtoPilotRoute32Ruins:
    text "RUINS OF ALPH"
    para "West gate is open."
    done
    db "@"
JohtoPilotRoute32Cave:
    text "UNION CAVE"
    para "Entrance closed"
    line "for now."
    done
    db "@"
JohtoPilotRoute32Center:
    text "#MON CENTER"
    para "Closed for now."
    done
    db "@"
JohtoPilotRoute32RuntimeObjects::
    db $05 ; source's outdoor forest border
    db 2 ; Gold ruins west gate pair only; center/cave remain closed
    db 2, 4, 2, JOHTO_REGISTERED_WARP_SELECTOR
    db 3, 4, 3, JOHTO_REGISTERED_WARP_SELECTOR
    db 4 ; Gold signs at (Y,X): (5,13), (1,9), (84,10), (73,12)
    db 5, 13, 1
    db 1, 9, 2
    db 84, 10, 3
    db 73, 12, 4
    db 0 ; NPCs / events deliberately deferred
