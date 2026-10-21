; B-East ID64: Gold MahoganyTown 10x9, original Johto blockset.
; WEST -> Route42 active; NORTH Route43 and EAST Route44 unbuilt and fenced.
JohtoMahoganyTown_h:
 db JOHTO
 db JOHTO_MAHOGANY_TOWN_HEIGHT, JOHTO_MAHOGANY_TOWN_WIDTH
 dw JohtoMahoganyTownBlocks, JohtoMahoganyTownTextPointers, EnableAutoTextBoxDrawing
 db WEST
 ; Gold MahoganyTown west -> Route42 east, offset 0: all 9 source rows.
 db REGION_NATIVE_MAP_SLOT
 dw JohtoRoute42Blocks + JOHTO_ROUTE_42_WIDTH - 3
 dw wOverworldMap + 3 * (JOHTO_MAHOGANY_TOWN_WIDTH + 6)
 db JOHTO_MAHOGANY_TOWN_HEIGHT
 db JOHTO_ROUTE_42_WIDTH
 db 0 ; Gold offset 0: arrival Y at same row
 db JOHTO_ROUTE_42_WIDTH * 2 - 1
 dw wOverworldMap + 6 + 2 * JOHTO_ROUTE_42_WIDTH
 dw JohtoMahoganyTownObject
