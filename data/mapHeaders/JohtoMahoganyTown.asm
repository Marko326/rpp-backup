; B-East ID64: Gold MahoganyTown 10x9, original Johto blockset.
; WEST -> Route42 active; NORTH Route43 and EAST Route44 unbuilt and fenced.
JohtoMahoganyTown_h:
 db JOHTO
 db JOHTO_MAHOGANY_TOWN_HEIGHT, JOHTO_MAHOGANY_TOWN_WIDTH
 dw JohtoMahoganyTownBlocks, JohtoMahoganyTownTextPointers, EnableAutoTextBoxDrawing
 db NORTH | WEST | EAST
 ; Gold north preview and genuine paired seam; passage is via the original gate Warp.
 db REGION_NATIVE_MAP_SLOT
 dw JohtoRoute43Blocks + JOHTO_ROUTE_43_WIDTH * (JOHTO_ROUTE_43_HEIGHT - 3)
 dw wOverworldMap + 3
 db JOHTO_MAHOGANY_TOWN_WIDTH
 db JOHTO_ROUTE_43_WIDTH
 db JOHTO_ROUTE_43_HEIGHT * 2 - 1
 db 0
 dw wOverworldMap + 1 + JOHTO_ROUTE_43_HEIGHT * (JOHTO_ROUTE_43_WIDTH + 6)
 ; Gold MahoganyTown west -> Route42 east, offset 0: all 9 source rows.
 db REGION_NATIVE_MAP_SLOT
 dw JohtoRoute42Blocks + JOHTO_ROUTE_42_WIDTH - 3
 dw wOverworldMap + 3 * (JOHTO_MAHOGANY_TOWN_WIDTH + 6)
 db JOHTO_MAHOGANY_TOWN_HEIGHT
 db JOHTO_ROUTE_42_WIDTH
 db 0 ; Gold offset 0: arrival Y at same row
 db JOHTO_ROUTE_42_WIDTH * 2 - 1
 dw wOverworldMap + 6 + 2 * JOHTO_ROUTE_42_WIDTH
 ; Gold east -> Route44, offset zero.
 db REGION_NATIVE_MAP_SLOT
 dw JohtoRoute44Blocks
 dw wOverworldMap + 3 * (JOHTO_MAHOGANY_TOWN_WIDTH + 6) + JOHTO_MAHOGANY_TOWN_WIDTH + 3
 db JOHTO_MAHOGANY_TOWN_HEIGHT
 db JOHTO_ROUTE_44_WIDTH
 db 0
 db 0
 dw wOverworldMap + 7 + JOHTO_ROUTE_44_WIDTH
 dw JohtoMahoganyTownObject
